{ config, pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    zellij
    lazygit
    git
    curl
    wget
    fzf
    ripgrep
    fd
    bat
    nodejs
  ];

  programs.git.enable = true;
  programs.fzf.enable = true;

  programs.zsh = {
    enable = true;
    shellAliases = {
      lg = "lazygit";
      zj = "zellij";
    };
  };
}
