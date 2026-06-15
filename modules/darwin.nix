{ ... }:

{
  programs.zsh.shellAliases = {
    nup = "git -C ~/nix pull && home-manager switch -b backup --flake ~/nix#laptop";
  };

  home.file.".aerospace.toml".source = ../files/aerospace.toml;
}
