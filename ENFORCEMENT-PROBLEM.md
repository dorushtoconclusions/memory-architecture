# ENFORCEMENT PROBLEM — Critical Architecture Gap

## The Failure
MIKA has 9 lessons in `memory/lessons/`, including `process-research-order.md` (verify commands before giving them). In the SAME SESSION that lesson was migrated, MIKA violated it twice:
1. Gave Jerome `gh auth login -u` — flag doesn't exist (never ran `--help`)
2. Gave Jerome `npm install -g @anthropic-ai/gemini-cli` — package doesn't exist (fabricated)

## The Root Cause
Lessons are **passive reference files**. They exist, they're searchable, they're well-formatted — but nothing FORCES them to be consulted before action. The current architecture assumes MIKA will voluntarily check lessons before acting. That assumption is proven wrong.

## What Needs Fixing
The memory architecture needs an **enforcement layer** — something that makes critical lessons unavoidable, not optional. Passive recall is not enough for safety-critical and trust-critical rules.

## Constraints
- Must work within OpenClaw's existing architecture (file-based, workspace injection, cron, heartbeat)
- Cannot rely on MIKA "choosing" to check — that's the failure mode we're fixing
- Must handle the specific case: "about to give a command to the human"
- Should be generalizable to other critical triggers (security recommendations, external-facing actions)
- Must not add so much friction that it slows down routine work

## Inputs
- `memory/lessons/*.md` — current lesson files with trigger/rule/boundary structure
- `AGENTS.md` — operational rules loaded every session
- `MEMORY.md` — curated boot context loaded every session  
- `ARCHITECTURE.md` — current memory architecture design
- Current failure evidence: this session's transcript

## Deliverable
A concrete architectural fix — not just "be more careful" or "add a checklist." Something structural that changes the system, not just the intent.
