{ pkgs, ... }:

{
  # The app is installed outside Nix; this only writes ~/.config/ghostty/config.
  # Stylix's ghostty target stays off (autoEnable = false), so theme/font are set here.
  programs.ghostty = {
    enable = pkgs.stdenv.hostPlatform.isDarwin;
    package = null;
    settings = {
      # Font
      font-family = "JetBrains Mono";
      font-size = 13;
      font-feature = "-calt"; # no ligatures
      adjust-cell-height = "15%";

      # Theme: follows macOS light/dark
      theme = "light:Catppuccin Latte,dark:Catppuccin Mocha";
      minimum-contrast = 1.1;

      # Padding
      window-padding-x = 12;
      window-padding-y = 8;
      window-padding-balance = true;
      window-padding-color = "extend";

      # Less distraction
      cursor-style = "block";
      cursor-style-blink = false;
      mouse-hide-while-typing = true;
      unfocused-split-opacity = 0.85;
      confirm-close-surface = false;

      # Workflow
      copy-on-select = "clipboard";
      shell-integration-features = "cursor,sudo,title";
      scrollback-limit = 100000000; # bytes, ~100MB
      clipboard-paste-protection = true;

      keybind = [
        # Splits
        "ctrl+shift+enter=new_split:auto"
        "ctrl+shift+h=goto_split:left"
        "ctrl+shift+l=goto_split:right"
        "ctrl+shift+k=goto_split:top"
        "ctrl+shift+j=goto_split:bottom"
        "ctrl+shift+z=toggle_split_zoom"
        # Drop-down terminal; global keybinds need Accessibility permission
        "global:ctrl+grave_accent=toggle_quick_terminal"
      ];
    };
  };
}
