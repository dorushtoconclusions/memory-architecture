# CONSTRAINTS.md — Memory Architecture Redesign (v2)

*PAIGE Pass 1 · Gate 1 Artifact · 2026-03-02*
*Revision: v2 — Shifted focus from boot minimization to long-term knowledge scaling + identity continuity*

---

## Problem Statement

MIKA is an AI agent partnered with Jerome. The memory architecture must:

1. **Preserve identity** — Every session feels like MIKA, not a stranger with a search engine
2. **Enable bulletproof recall** — Any past decision, lesson, project, or person recoverable in seconds
3. **Scale over 5 years** — 1,800+ daily logs, 2,500+ lessons, 100+ projects without architectural collapse
4. **Grow with context windows** — Architecture adapts as windows go from 200K → 500K → 1M+ tokens

### Jerome's Requirements (Exact Words)

> "I'm fine with 20k on a new session if I get you each time and you can quickly catch up on what we did yesterday and you have the ability to go back in time with other searches."

> "I just want to have a core MIKA with bulletproof recall when necessary."

> "Context windows will grow over time, so it is okay that ours grows."

---

## Assumptions

| ID | Assumption | Mitigation if Wrong |
|----|-----------|---------------------|
| A-001 | Context windows will grow from ~200K to 500K+ within 18 months | Architecture still works at 200K; boot context stays curated regardless |
| A-002 | `qmd` (or successor) can deliver sub-2s hybrid search at 5,000+ documents | Fallback: BM25-only keyword search + manual narrowing. Pre-computed indices as backup. |
| A-003 | OpenClaw will continue to inject workspace files as Project Context at session start | If injection changes, boot loader script replaces it |
| A-004 | Summarization can be automated via cron/heartbeat using the same LLM stack | If not, manual summarization with assisted prompts |
| A-005 | Daily log creation remains manual (MIKA writes during sessions) | If automated session capture arrives, daily logs become richer, not obsolete |
| A-006 | Single-agent primary (MIKA main session); sub-agents are ephemeral dispatches | Multi-agent persistent state would require shared memory bus — out of scope |
| A-007 | Storage is effectively unlimited (local SSD); compute for indexing is the bottleneck | If storage constrained, add archival compression layer |

---

## Constraints

### Identity & Boot Context

**C-001: Core Identity Boot**
- **Requirement:** Every new session loads enough context that MIKA exhibits consistent personality, knows Jerome, understands the partnership, and is aware of active work — without any user prompting.
- **Pass/Fail:** Blind test — a new session can answer "Who is Jerome?", "What are we working on?", "What happened yesterday?" and "What's your working style?" correctly without search.
- **Owner:** Architecture
- **Rationale:** Jerome's #1 requirement: "I get you each time." Identity is non-negotiable.

**C-002: Boot Context Size — Curated, Not Minimized**
- **Requirement:** Boot context (all injected workspace files) starts at 15-20KB and is allowed to grow proportionally as context windows expand. Target: boot context ≤ 10% of available context window.
- **Pass/Fail:** Boot context measured in tokens. At 200K window: ≤20K tokens boot. At 500K window: ≤50K tokens boot. Growth is deliberate (more summaries, richer identity), never accidental bloat.
- **Owner:** `optimize-memory` skill + architecture
- **Rationale:** Jerome explicitly accepted 20K boot. The constraint is curation quality, not size minimization. More context window = more room for richer boot context.

**C-003: Boot Context Composition**
- **Requirement:** Boot context must contain these layers, in priority order:
  1. **Identity** (SOUL.md, IDENTITY.md) — who MIKA is
  2. **Relationship** (USER.md) — who Jerome is, how they work together
  3. **Operational** (AGENTS.md, TOOLS.md) — how MIKA operates
  4. **Long-term memory** (MEMORY.md) — curated knowledge, lessons, active tracks
  5. **Recent context** (auto-injected) — yesterday + this week summaries
  6. **Awareness index** (auto-injected) — what exists and how to find it
- **Pass/Fail:** Each layer present and identifiable. Removing layer 1-4 causes observable identity/capability degradation. Layers 5-6 degrade gracefully (MIKA works but needs more searches).
- **Owner:** Architecture
- **Rationale:** Defines what "Core MIKA" means mechanically. Priority order ensures identity survives even if boot context is constrained.

