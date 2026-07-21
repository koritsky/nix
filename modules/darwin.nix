{ pkgs, ... }:

{
  # No sops on the Macs — secrets are kept as plain files on the machine, not
  # provisioned/decrypted by nix. (Linux servers still use sops.)
  profile.secrets = false;

  home.file.".aerospace.toml".source = ../files/aerospace.toml;

  home.packages = [
    # Clickable desktop notifications for zellaude (macOS only). Without it the
    # hook falls back to osascript, whose notifications can't focus the pane.
    pkgs.terminal-notifier

    # Docker via colima instead of Docker Desktop/OrbStack: macOS has no native
    # container runtime, so colima runs a lightweight Linux VM that hosts the
    # docker daemon; docker-client is the CLI that talks to it. All in the
    # user profile — no Homebrew, no sudo. Bring the daemon up with `colima
    # start` (persists across reboots once started).
    pkgs.colima
    pkgs.docker-client
    pkgs.docker-compose
  ];
}
