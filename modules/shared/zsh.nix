{ config, lib, ... }:

let
  envSecrets = import ../../lib/secrets.nix;
  secretToEnv = name: lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] name);
  exportSecrets = lib.concatMapStringsSep "\n" (
    name:
    let
      path = config.sops.secrets.${name}.path;
    in
    "[ -r ${path} ] && export ${secretToEnv name}=\"$(cat ${path})\""
  ) envSecrets;
in
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    shellAliases = {
      zl = "zellij";
      zlm = "zl a main";
      zla = "zl a --index 0";
      ysudo = "sudo yazi";
    };

    initContent = lib.mkMerge [
      (builtins.readFile ../../files/zsh-init.sh)
      exportSecrets
    ];
  };
}
