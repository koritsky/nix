{ pkgs, ... }:

{
  # No sops on the Macs — secrets are kept as plain files on the machine, not
  # provisioned/decrypted by nix. (Linux servers still use sops.)
  profile.secrets = false;

  home.file.".aerospace.toml".source = ../files/aerospace.toml;

  # Clickable desktop notifications for zellaude (macOS only). Without it the
  # hook falls back to osascript, whose notifications can't focus the pane.
  home.packages = [ pkgs.terminal-notifier ];
}