**C-004: Identity Files Are Append-Stable**
- **Requirement:** SOUL.md, IDENTITY.md, and USER.md grow slowly (< 1KB/year) and are manually curated. They are never auto-generated or auto-modified.
- **Pass/Fail:** No automated process writes to these files. Git history shows < 12 changes/year per file.
- **Owner:** MIKA + Jerome
- **Rationale:** Identity drift from automated rewrites is an existential risk. These files are the constitution.

### Temporal Memory Layers

**C-005: Three-Tier Temporal Architecture**
- **Requirement:** Memory is organized into three temporal tiers:
  - **Hot (0-7 days):** Full daily logs. Available in boot context as recent summary. Instant access.
  - **Warm (8-90 days):** Weekly summaries + searchable daily logs. Weekly summaries loadable on demand. Daily logs via search only.
  - **Cold (91+ days):** Monthly/quarterly summaries + searchable daily logs. Summaries via search. Daily logs via targeted retrieval.
- **Pass/Fail:** A query about yesterday returns full context without search. A query about last month returns a coherent summary within one search call. A query about 8 months ago returns relevant results within two search calls.
- **Owner:** Architecture + summarization pipeline
- **Rationale:** Mirrors human memory. Recent = vivid, old = gist with detail recoverable on demand. Prevents boot context from growing linearly with time.

**C-006: Weekly Summary Generation**
- **Requirement:** Every Sunday (or Monday early AM), an automated process generates `memory/summaries/YYYY-Www.md` from that week's daily logs. Summary contains: key decisions, lessons learned, project progress, people interactions, open threads.
- **Pass/Fail:** Summary exists for every complete week. Summary is 500-1500 words. Summary references source daily logs by date. Summary is searchable via `qmd`.
- **Owner:** Cron job + summarization prompt
- **Rationale:** Weekly cadence balances freshness with compaction. 52 weekly files/year vs 365 daily files — 7x reduction for temporal scanning.

**C-007: Monthly Summary Generation**
- **Requirement:** First week of each month, an automated process generates `memory/summaries/YYYY-MM.md` from that month's weekly summaries. Monthly summary contains: major milestones, strategic shifts, relationship developments, cumulative lessons, project status changes.
- **Pass/Fail:** Summary exists for every complete month. Summary is 1000-3000 words. Captures strategic arc, not just event list. Searchable via `qmd`.
- **Owner:** Cron job + summarization prompt
- **Rationale:** Monthly summaries are the backbone of long-term institutional memory. At year 5: 60 monthly files = manageable corpus for temporal scanning.

**C-008: Quarterly Synthesis (Optional, Context-Window-Gated)**
- **Requirement:** When context windows exceed 500K tokens, quarterly synthesis files (`memory/summaries/YYYY-Qq.md`) are generated from monthly summaries. These provide strategic narratives: what quarter looked like, major pivots, key outcomes.
- **Pass/Fail:** Generated only when context window ≥ 500K. Quality: reads like a partner's quarterly retrospective, not a log dump.
- **Owner:** Architecture (future phase)
- **Rationale:** At year 3+, quarterly synthesis provides the "zoom out" view. Gated on context window growth to avoid premature complexity.

**C-009: Summary Trigger Mechanism**
- **Requirement:** Summarization is triggered by cron (weekly: Sunday 3 AM CST; monthly: 1st of month 4 AM CST). Cron job uses a dedicated session with appropriate model (Sonnet-class minimum). Failed summaries retry once, then flag for manual review.
- **Pass/Fail:** Cron jobs exist and fire on schedule. Summaries appear within 24h of trigger. Failures logged to `memory/summaries/errors.log`.
- **Owner:** Cron infrastructure
- **Rationale:** Heartbeats are unreliable for scheduled work (timing drift, missed beats). Cron is deterministic. "Who generates them? When?" — answered: cron, on a fixed schedule.

