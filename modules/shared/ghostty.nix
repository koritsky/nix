{ lib, pkgs, ... }:

# Based on egorchakov/nix-config (modules/home/gui.nix, modules/home/darwin/terminal.nix),
# minus its nushell command/PATH. The app is a Homebrew cask, so package = null and
# this only writes ~/.config/ghostty/config.
{
  programs.ghostty = {
    enable = pkgs.stdenv.hostPlatform.isDarwin;
    package = null;
    settings = {
      window-inherit-working-directory = true;
      window-decoration = false;
      focus-follows-mouse = true;
      shell-integration-features = "sudo,no-ssh-env,no-ssh-terminfo";
      font-size = lib.mkForce 16;
      macos-option-as-alt = "left";
    };
  };

  # Colors and font from the Stylix theme.
  stylix.targets.ghostty.enable = true;
}
