{ pkgs, ... }:

# zellaude — a Zellij tab-bar plugin that shows per-tab Claude Code activity
# (thinking / running bash / waiting for permission) and rings the terminal bell
# on permission requests. https://github.com/ishefi/zellaude
#
# Wired declaratively instead of via the upstream ./install.sh: the plugin
# otherwise self-registers by editing ~/.claude/settings.json at runtime, which
# our home-manager activation overwrites on every deploy. Here the wasm, the hook
# bridge script (tagged `# zellaude v0.5.0`), and the Claude hooks (in claude.nix)
# are all pinned, so the plugin's installer sees everything "current" and never
# touches settings.json. The wasm is architecture-independent — one fetch serves
# every host (darwin + x86_64/aarch64 linux).
let
  version = "0.5.0";
  wasm = pkgs.fetchurl {
    url = "https://github.com/ishefi/zellaude/releases/download/v${version}/zellaude.wasm";
    hash = "sha256-HWtHklUKLQgzpr8ndxhOz5urQWwXi0nDF7XhsM2ELCQ=";
  };
in
{
  xdg.configFile = {
    "zellij/plugins/zellaude.wasm".source = wasm;

    # Placed as-is (tag intact) so the plugin's idempotent self-installer finds
    # its version tag and the registered path in settings.json, and no-ops.
    "zellij/plugins/zellaude-hook.sh" = {
      source = ../../files/zellaude-hook.sh;
      executable = true;
    };

    # Default layout: zellaude bar on top (replaces zellij:tab-bar), the standard
    # status-bar kept on the bottom for keybind hints.
    "zellij/layouts/default.kdl".text = ''
      layout {
          default_tab_template {
              pane size=1 borderless=true {
                  plugin location="file:~/.config/zellij/plugins/zellaude.wasm"
              }
              children
              pane size=2 borderless=true {
                  plugin location="zellij:status-bar"
              }
          }
      }
    '';
  };
}
