#!/usr/bin/env bash
# Claude Code status line - based on PS1 from ~/.bashrc

input=$(cat)

model=$(echo "$input" | grep -o '"display_name":"[^"]*"' | cut -d'"' -f4)
if [ -z "$model" ]; then
  model=$(echo "$input" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

# used_percentage
used=$(echo "$input" | grep -o '"used_percentage":[0-9]*' | cut -d':' -f2)

# Shorten home directory to ~
cwd=$(echo "$input" | grep -o '"current_dir":"[^"]*"' | cut -d'"' -f4)
short_cwd=$(echo $cwd | sed "s|^$HOME/|~/|")

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
 
# Build parts - only add directory if available
parts=""
if [ -n "$short_cwd" ]; then
  dir_part=$(printf '\033[01;34m%s\033[00m' "$short_cwd")
  parts="${dir_part}"
fi

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

printf '%s' "$parts"
