[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^Xe' edit-command-line
