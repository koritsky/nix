{
  config,
  lib,
  pkgs,
  rexHosts,
  ...
}:

# Forward this Mac's SSH agent into Rex sessions on the servers. Rex connects
# over its own Tailscale endpoint, not SSH, so its shells get no agent. Instead
# each server's Rex service points SSH_AUTH_SOCK at ~/.ssh/rex-agent.sock
# (hosts/server-linux.nix), and here one launchd job per server keeps an
# `ssh -A` open that links its forwarded agent to that path. The jobs only run
# while the Rex app is open: rex-agent-watch loads them when it starts and
# unloads them when it quits. From egorchakov/nix-config
# (modules/home/darwin/rex.nix); drop it all once Rex forwards agents itself.
let
  user = "nikita"; # account on the servers

  watcher = pkgs.runCommandCC "rex-agent-watch" { } ''
    mkdir -p "$out/bin"
    $CC -O2 -fobjc-arc -fblocks -framework AppKit \
      ${../files/rex-agent-watch.m} -o "$out/bin/rex-agent-watch"
  '';

  jobs = pkgs.linkFarm "rex-agent-jobs" (
    map (host: {
      name = "${host}.plist";
      path = pkgs.writeText "rex-agent-${host}.plist" (
        lib.generators.toPlist { escape = true; } {
          Label = "org.nix-community.home.rex-agent.${host}";
          ProgramArguments = [
            "/usr/bin/ssh"
            "-A"
            "-n"
            "-tt"
            "-S"
            "none"
            "-o"
            "BatchMode=yes"
            # ~/.ssh/config adds a pile of LocalForwards to these hosts; they'd
            # clash with the interactive sessions.
            "-o"
            "ClearAllForwardings=yes"
            "-o"
            "ConnectTimeout=10"
            "-o"
            "ServerAliveInterval=30"
            "-o"
            "ServerAliveCountMax=3"
            "-o"
            "LogLevel=ERROR"
            "-l"
            user
            host
            "/home/${user}/.local/libexec/rex-forward-agent"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          ThrottleInterval = 30;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/rex-agent-${host}.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/rex-agent-${host}.log";
        }
      );
    }) rexHosts
  );
in
{
  launchd.agents.rex-agent-watch = {
    enable = true;
    config = {
      ProgramArguments = [
        "${watcher}/bin/rex-agent-watch"
        "${jobs}"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/rex-agent-watch.log";
    };
  };
}
