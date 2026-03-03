# ENFORCEMENT FIX — Structural Analysis & Proposal

*Claude Opus analysis · 2026-03-03*

---

## 1. The Deeper Problem (It's Worse Than You Think)

The ENFORCEMENT-PROBLEM.md frames this as "lessons in passive files don't get consulted." That's true, but it's only half the story.

**The verify-commands rule is ALREADY in boot context.** USER.md line:

> **Verify CLI commands before giving them.** Check docs, `--help`, or test them. Never guess at flags or arguments — if I can't verify, say so explicitly.

This rule was loaded into the context window. It was present during the entire session. MIKA had it right there — in boot context, not in some distant lesson file — and still gave Jerome `gh auth login -u` (nonexistent flag) and `npm install -g @anthropic-ai/gemini-cli` (fabricated package).

**This means the problem isn't just "passive files vs boot context." Boot context rules also get violated.** The architectural gap is deeper than file placement.

---

## 2. Why Boot Context Rules Get Followed (Sometimes)

Let's examine what DOES work. MIKA reliably follows:
- Identity (SOUL.md) — never breaks character
- Safety basics (AGENTS.md) — asks before destructive commands
- Formatting preferences (USER.md) — tables for data, no filler
- Dispatch rules (MEMORY.md) — uses Codex for code, Gemini for research

What do these have in common?
1. **They're procedural, not aspirational.** "Use tables for data" is a concrete action. "Verify commands" is an aspiration.
2. **They trigger on output format, not on content generation.** Identity and formatting rules constrain HOW to respond. Verification rules constrain the PROCESS of generating the response.
3. **They don't require interrupting flow.** Following identity/formatting happens during generation. Verification requires STOPPING generation, running a tool, then resuming.
4. **They have no competing pressure.** Nothing pushes MIKA to break character. But helpfulness pressure pushes MIKA to answer quickly, which competes directly with "stop and verify."

**Core insight: Rules that require interrupting the generation flow to perform an external check are the hardest to enforce, because the model's default mode is to generate helpful responses, and verification is a speed bump on that path.**

---

## 3. Why "Just Put It in Boot Context" Isn't Enough

The ARCHITECTURE.md design is excellent for recall — temporal summaries, entity files, hybrid search, CONTEXT.md. But it has a blind spot: it treats enforcement as a recall problem.

The assumption chain:
1. If MIKA can find the lesson → MIKA will follow the lesson ❌
2. If the lesson is in boot context → MIKA will follow the lesson ❌
3. If the lesson is prominent → MIKA will follow the lesson ❌ (USER.md proves this)

**Recall is necessary but not sufficient.** The lesson was recalled (it was in boot context). It was ignored because nothing in the architecture creates a structural gate — a point where the agent MUST stop, check, and confirm before proceeding.

---

## 4. What Would Actually Work

### 4.1 The Gate Pattern

The only thing that reliably forces an LLM to do something before producing output is **making the required action part of the output generation protocol itself** — not a side instruction, but a step the model must execute as part of constructing its response.

**Analogy:** A checklist on a wall doesn't prevent surgical errors. A checklist that the surgeon must read aloud to the team before cutting does. The difference isn't content — it's that the protocol makes the check a required step in the workflow, not a reminder to consult.

### 4.2 Concrete Proposal: GATES.md

Create a new boot-context file: `GATES.md` at workspace root (auto-injected by OpenClaw).

**GATES.md is not a list of rules. It's a list of action-triggered protocols that MIKA must execute before specific output types.**

```markdown
# GATES.md — Mandatory Pre-Action Checks

These are NOT guidelines. They are GATES. You do not pass through without completing the check.
Skipping a gate is a trust violation equivalent to leaking private data.

## Gate: COMMAND
**Trigger:** About to tell Jerome to run a command, install a package, or use a CLI flag.
**Protocol:**
1. BEFORE writing the command in your response, run `--help` or equivalent in your own shell.
2. If you cannot verify (no shell access, command not installed), write: "⚠️ UNVERIFIED: [reason]"
3. There is no "I'm pretty sure" exception. Verify or label.
**Violation consequence:** Jerome runs a broken command. Trust erodes. This has happened twice already.

## Gate: EXTERNAL
**Trigger:** About to send an email, tweet, public post, or message to anyone other than Jerome.
**Protocol:**
1. Draft the message internally first.
2. Show Jerome the draft and recipient.
3. Wait for explicit approval before sending.
**Violation consequence:** Unauthorized communication on Jerome's behalf.

## Gate: DESTRUCTIVE
**Trigger:** About to run rm, drop, delete, wipe, or any irreversible operation.
**Protocol:**
1. Use `trash` instead of `rm` where possible.
2. State what will be destroyed and why.
3. Wait for explicit approval.
**Violation consequence:** Permanent data loss.

## Gate: SECURITY-RECOMMENDATION
**Trigger:** About to recommend a security configuration, firewall rule, or access control change.
**Protocol:**
1. Cite the specific documentation or standard.
2. If no citation available, label as "MIKA's reasoning, not documented best practice."
3. Test on non-production first if possible.
**Violation consequence:** False sense of security from unverified advice.
```

### 4.3 Why GATES.md Works Where USER.md Didn't

| Property | USER.md rule | GATES.md protocol |
|----------|-------------|-------------------|
| **Framing** | Preference ("Jerome likes verified commands") | Obligation ("you do not pass without completing the check") |
| **Specificity** | Descriptive ("check docs, --help, or test") | Procedural (step 1, step 2, step 3) |
| **Action** | Implicit (verify somehow) | Explicit (run `--help` in your shell) |
| **Fallback** | None stated | Explicit: write "⚠️ UNVERIFIED" |
| **Stakes** | Implied | Stated: "trust violation equivalent to leaking private data" |
| **Format** | Buried in a list of 15+ preferences | Isolated, each gate is visually distinct |
| **Cognitive load** | Must remember to apply while generating | Protocol IS the generation sequence |

