# ARCHITECTURE.md — Memory Architecture Redesign

*PAIGE Pass 2 · 2026-03-02*

---

## 1. Design Overview

MIKA's memory architecture is a file-based, tiered temporal system with structured knowledge entities, hybrid search, and curated boot injection. It replaces the current monolithic MEMORY.md approach with a system that scales sub-linearly while preserving identity continuity.

**Core principles:**
- Files are the database. Search is the query engine. [AC-001, AC-005, AC-008]
- Boot context is curated, not generated. [AC-003, C-002]
- Existing files are never touched. New system starts going forward. [Gate 1 resolution]
- Every component fails independently. [C-025]

---

## 2. File & Directory Structure

All paths relative to `/Users/mika/.openclaw/workspace/`.

```
├── SOUL.md                          # Identity (immutable) [C-001, C-004]
├── IDENTITY.md                      # Identity metadata [C-001, C-004]
├── USER.md                          # Jerome relationship [C-001, C-004]
├── AGENTS.md                        # Operational rules [C-003]
├── TOOLS.md                         # Environment notes [C-003]
├── MEMORY.md                        # Curated boot context (restructured) [C-002, C-003]
├── CONTEXT.md                       # NEW: Auto-generated recent context [C-005, C-022]
│
├── memory/
│   ├── YYYY-MM-DD.md                # Daily logs (existing, unchanged) [C-010]
│   ├── staging.md                   # memory-forge staging area (existing)
│   │
│   ├── summaries/                   # NEW: Temporal summaries [C-005]
│   │   ├── YYYY-Www.md             # Weekly summaries [C-006]
│   │   ├── YYYY-MM.md              # Monthly summaries [C-007]
│   │   ├── YYYY-Qq.md             # Quarterly (future, context-gated) [C-008]
│   │   └── errors.log              # Summarization failures [C-009]
│   │
│   ├── lessons/                     # NEW: First-class lesson entities [C-016]
│   │   └── CATEGORY-slug.md        # One file per lesson
│   │
│   ├── people/                      # NEW: People registry [C-018]
│   │   └── person-slug.md          # One file per person
│   │
│   ├── decisions/                   # NEW: Decision log [C-019]
│   │   └── YYYY-MM-DD-slug.md     # One file per decision
│   │
│   └── archive/                     # Cold storage [C-023]
│       └── (moved files, never deleted)
│
├── projects/                        # Project lifecycle (existing) [C-017]
│   ├── active-project/
│   │   └── README.md               # Status, dates, outcome
│   └── archive/                     # Completed projects
│       └── completed-project/
│           └── README.md
│
└── scripts/                         # NEW: Automation scripts
    ├── summarize-weekly.md          # Cron prompt for weekly summary
    ├── summarize-monthly.md         # Cron prompt for monthly summary
    └── generate-context.md          # Cron prompt for CONTEXT.md
```

**Rationale for CONTEXT.md as a separate workspace root file:** OpenClaw injects all workspace root `.md` files as Project Context [A-003]. By placing auto-generated recent context in `CONTEXT.md` at workspace root, it gets injected at boot without OpenClaw core changes. [Gate 1 resolution: boot injection within existing mechanisms]

---

## 3. Boot Context Composition

**What gets loaded at session start (via OpenClaw workspace file injection):**

| Priority | File | Content | Size Target | Constraint |
|----------|------|---------|-------------|------------|
| 1 | SOUL.md | Identity, personality, rules | ~1.5 KB (stable) | C-001, C-004 |
| 2 | IDENTITY.md | Name, avatar, emoji | ~0.4 KB (stable) | C-001, C-004 |
| 3 | USER.md | Jerome: who, how, preferences | ~2.1 KB (stable) | C-001, C-004 |
| 4 | AGENTS.md | Operational rules, heartbeat, safety | ~7.9 KB (slow growth) | C-003 |
| 5 | TOOLS.md | Environment-specific notes | ~2.0 KB (slow growth) | C-003 |
| 6 | MEMORY.md | Curated long-term knowledge | ~8-12 KB (curated growth) | C-002, C-003, C-020 |
| 7 | CONTEXT.md | Auto-generated recent context | ~2-4 KB (regenerated) | C-005, C-022 |
| — | Other root .md | Various (PIPELINE, etc.) | varies | — |

