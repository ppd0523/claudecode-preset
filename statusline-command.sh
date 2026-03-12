#!/usr/bin/env bash
# Claude Code status line - inspired by the "refined" (Pure) zsh theme

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -z "$used" ]; then
  remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
  if [ -n "$remaining" ]; then
    used=$(echo "$remaining" | awk '{printf "%d", 100 - $1}')
  fi
fi

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

printf '%s' "$parts"
