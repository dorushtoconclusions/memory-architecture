# PRESSURE TEST — Memory Architecture v2

*MIKA self-review, 2026-03-02*

---

## What's Strong

1. **CONTEXT.md as separate auto-generated file** — Cleanest solution I've seen for the "inject recent context without touching curated files" problem. Regenerated daily, never accumulates, exploits existing OpenClaw injection. No core changes needed.

2. **Temporal summarization pipeline** — Daily → Weekly → Monthly is the right cadence. Cron-driven, not heartbeat-dependent. Failure handling with retry and flagging in CONTEXT.md is practical.

3. **Entity files with frontmatter** — Individual files for lessons, people, decisions means the corpus is granular and searchable. Frontmatter enables filtered search which is critical for precision@3 at scale.

4. **Incremental migration** — Four phases, each independently useful with rollback. No big-bang. Existing files untouched. This is how you do it.

5. **Self-interrogation is honest** — Correctly identifies C-002 violation on day one (114KB root .md files) and C-012 (precision@3) as untested. Good.

---

## Pressure Points

### P1: Root .md File Cleanup Is Load-Bearing

The architecture DEPENDS on moving non-boot .md files out of workspace root (Phase 1, step 6). Without this, boot context is 114KB (~28K tokens) which is 56% of a 200K window. But some of those files might be needed — PIPELINE.md is referenced during builds, CRANK-MASTER.md during cranks.

**Risk:** Moving files breaks references or workflows that depend on them being at root.
**Mitigation:** Need an audit of which root .md files are referenced by other processes/skills before moving them. Don't just move everything.

### P2: Frontmatter Discipline Is Convention, Not Enforcement

C-013 requires 95% frontmatter coverage, but there's no linter, no pre-commit hook, no automated validation. memory-forge adds frontmatter when it creates files, but manually created daily logs? I'll forget sometimes.

**Risk:** R-006 is real. Frontmatter coverage erodes → search precision degrades → "bulletproof recall" fails silently.
**Mitigation:** Build a simple linting script in Phase 2 that runs during qmd reindex. Flag files missing frontmatter in CONTEXT.md generation.

### P3: Summarization Quality Is Unproven

The entire temporal layer depends on Sonnet producing good summaries. "Good" means: captures key decisions, not just events. Preserves rationale, not just outcomes. Identifies patterns across days, not just lists bullets.

**Risk:** Garbage summaries at the weekly level propagate to monthly level (garbage in, garbage out up the chain).
**Mitigation:** First 4 weekly summaries get manual review. Summarization prompts are iterable — stored as files in scripts/, not hardcoded. But there's no automated quality check.

### P4: The 5,000-Doc Benchmark Is Hypothetical

C-011 requires sub-2s search at 5,000 docs. Current corpus is 342. We're projecting qmd on Mac Studio M1 handles this fine, but we've never tested it. The architecture assumes A-002 holds.

**Risk:** At year 2-3, search latency degrades and the whole retrieval cascade slows down.
**Mitigation:** Phase 4 includes benchmarking, but should include a synthetic scaling test — generate 5,000 dummy docs and benchmark.

### P5: CONTEXT.md Could Become a Crutch

If CONTEXT.md becomes too good, I might stop searching deeper tiers. If it's too sparse, it doesn't help. The quality depends on the Haiku generation prompt, which is a single point of fragility.

**Risk:** Over-reliance on auto-generated context, under-utilization of search.
**Mitigation:** CONTEXT.md explicitly includes "Knowledge Index" section that reminds me what EXISTS to search, not just what happened recently. This is the awareness bridge.

### P6: No Watchdog for Silent Cron Failure

Self-interrogation correctly identifies this. If cron fails silently, summaries stop and nobody notices. CONTEXT.md generation checks for missing summaries, but if CONTEXT.md generation also fails, there's no outer watchdog.

**Mitigation:** Heartbeat checks should verify CONTEXT.md freshness (is it <24h old?). Add to HEARTBEAT.md.

### P7: Migration Timeline May Need Compression

4 weeks across 4 phases is conservative. Phase 1 (structure) and Phase 2 (summarization) could run in parallel since they're independent. Phase 3 (skill updates) depends on both. Realistic timeline: 2 weeks if we push, 3-4 if we're careful.

Jerome may want this faster. The architecture supports compression — phases are independent enough.

---

## Verdict

Architecture passes Gate 2. The design is sound, the migration is safe, and the hard problems (retrieval precision, summarization quality) are correctly identified as Phase 4 validation work rather than hand-waved away.

**Top 3 actions before Pass 3 (Build Plan):**
1. Audit root .md files — which ones actually need to be at root?
2. Build a frontmatter linter script into Phase 2
3. Add synthetic scaling test to Phase 4

**Recommendation:** Proceed to Pass 3.