**Total boot context at 200K window: ~26 KB** (all root .md files per `wc -c *.md` = ~114 KB currently, but many of those are non-essential). The essential boot files total ~24-30 KB, well within the ≤20K token budget (1 token ≈ 4 chars, so ~30 KB ≈ 7.5K tokens). [C-002]

**Problem: all root .md files are injected.** Current root has 15+ .md files including CONSTRAINTS.md, CRANK-MASTER.md, PIPELINE.md, etc. Many are not boot-critical.

**Solution:** Move non-boot files out of workspace root into appropriate subdirectories during migration. Only files that are genuinely boot-critical remain at root. This is a curation problem, not a technical one. [C-002, C-020]

### CONTEXT.md — Auto-Generated Recent Context

Generated daily (or more frequently) by cron. Contains:

```markdown
# CONTEXT.md — Recent Context (auto-generated, do not edit)
# Last updated: YYYY-MM-DD HH:MM CST

## Yesterday (YYYY-MM-DD)
<3-5 bullet summary of yesterday's daily log>

## This Week So Far
<5-8 bullet summary of this week's daily logs>

## Active Threads
<list of open items from recent daily logs>

## Awareness Index
- Lessons: N entries in memory/lessons/ (categories: Process, Safety, ...)
- People: N entries in memory/people/ (top 5 by recent interaction)
- Decisions: N entries in memory/decisions/ (most recent 3)
- Projects: N active in projects/ (list names)
- Weekly summaries: N in memory/summaries/ (latest: YYYY-Www)
```

**Size:** Targeted at 2-4 KB. Regenerated, never accumulated. [C-020, C-005]

**Generation:** Cron job, daily at 5 AM CST (after any daily log from previous day is complete). Uses Sonnet. [C-009, Gate 1 resolution]

---

## 4. MEMORY.md — Restructured Role

MEMORY.md transitions from a knowledge dump to a **curated identity + active state document**. [C-002, C-003, AC-003]

**New structure:**

```markdown
# MEMORY.md — Long-Term Memory

## About Jerome
<essential relationship context — stays>

## The Partnership
<partnership model — stays>

## Lessons
<REMOVED: migrated to memory/lessons/>
<Replaced with:>
See memory/lessons/ (N entries). Key categories: Process, Safety, Platform, Tool, Tech.
For recall: `qmd search "query" -c memory`

## Preferences
<stays — these are boot-critical operational rules>

## Dispatch Model
<stays — boot-critical operational context>

## Active Tracks
<stays — curated list of what's in progress>

## Key People
<REPLACED: summary list only>
- **Nate** — AI content creator, blogwatcher target
- **[Person]** — one-line context
Full profiles: memory/people/

## Agentic Economy Strategy
<stays — active strategic context>

## Pending
<stays — curated open items>

## Machines / Agent Setup / Security Model
<MOVED to TOOLS.md or MACHINE.md — reference material, not boot-critical identity>
```

**Target size:** 8-12 KB, stabilized. Growth comes from new active tracks and strategic context, not from accumulating lessons/people/decisions. [C-002, C-020, R-003]

**What moves out:**
- Individual lessons → `memory/lessons/` [C-016]
- People detail → `memory/people/` [C-018]
- Machine specs → `MACHINE.md` (already exists)
- Completed items → deleted (in git + daily logs)
- Codex/MLX reference → `TOOLS.md`

---

## 5. Temporal Summarization Pipeline

### 5.1 Weekly Summary [C-006, C-009]

**Schedule:** Sunday 3:00 AM CST (OpenClaw cron)
**Model:** Sonnet [Gate 1 resolution]
**Input:** Daily logs from the past 7 days
**Output:** `memory/summaries/YYYY-Www.md`

**Cron prompt** (stored at `scripts/summarize-weekly.md`):

