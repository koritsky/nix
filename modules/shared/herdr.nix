{ ... }:

{
  # Adapted from egorchakov/nix-config (modules/home/herdr.nix), minus the
  # nushell shell, kanagawa theme and sesh plugin. Package is nixpkgs' herdr.
  programs.herdr = {
    enable = true;
    settings = {
      onboarding = false;
      update = {
        version_check = false;
        manifest_check = false;
      };
      ui = {
        sidebar_start_collapsed = true;
        sidebar_collapsed_mode = "hidden";
        prompt_new_tab_name = false;
        pane_gaps = false;
        sound.enabled = false;
      };
      keys = {
        settings = "prefix+comma";
        next_agent = "prefix+]";
        previous_agent = "prefix+[";
        copy_mode = "prefix+shift+c";
      };
    };
  };
}
