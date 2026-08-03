{ lib, pkgs, ... }:

{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/onedark.yaml";
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sizes.terminal = 14;
    };
    autoEnable = false;
    targets = {
      # mkDefault: headless hosts turn these off in modules/linux.nix.
      font-packages.enable = lib.mkDefault true;
      fontconfig.enable = lib.mkDefault true;
      bat.enable = true;
      fzf.enable = true;
      starship.enable = true;
      zellij.enable = true;
      helix.enable = true;
    };
  };
}
