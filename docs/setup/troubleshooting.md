<!-- Author: Rommel Porras -->

# Troubleshooting

[Back to README](../../README.md) | Related: [CLI install checklist](kiro-cli-install-checklist.md) | [Security model](../reference/security-model.md)

Common issues and fixes for the kiro-config global setup.

## Diagnostics

Run these first to understand the current state:

```bash
# CLI health check
kiro-cli doctor

# Inside a Kiro session:
/context show     # What steering, skills, and resources are loaded
/mcp              # What MCP servers are active
/tools            # What tools are available and auto-approved
/agent            # What agent is active
```

---

## Steering not loading

**Symptom:** `/context show` doesn't list global steering files (`engineering.md`, `tooling.md`, `universal-rules.md`, `python-boto3.md`, `security.md`, `aws-cli.md`, `shell-bash.md`, `typescript.md`, `web-development.md`, `frontend.md`).

**Cause:** Custom agents don't load steering automatically. The `resources` field must explicitly include them.

**Fix:** Verify `base.json` has both global and workspace steering in `resources`:
```json
"resources": [
  "file://~/.kiro/steering/**/*.md",
  "file://.kiro/steering/**/*.md",
  ...
]
```

**Verify:** Restart `kiro-cli`, run `/context show`. Global steering files should appear under `~/.kiro/steering/**/*.md`.

---

## Skills not activating

**Symptom:** You describe a task but Kiro doesn't use the relevant skill.

**Causes:**
1. **Description mismatch** — Kiro matches your request against skill descriptions. If the wording is too different, it won't activate.
2. **Skills not loaded** — `/context show` doesn't list the skill.
3. **Custom agent missing skill resources** — agent config doesn't include `skill://` URIs.

**Fix:**
- Check `/context show` for skill listing
- Try using keywords from the skill's `description` field in your request
- Verify agent has `"skill://~/.kiro/skills/*/SKILL.md"` in `resources`

---

## MCP servers not loading

**Symptom:** `/mcp` shows no servers or missing servers.

**Causes:**
1. **npx/uvx not installed** — Context7 needs Node.js + npx, AWS servers need Python + uvx
2. **AWS SSO expired** — AWS MCP servers fail silently when credentials expire
3. **`includeMcpJson` not set** — custom agent doesn't load global MCP config

**Fix:**
```bash
# Check prerequisites
which npx    # Should return a path
which uvx    # Should return a path

# Re-authenticate AWS if needed
aws sso login --profile <profile-name>

# Verify agent config
# base.json must have: "includeMcpJson": true
```

---

## Hook blocking legitimate operations

**Symptom:** `BLOCKED: Detected potential [secret type]` when writing non-secret content.

**Cause:** A regex pattern in `scan-secrets.sh` matched content that isn't actually a secret (false positive).

**Fix options:**
1. **Narrow the pattern** — edit `hooks/scan-secrets.sh` to make the regex more specific
2. **Use env vars** — if writing actual credentials, use `${ENV_VAR}` references instead of hardcoded values
3. **Project override** — if a project legitimately needs to write matching patterns (test fixtures), create a project-specific agent without that hook

**Don't:** Disable the hook globally or remove it from `base.json`.

---

## "Permission denied" or path blocks

**Symptom:** Agent can't read/write files outside `~/personal` and `~/eam`.

**Cause:** `toolsSettings` in `base.json` restricts paths. Files outside `allowedPaths` require per-operation user approval.

**Fix:** If you need additional trusted paths, add them to `base.json`:
```json
"fs_read": {
  "allowedPaths": ["~/.kiro", "~/personal", "~/eam", "~/your-new-path"]
}
```

---

## Symlinks broken after update

**Symptom:** Kiro settings reset to defaults, skills missing, hooks not running.

**Cause:** Kiro CLI update may have recreated `~/.kiro/` directories, overwriting symlinks.

**Fix:**
```bash
# Re-symlink
for dir in steering agents skills settings hooks docs; do
  ln -sfn ~/personal/kiro-config/$dir ~/.kiro/$dir
done
```

**Prevent:** Back up before updating Kiro CLI:
```bash
ls -la ~/.kiro/  # Check symlinks are intact before updating
```

---

## Notification sound not playing

**Symptom:** No sound when agent completes a turn.

**Cause:** The `notify.sh` stop hook auto-detects platform (WSL → PowerShell sound, Linux → `notify-send`, fallback → terminal bell).

**Fix:**
- **WSL:** Ensure `powershell.exe` is accessible from WSL
- **Linux:** Install `libnotify` (`sudo apt install libnotify-bin`)
- **All:** Terminal bell (`\x07`) should work everywhere — if not, check terminal settings

---

## WSL-specific issues

See [Kiro IDE + WSL2 setup](kiro-ide-wsl-setup.md) for:
- Agent using PowerShell instead of bash/zsh
- MCP servers failing with "uvx not found"
- `kiro .` not opening in WSL remote mode
- Connection drops after Kiro updates

Quick fix for most WSL connection issues:
```bash
rm -rf ~/.kiro-server
```

---

## Getting help

```bash
# Built-in diagnostics
kiro-cli doctor

# File a bug
kiro-cli issue

# Check this repo's docs (symlinked into ~/.kiro/docs/ after setup)
ls ~/.kiro/docs/
```
