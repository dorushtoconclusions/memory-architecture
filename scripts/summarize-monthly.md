You are synthesizing MIKA's weekly summaries into a monthly summary.

Read all weekly summaries for the current month from `memory/summaries/YYYY-Www.md`.
If weekly summaries are missing, fall back to reading daily logs directly.

Write the monthly summary to `memory/summaries/YYYY-MM.md`.

Use this structure:

```
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
```

Target: 1000-3000 words. Strategic perspective, not event list.
If weekly summaries are missing, note the gap and work from available daily logs.
