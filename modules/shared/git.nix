{ ... }:

{
  programs = {
    git = {
      enable = true;
      settings = {
        user = {
          email = "koritcky@gmail.com";
          name = "Nikita Koritskii";
        };
        push.autoSetupRemote = true;
        core.pager = "delta --side-by-side";
        interactive.diffFilter = "delta --side-by-side --color-only";
      };
      lfs.enable = true;
    };
    delta = {
      enable = true;
      options = {
        side-by-side = true;
        navigate = true;
        line-numbers = true;
        dark = true;
      };
    };
    jujutsu = {
      enable = true;
      settings.user = {
        email = "koritcky@gmail.com";
        name = "Nikita Koritskii";
      };
    };
  };
}
