{ lib, pkgs, ... }:

{
  imports = [ ./herdr-plugins.nix ];

  # macOS system toasts: without it herdr falls back to osascript, which shows
  # as "Script Editor" and can't focus the terminal on click.
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.terminal-notifier ];

  # Package comes from llm-agents (flake.nix); defaults apart from what's below.
  programs.herdr = {
    enable = true;
    settings = {
      onboarding = false;
      ui = {
        sound.enabled = false;
        # OS notification center instead of herdr's in-app toast.
        toast.delivery = "system";
      };
      keys = {
        settings = "prefix+comma";
        next_agent = "prefix+]";
        previous_agent = "prefix+[";
        split_vertical = "prefix+v"; # side by side (herdr's default too)
        split_horizontal = "prefix+d"; # stacked; default is prefix+minus
      };
    };
  };
}
