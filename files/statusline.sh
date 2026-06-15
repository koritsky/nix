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

# Model segment
printf " ${PURPLE}%s${RESET}" "$model"

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
        sess_at=" ${DIM}↻ $(date -d "@$sess_reset" +%H:%M)${RESET}"
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
        week_at=" ${DIM}↻ $(date -d "@$week_reset" +%a)${RESET}"
    else
        week_at=""
    fi
    printf " ${DIM}|${RESET} ${DIM}wk${RESET} ${week_c}%d%%${RESET}%b" "$week_int" "$week_at"
fi

printf "\n"
