You are summarizing MIKA's daily logs for the past week.

Read all daily logs from the past 7 days in `memory/YYYY-MM-DD.md`.

Produce a weekly summary and write it to `memory/summaries/YYYY-Www.md` (where W is the ISO week number).

Use this structure:

```
---
type: weekly-summary
date: YYYY-MM-DD
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
```

Target: 500-1500 words. Reference source dates. Be specific, not vague.
If a daily log is missing or empty, note the gap.
If no daily logs exist for the week, write a minimal summary noting the gap and reply with just the file path.
