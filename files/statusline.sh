#!/usr/bin/env bash
# Claude Code status line — mirrors Starship layout (directory + git_branch + model + context)

input=$(cat)

# Extract all fields in one jq pass, one per line (empty string for absent
# values). mapfile preserves empty fields — an IFS=$'\t' read would collapse
# them, since tab is whitespace-IFS.
mapfile -t f < <(
    jq -r '[
        .workspace.current_dir // .cwd // "?",
        .model.display_name // "?",
        .effort.level // "",
        (.workspace.repo | if . then .owner + "/" + .name else "" end),
        .workspace.git_worktree // "",
        .context_window.used_percentage // "",
        .rate_limits.five_hour.used_percentage // "",
        .rate_limits.five_hour.resets_at // "",
        .rate_limits.seven_day.used_percentage // "",
        .rate_limits.seven_day.resets_at // ""
    ] | .[]' <<<"$input"
)
cwd=${f[0]} model=${f[1]} effort=${f[2]} branch=${f[3]} git_worktree=${f[4]}
used_pct=${f[5]} sess_pct=${f[6]} sess_reset=${f[7]} week_pct=${f[8]} week_reset=${f[9]}

# Portable epoch → formatted time. BSD date (macOS) uses -r; GNU date uses -d @.
fmt_ts() { date -r "$1" "+$2" 2>/dev/null || date -d "@$1" "+$2"; }

# Shorten home directory
cwd="${cwd/#$HOME/\~}"

# ANSI colors (base16 palette approximated with 256-color codes)
BLUE='\033[38;5;75m'    # base0D blue
GREEN='\033[38;5;114m'  # base0B green
YELLOW='\033[38;5;179m' # base0A yellow
CYAN='\033[38;5;73m'    # base0C cyan
PURPLE='\033[38;5;176m' # base0E purple
DIM='\033[2m'
RESET='\033[0m'

# Directory segment
printf "${BLUE}%s${RESET}" "$cwd"

# Git branch segment
if [ -n "$git_worktree" ]; then
    printf " ${GREEN}%s${RESET}" "$git_worktree"
elif [ -n "$branch" ]; then
    printf " ${GREEN}%s${RESET}" "$branch"
fi

# Model segment (with effort level when present, e.g. "Opus 4.8: xhigh")
if [ -n "$effort" ]; then
    printf " ${PURPLE}%s${RESET}${DIM}:${RESET} ${PURPLE}%s${RESET}" "$model" "$effort"
else
    printf " ${PURPLE}%s${RESET}" "$model"
fi

# Context usage segment
if [ -n "$used_pct" ]; then
    used_int=${used_pct%%.*}
    if [ "$used_int" -ge 80 ]; then
        CTX_COLOR='\033[38;5;167m'  # red-ish warning
    elif [ "$used_int" -ge 50 ]; then
        CTX_COLOR="$YELLOW"
    else
        CTX_COLOR="$CYAN"
    fi
    printf " ${DIM}|${RESET} ${DIM}ctx${RESET} ${CTX_COLOR}%d%%${RESET}" "$used_int"
fi

# Usage-limit color helper: cyan < 50, yellow 50-79, red >= 80
usage_color() {
    if [ "$1" -ge 80 ]; then printf '\033[38;5;167m'
    elif [ "$1" -ge 50 ]; then printf "$YELLOW"
    else printf "$CYAN"; fi
}

# Session (5-hour) usage segment — only present for Pro/Max after first API response
if [ -n "$sess_pct" ]; then
    sess_int=${sess_pct%%.*}
    sess_c=$(usage_color "$sess_int")
    if [ -n "$sess_reset" ]; then
        sess_at=" ${DIM}↻ $(fmt_ts "$sess_reset" %H:%M)${RESET}"
    else
        sess_at=""
    fi
    printf " ${DIM}|${RESET} ${DIM}5h${RESET} ${sess_c}%d%%${RESET}%b" "$sess_int" "$sess_at"
fi

# Weekly (7-day) usage segment
if [ -n "$week_pct" ]; then
    week_int=${week_pct%%.*}
    week_c=$(usage_color "$week_int")
    if [ -n "$week_reset" ]; then
        week_at=" ${DIM}↻ $(fmt_ts "$week_reset" %a)${RESET}"
    else
        week_at=""
    fi
    printf " ${DIM}|${RESET} ${DIM}wk${RESET} ${week_c}%d%%${RESET}%b" "$week_int" "$week_at"
fi

printf "\n"
