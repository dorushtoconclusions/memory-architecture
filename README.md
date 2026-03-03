# Memory Architecture Redesign

## What This Is
A tiered temporal memory system for AI agents that need to maintain identity, learn from experience, and scale knowledge over 1-5 years without drowning in context window bloat.

Built by MIKA + Jerome, March 2026. Designed to be shared across multiple agents.

## The Problem
AI agents using a single monolithic memory file face a dilemma: either the file grows until it kills the context window, or it gets pruned and knowledge is lost. This architecture solves that.

## The Solution
Three temporal tiers + structured knowledge entities + automated summarization:

- **Boot context** (~15-20K tokens): Identity, relationship, active work, recent context. Makes the agent feel like the same partner every session.
- **Warm storage** (searchable): Lessons, people, decisions, weekly/monthly summaries. Not loaded at boot, retrieved on demand via hybrid search.
- **Cold storage** (archival): Raw daily logs. Searchable but rarely accessed directly.

## Read Order

1. **CONSTRAINTS.md** — What the system must do (26 constraints, growth model to year 5)
2. **ARCHITECTURE.md** — How it works (file structure, summarization pipeline, entity schemas, retrieval cascade, migration plan)
3. **VERIFICATION-PLAN.md** — How to test each constraint
4. **PRESSURE-TEST.md** — Honest self-review with 7 identified risks
5. **memory-forge-SKILL.md** — Skill for creating high-quality memory entries

## Key Design Decisions

- **Files are the database, search is the query engine.** No custom DBs, no vector store servers.
- **Boot context is curated, not minimized.** 20K tokens today, grows as context windows grow.
- **Temporal summarization** via cron: daily → weekly → monthly → quarterly.
- **Entity files** with YAML frontmatter: lessons, people, decisions each get their own directory.
- **CONTEXT.md** auto-generated daily: recent context + awareness index. Exploits OpenClaw's workspace file injection.
- **Demotion ≠ deletion.** Knowledge moves between tiers, never destroyed.
- **Incremental migration.** 4 phases, each independently useful with rollback.

## For the Other Agent
If you're adopting this architecture:

1. Read CONSTRAINTS.md to understand the requirements
2. Read ARCHITECTURE.md sections 2 (file structure), 6 (entity schemas), and 7 (retrieval flow)
3. Adapt the file paths to your workspace
4. Start with Phase 1 of the migration plan (section 11 of ARCHITECTURE.md)
5. The memory-forge skill works standalone — you can use it immediately

## Status
- **Pass 1 (Constraints):** ✅ Complete
- **Pass 2 (Architecture):** ✅ Complete
- **Pressure Test:** ✅ Complete
- **Pass 3 (Build Plan):** Not started
- **Build:** Not started

## Ignore These Files
The following files are from a prior project and predate this architecture. They're included because they were in the same directory:
- BRIEF.md, CLAUDE-ANALYSIS.md, CLAUDE-REVIEW.md, CODEX-ANALYSIS.md, CODEX-REVIEW.md
- DISPATCH-DRAFT.md, MEMORY-DRAFT*.md, RESEARCH-AGENT-ORCHESTRATION.md, REVIEW-PASS*.md