The key differences:

1. **Isolation.** GATES.md is its own file, not buried in a list of preferences. It's a short, high-signal file that exists for one purpose.

2. **Procedural, not descriptive.** Each gate says exactly what to DO, in order. Not "verify commands" but "run --help before writing the command."

3. **Explicit fallback.** The verify-commands rule in USER.md has no escape hatch. When MIKA can't verify but wants to be helpful, it just... skips the rule. GATES.md provides an explicit fallback: label it unverified. This matters because it gives the model a way to be helpful AND compliant.

4. **Consequence framing.** LLMs respond to stated consequences. "This has happened twice already" and "trust violation equivalent to leaking private data" create weight that "check docs" doesn't.

5. **Trigger-action format.** Each gate starts with an explicit trigger condition. This is pattern-matchable — when the model is about to write a command, the trigger condition "about to tell Jerome to run a command" should activate.

### 4.4 The Promotion Pipeline

When memory-forge creates a lesson with `severity: critical`, it should ALSO:

1. Check if the lesson maps to an existing gate → update the gate's evidence/protocol
2. If no gate exists → draft a new gate entry and flag it for review
3. Update the gate count in CONTEXT.md awareness index

This means critical lessons don't just become searchable files — they get promoted to the enforcement layer.

```
Lesson created (severity: critical)
    │
    ├── Written to memory/lessons/ (recall layer)
    │
    └── Promoted to GATES.md (enforcement layer)
         │
         └── Auto-injected in boot context every session
```

### 4.5 Keeping GATES.md Small

GATES.md must stay small to stay effective. If it grows to 20 gates, it becomes another wall of text that gets skimmed. Design constraints:

- **Maximum 7 gates** (cognitive limit for distinct categories)
- **Each gate ≤ 150 words** (protocol must be scannable)
- **Review quarterly:** merge similar gates, archive ones that haven't been relevant
- **Only `severity: critical` lessons promote to gates** — high and below stay as lesson files

If a new critical lesson doesn't fit an existing gate, the LEAST-triggered gate gets reviewed for demotion to a lesson file.

---

## 5. Complementary Mechanism: The Verify Habit

GATES.md is structural. But it also helps to build the habit. Add to AGENTS.md under the Safety section:

```markdown
## Pre-Action Protocol
Before any response that includes commands, external messages, destructive operations,
or security recommendations: check GATES.md mentally. If a gate applies, follow its protocol.
This is not optional. See GATES.md for the full gate definitions.
```

This cross-reference creates two paths to the same enforcement:
1. Reading GATES.md directly (boot injection)
2. The AGENTS.md reminder pointing back to GATES.md

Redundancy is the point. Belt AND suspenders.

---

## 6. What This Doesn't Solve

Let me be honest about the limits:

1. **No file-based system can truly enforce behavior on an LLM.** All of this is soft constraint. A sufficiently strong helpfulness impulse can override any instruction. The goal is to make violation require actively ignoring a prominent, procedural, explicitly-consequenced gate — which is much harder to do unconsciously than ignoring a buried preference line.

2. **Novel action types.** Gates only cover known risk categories. A new type of risky action (not yet categorized) won't have a gate. The memory-forge → gate promotion pipeline helps, but there's always a first failure.

3. **Speed pressure.** If Jerome asks "quick, what's the command for X?" — the pressure to respond fast competes with the gate protocol. The explicit fallback ("⚠️ UNVERIFIED") is designed for this case, but it requires the model to choose the slower path.

4. **Gate fatigue.** If every response requires checking gates, the checks become rote and lose effectiveness. The trigger conditions must be specific enough that gates only activate when relevant.

---

## 7. Implementation Plan

### Immediate (today)
1. Create `GATES.md` at workspace root with the COMMAND, EXTERNAL, DESTRUCTIVE, and SECURITY-RECOMMENDATION gates
2. Add the cross-reference to AGENTS.md Safety section
3. Remove the verify-commands line from USER.md (it's now in GATES.md with more authority)

### Phase 3 of ARCHITECTURE.md migration (skill updates)
4. Update memory-forge: when `severity: critical`, also promote to GATES.md
5. Add gate-count to CONTEXT.md awareness index
6. Add GATES.md review to quarterly optimize-memory maintenance

### Ongoing
7. After any trust violation: review whether a gate should be added or an existing gate's protocol needs strengthening
8. Track gate activations informally in daily logs (did MIKA actually run --help before giving a command today?)

---

## 8. The Meta-Lesson

The reason this analysis matters beyond MIKA's specific case:

**The gap between "knowing" and "doing" in LLM agents is structural, not motivational.** An LLM doesn't forget rules or get lazy — it has competing optimization pressures (helpfulness, fluency, speed) that can override instructions, especially when those instructions require interrupting the generation flow.

The fix isn't better memory. It's better architecture at the point of action:
- **Isolation** (don't bury critical rules in long documents)
- **Procedure** (step-by-step protocols, not descriptions)
- **Fallbacks** (give the agent a compliant alternative to skipping the rule)
- **Consequences** (state what goes wrong — LLMs weight stated consequences)
- **Redundancy** (multiple paths to the same enforcement)

The ARCHITECTURE.md is excellent for recall. GATES.md is the missing enforcement layer.

---

*Analysis complete. The proposal is a single new file (GATES.md) + a memory-forge promotion pipeline + a cross-reference in AGENTS.md. Minimal surface area, maximum leverage on the actual failure mode.*
