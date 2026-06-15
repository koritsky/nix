{ ... }:

{
  imports = [
    ../home.nix
    ../modules/darwin.nix
  ];

  profile = {
    name = "laptop";
    username = "nikitaak";
    homeDirectory = "/Users/nikitaak";
    email = "koritcky@gmail.com";
    gitName = "Nikita Koritskii";
  };
}
