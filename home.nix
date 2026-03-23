{ config, pkgs, llm-agents, ... }:

{
  programs.home-manager.enable= true;

  home.packages = with pkgs; [
    nodejs
  ];

  home.sessionVariables = {
    AWS_VAULT_BACKEND = "file";
    PYTHONBREAKPOINT = "pudb.set_trace";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.atuin.enable = true;
  programs.bat.enable = true;
  programs.codex = {
    enable = true;
    package = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    settings = {
      model = "gpt-5.4";
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
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.fd.enable = true;
  programs.fzf.enable = true;
  programs.gh.enable = true;
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "dracula";
      editor = {
        auto-save = true;
        true-color = true;
        idle-timeout = 0;
        completion-trigger-len = 1;
        statusline = {
          left = [ "mode" "spinner" "file-name" "read-only-indicator" "file-modification-indicator" ];
          center = [ ];
          right = [ "diagnostics" "version-control" ];
        };
        indent-guides = {
          render = true;
          skip-levels = 2;
        };
        soft-wrap.enable = true;
        file-picker.hidden = false;
      };
      keys.select = {
        k = [ "extend_line_up" "extend_to_line_bounds" ];
        j = [ "extend_line_down" "extend_to_line_bounds" ];
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
            args = [ "--verify" "--strict" ];
          };
          language-servers = [ "nixd" "statix" ];
        }
        {
          name = "python";
          auto-format = true;
          language-servers = [ "ruff" "ty" ];
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
              rootMarkers = [ "flake.nix" "shell.nix" "default.nix" ];
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
  programs.htop.enable = true;
  programs.lazygit.enable = true;
  programs.ripgrep.enable = true;
  programs.starship = {
      enable = true;
      settings.format = "$directory$git_branch$git_state$nix_shell$direnv$python\n$character";
      settings.right_format = "$username$hostname";
    };
  programs.uv.enable = true;
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
  };

  xdg.configFile."yazi/theme.toml".source = ./yazi-theme.toml;
  programs.zellij.enable = true;
  programs.delta.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "koritcky@gmail.com";
        name = "koritsky";
      };
      push.autoSetupRemote = true;
    };
    lfs.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    shellAliases = {
      zl = "zellij";
      zlm = "zellij a main";
      zla = "zellij a --index 0";
      lg = "lazygit";
      ntop = "nvitop -m";
      y = "yazi";
      ysudo = "sudo yazi";
      nup = "git -C ~/nix pull && home-manager switch -b backup --flake ~/nix#server-linux";
    };

    initContent = ''
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
      [ -f ~/.secrets.zsh ] && source ~/.secrets.zsh
    '';
  };
}
