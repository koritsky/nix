{
  config,
  pkgs,
  lib,
  llm-agents,
  ...
}:

let
  envSecrets = [
    "aws-access-key-id"
    "aws-secret-access-key"
    "wandb-api-key"
    "openai-api-key"
  ];
  secretToEnv = name: lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] name);
  exportSecrets = lib.concatMapStringsSep "\n" (
    name: "export ${secretToEnv name}=$(cat ${config.sops.secrets.${name}.path})"
  ) envSecrets;
in
{
  home.packages = [
    pkgs.age
    pkgs.jq
    pkgs.just
    pkgs.nh
    pkgs.nvitop
    pkgs.sops
    pkgs.tealdeer
  ];

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/onedark.yaml";
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sizes.terminal = 14;
    };
    autoEnable = false;
    targets = {
      font-packages.enable = true;
      fontconfig.enable = true;
      bat.enable = true;
      fzf.enable = true;
      starship.enable = true;
      zellij.enable = true;
      helix.enable = true;
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets = lib.genAttrs envSecrets (_: { });
  };

  programs = {
    home-manager.enable = true;
    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = false;
        sync_frequency = "5m";
        search_mode = "fuzzy";
        filter_mode = "global";
      };
    };
    bat.enable = true;
    claude-code = {
      enable = true;
      package = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
    };
    codex = {
      enable = true;
      package = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
      settings = {
        model = "gpt-5.5";
        model_reasoning_effort = "xhigh";
        plan_mode_reasoning_effort = "xhigh";
        personality = "pragmatic";
        approval_policy = "never";
        sandbox_mode = "danger-full-access";
        web_search = "live";
        # suppress_unstable_features_warning = true;
        tui = {
          theme = "dracula";
          status_line = [
            "model-with-reasoning"
            "context-remaining"
            "current-dir"
            "git-branch"
            "five-hour-limit"
            "weekly-limit"
            "context-window-size"
            "used-tokens"
          ];
        };
        features = {
          apply_patch_freeform = true;
          fast_mode = true;
          multi_agent = true;
          remote_models = true;
          runtime_metrics = true;
          shell_snapshot = true;
          unified_exec = true;
        };
      };
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
      enableZshIntegration = true;
    };
    eza = {
      enable = true;
      git = true;
      icons = "auto";
    };
    fd.enable = true;
    fzf.enable = true;
    gh.enable = true;
    helix = {
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
      ];
    };
    htop.enable = true;
    lazygit.enable = true;
    ripgrep.enable = true;
    starship = {
      enable = true;
      settings.format = "$directory$git_branch$git_state$nix_shell$direnv$python\n$character";
      settings.right_format = "$username$hostname";
    };
    uv.enable = true;
    yazi = {
      enable = true;
      shellWrapperName = "y";
      settings.mgr = {
        show_symlink = true;
        sort_by = "natural";
        linemode = "size";
      };
      keymap.mgr.prepend_keymap = [
        {
          on = [
            "g"
            "n"
          ];
          run = "cd /nasa/drives/yaak/data";
          desc = "/nasa/drives/yaak/data";
        }
      ];
    };
    zellij.enable = true;
    delta = {
      enable = true;
      options = {
        side-by-side = true;
        navigate = true;
        line-numbers = true;
        dark = true;
      };
    };
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
    jujutsu = {
      enable = true;
      settings.user = {
        email = "koritcky@gmail.com";
        name = "Nikita Koritskii";
      };
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;

      shellAliases = {
        zl = "zellij";
        zlm = "zl a main";
        zla = "zl a --index 0";
        ntop = "LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1 nvitop -m";
        ysudo = "sudo yazi";
        nup = "git -C ~/nix pull && home-manager switch -b backup --flake ~/nix#server-linux";
      };

      initContent = ''
        [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

        ${exportSecrets}

        autoload -Uz edit-command-line
        zle -N edit-command-line
        bindkey '^Xe' edit-command-line
      '';
    };
  };

  xdg.configFile."yazi/theme.toml".source = lib.mkForce ./yazi-theme.toml;
  xdg.configFile."helix/themes/zedonedark.toml".source = ./zedonedark.toml;
}
