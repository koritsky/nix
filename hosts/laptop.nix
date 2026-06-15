{ ... }:

{
  imports = [
    ../home.nix
    ../modules/darwin.nix
  ];

  home = {
    username = "nikitaak";
    homeDirectory = "/Users/nikitaak";
  };
}
