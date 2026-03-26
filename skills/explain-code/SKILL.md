---
name: explain-code
description: Explains code with analogies and visual diagrams. Use when the user asks how code works, wants to understand a codebase, or uses phrases like "explain", "how does this work", "walk me through".
---

When explaining code, always structure the response in this order:

## 1. One-sentence summary
State what the code does in plain English — no jargon.

## 2. Analogy
Compare it to something from everyday life. Make it concrete and relatable.

## 3. ASCII diagram
Draw the flow, structure, or relationships visually. Examples:

```
[Input] → [Transform] → [Output]

┌──────────┐      ┌──────────┐
│ Module A │────▶│ Module B │
└──────────┘      └──────────┘
```

## 4. Step-by-step walkthrough
Trace through the code as if it were executing. Reference specific line numbers when pointing to important parts.

## 5. The gotcha
Call out one common mistake, misconception, or edge case that trips people up with this code.

---

Keep the tone conversational. For very complex concepts, use two analogies — one simple, one more technical. Prioritise clarity over completeness.
