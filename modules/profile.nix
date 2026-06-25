{ lib, config, ... }:

{
  options.profile = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "Host name — matches the flake's homeConfigurations key (used by `nup`).";
    };
    username = lib.mkOption {
      type = lib.types.str;
      description = "Unix username for this host.";
    };
    homeDirectory = lib.mkOption {
      type = lib.types.str;
      description = "Absolute path to the user's home directory.";
    };
    email = lib.mkOption {
      type = lib.types.str;
      description = "Email used for git/jujutsu commits.";
    };
    gitName = lib.mkOption {
      type = lib.types.str;
      description = "Display name used for git/jujutsu commits.";
    };
    secrets = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to provision sops secrets and export them in the shell.
        Disable on hosts that don't have the age key (e.g. a NixOS box managed
        by another flake where the key isn't provisioned yet).
      '';
    };
  };

  # mkDefault so the nix-darwin home-manager module (which sets these from the
  # user name) can override; standalone home-manager still needs them set here.
  config.home = {
    username = lib.mkDefault config.profile.username;
    homeDirectory = lib.mkDefault config.profile.homeDirectory;
  };
}
