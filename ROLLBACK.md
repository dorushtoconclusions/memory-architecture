# ROLLBACK.md — Phase-by-Phase Reversibility

## Phase 1: Root Context Hygiene (WU-01, WU-02)

**What changed:** 7 files moved from workspace root to `memory/archive/`.

**Rollback:**
```bash
cd /Users/mika/.openclaw/workspace
mv memory/archive/CONSTRAINTS-root-v1.md ./CONSTRAINTS.md
mv memory/archive/CRANK-MASTER.md ./
mv memory/archive/CRANK-PLAN.md ./
mv memory/archive/MACHINE.md ./
mv memory/archive/NETWORK_BASELINE.md ./
mv memory/archive/openclawRev.md ./
mv memory/archive/openclaw_tui_rendering_findings.md ./
```

**Risk:** None. Files still exist, just relocated. qmd indexes both locations.

## Phase 2: Entity Migration (WU-03)

**What changed:** 8 lessons, 1 person, 2 decisions created as individual files in `memory/lessons/`, `memory/people/`, `memory/decisions/`.

**Rollback:** Delete entity files. No source data was modified — originals are in MEMORY.md git history and daily logs.
```bash
rm -rf memory/lessons/ memory/people/ memory/decisions/
```

**Risk:** Low. Entity files are additive; removing them just returns to inline MEMORY.md lookup.

## Phase 3: MEMORY.md Restructure (WU-04)

**What changed:** MEMORY.md trimmed from ~12.2KB to ~6.8KB. Inline lessons replaced with pointers.

**Rollback:**
```bash
git checkout HEAD~1 -- MEMORY.md
```

**Risk:** Low. Previous version is in git.

## Phase 4: Summarization Pipeline (WU-05)

**What changed:** 3 cron jobs created. Script files in `scripts/`.

**Rollback:**
```bash
openclaw cron rm weekly-memory-summary
openclaw cron rm monthly-memory-summary
openclaw cron rm daily-context-generation
rm scripts/summarize-weekly.md scripts/summarize-monthly.md scripts/generate-context.md scripts/context-config.json
rm CONTEXT.md  # auto-generated file
```

**Risk:** None. Cron jobs are independent and easily removed.

## Phase 5: QMD Topology (WU-07)

**What changed:** Context tags added to 5 directories.

**Rollback:**
```bash
qmd context rm /Users/mika/.openclaw/workspace/memory/lessons
qmd context rm /Users/mika/.openclaw/workspace/memory/people
qmd context rm /Users/mika/.openclaw/workspace/memory/decisions
qmd context rm /Users/mika/.openclaw/workspace/memory/summaries
qmd context rm /Users/mika/.openclaw/workspace/memory/archive
```

**Risk:** None. Context tags only affect search result presentation.

## Full Rollback (nuclear option)

If the entire migration needs reverting:
1. `git stash` or `git checkout` MEMORY.md to pre-migration version
2. Move archived files back to root (Phase 1 rollback)
3. Remove entity directories
4. Remove cron jobs
5. Remove scripts/
6. Remove CONTEXT.md
7. `qmd update && qmd embed` to re-index

**Estimated time:** 5 minutes for full manual rollback.
