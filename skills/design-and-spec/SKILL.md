---
name: design-and-spec
description: Use before any creative work or spec creation. Explores intent, challenges assumptions, and produces specs. Triggers on "brainstorm", "let's design", "spec out", "define requirements", "write a spec", "challenge this", "poke holes", "what am I missing".
---

# Design and Spec

Turn ideas into approved specs through collaborative dialogue or structured requirements gathering.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## Entry Mode Detection

**Exploratory mode** — triggers on: `brainstorm`, `let's think about`, `I'm leaning toward`, open-ended structural questions.
- Present partial designs early and iterate — don't wait for the full picture
- Fold in new constraints mid-stream naturally
- Prefer open discussion over multiple choice
- Propose 2-3 approaches at real forks in the road
- Transition check: "Ready to formalize into a spec, or keep exploring?"

**Directed mode** — triggers on: `spec out`, `define requirements`, `write a spec`, `define requirements`.
- Ask clarifying questions one at a time, prefer multiple choice
- Structure: requirements → design → tasks
- Present design in sections, get approval per section
- Skip the design phase if the spec already contains architecture and module breakdown

Both modes start with: explore project context (read files, docs, recent commits).

## Assumption Challenging Phase

Before presenting any design in either mode, list 3 assumptions being made and question each:

- "What happens if [assumption] is wrong?"
- "What's the simplest version of this that could work?"
- "What are you optimizing for — and what are you giving up?"

Have strong opinions, held loosely — push back with conviction, change your mind when the user presents good evidence.

## Design Principles

- **One question at a time** — never multiple questions in one message
- **YAGNI ruthlessly** — remove unnecessary features from all designs
- **Design for isolation** — each unit has one clear purpose, communicates through well-defined interfaces, can be understood and tested independently
- **Explore existing patterns** — read the codebase before proposing changes; follow what's there
- **Decompose large scope** — if the request spans multiple independent subsystems, flag it and help decompose before designing any one piece

## Convergence (both modes)

0. **Ripple check** — list which existing docs enumerate the artifact category being added (agents, skills, hooks, steering). Include those docs in the spec's "Files to Update" section. If unsure, grep `docs/` and `README.md` for artifact names from the category.
1. Write spec to `docs/specs/YYYY-MM-DD-<topic>/spec.md`
2. Ask user to review: "Spec written to `<path>`. Review it and let me know if you want changes before we move to planning."
3. Wait for approval. Make changes if requested, then re-ask.
4. **Hand off to writing-plans** — this is the terminal state. Do NOT invoke any other skill.

**The only next step after design-and-spec is writing-plans.**
