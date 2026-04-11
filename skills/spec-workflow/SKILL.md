---
name: spec-workflow
description: Use when the user wants to spec out a feature, define requirements, create a design document, or plan implementation before coding. Triggers on "spec out", "define requirements", "write a spec", "requirements for", "design document for", "let's plan the feature".
---

# Spec Workflow

Walk the user through a structured specification process. Handle this as a
direct conversation — do NOT delegate to subagents.

## Phase 1: Requirements

Ask the user to describe what they want to build. Then produce a
requirements document with:

- **Purpose:** One paragraph — what problem this solves
- **Scope:** What's in, what's explicitly out
- **User stories:** "As a [role], I want [action], so that [benefit]"
- **Acceptance criteria:** Concrete, testable conditions per story
- **Constraints:** Performance, security, compatibility requirements
- **Dependencies:** External services, libraries, APIs

Save to: `docs/specs/{feature-name}/requirements.md`

Ask the user to review before proceeding. Do not advance until they approve.

## Phase 2: Technical Design

Based on approved requirements, produce a design document with:

- **Architecture:** How components fit together
- **Module breakdown:** Files, classes, functions — named and described
- **Data flow:** Inputs → processing → outputs
- **Error handling strategy:** What fails, how it recovers
- **Technology choices:** Language, libraries, and why

Save to: `docs/specs/{feature-name}/design.md`

Ask the user to review before proceeding. Do not advance until they approve.

## Phase 3: Implementation Planning

After requirements and design are approved, hand off to the writing-plans
skill to produce the detailed implementation plan. Pass it the approved
requirements and design documents as context.

Do NOT produce your own task list — writing-plans is the single source
of truth for implementation plans. It produces bite-sized tasks with
exact file paths, code, test commands, and commit messages.

## Phase 4: Execution (only on user approval)

After the writing-plans skill produces the plan and the user approves it,
use the subagent-driven-development skill to execute tasks sequentially
by delegating each to the appropriate subagent.

## Guidelines

- Each phase is a conversation. Ask clarifying questions.
- Do not skip phases or rush through them.
- The user can revise any phase. Loop until they're satisfied.
- Keep documents concise — detailed enough to implement from, not more.
- If the feature is trivial (< 3 tasks), suggest skipping to Phase 3.
