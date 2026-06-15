{ ... }:

{
  imports = [
    ../home.nix
    ../modules/linux.nix
  ];

  profile = {
    name = "server-linux";
    username = "nikita";
    homeDirectory = "/home/nikita";
    email = "koritcky@gmail.com";
    gitName = "Nikita Koritskii";
  };
}
