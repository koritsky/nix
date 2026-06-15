{ pkgs, lib, ... }:

{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = lib.mkForce "zedonedark";
      editor = {
        auto-save = true;
        true-color = true;
        idle-timeout = 0;
        completion-trigger-len = 1;
        statusline = {
          left = [
            "mode"
            "spinner"
            "file-name"
            "read-only-indicator"
            "file-modification-indicator"
          ];
          center = [ ];
          right = [
            "diagnostics"
            "version-control"
          ];
        };
        indent-guides = {
          render = true;
          skip-levels = 2;
        };
        soft-wrap.enable = true;
        file-picker.hidden = false;
      };
      keys.select = {
        k = [
          "extend_line_up"
          "extend_to_line_bounds"
        ];
        j = [
          "extend_line_down"
          "extend_to_line_bounds"
        ];
      };
      keys.normal = {
        C-k = "jump_forward";
        C-j = "jump_backward";
        A-S-h = "jump_view_left";
        A-S-l = "jump_view_right";
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "${pkgs.nixfmt}/bin/nixfmt";
            args = [
              "--verify"
              "--strict"
            ];
          };
          language-servers = [
            "nixd"
            "statix"
          ];
        }
        {
          name = "python";
          auto-format = true;
          language-servers = [
            "ruff"
            "ty"
          ];
        }
        {
          name = "toml";
          auto-format = true;
        }
        {
          name = "yaml";
          auto-format = true;
          formatter = {
            command = "${pkgs.yamlfmt}/bin/yamlfmt";
            args = [ "-" ];
          };
        }
        {
          name = "just";
          auto-format = true;
        }
        {
          name = "markdown";
          language-servers = [ "markdown-oxide" ];
        }
      ];
      language-server = {
        ty = {
          command = "ty";
          args = [ "server" ];
          config.experimental = {
            rename = true;
            autoImport = true;
          };
        };
        ruff = {
          command = "${pkgs.ruff}/bin/ruff";
          args = [ "server" ];
          config.settings.format.preview = true;
        };
        nixd = {
          command = "${pkgs.nixd}/bin/nixd";
          args = [ "--semantic-tokens=true" ];
        };
        markdown-oxide = {
          command = "${pkgs.markdown-oxide}/bin/markdown-oxide";
        };
        statix = {
          command = "${pkgs.efm-langserver}/bin/efm-langserver";
          config.languages.nix = [
            {
              lintCommand = "${pkgs.statix}/bin/statix check --stdin --format=errfmt";
              lintStdIn = true;
              lintIgnoreExitCode = true;
              lintFormats = [ "<stdin>>%l:%c:%t:%n:%m" ];
              rootMarkers = [
                "flake.nix"
                "shell.nix"
                "default.nix"
              ];
            }
          ];
        };
      };
    };
    extraPackages = with pkgs; [
      tombi
      yaml-language-server
      vscode-json-languageserver
      just-lsp
      ruff
      ty
      rust-analyzer
      clippy
      rustfmt
      nixfmt
      nixd
      efm-langserver
      statix
      yamlfmt
      markdown-oxide
    ];
  };

  xdg.configFile."helix/themes/zedonedark.toml".source = ../../files/zedonedark.toml;
}