```
You are summarizing MIKA's daily logs for the week of YYYY-MM-DD to YYYY-MM-DD.

Read these daily logs: memory/YYYY-MM-DD.md (for each day of the week)

Produce a weekly summary with this structure:

---
type: weekly-summary
date: YYYY-MM-DD  # Monday of the week
week: YYYY-Www
tags: [auto-generated from content]
projects: [project slugs mentioned]
people: [people mentioned]
---

# Week of YYYY-MM-DD — YYYY-MM-DD

## Key Decisions
<decisions made this week, with rationale>

## Lessons Learned
<new patterns, mistakes, discoveries>

## Project Progress
<per-project status changes>

## People & Interactions
<notable interactions, new contacts>

## Open Threads
<things started but not finished>

## Week Summary
<2-3 sentence narrative arc of the week>

Target: 500-1500 words. Reference source dates. Be specific, not vague.
If a daily log is missing or empty, note the gap.
```

**Failure handling:** If summarization fails, log error to `memory/summaries/errors.log` with timestamp and reason. Retry once after 1 hour. If retry fails, flag in next day's CONTEXT.md generation as "Weekly summary pending — manual review needed." [C-009]

### 5.2 Monthly Summary [C-007, C-009]

**Schedule:** 1st of each month, 4:00 AM CST
**Model:** Sonnet [Gate 1 resolution]
**Input:** Weekly summaries for the past month
**Output:** `memory/summaries/YYYY-MM.md`

**Cron prompt** (stored at `scripts/summarize-monthly.md`):

```
You are synthesizing MIKA's weekly summaries into a monthly summary for YYYY-MM.

Read: memory/summaries/YYYY-Www.md (for each week in the month)

Produce a monthly summary:

---
type: monthly-summary
date: YYYY-MM-01
month: YYYY-MM
tags: [auto-generated]
projects: [all project slugs]
people: [all people mentioned]
---

# Month: YYYY-MM

## Major Milestones
<what shipped, what completed>

## Strategic Shifts
<changes in direction, new priorities>

## Relationship Developments
<new contacts, deepened partnerships>

## Cumulative Lessons
<patterns that emerged across weeks>

## Project Status
<per-project: where it started, where it ended>

## Month Narrative
<3-5 sentence strategic arc>

Target: 1000-3000 words. Strategic perspective, not event list.
```

### 5.3 Quarterly Synthesis [C-008]

**Gated:** Only generated when context window ≥ 500K tokens.
**Schedule:** First week of quarter months (Jan, Apr, Jul, Oct), 5:00 AM CST
**Input:** Monthly summaries for the past quarter
**Output:** `memory/summaries/YYYY-Qq.md`

Not designed further until the context window gate is met. [C-008: "future phase"]

### 5.4 CONTEXT.md Generation [C-005, C-022]

**Schedule:** Daily at 5:00 AM CST, plus after each main session ends (if feasible via heartbeat)
**Model:** Haiku (lightweight, fast) [Gate 1 dispatch rules]
**Input:** Today's daily log (if exists), yesterday's daily log, this week's daily logs, latest weekly summary
**Output:** Overwrites `CONTEXT.md` at workspace root

**Cron prompt** (stored at `scripts/generate-context.md`):

```
You are generating MIKA's boot context file. This file is loaded every session.

Read:
- memory/YYYY-MM-DD.md (today, if exists)
- memory/YYYY-MM-DD.md (yesterday)
- memory/YYYY-MM-DD.md (other days this week)
- memory/summaries/ (latest weekly summary)
- memory/lessons/ (count files, list categories)
- memory/people/ (count files, list top 5 by modified date)
- memory/decisions/ (count files, list 3 most recent)
- projects/ (list active project names)

Produce CONTEXT.md:

# CONTEXT.md — Recent Context
# Auto-generated YYYY-MM-DD HH:MM CST — Do not edit

## Yesterday
<3-5 bullet summary>

## This Week
<5-8 bullet summary>

## Active Threads
<open items requiring follow-up>

## Knowledge Index
- Lessons: N (Process: n, Safety: n, ...)
- People: N (recently active: name, name, ...)
- Decisions: N (recent: slug, slug, slug)
- Projects: N active (name, name, ...)
- Summaries: N weekly, N monthly

Keep under 3KB. Be specific. No fluff.
```

---

## 6. Knowledge Entity Schemas

### 6.1 Lessons [C-016, C-013]

**Path:** `memory/lessons/CATEGORY-slug.md`
**Example:** `memory/lessons/process-research-order.md`

```yaml
---
type: lesson
date: 2026-03-02
category: process
tags: [research, tools, documentation]
trigger: about-to-recommend-tool
severity: high
---
```

