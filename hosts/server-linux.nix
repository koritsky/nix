{ lib, ... }:

{
  imports = [
    ../home.nix
    ../modules/linux.nix
  ];

  profile = {
    # mkDefault: hosts built on top of this one (renate, delta-*) set their own,
    # so `nup` there switches to their config rather than this one.
    name = lib.mkDefault "server-linux";
    username = "nikita";
    homeDirectory = "/home/nikita";
  };
}
