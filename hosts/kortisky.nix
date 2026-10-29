{ lib, ... }:

{
  imports = [
    ../home.nix
    ../modules/darwin.nix
  ];

  # kortisky is rarely logged in, so its gui/501 launchd domain doesn't exist and
  # bootstrapping the agent fails, aborting the whole darwin-rebuild activation.
  services.home-manager.autoExpire.enable = lib.mkForce false;

  profile = {
    name = "kortisky";
    username = "kortisky";
    homeDirectory = "/Users/kortisky";
  };
}
