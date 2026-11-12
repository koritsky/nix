{ ... }:

{
  imports = [
    ../home.nix
    ../modules/darwin.nix
    ../modules/darwin-rex.nix
  ];

  profile = {
    name = "nikitaak";
    username = "nikitaak";
    homeDirectory = "/Users/nikitaak";
  };
}
