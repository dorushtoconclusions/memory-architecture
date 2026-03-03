# Migration Rollup — Decision Log & Rollback Notes
*Created: 2026-03-03 | PAIGE Pass 4*

## Phase 1: Root Context Hygiene (WU-01 + WU-02)
### Decisions
- D-001: Root CONSTRAINTS.md is v1; projects/memory-rewrite/CONSTRAINTS.md is v2. Safe to archive root copy.
- D-002: CRANK-* files are historical planning from early partnership. Archive, don't delete.
- D-003: openclawRev.md (33KB Deep Research) is reference material. Archive for search, not boot.
- D-004: MACHINE.md and NETWORK_BASELINE.md are static snapshots. Archive for retrieval.
- D-005: PIPELINE.md stays at root — referenced frequently during active builds.
- D-006: WORKSPACE-POLICY.md stays at root — needed by dispatched agents.
- D-007: CLAUDE.md stays at root — Claude Code reads it on session start.

### Rollback
```bash
# To reverse Phase 1 file moves:
cd /Users/mika/.openclaw/workspace
mv memory/archive/CONSTRAINTS-root-v1.md ./CONSTRAINTS.md
mv memory/archive/CRANK-MASTER.md ./
mv memory/archive/CRANK-PLAN.md ./
mv memory/archive/MACHINE.md ./
mv memory/archive/NETWORK_BASELINE.md ./
mv memory/archive/openclawRev.md ./
mv memory/archive/openclaw_tui_rendering_findings.md ./
```

## Phase 2: Entity Migration (WU-03)
- Pending

## Phase 3: Restructure + Pipelines (WU-04, WU-05, WU-06)
- Pending

## Phase 4: Search + Skills + Verification (WU-07, WU-08, WU-09, WU-10)
- Pending
