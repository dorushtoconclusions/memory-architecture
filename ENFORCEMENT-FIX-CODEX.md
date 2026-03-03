# ENFORCEMENT-FIX-CODEX

## Executive Summary
The failure happened because lessons were **data, not behavior controls**. MIKA had the lesson files and could search them, but there was no architectural mechanism that forces a gate before outputting unsafe/unverified recommendations.

**Structural fix:** introduce an **Action-Gate layer** that turns critical lessons into an execution contract. Before sending any command/recommendation that affects Jerome’s machine or trust-critical workflows, MIKA must pass through a file-based gate that produces a verifiable evidence artifact.

This moves enforcement from “remember to check lessons” to “cannot emit command without gate artifact.”

---

## Where the current architecture failed

From the incident and reviewed files:

- `memory/lessons/*.md` are indexed but optional to consult.
- No boot-critical manifest of **high-severity action triggers** exists at session start.
- No shared, machine-readable contract for what must be checked before recommendation.
- No pre-action interception path for command/security/tool suggestions.

So the system optimized for **recall** but not **prevention**.

---

## Proposed Structural Change: Three-Part Enforcement Layer

### 1) **Compile-time Action Gate Pack (Boot-injected once per session)**

Create a generated root-injected policy file (e.g., `ACTION-GATES.md`) built from lessons with `severity: high|critical` and command/security-related triggers.

- Source: lessons + additional metadata in their frontmatter (see section 2).
- Location: root (`/Users/mika/.openclaw/workspace/ACTION-GATES.md`) so OpenClaw injects it like other core context files.
- Contents:
  - Trigger matrix (normalized)
  - Required checks per trigger
  - Forbidden output forms when checks are missing
  - Verification evidence format

**Why structural:** MIKA sees the gate contract at boot automatically; lesson lookup is no longer hunting in memory.

---

### 2) **Hard Response Contract in AGENTS.md (Prompt structure as execution boundary)

Add a strict section in `AGENTS.md` for all external-facing outputs:

- `about-to-recommend-tool`
- `about-to-give-jerome-a-command`
- `recommending-security-changes`
- `presenting-recommendation`

**Contract rule:**

1. If response contains a command or config recommendation, it **must** include a `COMMAND/TOOL GATE` block.
2. The block must include:
   - `verification_id`
   - list of checks run
   - check outputs (or explicit “unverified” status)
   - confidence label (`verified/reasoned/unverified`)
3. If verification checks fail/aren’t run, response must only be `I haven't verified this.` + next step.

This is a protocol-level hard-stop, not style guidance.

---

### 3) **Pre-action verification artifact + script (Command/Suggestion Gate)

Introduce a first-class evidence file and lightweight validator script:

- Directory: `memory/verification/pending/` and `memory/verification/issued/`
- Script: `scripts/verify-gate.sh` (or wrapper in an existing skill)

For each candidate command recommendation:

1. Candidate is first written as a verification request with proposed command.
2. Validator runs required checks from `ACTION-GATES.md`:
   - help/flag existence (`--help`/`man`)
   - package/module provenance (`brew`/`npm` where applicable)
   - safe dry-run where possible
3. Validator emits a timestamped evidence file:
   - `memory/verification/issued/<YYYYMMDDTHHMMSSZ>-cmd-<slug>.md`
4. MIKA must reference this file in the response (not just raw advice).

**Result:** command claims become data products, not casual text.

---

## Why this is stronger than “be careful”

This design changes the path from:

> “MIKA decides it’s a good time to cite a lesson”

to:

> “Action is only emitted through a gate artifact required by injected policy.”

Even if LLM intent drifts, a missing gate artifact is visible as an explicit protocol breach.

---

## Generalization to non-command critical actions

Use same mechanism for all high-risk recommendations:

- **Security/config recommendations** (`safety-understand-enforcement`) -> required checks include enforcement-chain summary + rollback plan.
- **Tool recommendations** (`process-research-order`) -> required checks include README/docs + `--help` before web-first claims.
- **Any recommendation surfaced as fact** (`safety-label-confidence`) -> required confidence label is mandatory and tied to evidence.

This gives one mechanism for all critical triggers instead of per-case habits.

---

## Concrete schema additions (minimal)

Add machine-readable fields to lesson frontmatter to let policy compile automatically:

- `enforcement_mode: hard | soft`
- `required_checks:` list
- `allowed_outputs: [command_block, confidence_label, fallback_text]`
- `failure_action: [refuse, state-unverified, request_verification]`

Example extension for `process-verify-commands-before-giving.md`:

```yaml
severity: critical
enforcement_mode: hard
action_trigger: about-to-give-jerome-a-command
required_checks:
  - command_help
  - package_origin_lookup
  - dry_run_if_possible
failure_action: state-unverified
```

This keeps lessons as rules, but now they compile into enforceable gates.

---

## Rollout (low-friction)

1. Add `ACTION-GATES.md` generator and the hard contract text in `AGENTS.md`.
2. Add `verify-gate` helper script + evidence directory.
3. Update lesson schema in the two critical lessons now (process/safety + command verification).
4. Run `qmd update` so new gate files are indexed.
5. Add a weekly audit script in existing verification harness to validate command outputs always include verification blocks.

---

## Acceptance criteria for this fix

- In a new session, `ACTION-GATES.md` is loaded at boot automatically.
- If a command recommendation is made without a valid verification artifact, AGENTS-level contract is visibly broken.
- Any repeated command-error regression now has explicit, structured evidence of which gate failed.
- Similar gate logic applies across command, tool, and security recommendation flows.

---

### Relevant references reviewed

- `ENFORCEMENT-PROBLEM.md`
- `AGENTS.md`
- `MEMORY.md`
- `memory/lessons/process-research-order.md`
- `memory/lessons/process-verify-commands-before-giving.md`
- `ARCHITECTURE.md`