{ pkgs, ... }:

let
  # clipssh — copy content to the local clipboard from inside an SSH session.
  # Not in nixpkgs, so fetch the upstream script (pinned by hash; re-fetch +
  # bump the hash when it changes) and wrap it so pngpaste is always on its
  # PATH regardless of the caller's environment. Lands in the nix profile bin
  # (already on PATH) — no ~/.local/bin, no ./install.sh.
  clipsshSrc = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/samuellawrentz/clipssh/main/clipssh";
    hash = "sha256-Ukhdx/geyuW3EVrvlwm22X/8Ghq65R0LAL3oHmRuqyA=";
  };
  clipssh = pkgs.runCommandLocal "clipssh" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
    install -Dm755 ${clipsshSrc} $out/bin/clipssh
    wrapProgram $out/bin/clipssh --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.pngpaste ]}
  '';
in
{
  # No sops on the Macs — secrets are kept as plain files on the machine, not
  # provisioned/decrypted by nix. (Linux servers still use sops.)
  profile.secrets = false;

  home.file.".aerospace.toml".source = ../files/aerospace.toml;

  home.packages = [
    # Clickable desktop notifications for zellaude (macOS only). Without it the
    # hook falls back to osascript, whose notifications can't focus the pane.
    pkgs.terminal-notifier

    # Paste clipboard images as PNG. From nixpkgs rather than Homebrew —
    # /opt/homebrew is owned by the other user, so `brew install` fails for us.
    # Also bundled into clipssh; kept here so `pngpaste` works standalone too.
    pkgs.pngpaste

    # clipssh (declared in the let block above).
    clipssh

    # Docker via colima instead of Docker Desktop/OrbStack: macOS has no native
    # container runtime, so colima runs a lightweight Linux VM that hosts the
    # docker daemon; docker-client is the CLI that talks to it. All in the
    # user profile — no Homebrew, no sudo. Bring the daemon up with `colima
    # start`; it does not auto-start at login, so re-run it after a reboot.
    pkgs.colima
    pkgs.docker-client
    pkgs.docker-compose
  ];
}
