{ ... }:

{
  imports = [
    ../home.nix
    ../modules/darwin.nix
  ];

  profile = {
    name = "nikitaak";
    username = "nikitaak";
    homeDirectory = "/Users/nikitaak";
  };
}
