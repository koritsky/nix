{ config, ... }:

{
  programs = {
    git = {
      enable = true;
      settings = {
        user = {
          email = config.profile.email;
          name = config.profile.gitName;
        };
        push.autoSetupRemote = true;
      };
      lfs.enable = true;
    };
  };
}
