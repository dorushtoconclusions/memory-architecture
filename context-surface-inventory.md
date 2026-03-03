# Context Surface Inventory — WU-01
*Created: 2026-03-03 | PAIGE Pass 4*

## Boot-Critical (KEEP at root)
| File | Size | Role | Constraint |
|------|------|------|------------|
| SOUL.md | 1.2KB | Identity core | C-001, C-004 |
| IDENTITY.md | 0.4KB | Identity metadata | C-001, C-004 |
| USER.md | 2.1KB | Jerome relationship | C-001, C-004 |
| AGENTS.md | 7.9KB | Operational rules | C-003 |
| TOOLS.md | 2.0KB | Environment notes | C-003 |
| MEMORY.md | 12.2KB | Curated boot context | C-002, C-003 |
| HEARTBEAT.md | 0.3KB | Heartbeat instructions | C-003 |
| PIPELINE.md | 8.5KB | PAIGE pipeline ref | C-003 |
| WORKSPACE-POLICY.md | 4.8KB | Agent coordination | C-003 |
| CLAUDE.md | 1.7KB | Claude Code instructions | Operational |
| **Total KEEP** | **~41.1KB (~10.3K tokens)** | | |

## Move (NOT boot-critical)
| File | Size | Destination | Reason |
|------|------|-------------|--------|
| CONSTRAINTS.md | 24.1KB | projects/memory-rewrite/ (already there as v2) | Project artifact, stale v1 at root |
| CRANK-MASTER.md | 4.6KB | memory/archive/ | Historical planning doc |
| CRANK-PLAN.md | 2.0KB | memory/archive/ | Historical planning doc |
| MACHINE.md | 2.0KB | memory/archive/ | System inventory (static, rarely needed) |
| NETWORK_BASELINE.md | 2.2KB | memory/archive/ | Network baseline (static) |
| openclawRev.md | 33.0KB | memory/archive/ | Deep Research dump, reference only |
| openclaw_tui_rendering_findings.md | 4.9KB | memory/archive/ | TUI investigation notes |
| **Total MOVE** | **~72.8KB (~18.2K tokens)** | | |

## Impact
- **Before:** ~114KB (~28.5K tokens) — 14.25% of 200K window
- **After:** ~41.1KB (~10.3K tokens) — 5.15% of 200K window
- **Headroom reclaimed:** ~72.8KB for actual conversation

## Rollback
All moved files go to `memory/archive/` — recoverable via `mv` or `qmd search`.
No files deleted. Daily logs untouched (C-010).
