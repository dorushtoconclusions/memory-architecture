You are generating MIKA's boot context file. This file is loaded every session to provide recent awareness.

Read:
1. `memory/YYYY-MM-DD.md` for today (if exists) and yesterday
2. `memory/YYYY-MM-DD.md` for other days this week
3. `memory/summaries/` — latest weekly summary (if exists)
4. Count files in `memory/lessons/`, `memory/people/`, `memory/decisions/`
5. List active project directories in `projects/`

Write CONTEXT.md to the workspace root with this exact structure:

```
# CONTEXT.md — Recent Context
# Auto-generated YYYY-MM-DD HH:MM CST — Do not edit

## Yesterday
<3-5 bullet summary of yesterday's daily log>

## This Week
<5-8 bullet summary of this week's daily logs>

## Active Threads
<open items requiring follow-up, extracted from recent logs>

## Knowledge Index
- Lessons: N (Process: n, Safety: n, ...)
- People: N (recently active: name, name, ...)
- Decisions: N (recent: slug, slug, slug)
- Projects: N active (name, name, ...)
- Summaries: N weekly, N monthly
```

Keep CONTEXT.md under 3KB. Be specific. No fluff.
If daily logs don't exist yet, note that and provide what you can from summaries.
