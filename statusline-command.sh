#!/usr/bin/env bash
# Claude Code status line - inspired by the "refined" (Pure) zsh theme

input=$(cat)
echo "[claude input] $input" >> claude-input.txt

# Parse single-line JSON using grep -o + awk
cwd=$(echo "$input" | grep -o '"current_dir":"[^"]*"' | awk -F'"' '{print $4}')
[ -z "$cwd" ] && cwd=$(echo "$input" | grep -o '"cwd":"[^"]*"' | awk -F'"' '{print $4}')

model=$(echo "$input" | grep -o '"display_name":"[^"]*"' | awk -F'"' '{print $4}')

used=$(echo "$input" | grep -o '"used_percentage":[0-9]*' | head -1 | awk -F: '{print $2}')
if [ -z "$used" ]; then
  remaining=$(echo "$input" | grep -o '"remaining_percentage":[0-9]*' | head -1 | awk -F: '{print $2}')
  if [ -n "$remaining" ]; then
    used=$(echo "$remaining" | awk '{printf "%d", 100 - $1}')
  fi
fi

five_hour=$(echo "$input" | grep -o '"five_hour":{[^}]*}' | grep -o '"used_percentage":[0-9]*' | awk -F: '{print $2}')
[ -z "$five_hour" ] && five_hour=0

seven_day=$(echo "$input" | grep -o '"seven_day":{[^}]*}' | grep -o '"used_percentage":[0-9]*' | awk -F: '{print $2}')
[ -z "$seven_day" ] && seven_day=0

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/~}"

# Git branch (skip optional locks)
git_branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" -c core.fsmonitor=false symbolic-ref --short HEAD 2>/dev/null \
               || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  # Check dirty status
  if ! git -C "$cwd" -c core.fsmonitor=false diff --quiet --ignore-submodules HEAD 2>/dev/null; then
    git_branch="${git_branch}*"
  fi
fi

# Build the status line
parts=""

# Directory (green)
parts=$(printf '\033[32m%s\033[0m' "$short_cwd")

# Git branch (dark gray)
if [ -n "$git_branch" ]; then
  parts="$parts $(printf '\033[90mgit:%s\033[0m' "$git_branch")"
fi

# Model (orange)
if [ -n "$model" ]; then
  parts="$parts $(printf '\033[38;5;214m%s\033[0m' "$model")"
fi

# Context used (yellow if high usage, gray otherwise)
if [ -n "$used" ]; then
  used_int=${used%.*}
  if [ "$used_int" -ge 80 ] 2>/dev/null; then
    parts="$parts $(printf '\033[33mctx:%s%%\033[0m' "$used_int")"
  else
    parts="$parts $(printf '\033[90mctx:%s%%\033[0m' "$used_int")"
  fi
fi

# Rate limits: (5h%/7d%) — 어느 하나라도 80% 이상이면 빨간색, 아니면 회색
if [ "$five_hour" -ge 80 ] || [ "$seven_day" -ge 80 ] 2>/dev/null; then
  parts="$parts $(printf '\033[31m(%d%%/%d%%)\033[0m' "$five_hour" "$seven_day")"
else
  parts="$parts $(printf '\033[90m(%d%%/%d%%)\033[0m' "$five_hour" "$seven_day")"
fi

printf '%s' "$parts"
