{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../home.nix
    ../modules/linux.nix
  ];

  profile = {
    # mkDefault: hosts built on top of this one (renate, delta-*) set their own,
    # so `nup` there switches to their config rather than this one.
    name = lib.mkDefault "server-linux";
    username = "nikita";
    homeDirectory = "/home/nikita";
  };

  # Personal Rex server as a systemd user service, on the tailnet as its own
  # node (Rex's built-in Tailscale — no tailscaled on the box). Reach it at
  # https://rex-<host>.<tailnet>.ts.net. First start: open the sign-in link
  # from `rex server status` / `journalctl --user -u rex`. Deploys don't
  # restart a running server (that would end its sessions): `systemctl --user
  # restart rex` picks up a new version.
  #
  # SSH_AUTH_SOCK: Rex shells get the Mac's agent through a fixed socket path
  # that rex-forward-agent (below) links to while the Mac holds an `ssh -A`
  # open — see modules/darwin-rex.nix. Takes effect after that restart.
  services.rex = {
    enable = true;
    environment.SSH_AUTH_SOCK = "${config.home.homeDirectory}/.ssh/rex-agent.sock";
    tailscale = {
      enable = true;
      hostname = "rex-${config.profile.name}";
    };
  };

  # Run by the Mac's per-host launchd job: link this login's forwarded agent to
  # ~/.ssh/rex-agent.sock and hold the connection open. On exit, remove the
  # link only if it is still ours (a newer connection may have replaced it).
  home.file.".local/libexec/rex-forward-agent".source = lib.getExe (
    pkgs.writeShellApplication {
      name = "rex-forward-agent";
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        if [[ -z "''${SSH_AUTH_SOCK:-}" || ! -S "''${SSH_AUTH_SOCK:-}" ]]; then
          echo "SSH agent forwarding is unavailable" >&2
          exit 1
        fi

        socket="$HOME/.ssh/rex-agent.sock"
        install -d -m 0700 "$HOME/.ssh"
        ln -sfn -- "$SSH_AUTH_SOCK" "$socket"
        trap 'if [[ "$(readlink "$socket")" == "$SSH_AUTH_SOCK" ]]; then rm -f -- "$socket"; fi' EXIT
        trap 'exit 0' HUP INT TERM
        sleep infinity &
        wait "$!"
      '';
    }
  );

  # Keep user services (Rex) running after logout. Enabling lingering for
  # yourself needs polkit to allow it without a password; if it doesn't, this
  # warns instead of failing the deploy.
  home.activation.enableLinger = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e /var/lib/systemd/linger/${config.home.username} ]; then
      run /usr/bin/loginctl --no-ask-password enable-linger ${config.home.username} \
        || warnEcho "Could not enable lingering; run 'sudo loginctl enable-linger ${config.home.username}' so Rex survives logout."
    fi
  '';
}
