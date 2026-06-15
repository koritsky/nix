[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

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
