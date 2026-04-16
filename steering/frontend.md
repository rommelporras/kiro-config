# Frontend

## HTML
- **Semantic markup** — use `<nav>`, `<main>`, `<section>`, `<article>`, `<header>`,
  `<footer>` appropriately. No div soup. Proper heading hierarchy (`h1` → `h2` → `h3`).
- **Form labels** — every `<input>` has an associated `<label>` (via `for`/`id` or wrapping).
  Never rely on `placeholder` as a label substitute.

## CSS
- **BEM naming** — `.block__element--modifier` for component styles. Predictable,
  collision-resistant, self-documenting.
- **Utility classes from project set only** — no Tailwind or external utility frameworks.
  Define a small project-level utility set (`u-hidden`, `u-sr-only`, etc.) and use only those.
- **Mobile-first** — write base styles for narrow viewports (min 320px), then use
  `min-width` media queries to enhance for wider screens. No horizontal overflow.

## TypeScript DOM Patterns
- **No framework** — vanilla TypeScript only. Use `document.querySelector` with
  explicit type assertions (`as HTMLInputElement`) after null checks.
- **Null-check DOM queries** — `querySelector` returns `Element | null`. Always
  guard before use; throw a descriptive error if a required element is missing.
- **Event delegation** — attach listeners to stable parent elements where possible,
  not to dynamically created children.

## Chart.js
- **Typed config** — import `ChartConfiguration` and type chart configs explicitly.
  Prevents silent misconfiguration.
- **Destroy before recreate** — call `chart.destroy()` before creating a new chart
  on the same canvas. Prevents memory leaks and rendering artifacts.
- **Sample data for verification** — always test chart config with known sample data
  before wiring to live API responses.

## Fetch API
- **Typed responses** — define a Zod schema for every API response. Parse with
  `schema.safeParse()` after `response.json()`. Never trust raw API data.
- **Error handling** — check `response.ok` before parsing. Surface HTTP errors
  (non-2xx) as typed errors, not silent failures.
- **Loading and empty states** — every data fetch must handle: loading (show spinner
  or skeleton), empty result (show empty state message), and error (show error message).

## Accessibility
- **WCAG 2.1 AA** — minimum compliance target. Covers contrast ratios, keyboard
  navigation, screen reader support.
- **ARIA attributes** — use `aria-label`, `aria-live`, `aria-describedby` where
  native semantics are insufficient. Don't add ARIA to elements that already have
  implicit roles.
- **Keyboard navigation** — all interactive elements reachable and operable via
  keyboard. Focus order follows visual order. Visible focus indicator always present.
- **Color contrast** — document contrast ratios in CSS comments for non-obvious
  color pairs. Minimum 4.5:1 for normal text, 3:1 for large text.

## Error Handling
- **API failures** — show a user-facing error message. Never silently swallow
  fetch errors or leave the UI in a loading state indefinitely.
- **Loading states** — show a loading indicator immediately on fetch start.
  Remove it on both success and error paths.
- **Empty states** — distinguish between "no data yet" and "error". Show
  appropriate messaging for each.
- **No `console.log` in production** — remove debug logging before shipping.
  Use a lightweight logger or conditional `DEBUG` flag if needed.

## Verification Checklist
Before reporting complete, verify:
- **HTML validation** — semantic structure, no div soup, proper heading hierarchy,
  all form inputs have labels.
- **Accessibility** — ARIA attributes present where needed, keyboard navigation
  works, focus indicators visible.
- **Responsive** — no horizontal overflow at 320px, layout adapts at breakpoints,
  no truncated content.
- **Error states** — UI handles API unreachable, empty data, loading state, and
  malformed response without breaking.
- **Chart rendering** — Chart.js config produces the expected chart type with
  sample data before connecting to live data.
