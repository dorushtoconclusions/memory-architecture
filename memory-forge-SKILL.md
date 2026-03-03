---
name: memory-forge
description: Create high-quality, structured memory entries from lessons, mistakes, and discoveries. Use when a session reveals a reusable pattern, after debugging incidents, when Jerome says "remember this", or during periodic memory maintenance. Enforces a 7-step workflow (capture, filter, verify, draft, test, promote, cleanup) with scoring rubric and anti-bloat rules. NOT for routine facts (use daily notes) or optimizing existing MEMORY.md (use optimize-memory skill).
---

# memory-forge — High-Quality Memory Creation

## When to Use This Skill

Trigger this skill when:
- A session produced a lesson, mistake, or discovery worth remembering
- During periodic memory maintenance (heartbeat review of daily logs)
- After an incident or debugging session that revealed a reusable pattern
- When Jerome explicitly says "remember this" or "don't do that again"

Do NOT use for:
- Routine facts (use daily notes)
- One-off context unlikely to recur
- Information already captured in MEMORY.md

## Workflow

### 1. CAPTURE

Identify candidate lessons from the session. Write raw candidates to `memory/staging.md` (create if needed). Format:

```
### Candidate: <short name>
- What happened: <1-2 sentences>
- Why it matters: <1 sentence>
- Source: <where this was observed>
```

### 2. FILTER (score ≥ 6/10 to pass)

Score each candidate on five dimensions (0-2 each):

| Dimension | 0 | 1 | 2 |
|-----------|---|---|---|
| **Reusability** | One-off | Occasional | Weekly+ |
| **Risk reduction** | Cosmetic | Moderate waste | Trust/security/hours lost |
| **Specificity** | Vague principle | Partial trigger | Exact trigger + action |
| **Novelty** | Already in MEMORY.md | Partial overlap | Genuinely new |
| **Boot criticality** | Nice to know | Helpful context | Must know every session |

**Hard filters (auto-reject):**
- Not actionable (no clear trigger + action)
- Redundant with existing MEMORY.md entry (merge instead of add)
- Low confidence AND not safety-critical → daily notes only

### 3. VERIFY

Every entry that passes the filter gate must meet verification requirements:

- **Primary source (required):** Link to docs, README, spec, or authoritative reference that supports the rule.
- **Reproduction (required if testable):** Command + output, or describe the test and result.
- **Cross-check (required for security/policy rules):** Independent second source confirming the mechanism.

If verification fails: downgrade to daily notes with a `[UNVERIFIED]` tag. Do not promote to MEMORY.md.

### 4. DRAFT

Write each entry using this template:

```
- **Category:** [Platform|Tool|Safety|Process|Tech]
  **Trigger:** <specific situation or pattern that activates this rule>
  **Rule:** <single concrete action to take>
  **Evidence:** <primary source or test that confirms this>
  **Boundary:** <what this does NOT apply to>
```

Rules for drafting:
- One rule per entry (atomic)
- Under 120 words
- Trigger must be a recognizable pattern, not a vague concept
- Rule must be a concrete action, not a principle
- Boundary prevents over-application

### 5. TEST

Before promoting, sanity-check each draft:

- [ ] Read it cold — would future-you understand it without context?
- [ ] Does the trigger fire too often? (If yes: narrow it)
- [ ] Does the trigger fire too rarely? (If yes: is it worth a MEMORY slot?)
- [ ] Is it redundant with an existing entry? (If yes: merge or discard)
- [ ] Could it conflict with another entry? (If yes: resolve the conflict)

### 6. PROMOTE

Append passing entries to `MEMORY.md` under `## Lessons`.

If an entry supersedes an existing one: **replace** the old entry, don't stack.

### 7. CLEANUP

- Delete processed candidates from `memory/staging.md`
- If any candidates were rejected, optionally log them in today's daily note with rationale
- Confirm final MEMORY.md entry count hasn't grown by more than 5 entries in one pass

## Anti-Bloat Rules

1. **Max 5 new entries per pass.** If you have more candidates, ruthlessly prioritize.
2. **Merge over add.** If a new lesson overlaps with an existing entry, update the existing one.
3. **No chronological logs.** MEMORY.md is rules, not history. Daily notes hold the story.
4. **Quarterly review.** Every ~90 days, review all Lessons entries. Archive any that haven't influenced behavior.
5. **One rule per entry.** If you're writing "and also," split it or pick the more important half.
6. **Kill vague entries.** "Be careful with X" is not a memory. "When X happens, do Y because Z" is.

## Examples

### ✅ Good Entry
```
- **Category:** Process
  **Trigger:** About to recommend a tool/config/command.
  **Rule:** Read the tool's own docs/README before searching the web. Follow order: local docs → --help → GitHub issues → web → sub-agent.
  **Evidence:** TCC incident — web results were stale; tool README had current answer.
  **Boundary:** General knowledge questions unrelated to a specific tool.
```

**Why it's good:** Specific trigger, concrete action sequence, real evidence, clear boundary.

### ❌ Bad Entry
```
- Always read documentation before making recommendations.
```

**Why it's bad:** No trigger pattern, no specificity about *which* documentation, no evidence, no boundary. Will be ignored because it's too vague to act on.

### ❌ Bad Entry
```
- **Category:** Process
  **Trigger:** Any time you do anything.
  **Rule:** Be more careful.
  **Evidence:** Things went wrong once.
  **Boundary:** None.
```

**Why it's bad:** Trigger is everything (= nothing). Rule is not actionable. Evidence is not traceable. No boundary means it'll over-fire and get ignored.

### ✅ Good Merge Example

If MEMORY.md already has:
```
- Write things down IMMEDIATELY. Mental notes don't survive restarts.
```
Don't create a second entry. Update the existing one:
```
- **Category:** Process
  **Trigger:** Learning something worth remembering during a session.
  **Rule:** Write it to a file immediately. Mental notes don't survive restarts. Use daily notes for raw capture, memory-forge skill for distilling into MEMORY.md.
  **Evidence:** Multiple sessions where context was lost. Jerome: "If you can't reliably remember we are nowhere."
  **Boundary:** Ephemeral task context belongs in session, not memory files.
```