```markdown
# Research Order Before Recommending

**Trigger:** About to recommend a tool, config, or command.

**Rule:** Follow research order: (1) tool's own README/docs, (2) `--help`/man page, (3) GitHub issues, (4) web search, (5) sub-agent. Never skip to web search before reading local docs.

**Evidence:** iMessage TCC incident 2026-03-02 — web searches and sub-agent both returned wrong advice; the imsg README had the correct answer.

**Boundary:** General knowledge questions unrelated to a specific tool.
```

**Naming convention:** `{category}-{descriptive-slug}.md` where category is one of: `process`, `safety`, `platform`, `tool`, `tech`.

**Migration from MEMORY.md:** Each lesson currently inline in MEMORY.md becomes a separate file. MEMORY.md's `## Lessons` section becomes a pointer: "N lessons in memory/lessons/. Use `qmd search` for recall."

### 6.2 People [C-018, C-013]

**Path:** `memory/people/person-slug.md`
**Example:** `memory/people/nate.md`

```yaml
---
type: person
name: Nate
relationship: AI content creator
first-contact: 2026-02-21
tags: [newsletter, AI, content]
active: true
---
```

```markdown
# Nate

**Relationship:** AI content creator (natesnewsletter.substack.com)
**Context:** Blogwatcher scanning 2x daily for his newsletter content.
**Notes:** Source for AI trend monitoring. Feed configured in blogwatcher.

## Interaction Log
- 2026-02-21: Set up blogwatcher scanning for Nate's Newsletter
```

**Boot context integration:** Top 10 people (by `active: true` + recency) get a one-line entry in MEMORY.md. Others found via `qmd search`. [C-018]

### 6.3 Decisions [C-019, C-013]

**Path:** `memory/decisions/YYYY-MM-DD-slug.md`
**Example:** `memory/decisions/2026-03-01-mac-studio-primary.md`

```yaml
---
type: decision
date: 2026-03-01
tags: [infrastructure, migration]
project: mac-studio-migration
people: [jerome]
status: pending
---
```

```markdown
# Migrate OpenClaw from p920 to Mac Studio

**Decision:** Mac Studio (M1, 64GB) becomes primary OpenClaw host. p920 becomes secondary/fallback.

**Rationale:** Native Talk Mode, iMessage, Apple integrations. MLX inference local. Unified machine reduces operational complexity.

**Alternatives Considered:**
- Keep p920 as primary (rejected: no Apple integrations)
- Run both as co-primary (rejected: complexity without benefit)

**Outcome:** Pending — awaiting Jerome's go-ahead to wipe.

**Related:** projects/mac-studio-migration/
```

### 6.4 Daily Logs [C-010, C-013]

**Existing logs remain exactly as they are.** [Gate 1 resolution]

**Going forward**, new daily logs get frontmatter:

```yaml
---
type: daily-log
date: 2026-03-02
tags: [memory-rewrite, architecture]
projects: [memory-rewrite]
people: [jerome]
---
```

**Immutability rule:** Once a daily log has been included in a weekly summary (i.e., log is >8 days old), no further edits. [C-010]

### 6.5 Summaries [C-006, C-007, C-013]

Frontmatter shown in §5.1 and §5.2 above.

---

## 7. Retrieval Flow

When MIKA needs to recall something not in boot context: [C-011, C-012, C-014]

```
┌─────────────────────────────────────────────────┐
│ 1. BOOT CONTEXT (always available, 0ms)          │
│    MEMORY.md + CONTEXT.md + identity files        │
│    → Answers: identity, active tracks, yesterday, │
│      this week, key people, preferences            │
└──────────────────────┬──────────────────────────┘
                       │ Not found
                       ▼
┌─────────────────────────────────────────────────┐
│ 2. QMD HYBRID SEARCH (<2s) [C-011, C-014]       │
│    qmd query "natural language query" -n 5        │
│    → BM25 + vector + reranking                    │
│    → Returns top 5 with snippets                  │
│    → Check precision: right answer in top 3?      │
└──────────────────────┬──────────────────────────┘
                       │ Need more detail
                       ▼
┌─────────────────────────────────────────────────┐
│ 3. TARGETED RETRIEVAL (<5s)                      │
│    qmd get "docid" — full document                │
│    read file directly if path known               │
│    → Loads full context for the specific item     │
└──────────────────────┬──────────────────────────┘
                       │ Need broader context
                       ▼
┌─────────────────────────────────────────────────┐
│ 4. FILTERED SEARCH (<5s) [C-013]                 │
│    qmd search "query" -c memory                   │
│    → Filter by collection, manually by frontmatter│
│    → Narrow to type, project, person, date range  │
└──────────────────────┬──────────────────────────┘
                       │ Still not found
                       ▼
┌─────────────────────────────────────────────────┐
│ 5. TEMPORAL DRILL-DOWN                           │
│    Read summary for the relevant time period      │
│    Weekly → find the week, read daily logs from it│
│    Monthly → find the month, read weekly summaries│
│    → Follow references to source material         │
└─────────────────────────────────────────────────┘
```

