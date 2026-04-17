<!-- Author: Rommel Porras -->

# Rommel Porras — Personal Setup

[Back to README](../../README.md)

My personal setup that layers on top of the generic kiro-config. Managed via
[chezmoi](https://www.chezmoi.io/) and `~/personal/dotfiles`.

> **For AI agents:** This doc explains how my dotfiles integrate with kiro-config.
> If I ask you to modify shell config, Kiro settings, or zsh functions, read this
> first to understand where each piece lives.

---

## How it all fits together

```
~/personal/dotfiles/          # chezmoi-managed, private repo
├── dot_zshrc.tmpl            # Shell config (templated per machine context)
├── dot_config/               # XDG config files
└── ...

~/personal/kiro-config/       # This repo, public, shared with team
├── steering/                 # Symlinked → ~/.kiro/steering/
├── agents/                   # Symlinked → ~/.kiro/agents/
├── skills/                   # Symlinked → ~/.kiro/skills/
├── settings/                 # Symlinked → ~/.kiro/settings/
└── hooks/                    # Symlinked → ~/.kiro/hooks/

~/.kiro/                      # All symlinks, nothing stored directly here
```

**Rule:** kiro-config owns everything under `~/.kiro/`. Dotfiles owns everything
in `~/.zshrc` and `~/.config/`. They don't overlap.

## Chezmoi integration

### .chezmoiignore

`.kiro/` is in `.chezmoiignore` so chezmoi never touches it. The symlinks from
kiro-config manage that directory entirely.

### dot_zshrc.tmpl

Kiro-related shell config lives in `dot_zshrc.tmpl` behind context guards:

```go-template
{{ if hasPrefix "work-" .context }}
# Kiro CLI — pre/post blocks added by installer
# (exact lines vary by Kiro version)

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
{{ end }}
```

**Why context guard?** The `kiro()` function only makes sense on work WSL machines.
Personal machines, Aurora, and distrobox containers don't need it.

### When Kiro CLI updates

After a Kiro CLI update, diff your `.zshrc` against the template:

```bash
diff ~/.zshrc <(chezmoi cat dot_zshrc.tmpl)
```

Port any new lines Kiro added into `dot_zshrc.tmpl` under the appropriate guard.

## AWS profiles

My AWS SSO profiles (configured in `~/.aws/config`, managed by chezmoi):

| Profile | Environment | Usage |
|---|---|---|
| `stg-admin` | Staging | Day-to-day development |
| `dev-admin` | Development | Development environment |
| `pre-prd-admin` | Pre-production | Release validation |
| `prd-admin` | Production | Production operations |

All profiles use SSO via `https://<your-org>.awsapps.com/start`.
Configure `sso_region` and target region in `~/.aws/config`.

Set before launching Kiro:

```bash
export AWS_PROFILE=stg-admin
kiro-cli
```

## Machine contexts

| Context | Machine | Platform | Notes |
|---|---|---|---|
| `work-wsl` | Work laptop WSL2 | Ubuntu on WSL2 | Primary dev environment |
| `work-aurora` | Work laptop host | Fedora Aurora DX | Immutable, uses `rpm-ostree`/`brew` |
| `personal` | Home machines | Various | No Kiro IDE, CLI only |

## Trusted paths

My `base.json` trusts:
- **Read:** `~/.kiro`, `~/personal`, `~/eam`
- **Write:** `~/personal`, `~/eam`

`~/eam` is where all work repos live.

## Maintenance checklist

| When | What to do |
|---|---|
| Kiro CLI update | Diff `.zshrc`, port changes to `dot_zshrc.tmpl`, `chezmoi apply` |
| New AWS profile | Add to `~/.aws/config` via chezmoi, no kiro-config changes needed |
| New work repo | Clone into `~/eam/`, already in trusted paths |
| Kiro symlinks broken | `for dir in steering agents skills settings hooks docs; do ln -sfn ~/personal/kiro-config/$dir ~/.kiro/$dir; done` |
| New machine setup | `chezmoi init && chezmoi apply`, then run [CLI install checklist](kiro-cli-install-checklist.md) |