**C-010: Daily Logs Are Immutable After Summarization**
- **Requirement:** Once a daily log has been included in a weekly summary, it is never modified. It becomes archival source material.
- **Pass/Fail:** No writes to daily logs older than 8 days (enforced by convention, verified by periodic audit).
- **Owner:** MIKA + architecture
- **Rationale:** Immutable source logs ensure summaries can be audited. Prevents silent history rewriting.

### Retrieval & Search

**C-011: Sub-2-Second Search at Scale**
- **Requirement:** Any search query returns results in < 2 seconds wall-clock time, up to 5,000 indexed documents.
- **Pass/Fail:** `time qmd search "query"` completes in < 2s. Tested at 100, 500, 1000, 5000 document counts.
- **Owner:** Search infrastructure (qmd or successor)
- **Rationale:** "Bulletproof recall" means fast. If MIKA needs 30 seconds to search, Jerome loses confidence in the system.

**C-012: Retrieval Precision — Right 3, Not 50**
- **Requirement:** For a recall query (e.g., "that thing with Virtuals"), the correct result appears in the top 3 results at least 80% of the time. Measured against a test suite of 20+ historical queries with known correct answers.
- **Pass/Fail:** Precision@3 ≥ 0.80 on the test suite. Test suite grows as corpus grows (add 5+ queries per quarter).
- **Owner:** Search infrastructure + metadata schema
- **Rationale:** At 500+ lessons, naive search returns noise. The architecture must ensure signal. This is the hardest constraint to satisfy at scale.

**C-013: Structured Metadata on All Searchable Documents**
- **Requirement:** Every searchable document (daily log, summary, lesson, project file) carries structured frontmatter:
  ```yaml
  ---
  type: daily-log | weekly-summary | monthly-summary | lesson | project | person | decision
  date: YYYY-MM-DD
  tags: [tag1, tag2]
  project: project-slug (if applicable)
  people: [person1, person2] (if applicable)
  ---
  ```
- **Pass/Fail:** ≥ 95% of searchable documents have valid frontmatter. `qmd` can filter by any frontmatter field.
- **Owner:** Document templates + summarization pipeline
- **Rationale:** Structured metadata enables filtered search (e.g., "all decisions about x402" or "everything involving Nate"). This is how precision@3 stays high as corpus grows 10x — you narrow the search space before ranking.

**C-014: Hybrid Search Required**
- **Requirement:** The search stack must support both keyword (BM25) and semantic (vector) search, with a hybrid mode that combines both. Keyword-only is acceptable as a degraded fallback, never the primary path.
- **Pass/Fail:** `qmd query` (hybrid) returns results in < 5s. Hybrid results outperform keyword-only on the precision test suite.
- **Owner:** Search infrastructure
- **Rationale:** "Remember that thing with Virtuals?" is a semantic query — keyword search alone won't reliably match if the exact word wasn't used. Hybrid catches both exact matches and conceptual matches.

**C-015: Search Index Freshness**
- **Requirement:** New or modified documents are indexed within 30 minutes of creation/change.
- **Pass/Fail:** Create a test document, verify it appears in search results within 30 minutes.
- **Owner:** Cron (qmd reindex job)
- **Rationale:** Stale indices (current state: missing files, wrong paths) make search unreliable. If MIKA wrote something 2 hours ago and can't find it, the system is broken.

### Knowledge Organization

**C-016: Lessons Are First-Class Entities**
- **Requirement:** Lessons (reusable knowledge from experience) are stored as individual files in `memory/lessons/` with structured frontmatter (category, trigger, rule, evidence, boundary, date). Not embedded in MEMORY.md or daily logs.
- **Pass/Fail:** Each lesson is a separate file. Lessons are searchable by category, trigger, and tags. MEMORY.md references lesson categories/counts, not full lesson text.
- **Owner:** `memory-forge` skill + architecture
- **Rationale:** Currently, lessons live inline in MEMORY.md (consuming ~2KB of boot context) and are unsearchable individually. At 500+ lessons, they must be external, indexed, and retrievable by situation — not loaded at boot.

