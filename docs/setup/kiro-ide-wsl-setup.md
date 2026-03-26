<!-- Author: Rommel Porras -->

# Kiro IDE + WSL2 Setup Guide

[Back to README](../../README.md) | Related: [CLI install checklist](kiro-cli-install-checklist.md) | [Troubleshooting](troubleshooting.md)

Kiro IDE is a Code OSS fork — not VS Code. Microsoft's `Remote - WSL` extension
is proprietary and unavailable. This guide covers the working alternative.

> Tracked upstream: [kirodotdev/Kiro#17](https://github.com/kirodotdev/Kiro/issues/17) (72+ upvotes, still open as of 2026-03-26).

> **CLI-only users:** This guide is only needed for Kiro IDE on WSL2.
> If you only use `kiro-cli`, skip this entirely.

---

## Fix: Open Remote - WSL Extension

### Step 1: Enable proposed API

Find your Windows username:

```bash
# From WSL
cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r'
```

Edit `%USERPROFILE%\.kiro\argv.json` on Windows. From WSL:

```bash
nano "/mnt/c/Users/<your-windows-username>/.kiro/argv.json"
```

Add/merge this content:

```json
{
  "enable-proposed-api": [
    "jeanp413.open-remote-wsl"
  ]
}
```

If the file already has content, add the `enable-proposed-api` key alongside existing keys.

**Restart Kiro completely** (close all windows, reopen).

### Step 2: Install the extension

In Kiro: Extensions sidebar (Ctrl+Shift+X) → search "WSL" → install **"Open Remote - WSL"** by `jeanp413`

**Restart Kiro again.**

### Step 3: Connect to WSL

Click the `><` remote indicator (bottom-left corner) → select your WSL distro.

### Step 4: Set WSL as default terminal

`Ctrl+Shift+P` → `Terminal: Select Default Profile` → select your WSL distro (e.g. "Ubuntu (WSL)")

**Critical** — without this, Kiro's agent runs PowerShell commands even when connected to WSL ([Issue #4694](https://github.com/kirodotdev/Kiro/issues/4694)).

### Step 5: MCP servers need WSL wrapping

MCP servers run in Windows shell by default. Wrap commands with `wsl.exe` in your
project's `.kiro/settings/mcp.json`:

```json
{
  "mcpServers": {
    "fetch": {
      "command": "wsl.exe",
      "args": ["--shell-type", "login", "uvx", "mcp-server-fetch"],
      "env": {},
      "disabled": false
    }
  }
}
```

---

## Quick-launch: `kiro .` from WSL

The default `kiro` launcher script is broken for WSL — it hardcodes `ms-vscode-remote.remote-wsl`
as the extension ID, which doesn't exist in Kiro.

### Shell function fix

Add this to your `~/.zshrc` or `~/.bashrc`:

```bash
# Kiro IDE — auto-detect install, launch with WSL remoting
_KIRO_EXE=$(find /mnt/c/Users/*/AppData/Local/Programs/Kiro/Kiro.exe 2>/dev/null | head -1)
if [ -n "$_KIRO_EXE" ]; then
  kiro() {
    local kiro_path="${_KIRO_EXE%/Kiro.exe}"
    local cli
    cli=$(wslpath -m "$kiro_path/resources/app/out/cli.js")
    local target="${1:-.}"
    if [ -d "$target" ]; then
      target="$(cd "$target" && pwd)"
      WSLENV="ELECTRON_RUN_AS_NODE/w:$WSLENV" ELECTRON_RUN_AS_NODE=1 \
        "$_KIRO_EXE" "$cli" \
        --folder-uri "vscode-remote://wsl+${WSL_DISTRO_NAME}${target}" &>/dev/null &
    else
      WSLENV="ELECTRON_RUN_AS_NODE/w:$WSLENV" ELECTRON_RUN_AS_NODE=1 \
        "$_KIRO_EXE" "$cli" "$target" &>/dev/null &
    fi
  }
fi
```

Then reload your shell:

```bash
source ~/.zshrc   # or source ~/.bashrc
```

### Usage

```bash
kiro .                    # open current directory with WSL remoting
kiro ~/my-project         # open specific project
kiro somefile.py          # open a single file (no remoting needed)
```

### How it works

1. Calls `Kiro.exe` directly with `ELECTRON_RUN_AS_NODE=1`
2. Passes `--folder-uri "vscode-remote://wsl+<DISTRO>/path"` to force WSL remote mode
3. The `jeanp413.open-remote-wsl` extension handles the connection

### Verification

Bottom-left corner of Kiro should show **`WSL: <DISTRO>`** (e.g., `WSL: Ubuntu`).

---

## Known Issues

> These are upstream tracking issues — check their status before troubleshooting.

| Issue | Impact | Workaround |
|---|---|---|
| **Kiro updates break WSL** ([#2082](https://github.com/kirodotdev/Kiro/issues/2082)) | Connection fails after update | `rm -rf ~/.kiro-server` inside WSL, reconnect |
| **Agent uses PowerShell** ([#4694](https://github.com/kirodotdev/Kiro/issues/4694)) | Agent runs `executePwsh` in loops | Set WSL as default terminal (step 4) |
| **MCP runs on Windows shell** ([#6023](https://github.com/kirodotdev/Kiro/issues/6023)) | `uvx not found` errors | Wrap MCP commands with `wsl.exe` (step 5) |
| **Split terminal broken** ([#4453](https://github.com/kirodotdev/Kiro/issues/4453)) | Can't split terminal panes | No workaround yet |
| **Connection drops randomly** | Server cache stale | `rm -rf ~/.kiro-server` in WSL |

## Extension Compatibility

| Extension | Works? | Why |
|---|---|---|
| `ms-vscode-remote.remote-wsl` (Microsoft) | **No** | Proprietary, Marketplace only |
| `jeanp413.open-remote-wsl` | **Yes** | Needs `enable-proposed-api` |
| `jeanp413.open-remote-ssh` | **Yes** | Same requirement |
| Most Open VSX extensions | **Yes** | Default registry |
| VS Code Marketplace exclusives | **No** | Not on Open VSX |