**Precision@3 strategy** [C-012]:
- Structured frontmatter enables pre-filtering (by type, project, person) before ranking
- Hybrid search (BM25 + vector) catches both exact and semantic matches [C-014]
- Weekly/monthly summaries act as "index documents" — they mention topics from their period, so they surface in search and point to source material
- qmd collection tags provide additional context for search relevance

**"Bulletproof recall" definition:** Any past decision, lesson, project, or person found in ≤2 search calls and <10 seconds total. [Glossary]

---

## 8. Skill Changes

### 8.1 memory-forge Modifications [C-016]

**Current:** Promotes lessons as inline entries in MEMORY.md `## Lessons` section.
**New:** Promotes lessons as individual files in `memory/lessons/`.

Changes to the workflow:

1. **Step 4 (DRAFT):** Output format changes to full file with frontmatter (§6.1 schema)
2. **Step 6 (PROMOTE):** Instead of appending to MEMORY.md, write to `memory/lessons/CATEGORY-slug.md`
3. **Step 6 (PROMOTE):** Update MEMORY.md lesson count reference (not individual entries)
4. **Step 7 (CLEANUP):** Also run `qmd update` to ensure new lesson is indexed within minutes (vs waiting for 30-min cron)
5. **Anti-Bloat Rule #4 (quarterly review):** Review `memory/lessons/` directory. Archive stale lessons to `memory/archive/lessons/` [C-023]

**New capability:** memory-forge can also create people entries (`memory/people/`) and decision entries (`memory/decisions/`) when the captured knowledge fits those entity types rather than being a "lesson."

### 8.2 optimize-memory Modifications [C-002, C-020]

**Current:** Trims MEMORY.md by removing completed/stale items.
**New:** Additionally responsible for:

1. **Entity extraction:** During optimization, identify lessons/people/decisions still inline in MEMORY.md and extract them to proper entity files
2. **Boot budget monitoring:** Check total boot context size (all root .md files) against the 10% context window target [C-002]
3. **CONTEXT.md validation:** Verify CONTEXT.md is fresh (generated within last 24h) and within size target
4. **Growth tracking:** Log boot context size to `memory/boot-size-log.json` for sub-linear growth verification [C-020]

```json
{
  "measurements": [
    {"date": "2026-03-15", "boot_bytes": 28000, "corpus_docs": 150},
    {"date": "2026-04-01", "boot_bytes": 29500, "corpus_docs": 220}
  ]
}
```

---

## 9. Context Window Adaptation [C-022]

The adaptation ladder is implemented via the CONTEXT.md generation prompt, which includes more or less content based on a configurable threshold.

**Mechanism:** A config value in `scripts/context-config.json`:

```json
{
  "context_window_tokens": 200000,
  "adaptation_tier": "200k",
  "boot_budget_pct": 10,
  "boot_budget_tokens": 20000
}
```

**Adaptation tiers:**

| Window | Tier | CONTEXT.md includes | Estimated boot total |
|--------|------|---------------------|---------------------|
| 200K | `200k` | Yesterday summary + this week bullets + awareness index | ~15-20K tokens |
| 500K | `500k` | Above + full daily logs (this week) + 4 recent weekly summaries | ~40-50K tokens |
| 1M+ | `1m` | Above + full month context + quarterly synthesis + expanded people | ~80-100K tokens |

