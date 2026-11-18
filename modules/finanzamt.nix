{
  config,
  lib,
  pkgs,
  ...
}:

# finanzamt (personal finance + documents dashboard, github.com/koritsky/finanzamt)
# on kit-thinkpad. The app is a git checkout in ~/finanzamt that the Mac pushes to
# with `just deploy` (which also builds and restarts it); paperless-ngx runs from
# Docker in ~/paperless. This module only runs them:
#
# - finanzamt-api / finanzamt-web: FastAPI on 127.0.0.1:8000, Next.js on
#   127.0.0.1:3000, from the checkout. The SQLite DB is ~/finanzamt/finanzamt.db.
# - tailnet-finanzamt / tailnet-paperless: each app as its own tailnet node, so the
#   browser address is http://finanzamt/ or http://paperless/ (and
#   https://<name>.<tailnet>.ts.net; the finanzamt API is on :8443). One userspace
#   tailscaled per name, beside the box's own (apt) tailscaled. First start of a
#   node: `ts-finanzamt up --hostname=finanzamt` (or ts-paperless), open the
#   sign-in link, then turn off key expiry for that machine in the admin console.
#   The serve config below is (re)applied on every start.
# - timers: price refresh 18:30, DB backup 02:30, paperless backup 02:45. Each job
#   records its outcome in ~/finanzamt/backups/status (shown on the /system page).
#   Logs: `journalctl --user -u <name>`.
let
  home = config.home.homeDirectory;
  app = "${home}/finanzamt";
  stateRoot = "${home}/.local/state/tailnet-nodes";
  tailnet = "tailf5a5bb.ts.net";

  # What the app and its scripts call. /usr/bin comes last for docker (apt) and
  # shasum.
  path =
    lib.makeBinPath (
      with pkgs;
      [
        uv
        nodejs_24
        bash
        coreutils
        findutils
        gnugrep
        gnused
        gnutar
        gzip
        sqlite
        rclone
        openssh
        rsync
      ]
    )
    + ":/usr/bin:/bin";

  # name -> `tailscale serve` targets for that node.
  nodes = {
    finanzamt = [
      "--https=443 http://127.0.0.1:3000"
      "--http=80 http://127.0.0.1:3000"
      "--https=8443 http://127.0.0.1:8000"
    ];
    paperless = [
      "--https=443 http://127.0.0.1:8010"
      "--http=80 http://127.0.0.1:8010"
    ];
  };

  socket = name: "${stateRoot}/${name}/tailscaled.sock";
  cli = name: "${pkgs.tailscale}/bin/tailscale --socket=${socket name}";

  # Apply the serve config once the node is up (and signed in).
  serveScript =
    name: targets:
    pkgs.writeShellScript "tailnet-${name}-serve" ''
      for _ in $(seq 1 60); do
        ${cli name} status >/dev/null 2>&1 && break
        sleep 1
      done
      ${lib.concatMapStringsSep "\n" (t: "${cli name} serve --bg ${t} >/dev/null") targets}
    '';

  tailnetNode = name: targets: {
    Unit = {
      Description = "Tailnet node ${name} (userspace tailscaled)";
      After = [ "network-online.target" ];
    };
    Service = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${stateRoot}/${name}";
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.tailscale}/bin/tailscaled"
        "--tun=userspace-networking"
        "--statedir=${stateRoot}/${name}"
        "--socket=${socket name}"
        "--port=0"
      ];
      # "-": not signed in yet is fine; `ts-<name> up` then restart applies it.
      ExecStartPost = "-${serveScript name targets}";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  appService = description: dir: env: exec: {
    Unit = {
      Description = description;
      After = [ "network-online.target" ];
    };
    Service = {
      WorkingDirectory = dir;
      Environment = [ "PATH=${path}" ] ++ env;
      ExecStart = exec;
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  job = description: env: command: {
    Unit.Description = description;
    Service = {
      Type = "oneshot";
      WorkingDirectory = app;
      Environment = [ "PATH=${path}" ] ++ env;
      ExecStart = "${pkgs.bash}/bin/bash -c ${lib.escapeShellArg command}";
    };
  };

  daily = description: time: {
    Unit.Description = description;
    Timer = {
      OnCalendar = "*-*-* ${time}";
      Persistent = true; # catch up after the laptop was off
    };
    Install.WantedBy = [ "timers.target" ];
  };
in
{
  # nodejs/sqlite/rclone for `just deploy` and working in ~/finanzamt over SSH;
  # ts-<name> is the tailscale CLI of each node.
  home.packages =
    (with pkgs; [
      nodejs_24
      sqlite
      rclone
    ])
    ++ lib.mapAttrsToList (
      name: _: pkgs.writeShellScriptBin "ts-${name}" ''exec ${cli name} "$@"''
    ) nodes;

  systemd.user.services = {
    finanzamt-api =
      appService "finanzamt API" app
        [
          "FINANZAMT_CORS_ORIGINS=http://finanzamt,https://finanzamt.${tailnet}"
          "FINANZAMT_WEB_URL=http://finanzamt"
        ]
        "${pkgs.uv}/bin/uv run --frozen --no-dev uvicorn finanzamt.api.main:app --host 127.0.0.1 --port 8000";

    finanzamt-web = appService "finanzamt web app" "${app}/web" [
      "API_BASE_INTERNAL=http://127.0.0.1:8000"
      "NODE_ENV=production"
    ] "${pkgs.nodejs_24}/bin/npm run start -- --hostname 127.0.0.1 --port 3000";

    finanzamt-prices-refresh =
      job "finanzamt: refresh holding prices" [ ]
        "uv run --frozen --no-dev python scripts/refresh_prices.py";
    finanzamt-db-backup =
      job "finanzamt: back up the database to Google Drive" [ ]
        "bash scripts/db_backup_to_gdrive.sh";
    finanzamt-paperless-backup = job "finanzamt: back up paperless to Google Drive" [
      "FINANZAMT_PAPERLESS_HOST=local"
      # sg: the user manager may predate kit joining the docker group.
    ] "/usr/bin/sg docker -c 'bash scripts/paperless_backup_to_gdrive.sh'";
  }
  // lib.mapAttrs' (
    name: targets: lib.nameValuePair "tailnet-${name}" (tailnetNode name targets)
  ) nodes;

  systemd.user.timers = {
    finanzamt-prices-refresh = daily "finanzamt: refresh holding prices daily" "18:30:00";
    finanzamt-db-backup = daily "finanzamt: back up the database daily" "02:30:00";
    finanzamt-paperless-backup = daily "finanzamt: back up paperless daily" "02:45:00";
  };
}
