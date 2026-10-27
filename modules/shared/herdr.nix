{ pkgs, ... }:

{
  imports = [ ./herdr-plugins.nix ];

  # Stock herdr from nixpkgs; defaults apart from what's below.
  programs.herdr = {
    enable = true;
    plugins = [ (pkgs.callPackage ../../pkgs/herdr-sesh.nix { }) ];
    settings = {
      onboarding = false;
      # Plugin actions have no default key; prefix+s as in egor's config.
      keys.command = [
        {
          key = "prefix+s";
          type = "plugin_action";
          command = "fullerzz.sesh.open-picker";
          description = "open Sesh picker";
        }
      ];
    };
  };
}