**How it works without OpenClaw changes:**
- CONTEXT.md is always injected (it's a root .md file) [A-003]
- The cron job that generates CONTEXT.md reads `context-config.json` to decide how much to include
- When context windows grow, Jerome or MIKA updates the config value
- CONTEXT.md grows in content → boot context naturally includes more
- No conditional injection needed — just bigger CONTEXT.md [Gate 1 resolution]

**Trade-off:** At 200K tier, CONTEXT.md is small (~2-4 KB). At 1M tier, CONTEXT.md could be 30-50 KB. This is deliberate — more window = richer boot context. The constraint is quality, not size. [AC-004]

---

## 10. QMD Collection & Indexing Strategy [C-011, C-014, C-015]

**Current state:** Two collections (`workspace`, `memory`) indexing all .md files. 342 total documents. 30-min reindex cron.

**Changes needed:**

1. **Keep existing collections.** The `memory` collection already covers daily logs. The `workspace` collection covers everything.

2. **Context tags.** Add context descriptions to improve search relevance:
   - `memory/lessons/` context: "Reusable lessons and rules learned from experience"
   - `memory/people/` context: "People MIKA and Jerome interact with"
   - `memory/decisions/` context: "Significant decisions with rationale and alternatives"
   - `memory/summaries/` context: "Temporal summaries of daily activity"

3. **Index freshness.** The existing 30-min reindex cron [C-015] is sufficient. Memory-forge and summarization scripts can trigger immediate `qmd update` after writing new files for critical-path freshness.

4. **Scaling.** At 5,000 docs [A-002], qmd on Mac Studio M1 64GB with Metal should handle sub-2s search. The current 342 docs → projected 6,000 at year 5 is within the tested envelope. Monitor via periodic benchmarks. [R-001]

5. **Archive collection.** When files are archived to `memory/archive/`, they leave the default search scope. Add a separate `archive` collection that can be explicitly queried: `qmd search "query" -c archive`. [C-023]

---

## 11. Migration Plan [C-026]

**Principle:** Incremental. Each phase independently useful. No big-bang. Existing files untouched.

### Phase 1: Structure (Week 1)
**Goal:** Create directory structure, migrate existing inline knowledge to entity files.

1. Create directories: `memory/lessons/`, `memory/people/`, `memory/decisions/`, `memory/summaries/`, `memory/archive/`, `scripts/`
2. Extract lessons from MEMORY.md into individual files in `memory/lessons/`
3. Extract people from MEMORY.md into individual files in `memory/people/`
4. Extract decisions (scattered across daily logs and MEMORY.md) into `memory/decisions/`
5. Update MEMORY.md to reference entity directories instead of inline content
6. Move non-boot .md files from workspace root to appropriate subdirectories
7. Run `qmd update && qmd embed` to index new files
8. Add qmd context tags for new directories

**Rollback:** `git revert` the phase 1 commit. Original MEMORY.md restored. Entity files remain but are harmless.

**Verification:** Search for a migrated lesson via `qmd search`. Confirm it's found. Confirm MEMORY.md is smaller but still boot-functional.

### Phase 2: Summarization (Week 2-3)
**Goal:** Set up temporal summarization pipeline.

1. Write cron prompts: `scripts/summarize-weekly.md`, `scripts/summarize-monthly.md`, `scripts/generate-context.md`
2. Write `scripts/context-config.json`
3. Create CONTEXT.md generation cron job (daily 5 AM CST, Haiku)
4. Create weekly summary cron job (Sunday 3 AM CST, Sonnet) [C-009]
5. Create monthly summary cron job (1st of month 4 AM CST, Sonnet) [C-009]
6. Generate the first CONTEXT.md manually to validate
7. Wait for first automated weekly summary, review quality

**Rollback:** Delete cron jobs. Remove CONTEXT.md (or leave it — it's harmless). Summaries in `memory/summaries/` are additive, not destructive.

**Verification:** CONTEXT.md appears at boot with valid recent context. Weekly summary generates on schedule and is searchable.

### Phase 3: Skill Updates (Week 3-4)
**Goal:** Update memory-forge and optimize-memory to use new architecture.

1. Update memory-forge SKILL.md: promote to `memory/lessons/` instead of MEMORY.md inline
2. Update optimize-memory SKILL.md: add entity extraction, boot budget monitoring, growth tracking
3. Add frontmatter to new daily logs going forward
4. Test memory-forge end-to-end: capture → filter → verify → promote to file → indexed → searchable
5. Create `memory/boot-size-log.json` with initial measurement

**Rollback:** Revert skill .md files. Skills still work with old behavior.

### Phase 4: Validation & Tuning (Week 4+)
**Goal:** Verify constraints, tune search quality, establish baselines.

1. Build precision@3 test suite (20+ queries with known answers) [C-012]
2. Benchmark search latency at current doc count [C-011]
3. Verify sub-linear boot growth with first data point [C-020]
4. Test graceful degradation scenarios [C-025]
5. Review first month of summaries for quality [C-006, C-007]
6. Adjust summarization prompts based on output quality

**Rollback:** N/A — this phase is measurement, not structural change.

---

## 12. Constraint Traceability Matrix

Every design element linked to its constraint(s):

| Design Element | Constraints | Section |
|----------------|-------------|---------|
| Boot file composition | C-001, C-002, C-003, C-004 | §3 |
| CONTEXT.md auto-generation | C-005, C-022 | §3, §5.4 |
| MEMORY.md restructuring | C-002, C-003, C-020, AC-003, R-003 | §4 |
| Weekly summaries | C-006, C-009, C-013 | §5.1 |
| Monthly summaries | C-007, C-009, C-013 | §5.2 |
| Quarterly synthesis | C-008 | §5.3 |
| Cron scheduling | C-009 | §5.1, §5.2, §5.4 |
| Daily log immutability | C-010 | §6.4 |
| Search latency | C-011, A-002 | §7, §10 |
| Precision@3 | C-012, C-013, C-014 | §7 |
| Structured frontmatter | C-013 | §6 (all schemas) |
| Hybrid search | C-014, AC-005 | §7, §10 |
| Index freshness | C-015 | §10 |
| Lessons as entities | C-016 | §6.1, §8.1 |
| Project lifecycle | C-017 | §2 |
| People registry | C-018 | §6.2 |
| Decision log | C-019 | §6.3 |
| Sub-linear boot growth | C-020 | §4, §8.2, §9 |
| Corpus projections | C-021 | §10 |
| Context window adaptation | C-022 | §9 |
| Archive, never delete | C-023 | §2, §10 |
| Cross-session visibility | C-024 | §10 (indexing) |
| Graceful degradation | C-025 | §7 (layered retrieval) |
| Incremental migration | C-026 | §11 |

### Constraint Deltas (decisions NOT linked to a constraint)

| Delta | Decision | Rationale |
|-------|----------|-----------|
| CD-001 | CONTEXT.md as a separate root file (vs expanding MEMORY.md) | Separation of concerns: curated (MEMORY.md) vs generated (CONTEXT.md). Prevents auto-generation from touching the curated file. Aligns with AC-003. |
| CD-002 | Haiku for CONTEXT.md generation (vs Sonnet) | CONTEXT.md is a structured extraction task, not synthesis. Haiku is sufficient and cheaper. If quality is poor, upgrade to Sonnet. |
| CD-003 | Moving non-boot .md files out of workspace root | Required to control boot context size, but not explicitly constrained. Needed to satisfy C-002's 10% budget. |
| CD-004 | Immediate `qmd update` after memory-forge writes (vs waiting for 30-min cron) | Improves effective freshness for entity creation beyond C-015's 30-min requirement. Low cost, high value. |
| CD-005 | `memory/boot-size-log.json` for growth tracking | Operational telemetry not in constraints but required to verify C-020 over time. |

---

## 13. Self-Interrogation

### 1. What am I assuming that isn't in CONSTRAINTS.md?

- **OpenClaw workspace file injection is stable and consistent.** A-003 covers this, but I'm assuming the injection order doesn't matter and that all .md files at root are always injected. If OpenClaw ever adds selective injection, the architecture gets simpler (conditional CONTEXT.md tiers).
- **Sonnet can produce quality summaries from daily logs.** The quality of weekly summaries depends entirely on daily log quality (R-002) and Sonnet's ability to synthesize. If daily logs are thin or Sonnet hallucinates, summaries degrade.
- **MIKA will consistently add frontmatter to new files.** C-013 requires 95% coverage, but it's enforced by convention, not tooling. The summarization pipeline can validate, but won't fix missing frontmatter.
- **qmd's `--collection` flag is sufficient for archive isolation.** C-023 requires archived files to leave default search. I'm assuming collection-based filtering achieves this.

### 2. What would an adversarial reviewer challenge?

- **"CONTEXT.md will bloat just like MEMORY.md did."** Defense: CONTEXT.md is regenerated, not accumulated. It's overwritten each run. The generation prompt has a hard size target. The failure mode is poor content, not size growth.
- **"You're adding complexity (6 entity types, 3 cron jobs, 2 new skills) to a system that barely works today."** Defense: Each piece is independently useful. Lessons-as-files works even without summaries. Summaries work even without lessons-as-files. The complexity is modular, not monolithic. Migration is phased.
- **"Frontmatter discipline will erode (R-006)."** Partially valid. Mitigation: summarization pipeline validates frontmatter on input files and logs warnings. But there's no hard enforcement — it's a convention. A linting script (mentioned in R-006) should be built in Phase 2.
- **"You're not actually testing qmd at 5,000 docs."** Valid. Current corpus is 342 docs. C-011 and A-002 are untested assumptions. Phase 4 includes benchmarking, but it'll be at ~400-500 docs, not 5,000. Recommend a synthetic scaling test.

### 3. What failure mode am I not accounting for?

- **Cron job silent failure.** If the OpenClaw cron system fails silently (no error log, no retry), summaries stop generating and nobody notices for weeks. Mitigation: CONTEXT.md generation checks for missing summaries and flags gaps. But if CONTEXT.md generation also fails silently, there's no watchdog.
- **Prompt drift.** Summarization prompts are static files. If MIKA's daily log format evolves, the prompts may produce lower-quality output without obvious failure. Needs periodic human review.
- **qmd index corruption.** If the SQLite index corrupts, all search breaks. Mitigation: `qmd cleanup` exists, and the index can be rebuilt from source files. But the rebuild takes time and there's no automatic detection of corruption.

### 4. Which constraint am I closest to violating?

- **C-002 (boot ≤ 10% of context window).** Current root .md files total ~114 KB. At 200K window (~50K tokens), 114 KB (~28K tokens) is 56% of the window. This is WAY over budget. Phase 1 migration (moving non-boot files out of root) is critical. If that cleanup doesn't happen, the architecture violates C-002 on day one.
- **C-012 (precision@3 ≥ 0.80).** This is the hardest constraint. With 342 docs and no frontmatter filtering, precision is unknown. The architecture provides the mechanisms (frontmatter, hybrid search) but the actual precision depends on qmd's ranking quality, which is untested at this scale with this content.

### 5. What would Jerome say "that's not what I meant" about?

- **"Moving files out of workspace root."** Jerome might say: "I just want MEMORY.md to be better, not a file reorganization project." But the boot context budget (C-002) requires controlling what's at root. I'd explain: the root cleanup is necessary plumbing to make the important parts work.
- **"CONTEXT.md feels like another auto-generated thing that'll go stale."** Jerome explicitly rejected auto-generated MEMORY.md (AC-003). CONTEXT.md is different — it's ephemeral, regenerated, clearly labeled "do not edit," and supplements rather than replaces the curated MEMORY.md. But the distinction might feel academic if the output quality is poor.
- **"Four phases over 4 weeks seems slow."** Jerome might want this done in a weekend. The phasing is for safety (C-026), but if the risk tolerance is higher, phases 1-3 could compress to a week.

---

## 14. Appendix: Cron Job Summary

| Job | Schedule | Model | Input | Output | Constraint |
|-----|----------|-------|-------|--------|------------|
| generate-context | Daily 5 AM CST | Haiku | Daily logs, latest summary, entity counts | CONTEXT.md | C-005, C-022 |
| summarize-weekly | Sunday 3 AM CST | Sonnet | Week's daily logs | memory/summaries/YYYY-Www.md | C-006, C-009 |
| summarize-monthly | 1st of month 4 AM CST | Sonnet | Month's weekly summaries | memory/summaries/YYYY-MM.md | C-007, C-009 |
| qmd-reindex | Every 30 min | N/A (CLI) | All .md files | Updated index | C-015 |

---

*Architecture complete. Ready for Gate 2 review.*
