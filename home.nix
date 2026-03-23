{ config, pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.sessionVariables = {
    AWS_VAULT_BACKEND = "file";
    PYTHONBREAKPOINT = "pudb.set_trace";
    NVM_DIR = "$HOME/.nvm";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "/usr/local/cuda-12.2/bin"
  ];

  programs.atuin.enable = true;
  programs.bat.enable = true;
  programs.fzf.enable = true;
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
  };
  programs.lazygit.enable = true;
  programs.starship = {
      enable = true;
      settings.format = "$directory$git_branch$git_state$nix_shell$direnv$python\n$character";
      settings.right_format = "$username$hostname";
    };
  programs.uv.enable = true;
  programs.yazi.enable = true;
  programs.zellij.enable = true;

  programs.git = {
    enable = true;
    userName = "koritsky";
    userEmail = "koritcky@gmail.com";
    delta.enable = true;
    lfs.enable = true;
    extraConfig = {
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
    };
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
      nup = "git -C ~/nix pull && home-manager switch --flake ~/nix#server-linux";
    };

    initContent = ''
      export LD_LIBRARY_PATH="/usr/local/cuda-12.2/lib64:$LD_LIBRARY_PATH"
      export LD_LIBRARY_PATH="/home/nikita/rmind/.venv/lib/python3.12/site-packages/nvidia/nvjitlink/lib:$LD_LIBRARY_PATH"

      if [ -x /opt/anaconda3/bin/conda ]; then
        __conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
        if [ $? -eq 0 ]; then
          eval "$__conda_setup"
        elif [ -f /opt/anaconda3/etc/profile.d/conda.sh ]; then
          . /opt/anaconda3/etc/profile.d/conda.sh
        else
          export PATH="/opt/anaconda3/bin:$PATH"
        fi
        unset __conda_setup
      fi

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
      [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
      [ -f "$HOME/.iterm2_shell_integration.zsh" ] && source "$HOME/.iterm2_shell_integration.zsh"
      [ -f ~/.secrets.zsh ] && source ~/.secrets.zsh

    '';
  };
}
