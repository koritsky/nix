{ pkgs, ... }:

{
  imports = [ ./herdr-plugins.nix ];

  # Package comes from llm-agents (flake.nix); defaults apart from what's below.
  programs.herdr = {
    enable = true;
    plugins = [
      (pkgs.callPackage ../../pkgs/herdr-sesh.nix { })
      (pkgs.callPackage ../../pkgs/herdr-bar.nix { })
    ];
    settings = {
      onboarding = false;
      keys = {
        settings = "prefix+comma";
        next_agent = "prefix+]";
        previous_agent = "prefix+[";
        split_vertical = "prefix+v"; # side by side (herdr's default too)
        split_horizontal = "prefix+d"; # stacked; default is prefix+minus
        # Plugin actions have no default key; prefix+s as in egor's config.
        command = [
          {
            key = "prefix+s";
            type = "plugin_action";
            command = "fullerzz.sesh.open-picker";
            description = "open Sesh picker";
          }
          {
            key = "prefix+k";
            type = "plugin_action";
            command = "herdr-bar.open";
            description = "command bar";
          }
        ];
      };
    };
  };
}
