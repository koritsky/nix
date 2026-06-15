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
  };

  config.home = {
    username = config.profile.username;
    homeDirectory = config.profile.homeDirectory;
  };
}