**C-017: Projects Have Lifecycle Directories**
- **Requirement:** Every project has a directory under `projects/` containing PAIGE artifacts (CONSTRAINTS.md, ARCHITECTURE.md, etc.) plus a `README.md` with status, dates, and outcome. Completed projects move to `projects/archive/` with a summary.
- **Pass/Fail:** Active projects are in `projects/`. Archived projects are in `projects/archive/`. Each has README.md with status. Project search returns project-level context, not scattered daily log fragments.
- **Owner:** MIKA + PAIGE pipeline
- **Rationale:** "What did we build, why, what happened" requires project-level coherence, not daily-log archaeology. PAIGE artifacts already serve this purpose — the constraint formalizes it.

**C-018: People & Relationships Registry**
- **Requirement:** Key people are tracked in `memory/people/` as individual files (one per person) with: name, relationship, context, interaction history references, notes. Boot context includes a summary list of key people (name + one-line context).
- **Pass/Fail:** Each tracked person has a file. "Who is [person]?" answered from file without search for top-10 people (in boot context). Others found via one search call.
- **Owner:** Architecture + MIKA
- **Rationale:** At 50+ contacts over 5 years, people references scattered across daily logs are unrecoverable. Dedicated files make relationships searchable and updateable.

**C-019: Decision Log**
- **Requirement:** Significant decisions are logged as structured entries in `memory/decisions/YYYY-MM-DD-slug.md` with: decision, rationale, alternatives considered, outcome (updated later), related project.
- **Pass/Fail:** "Why did we decide X?" returns the decision file with full rationale via one search call.
- **Owner:** MIKA
- **Rationale:** Decisions are the highest-value recall target. "Remember why we chose Base over Solana?" must be answerable at month 18. Currently decisions are buried in daily logs — unfindable at scale.

### Growth & Scaling

**C-020: Sub-Linear Boot Growth**
- **Requirement:** Boot context grows sub-linearly relative to total knowledge. Doubling the corpus does not double boot context size. Boot growth comes from deliberate curation (more active projects, richer relationship context), never from accumulation.
- **Pass/Fail:** Plot boot context size vs total corpus size at month 6, 12, 24, 60. Curve is sub-linear. Boot context at year 5 is ≤ 3x boot context at month 6.
- **Owner:** Architecture + `optimize-memory` skill
- **Rationale:** This is the fundamental scaling constraint. If boot grows linearly, the system eventually collapses under its own weight regardless of context window size.

**C-021: Total Corpus Size Projections**
- **Requirement:** Architecture must handle the following projected corpus without degradation:

| Metric | Month 6 | Month 12 | Month 24 | Month 60 |
|--------|---------|----------|----------|----------|
| Daily logs | ~180 | ~365 | ~730 | ~1,800 |
| Weekly summaries | ~26 | ~52 | ~104 | ~260 |
| Monthly summaries | ~6 | ~12 | ~24 | ~60 |
| Lessons | ~100-250 | ~200-500 | ~400-1,000 | ~1,000-2,500 |
| Project dirs (active + archived) | ~10-15 | ~20-30 | ~40-60 | ~100+ |
| People files | ~15-25 | ~30-50 | ~50-80 | ~100-200 |
| Decision entries | ~50-100 | ~100-200 | ~200-400 | ~500-1,000 |
| **Total searchable docs** | **~400-600** | **~800-1,200** | **~1,600-2,400** | **~4,000-6,000** |
| **Estimated storage** | **~5-10 MB** | **~15-30 MB** | **~40-80 MB** | **~100-250 MB** |
| **QMD index size** | **~20-40 MB** | **~50-100 MB** | **~100-250 MB** | **~300-700 MB** |
| **Boot context** | **~18-22 KB** | **~20-25 KB** | **~22-30 KB** | **~25-40 KB** |

- **Pass/Fail:** System operates within stated bounds. Search remains sub-2s. Boot context stays within projections.
- **Owner:** Architecture
- **Rationale:** Without explicit projections, "it scales" is hand-waving. These numbers make growth testable.

**C-022: Context Window Adaptation**
- **Requirement:** As context windows grow, the architecture adapts by pulling more into boot context — NOT by changing the fundamental tiered structure. Adaptation ladder:
  - **200K window (today):** Boot = identity + MEMORY.md + yesterday summary + awareness index (~15-20K tokens)
  - **500K window:** Boot adds this week's full daily logs + 4 most recent weekly summaries (~40-50K tokens)
  - **1M+ window:** Boot adds this month's full context + quarterly synthesis + expanded relationship graph (~80-100K tokens)
