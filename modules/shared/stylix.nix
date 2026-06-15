{ pkgs, lib, ... }:

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
      font-packages.enable = true;
      fontconfig.enable = true;
      bat.enable = true;
      fzf.enable = true;
      starship.enable = true;
      zellij.enable = true;
      helix.enable = true;
    };
  };
}
