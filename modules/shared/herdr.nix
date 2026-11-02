{ ... }:

{
  imports = [ ./herdr-plugins.nix ];

  # Package comes from llm-agents (flake.nix); defaults apart from what's below.
  programs.herdr = {
    enable = true;
    settings = {
      onboarding = false;
      ui = {
        sound.enabled = false;
        toast.delivery = "off"; # no pop-up notifications
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
