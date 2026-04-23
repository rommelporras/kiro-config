[Back to README](../../README.md) | [How It Works](how-it-works.md) | [Workflows](workflows.md) | [Commands](commands.md)

# Tips

---

## Getting better results

- **Be specific about files** — "Fix the retry logic in `src/services/retry.py`" beats "fix the retry logic"
- **Paste errors directly** — the orchestrator routes better when it sees the actual error message
- **Mention the language/stack** — "write a Python script" routes immediately instead of guessing
- **One thing at a time** — "implement X then review Y" works better as two separate requests
- **Start sessions from your project directory** — agents read and write relative to CWD

---

## Power user patterns

- **Say "verify before completing"** for critical work — triggers extra verification checks before the agent reports done
- **Use `@file:path/to/file`** to attach file content directly to your message
- **`/compact`** on long sessions — compacts conversation history and saves tokens
- **`/spawn`** for parallel work — opens an independent session for a second task while the first is running

---

## Common mistakes

- **Asking for multiple things at once** — the orchestrator handles it, but you get better results splitting requests
- **Not pasting the actual error** — describing an error is slower than pasting it; the AI routes on the text
- **Forgetting AWS SSO auth before launching** — run `aws sso login --profile <profile>` before starting a session that needs AWS access
- **Expecting the AI to remember across sessions** — each session starts fresh; context from previous sessions isn't carried over automatically

---

## Self-learning

If the AI makes a repeated mistake, correct it in plain language — "that's wrong, it should be X". The system captures corrections automatically and learns from them. After 2-3 corrections on the same topic, the pattern becomes a permanent rule that's injected into every future session.

---

## Known gotchas

- **Shell output is buffered** — long-running commands in subagent shell appear stuck until they finish; they're running, just not streaming output
- **Interactive commands don't work in subagent shell** — commands that prompt for input (`rm -i`, `npm init`, SSH host key prompts) have no stdin and will hang or fail
- **WSL SSH agent socket can go stale** — if git or SSH operations fail after resuming a WSL session, open a new terminal tab to recreate the socket, then relaunch
