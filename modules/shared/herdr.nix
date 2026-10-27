{ pkgs, ... }:

{
  imports = [ ./herdr-plugins.nix ];

  # Package comes from llm-agents (flake.nix); defaults apart from what's below.
  programs.herdr = {
    enable = true;
    plugins = [ (pkgs.callPackage ../../pkgs/herdr-sesh.nix { }) ];
    settings = {
      onboarding = false;
      keys = {
        settings = "prefix+comma";
        next_agent = "prefix+]";
        previous_agent = "prefix+[";
        # Plugin actions have no default key; prefix+s as in egor's config.
        command = [
          {
            key = "prefix+s";
            type = "plugin_action";
            command = "fullerzz.sesh.open-picker";
            description = "open Sesh picker";
          }
        ];
      };
    };
  };
}