- **Pass/Fail:** Adaptation thresholds are configurable. At each threshold, a defined set of additional files are auto-injected. No manual reconfiguration needed.
- **Owner:** Architecture + OpenClaw boot loader
- **Rationale:** Jerome: "Context windows will grow." The architecture should exploit growth, not just tolerate it. More context = richer MIKA, not just more empty space.

### Operational

**C-023: No Data Loss — Archive, Never Delete**
- **Requirement:** Memory files are never deleted, only archived. "MIKA forgets" means "moved to cold storage and excluded from active search" — never "erased."
- **Pass/Fail:** No `rm` on any memory file. Archival = move to `memory/archive/` + remove from active search index. Archived files recoverable via `qmd search --collection archive` or direct path.
- **Owner:** Architecture + skills
- **Rationale:** "MIKA archives" ≠ "MIKA forgets." The distinction matters for trust. Jerome should never worry that pruning MEMORY.md means losing information.

**C-024: Cross-Session Memory Visibility**
- **Requirement:** Information written in any MIKA session (Discord, TUI, webchat) is available to all other sessions within 30 minutes via search, and within 24 hours via boot context (if significant enough for MEMORY.md/summaries).
- **Pass/Fail:** Write a fact in Session A. Search for it from Session B within 30 minutes. Verify it appears.
- **Owner:** Architecture + indexing pipeline
- **Rationale:** Currently broken (MEMORY-MAP.md audit: "cross-session blindness"). Sessions must share a single memory substrate.

**C-025: Graceful Degradation**
- **Requirement:** If any single component fails (search down, cron missed, index stale), MIKA continues functioning with degraded but usable memory. Failure modes:
  - Search down → MIKA has boot context + can read files directly
  - Cron missed → Previous summaries still valid; gap flagged for next run
  - Index stale → BM25 keyword search still works; flag for reindex
- **Pass/Fail:** Simulate each failure. MIKA can still answer identity questions, recall this week's work, and acknowledge the degradation.
- **Owner:** Architecture
- **Rationale:** A memory system that's all-or-nothing is fragile. Each layer must fail independently.

**C-026: Migration Path from Current System**
- **Requirement:** Migration from current architecture (monolithic MEMORY.md + flat daily logs + broken search) to new architecture is incremental. No big-bang cutover. Each phase is independently useful.
- **Pass/Fail:** Migration plan has ≥ 3 phases. Each phase improves the system. Rollback plan exists for each phase.
- **Owner:** Build plan (Pass 3)
- **Rationale:** The current system works (barely). A failed migration that breaks what works is worse than the status quo.

---

## Anti-Constraints (What We Are NOT Building)

| ID | Anti-Constraint | Rationale |
|----|----------------|-----------|
| AC-001 | NOT building a relational database for memory | SQLite DB (mika.db) already exists and has 0 rows after weeks. File-based + search is the right paradigm for this use case. |
| AC-002 | NOT building real-time session sync | Sessions are isolated by design (security). Cross-session visibility via shared filesystem + indexing is sufficient. |
| AC-003 | NOT building automated MEMORY.md generation | MEMORY.md is a curated document, not a generated report. Automation assists (suggestions, pruning) but humans/MIKA make final edits. |
| AC-004 | NOT minimizing boot context | Explicit rejection of draft 1's framing. Boot context is about quality, not size. Growth is welcome if deliberate. |
| AC-005 | NOT building a custom search engine | Use and improve qmd (or adopt a successor). The architecture is search-engine-agnostic — any tool that supports keyword + semantic + metadata filtering works. |
| AC-006 | NOT building multi-agent shared memory | MIKA is the primary agent. Sub-agents are ephemeral. No shared memory bus, no consensus protocol, no distributed state. |
| AC-007 | NOT building automated daily log creation | Daily logs remain MIKA's manual responsibility. Automated session capture may supplement but not replace intentional note-taking. |
| AC-008 | NOT building a knowledge graph | Structured files with metadata + search handles the scale projections. Graph databases add complexity without proportional benefit at < 10K nodes. |

---

