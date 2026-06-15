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
      settings = {
        model = "claude-opus-4-8";
        permissions = {
          defaultMode = "auto";
          allow = [
            # navigation & search
            "Bash(ls:*)"
            "Bash(find:*)"
            "Bash(grep:*)"
            "Bash(rg:*)"
            "Bash(cat:*)"
            "Bash(sed:*)"
            "Bash(head:*)"
            "Bash(tail:*)"
            "Bash(wc:*)"
            "Bash(diff:*)"
            "Bash(which:*)"
            "Bash(echo:*)"
            "Bash(cd:*)"

            # git (read + safe writes)
            "Bash(git status:*)"
            "Bash(git log:*)"
            "Bash(git diff:*)"
            "Bash(git show:*)"
            "Bash(git branch:*)"
            "Bash(git add:*)"
            "Bash(git commit:*)"
            "Bash(git checkout:*)"
            "Bash(git stash:*)"
            "Bash(git fetch:*)"
            "Bash(git pull:*)"

            # node / python / nix dev
            "Bash(npm run:*)"
            "Bash(npm install:*)"
            "Bash(npx:*)"
            "Bash(node:*)"
            "Bash(python:*)"
            "Bash(python3:*)"
            "Bash(pip:*)"
            "Bash(uv:*)"
            "Bash(nix build:*)"
            "Bash(nix flake:*)"
            "Bash(nix fmt:*)"
            "Bash(just:*)"
            "Bash(nvidia-smi:*)"


            # linting / formatting
            "Bash(ruff:*)"
            "Bash(black:*)"
            "Bash(prettier:*)"
            "Bash(eslint:*)"
            "Bash(mypy:*)"
            "Bash(tsc:*)"

            # testing
            "Bash(pytest:*)"
            "Bash(jest:*)"
            "Bash(cargo test:*)"

            # misc safe utils
            "Bash(jq:*)"
            "Bash(yq:*)"
            "Bash(curl:*)"
            "Bash(mkdir:*)"
            "Bash(cp:*)"
            "Bash(mv:*)"
            "Bash(date:*)"
            "Bash(env:*)"

            # web
            "WebFetch(*)"
            "WebSearch(*)"
          ];
          deny = [
            "Bash(rm:*)"
            "Bash(sudo:*)"
            "Bash(chmod:*)"
            "Bash(chown:*)"
            "Bash(dd:*)"
            "Bash(mkfs:*)"
            "Bash(git push:*)"
            "Bash(git rebase:*)"
            "Bash(git reset --hard:*)"
          ];
        };
        statusLine = {
          type = "command";
          command = "bash ~/.claude/statusline.sh";
        };
        autoUpdatesChannel = "stable";
        outputStyle = "Concise";
        skipWebFetchPreflight = true;
        includeGitInstructions = true;
        preferredNotifChannel = "iterm2";
        cleanupPeriodDays = 30;
      };
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
      settings.format = "$directory$git_branch$git_state$nix_shell$python\n$character";
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
      plugins = {
        inherit (pkgs.yaziPlugins) rsync;
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
        {
          on = [ "R" ];
          run = "plugin rsync";
          desc = "rsync";
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

        # Auto-activate Python virtual environments
        function auto_activate_venv() {
          if [[ -z "$VIRTUAL_ENV" ]]; then
            # Not in a venv, check if we should activate one
            if [[ -f .venv/bin/activate ]]; then
              source .venv/bin/activate
            elif [[ -f venv/bin/activate ]]; then
              source venv/bin/activate
            fi
          else
            # In a venv, check if we should deactivate
            local parent_dir="$(pwd)"
            if [[ ! -f "$parent_dir/.venv/bin/activate" ]] && [[ ! -f "$parent_dir/venv/bin/activate" ]]; then
              # Check if venv is in any parent directory
              local in_venv_dir=false
              while [[ "$parent_dir" != "/" ]]; do
                if [[ "$VIRTUAL_ENV" == "$parent_dir/.venv" ]] || [[ "$VIRTUAL_ENV" == "$parent_dir/venv" ]]; then
                  in_venv_dir=true
                  break
                fi
                parent_dir="$(dirname "$parent_dir")"
              done
              if [[ "$in_venv_dir" == false ]]; then
                deactivate
              fi
            fi
          fi
        }

        # Run on directory change
        autoload -Uz add-zsh-hook
        add-zsh-hook chpwd auto_activate_venv

        # Run on shell start
        auto_activate_venv
      '';
    };
  };

  home.file.".claude/statusline.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Claude Code status line — mirrors Starship layout (directory + git_branch + model + context)

      input=$(cat)

      # Extract fields
      cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "?"')
      model=$(echo "$input" | jq -r '.model.display_name // "?"')
      branch=$(echo "$input" | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end')
      git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')
      used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
      sess_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
      sess_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
      week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
      week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

      # Shorten home directory
      cwd="''${cwd/#$HOME/\~}"

      # ANSI colors (base16 palette approximated with 256-color codes)
      BLUE='\033[38;5;75m'    # base0D blue
      GREEN='\033[38;5;114m'  # base0B green
      YELLOW='\033[38;5;179m' # base0A yellow
      CYAN='\033[38;5;73m'    # base0C cyan
      PURPLE='\033[38;5;176m' # base0E purple
      DIM='\033[2m'
      RESET='\033[0m'

      # Directory segment
      printf "''${BLUE}%s''${RESET}" "$cwd"

      # Git branch segment
      if [ -n "$git_worktree" ]; then
          printf " ''${GREEN}%s''${RESET}" "$git_worktree"
      elif [ -n "$branch" ]; then
          printf " ''${GREEN}%s''${RESET}" "$branch"
      fi

      # Model segment
      printf " ''${PURPLE}%s''${RESET}" "$model"

      # Context usage segment
      if [ -n "$used_pct" ]; then
          used_int=''${used_pct%%.*}
          if [ "$used_int" -ge 80 ]; then
              CTX_COLOR='\033[38;5;167m'  # red-ish warning
          elif [ "$used_int" -ge 50 ]; then
              CTX_COLOR="$YELLOW"
          else
              CTX_COLOR="$CYAN"
          fi
          printf " ''${DIM}|''${RESET} ''${DIM}ctx''${RESET} ''${CTX_COLOR}%d%%''${RESET}" "$used_int"
      fi

      # Usage-limit color helper: cyan < 50, yellow 50-79, red >= 80
      usage_color() {
          if [ "$1" -ge 80 ]; then printf '\033[38;5;167m'
          elif [ "$1" -ge 50 ]; then printf "$YELLOW"
          else printf "$CYAN"; fi
      }

      # Session (5-hour) usage segment — only present for Pro/Max after first API response
      if [ -n "$sess_pct" ]; then
          sess_int=''${sess_pct%%.*}
          sess_c=$(usage_color "$sess_int")
          if [ -n "$sess_reset" ]; then
              sess_at=" ''${DIM}↻ $(date -d "@$sess_reset" +%H:%M)''${RESET}"
          else
              sess_at=""
          fi
          printf " ''${DIM}|''${RESET} ''${DIM}5h''${RESET} ''${sess_c}%d%%''${RESET}%b" "$sess_int" "$sess_at"
      fi

      # Weekly (7-day) usage segment
      if [ -n "$week_pct" ]; then
          week_int=''${week_pct%%.*}
          week_c=$(usage_color "$week_int")
          if [ -n "$week_reset" ]; then
              week_at=" ''${DIM}↻ $(date -d "@$week_reset" +%a)''${RESET}"
          else
              week_at=""
          fi
          printf " ''${DIM}|''${RESET} ''${DIM}wk''${RESET} ''${week_c}%d%%''${RESET}%b" "$week_int" "$week_at"
      fi

      printf "\n"
    '';
  };

  xdg.configFile."yazi/theme.toml".source = lib.mkForce ./yazi-theme.toml;
  xdg.configFile."helix/themes/zedonedark.toml".source = ./zedonedark.toml;
}
