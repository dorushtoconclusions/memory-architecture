---
type: decision
date: 2026-03-01
tags: [infrastructure, migration]
project: mac-studio-migration
people: [jerome]
status: pending
---

# Migrate OpenClaw from p920 to Mac Studio

**Decision:** Mac Studio (M1, 64GB) becomes primary OpenClaw host. p920 becomes secondary/fallback.

**Rationale:** Native Talk Mode, iMessage, Apple integrations. MLX inference local. Unified machine reduces operational complexity.

**Alternatives Considered:**
- Keep p920 as primary (rejected: no Apple integrations)
- Run both as co-primary (rejected: complexity without benefit)

**Outcome:** Pending — awaiting Jerome's go-ahead to wipe.

**Related:** MEMORY.md pending items