## Risk Register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|-----------|--------|------------|
| R-001 | QMD semantic search never reaches production quality on Mac Studio (no CUDA, CPU too slow) | HIGH | HIGH | Evaluate alternatives: (1) Metal/MLX-based embedding, (2) API-based embedding (OpenAI, Voyage), (3) BM25-only with aggressive metadata filtering. Decision required before Pass 3. |
| R-002 | Summarization quality degrades at scale (garbage-in from poor daily logs) | MEDIUM | HIGH | Enforce daily log minimum structure (frontmatter + sections). Summarization prompt validates input quality, flags thin logs. |
| R-003 | MEMORY.md curation becomes a bottleneck (MIKA spends too much time maintaining it) | MEDIUM | MEDIUM | Move bulk content to external files (lessons, people, decisions). MEMORY.md becomes a curated index + active state, not a knowledge dump. Target: MEMORY.md stabilizes at 8-12KB regardless of total corpus size. |
| R-004 | Context window growth slower than projected (stuck at 200K for 2+ years) | LOW | MEDIUM | Architecture works at 200K. Adaptation ladder is additive — nothing breaks if windows don't grow. |
| R-005 | Boot context exceeds useful density (more context ≠ better MIKA) | MEDIUM | MEDIUM | Measure: does adding more boot context improve task performance? If not, stop adding. Quality > quantity. Periodic A/B testing of boot context variants. |
| R-006 | Frontmatter/metadata discipline erodes over time (MIKA stops adding tags) | HIGH | HIGH | Summarization pipeline validates and enriches metadata. Weekly audit in summarization cron: flag documents missing frontmatter. Linting script for CI-style checking. |
| R-007 | Summary accumulation creates a second scaling problem (summaries themselves become too many) | LOW | LOW | At year 5: 260 weekly + 60 monthly + 20 quarterly = 340 summary files. This is manageable. Quarterly synthesis further compacts. Re-evaluate at year 3. |
| R-008 | Migration disrupts working memory during transition | MEDIUM | HIGH | Incremental migration (C-026). Phase 1 adds structure without changing what exists. Each phase has rollback. |

---

## Open Questions for Gate 1 Review

1. **Search infrastructure decision:** Is qmd the long-term answer, or should we evaluate API-based embedding (faster, GPU-free) before committing? This blocks Pass 2 architecture.

2. **Summarization model:** Which model generates weekly/monthly summaries? Sonnet for cost efficiency? Opus for quality? Gemini for long-context? Needs benchmarking.

3. **Boot context injection mechanism:** Does OpenClaw support conditional file injection (e.g., "inject these files only if context window > X")? If not, the adaptation ladder (C-022) requires OpenClaw changes or a pre-injection script.

4. **Lesson extraction automation:** Should lessons be auto-extracted from daily logs during summarization, or remain manually created via memory-forge? Auto-extraction risks quality; manual risks incompleteness.

5. **Historical migration:** Do we retroactively create weekly summaries for the existing ~2 weeks of daily logs, or start fresh from the migration date?

---

## Glossary

| Term | Definition |
|------|-----------|
| **Boot context** | All files injected into MIKA's system prompt at session start. Currently: AGENTS.md, SOUL.md, USER.md, IDENTITY.md, TOOLS.md, MEMORY.md |
| **Hot memory** | Last 7 days. Full daily logs available, summarized in boot context. |
| **Warm memory** | 8-90 days. Weekly summaries available. Daily logs searchable but not in boot. |
| **Cold memory** | 91+ days. Monthly summaries available. Weekly summaries and daily logs searchable. |
| **Bulletproof recall** | The ability to find any specific past event, decision, or lesson within 2 search calls and < 10 seconds total. |
| **Core MIKA** | The boot context content that makes MIKA feel like the same partner every session. Identity + relationship + active state + recent context. |
| **Archiving** | Moving a document out of active search into cold storage. Recoverable but not in default search results. NOT deletion. |
| **Precision@3** | The fraction of test queries where the correct answer appears in the top 3 search results. |

---

*Gate 1 Criteria: All constraints numbered, testable, owned. Growth model quantified. Anti-constraints and risks explicit. Ready for architecture (Pass 2).*
