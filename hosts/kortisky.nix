{ ... }:

{
  imports = [
    ../home.nix
    ../modules/darwin.nix
  ];

  profile = {
    name = "kortisky";
    username = "kortisky";
    homeDirectory = "/Users/kortisky";
    email = "koritcky@gmail.com";
    gitName = "Nikita Koritskii";
  };
}
