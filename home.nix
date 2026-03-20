{ config, pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "hx";
    AWS_VAULT_BACKEND = "file";
    PYTHONBREAKPOINT = "pudb.set_trace";
    NVM_DIR = "$HOME/.nvm";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "/usr/local/cuda-12.2/bin"
  ];

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
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "robbyrussell";
    };

    initExtra = ''
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

      [ -f ~/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme ] && source ~/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme
      [ -f ~/.p10k.zsh ] && source ~/.p10k.zsh
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
      [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
      [ -f "$HOME/.iterm2_shell_integration.zsh" ] && source "$HOME/.iterm2_shell_integration.zsh"
      [ -f ~/.secrets.zsh ] && source ~/.secrets.zsh
    '';
  };
}
