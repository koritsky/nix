{ config, lib, ... }:

let
  envSecrets = import ../lib/secrets.nix;
in
{
  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    secrets = lib.genAttrs envSecrets (_: { });
  };
}
