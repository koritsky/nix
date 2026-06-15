{ ... }:

{
  imports = [
    ../home.nix
    ../modules/linux.nix
  ];

  home = {
    username = "nikita";
    homeDirectory = "/home/nikita";
  };
}
