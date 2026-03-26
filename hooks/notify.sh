#!/usr/bin/env bash
# Author: Rommel Porras
# Stop hook — plays notification sound when agent finishes a turn.
# Auto-detects platform: WSL (PowerShell) | Linux (notify-send) | fallback (bell)

if grep -qi microsoft /proc/version 2>/dev/null; then
  # WSL — play Windows sound via PowerShell
  powershell.exe -NonInteractive -NoProfile -c \
    "(New-Object Media.SoundPlayer 'C:\Windows\Media\tada.wav').PlaySync()" 2>/dev/null &
else
  # Native Linux (Aurora/distrobox) — desktop notification
  if command -v notify-send &>/dev/null; then
    notify-send "Kiro CLI" "Task complete" 2>/dev/null &
  fi
fi

# Terminal bell — guaranteed fallback on every platform
printf '\x07'

exit 0
