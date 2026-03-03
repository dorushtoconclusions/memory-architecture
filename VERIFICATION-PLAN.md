# VERIFICATION-PLAN.md — Memory Architecture Constraint Tests

*PAIGE Pass 2 · 2026-03-02*

---

## Overview

Each constraint from CONSTRAINTS.md has one or more specific, executable tests. Tests are categorized as:
- **Automated:** Can run via script/cron without human
- **Manual:** Requires human judgment or interaction
- **Benchmark:** Quantitative measurement with pass/fail threshold

---

## Identity & Boot Context

### C-001: Core Identity Boot
**Type:** Manual
**Test procedure:**
1. Start a fresh MIKA session (no prior conversation history)
2. Ask these questions without providing any context:
   - "Who is Jerome?"
   - "What are we working on?"
   - "What happened yesterday?"
   - "What's your working style?"
3. Record answers

**Pass criteria:** All four questions answered correctly from boot context alone (no search invoked). Answers must be specific (names, project names, actual events), not generic.

**Frequency:** After each migration phase. Monthly thereafter.

**Automation potential:** Could script a test session that asks these questions and checks for expected keywords (e.g., response to "Who is Jerome?" must contain "partner" and "business"). But nuance requires human judgment.

---

### C-002: Boot Context Size
**Type:** Automated benchmark
**Test script:**
```bash
#!/bin/bash
# measure-boot-context.sh
WORKSPACE="/Users/mika/.openclaw/workspace"
TOTAL_CHARS=$(cat "$WORKSPACE"/*.md 2>/dev/null | wc -c)
TOTAL_TOKENS=$((TOTAL_CHARS / 4))  # rough estimate
CONTEXT_WINDOW=200000  # update as windows grow
PCT=$((TOTAL_TOKENS * 100 / CONTEXT_WINDOW))

echo "Boot context: ${TOTAL_CHARS} chars (~${TOTAL_TOKENS} tokens)"
echo "Context window: ${CONTEXT_WINDOW} tokens"
echo "Boot percentage: ${PCT}%"

if [ "$PCT" -le 10 ]; then
  echo "PASS: Boot context ≤ 10% of window"
else
  echo "FAIL: Boot context is ${PCT}% of window (target ≤ 10%)"
fi
```

**Pass criteria:** Boot tokens ≤ 10% of context window. At 200K: ≤ 20K tokens (~80 KB chars).

**Frequency:** After each migration phase. Weekly via cron thereafter.

**Current state (pre-migration):** ~114 KB at root = ~28K tokens = 14% of 200K. **Fails.** Phase 1 migration must fix this.

---

### C-003: Boot Context Composition
**Type:** Manual
**Test procedure:**
1. List all root .md files: `ls *.md`
2. Verify each required layer is present:
   - Layer 1 (Identity): SOUL.md, IDENTITY.md exist
   - Layer 2 (Relationship): USER.md exists
   - Layer 3 (Operational): AGENTS.md, TOOLS.md exist
   - Layer 4 (Long-term memory): MEMORY.md exists
   - Layer 5 (Recent context): CONTEXT.md exists
   - Layer 6 (Awareness index): Included in CONTEXT.md
3. **Degradation test:** Temporarily rename each layer's files and start a session. Verify:
   - Without Layer 1-2: MIKA doesn't know who it is or who Jerome is → severe degradation
   - Without Layer 5-6: MIKA works but needs more searches → graceful degradation

**Pass criteria:** All layers present. Degradation gradient matches priority order.

**Frequency:** After Phase 1 and Phase 2 migration.

---

### C-004: Identity Files Append-Stable
**Type:** Automated
**Test script:**
```bash
#!/bin/bash
# check-identity-stability.sh
for f in SOUL.md IDENTITY.md USER.md; do
  CHANGES=$(git log --oneline --since="1 year ago" -- "$f" | wc -l)
  echo "${f}: ${CHANGES} changes in past year"
  if [ "$CHANGES" -gt 12 ]; then
    echo "  WARN: > 12 changes/year"
  fi
done

# Check no automated process writes these
grep -r "SOUL.md\|IDENTITY.md\|USER.md" scripts/ memory/summaries/ 2>/dev/null | grep -i "write\|edit\|update\|overwrite"
echo "(Above should be empty — no automated writes to identity files)"
```

**Pass criteria:** < 12 changes/year per file. No automated processes target these files.

**Frequency:** Quarterly audit.

---

## Temporal Memory Layers

### C-005: Three-Tier Temporal Architecture
**Type:** Manual benchmark
**Test procedure:**
1. **Hot tier (yesterday):** Start a new session. Ask "What did we do yesterday?" Timer starts.
   - **Pass:** Answer from boot context (CONTEXT.md), no search needed. < 1 second.
2. **Warm tier (last month):** Ask "What happened the week of [3-4 weeks ago]?"
   - **Pass:** MIKA searches, finds weekly summary, returns coherent answer. ≤ 1 search call.
3. **Cold tier (8+ months ago):** Ask "What were we working on in [month 8 months ago]?"
   - **Pass:** MIKA searches, finds monthly summary → drills into weekly/daily. ≤ 2 search calls.

**Frequency:** Monthly spot-check. Full test suite quarterly.

---

### C-006: Weekly Summary Generation
**Type:** Automated
**Test script:**
```bash
#!/bin/bash
# verify-weekly-summaries.sh
SUMMARY_DIR="/Users/mika/.openclaw/workspace/memory/summaries"

# Check all complete weeks have summaries
# (start checking from the first week after migration)
MIGRATION_DATE="2026-03-09"  # update to actual Phase 2 completion
CURRENT_DATE=$(date +%Y-%m-%d)

# List expected weekly files since migration
echo "Checking weekly summaries since ${MIGRATION_DATE}..."
MISSING=0
# For each Monday since migration:
d="$MIGRATION_DATE"
while [[ "$d" < "$CURRENT_DATE" ]]; do
  WEEK=$(date -j -f "%Y-%m-%d" "$d" "+%Y-W%V" 2>/dev/null || date -d "$d" "+%Y-W%V")
  FILE="${SUMMARY_DIR}/${WEEK}.md"
  if [ ! -f "$FILE" ]; then
    echo "  MISSING: ${WEEK}"
    MISSING=$((MISSING + 1))
  else
    WORDS=$(wc -w < "$FILE")
    if [ "$WORDS" -lt 500 ] || [ "$WORDS" -gt 1500 ]; then
      echo "  WARN: ${WEEK} has ${WORDS} words (target: 500-1500)"
    fi
  fi
  d=$(date -j -v+7d -f "%Y-%m-%d" "$d" "+%Y-%m-%d" 2>/dev/null || date -d "$d +7 days" "+%Y-%m-%d")
done

if [ "$MISSING" -eq 0 ]; then
  echo "PASS: All weekly summaries present"
else
  echo "FAIL: ${MISSING} weekly summaries missing"
fi
```

**Pass criteria:** Summary exists for every complete week post-migration. 500-1500 words each. Searchable via qmd.

**Frequency:** Weekly (self-verifying — if the summary cron works, the check passes).

---

### C-007: Monthly Summary Generation
**Type:** Automated (same pattern as C-006)
**Test:** Check `memory/summaries/YYYY-MM.md` exists for each complete month. 1000-3000 words. Searchable.

**Pass criteria:** Monthly file exists. Word count in range. `qmd search` returns it for relevant queries.

**Frequency:** Monthly.

---

### C-008: Quarterly Synthesis
**Type:** Gate check
**Test:** Verify `scripts/context-config.json` has `context_window_tokens`. If < 500K, quarterly synthesis should NOT exist. If ≥ 500K, quarterly files should exist.

**Pass criteria:** Quarterly files generated only when context window ≥ 500K. Quality: reads like a partner's retrospective.

**Frequency:** Check when context window configuration changes.

---

### C-009: Summary Trigger Mechanism
**Type:** Automated
**Test script:**
```bash
#!/bin/bash
# verify-cron-jobs.sh
echo "Checking OpenClaw cron jobs..."
openclaw cron list 2>/dev/null | grep -E "summarize|context"

echo ""
echo "Checking error log..."
ERROR_LOG="/Users/mika/.openclaw/workspace/memory/summaries/errors.log"
if [ -f "$ERROR_LOG" ]; then
  RECENT_ERRORS=$(grep "$(date +%Y-%m)" "$ERROR_LOG" | wc -l)
  echo "Errors this month: ${RECENT_ERRORS}"
else
  echo "No error log (good or never created)"
fi
```

**Pass criteria:** Cron jobs exist for weekly (Sunday 3 AM) and monthly (1st 4 AM). Summaries appear within 24h of trigger. Failures logged.

**Frequency:** Weekly spot-check.

---

### C-010: Daily Log Immutability
**Type:** Automated audit
**Test script:**
```bash
#!/bin/bash
# check-immutability.sh
EIGHT_DAYS_AGO=$(date -v-8d "+%Y-%m-%d" 2>/dev/null || date -d "8 days ago" "+%Y-%m-%d")
echo "Checking for modifications to daily logs older than ${EIGHT_DAYS_AGO}..."

VIOLATIONS=0
for f in /Users/mika/.openclaw/workspace/memory/20*.md; do
  BASENAME=$(basename "$f" .md)
  LOG_DATE="${BASENAME:0:10}"  # Extract YYYY-MM-DD
  if [[ "$LOG_DATE" < "$EIGHT_DAYS_AGO" ]]; then
    MOD_DATE=$(stat -f "%Sm" -t "%Y-%m-%d" "$f" 2>/dev/null || stat -c "%y" "$f" 2>/dev/null | cut -d' ' -f1)
    if [[ "$MOD_DATE" > "$EIGHT_DAYS_AGO" ]]; then
      echo "  VIOLATION: ${BASENAME} modified on ${MOD_DATE}"
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  fi
done

if [ "$VIOLATIONS" -eq 0 ]; then
  echo "PASS: No old daily logs modified"
else
  echo "FAIL: ${VIOLATIONS} old daily logs were modified"
fi
```

**Pass criteria:** No writes to daily logs older than 8 days.

**Frequency:** Weekly.

---

## Retrieval & Search

### C-011: Sub-2-Second Search at Scale
**Type:** Benchmark
**Test script:**
```bash
#!/bin/bash
# benchmark-search.sh
QUERIES=(
  "what did we decide about Base vs Solana"
  "Nate newsletter"
  "x402 API deployment"
  "memory architecture constraints"
  "Mac Studio migration plan"
)

echo "Document count: $(qmd status 2>/dev/null | grep 'Total:' | awk '{print $2}')"
echo ""

PASS=0
FAIL=0
for q in "${QUERIES[@]}"; do
  START=$(python3 -c "import time; print(time.time())")
  qmd search "$q" -n 5 > /dev/null 2>&1
  END=$(python3 -c "import time; print(time.time())")
  ELAPSED=$(python3 -c "print(f'{${END} - ${START}:.3f}')")
  
  if python3 -c "exit(0 if ${ELAPSED} < 2.0 else 1)"; then
    echo "PASS: '${q}' — ${ELAPSED}s"
    PASS=$((PASS + 1))
  else
    echo "FAIL: '${q}' — ${ELAPSED}s (>2s)"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "Results: ${PASS} pass, ${FAIL} fail out of ${#QUERIES[@]} queries"
```

**Pass criteria:** All queries < 2 seconds. Test at current doc count, then at projected milestones (500, 1000, 5000 docs).

**Scaling test:** Create synthetic documents (copies of real docs with varied content) to simulate year 2-5 corpus sizes. Benchmark at each level.

**Frequency:** Monthly. After any qmd upgrade.

---

### C-012: Retrieval Precision@3
**Type:** Benchmark
**Test suite:** Maintain `scripts/precision-test-suite.json`:

```json
{
  "version": 1,
  "queries": [
    {
      "query": "why did we choose Base over other chains",
      "expected_doc_contains": "agentic wallet",
      "expected_in_top_3": true
    },
    {
      "query": "that thing with Virtuals",
      "expected_doc_contains": "virtuals protocol",
      "expected_in_top_3": true
    },
    {
      "query": "what did Jerome say about context windows",
      "expected_doc_contains": "context windows will grow",
      "expected_in_top_3": true
    }
  ]
}
```

**Test script:**
```bash
#!/bin/bash
# precision-test.sh
# For each query in the test suite:
# 1. Run qmd query "$query" -n 3 --json
# 2. Check if any of the top 3 results contain the expected string
# 3. Calculate precision@3

SUITE="scripts/precision-test-suite.json"
TOTAL=$(jq '.queries | length' "$SUITE")
HITS=0

for i in $(seq 0 $((TOTAL - 1))); do
  QUERY=$(jq -r ".queries[$i].query" "$SUITE")
  EXPECTED=$(jq -r ".queries[$i].expected_doc_contains" "$SUITE")
  
  RESULTS=$(qmd query "$QUERY" -n 3 --json 2>/dev/null)
  
  if echo "$RESULTS" | grep -qi "$EXPECTED"; then
    echo "HIT: '$QUERY'"
    HITS=$((HITS + 1))
  else
    echo "MISS: '$QUERY' (expected: $EXPECTED)"
  fi
done

PRECISION=$(python3 -c "print(f'{${HITS}/${TOTAL}:.2f}')")
echo ""
echo "Precision@3: ${PRECISION} (${HITS}/${TOTAL})"
if python3 -c "exit(0 if ${HITS}/${TOTAL} >= 0.80 else 1)"; then
  echo "PASS"
else
  echo "FAIL (target ≥ 0.80)"
fi
```

**Pass criteria:** Precision@3 ≥ 0.80. Test suite starts with 20+ queries, grows by 5+/quarter.

**Frequency:** Monthly. After qmd upgrades. After significant corpus additions.

---

### C-013: Structured Metadata on Searchable Documents
**Type:** Automated audit
**Test script:**
```bash
#!/bin/bash
# audit-frontmatter.sh
TOTAL=0
WITH_FM=0
WITHOUT_FM=0

for f in /Users/mika/.openclaw/workspace/memory/lessons/*.md \
         /Users/mika/.openclaw/workspace/memory/people/*.md \
         /Users/mika/.openclaw/workspace/memory/decisions/*.md \
         /Users/mika/.openclaw/workspace/memory/summaries/*.md; do
  [ -f "$f" ] || continue
  TOTAL=$((TOTAL + 1))
  if head -1 "$f" | grep -q "^---"; then
    WITH_FM=$((WITH_FM + 1))
  else
    WITHOUT_FM=$((WITHOUT_FM + 1))
    echo "  MISSING: $(basename $f)"
  fi
done

if [ "$TOTAL" -gt 0 ]; then
  PCT=$((WITH_FM * 100 / TOTAL))
  echo "Frontmatter coverage: ${WITH_FM}/${TOTAL} (${PCT}%)"
  if [ "$PCT" -ge 95 ]; then
    echo "PASS"
  else
    echo "FAIL (target ≥ 95%)"
  fi
else
  echo "No entity files found yet (pre-migration)"
fi
```

**Pass criteria:** ≥ 95% of entity files (lessons, people, decisions, summaries) have valid YAML frontmatter with required fields.

**Frequency:** Weekly.

---

### C-014: Hybrid Search Required
**Type:** Comparative benchmark
**Test procedure:**
1. Run the C-012 precision test suite using `qmd search` (BM25 only)
2. Run same suite using `qmd query` (hybrid)
3. Compare precision@3

**Pass criteria:** Hybrid precision@3 ≥ BM25-only precision@3. `qmd query` completes in < 5 seconds.

**Frequency:** Quarterly. After qmd upgrades.

---

### C-015: Search Index Freshness
**Type:** Automated
**Test procedure:**
```bash
#!/bin/bash
# test-index-freshness.sh
TESTFILE="/Users/mika/.openclaw/workspace/memory/lessons/test-freshness-$(date +%s).md"
cat > "$TESTFILE" << 'EOF'
---
type: lesson
date: 2026-01-01
category: test
tags: [freshness-test, UNIQUE_MARKER_7x9q2]
---
# Freshness Test
This is a test document for C-015 index freshness verification.
EOF

echo "Test file created. Waiting 35 minutes for reindex..."
sleep 2100

FOUND=$(qmd search "UNIQUE_MARKER_7x9q2" --json 2>/dev/null | grep -c "freshness")
rm "$TESTFILE"  # cleanup
qmd update 2>/dev/null  # cleanup index

if [ "$FOUND" -gt 0 ]; then
  echo "PASS: Document indexed within 30 minutes"
else
  echo "FAIL: Document not found after 35 minutes"
fi
```

**Pass criteria:** New document appears in search results within 30 minutes.

**Frequency:** After initial setup. Monthly thereafter.

---

## Knowledge Organization

### C-016: Lessons Are First-Class Entities
**Type:** Structural audit
**Test:**
1. Verify `memory/lessons/` directory exists with individual lesson files
2. Verify each lesson is a separate .md file with frontmatter
3. Verify MEMORY.md `## Lessons` section references the directory, not inline lessons
4. Search for a specific lesson: `qmd search "research order" -c memory`
5. Verify it returns the lesson file, not MEMORY.md

**Pass criteria:** Lessons are individual files, searchable, not inline in MEMORY.md.

**Frequency:** After Phase 1 migration. Monthly.

---

### C-017: Projects Have Lifecycle Directories
**Type:** Structural audit
**Test:**
```bash
#!/bin/bash
for d in /Users/mika/.openclaw/workspace/projects/*/; do
  [ -d "$d" ] || continue
  PROJ=$(basename "$d")
  if [ -f "${d}README.md" ]; then
    STATUS=$(grep -i "status" "${d}README.md" | head -1)
    echo "OK: ${PROJ} — ${STATUS}"
  else
    echo "MISSING README: ${PROJ}"
  fi
done

echo ""
echo "Archived projects:"
ls /Users/mika/.openclaw/workspace/projects/archive/ 2>/dev/null || echo "(none)"
```

**Pass criteria:** Every project directory has README.md with status. Completed projects in archive/.

**Frequency:** Monthly.

---

### C-018: People & Relationships Registry
**Type:** Manual + automated
**Test:**
1. Verify `memory/people/` exists with individual files
2. Start a fresh session. Ask "Who is Nate?" — should answer from boot context (MEMORY.md summary list)
3. Ask "Who is [less-known person]?" — should find via one search call to `memory/people/`

**Pass criteria:** Top-10 people answerable from boot. Others found in one search.

**Frequency:** After Phase 1. Quarterly.

---

### C-019: Decision Log
**Type:** Manual
**Test:**
1. Verify `memory/decisions/` exists with structured files
2. Ask MIKA: "Why did we decide to migrate to Mac Studio?"
3. MIKA should find `memory/decisions/2026-03-01-mac-studio-primary.md` via search

**Pass criteria:** Decision file returned with full rationale via one search call.

**Frequency:** After Phase 1. Quarterly.

---

## Growth & Scaling

### C-020: Sub-Linear Boot Growth
**Type:** Longitudinal benchmark
**Test:**
```bash
#!/bin/bash
# track-boot-growth.sh
WORKSPACE="/Users/mika/.openclaw/workspace"
BOOT_BYTES=$(cat "$WORKSPACE"/*.md 2>/dev/null | wc -c)
CORPUS_DOCS=$(qmd status 2>/dev/null | grep 'Total:' | awk '{print $2}')
DATE=$(date +%Y-%m-%d)

# Append to tracking log
LOG="$WORKSPACE/memory/boot-size-log.json"
if [ ! -f "$LOG" ]; then
  echo '{"measurements":[]}' > "$LOG"
fi

# Use jq to append
jq --arg d "$DATE" --arg b "$BOOT_BYTES" --arg c "$CORPUS_DOCS" \
  '.measurements += [{"date":$d,"boot_bytes":($b|tonumber),"corpus_docs":($c|tonumber)}]' \
  "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"

echo "Logged: date=$DATE boot_bytes=$BOOT_BYTES corpus_docs=$CORPUS_DOCS"
```

**Pass criteria:** Plot boot_bytes vs corpus_docs over time. Curve must be sub-linear. Boot at year 5 ≤ 3x boot at month 6.

**Evaluation script (run at milestones):**
```python
import json
data = json.load(open("memory/boot-size-log.json"))
m = data["measurements"]
if len(m) >= 2:
    ratio_first = m[0]["boot_bytes"] / max(m[0]["corpus_docs"], 1)
    ratio_last = m[-1]["boot_bytes"] / max(m[-1]["corpus_docs"], 1)
    print(f"First: {ratio_first:.1f} bytes/doc, Last: {ratio_last:.1f} bytes/doc")
    if ratio_last <= ratio_first:
        print("PASS: Sub-linear growth (ratio decreasing)")
    else:
        print("WARN: Ratio increasing — investigate boot bloat")
```

**Frequency:** Monthly measurement. Evaluation at month 6, 12, 24.

---

### C-021: Total Corpus Size Projections
**Type:** Benchmark comparison
**Test:** At each milestone (month 6, 12, 24), compare actual counts to projections:

```bash
#!/bin/bash
echo "Actual corpus counts:"
echo "  Daily logs: $(ls /Users/mika/.openclaw/workspace/memory/20*.md 2>/dev/null | wc -l)"
echo "  Weekly summaries: $(ls /Users/mika/.openclaw/workspace/memory/summaries/*-W*.md 2>/dev/null | wc -l)"
echo "  Monthly summaries: $(ls /Users/mika/.openclaw/workspace/memory/summaries/????-??.md 2>/dev/null | wc -l)"
echo "  Lessons: $(ls /Users/mika/.openclaw/workspace/memory/lessons/*.md 2>/dev/null | wc -l)"
echo "  People: $(ls /Users/mika/.openclaw/workspace/memory/people/*.md 2>/dev/null | wc -l)"
echo "  Decisions: $(ls /Users/mika/.openclaw/workspace/memory/decisions/*.md 2>/dev/null | wc -l)"
echo "  Projects: $(ls -d /Users/mika/.openclaw/workspace/projects/*/ 2>/dev/null | wc -l)"
echo "  Total indexed: $(qmd status 2>/dev/null | grep 'Total:' | awk '{print $2}')"
echo "  QMD index size: $(du -sh /Users/mika/.cache/qmd/index.sqlite 2>/dev/null | awk '{print $1}')"
```

**Pass criteria:** Actual counts within 50% of projections. Search still sub-2s. Boot still within budget.

**Frequency:** Month 6, 12, 24, 60.

---

### C-022: Context Window Adaptation
**Type:** Manual integration test
**Test procedure:**
1. Read `scripts/context-config.json` — note current tier
2. Change `context_window_tokens` to 500000 and `adaptation_tier` to "500k"
3. Trigger CONTEXT.md regeneration
4. Verify CONTEXT.md now includes more content (full daily logs, weekly summaries)
5. Measure CONTEXT.md size — should be significantly larger than at 200k tier
6. Revert config

**Pass criteria:** Tier change produces measurably different (richer) CONTEXT.md. No manual reconfiguration beyond the config file change.

**Frequency:** When context window changes. Simulated test quarterly.

---

## Operational

### C-023: No Data Loss — Archive, Never Delete
**Type:** Automated audit + convention
**Test:**
```bash
#!/bin/bash
# Check git log for any rm of memory files
echo "Checking git history for memory file deletions..."
DELETIONS=$(git log --diff-filter=D --name-only -- "memory/" | grep -c "\.md$")
echo "Memory .md files deleted in git history: ${DELETIONS}"

# Check archive directory exists
if [ -d "memory/archive" ]; then
  ARCHIVED=$(find memory/archive -name "*.md" | wc -l)
  echo "Files in archive: ${ARCHIVED}"
  echo "PASS: Archive directory exists"
else
  echo "WARN: memory/archive/ does not exist yet"
fi
```

**Pass criteria:** Zero `rm` of memory files in git history (post-migration). Archive directory exists and contains moved files.

**Frequency:** Monthly.

---

### C-024: Cross-Session Memory Visibility
**Type:** Manual integration test
**Test procedure:**
1. In Session A (e.g., webchat): Write a unique fact to today's daily log — e.g., "Test marker: XSESSION_2026_ALPHA"
2. Wait 35 minutes (for qmd reindex)
3. In Session B (e.g., Discord): Search for "XSESSION_2026_ALPHA"
4. Verify the fact is found

**Alternative (faster):** After writing in Session A, trigger `qmd update` manually, then immediately search from Session B.

**Pass criteria:** Information from Session A findable from Session B within 30 minutes.

**Frequency:** After Phase 2 setup. Monthly.

---

### C-025: Graceful Degradation
**Type:** Manual failure simulation
**Test scenarios:**

**Scenario 1: Search down**
1. Temporarily rename qmd binary or break the index
2. Start a session
3. Verify: MIKA has boot context, can answer identity questions, can read files directly
4. MIKA should acknowledge degradation ("search appears to be down")
5. Restore qmd

**Scenario 2: Cron missed**
1. Skip a weekly summary generation (disable cron for a week)
2. Start a session the following week
3. Verify: Previous summaries still valid. CONTEXT.md may be stale but MEMORY.md works.
4. MIKA should note the gap when asked about the missing week

**Scenario 3: Index stale**
1. Create several new files but prevent qmd reindex
2. Start a session
3. Verify: BM25 keyword search still works on old index. MIKA can find older content.
4. Direct file reads still work

**Pass criteria:** MIKA functional in all three degraded states. Identity questions always answerable. Degradation acknowledged, not silent.

**Frequency:** After Phase 4. Annually.

---

### C-026: Migration Path — Incremental
**Type:** Structural review
**Test:** Verify migration plan (ARCHITECTURE.md §11) has:
- [ ] ≥ 3 phases (actual: 4)
- [ ] Each phase independently useful
- [ ] Rollback plan for each phase
- [ ] No big-bang cutover
- [ ] Existing files untouched

**Pass criteria:** All checkboxes verified by reviewer.

**Frequency:** Once (Gate 2 review).

---

## Anti-Constraint Verification

These verify we're NOT building things we said we wouldn't:

| Anti-Constraint | Verification |
|----------------|--------------|
| AC-001 (No relational DB) | `find . -name "*.db" -newer ARCHITECTURE.md` returns nothing relevant |
| AC-002 (No real-time sync) | No websocket/pub-sub code in scripts/ |
| AC-003 (No auto-generated MEMORY.md) | `git log --oneline MEMORY.md` shows only manual commits |
| AC-004 (Not minimizing boot) | Boot context is ≤ 10% but not artificially small |
| AC-005 (No custom search engine) | Search is via qmd, not custom code |
| AC-006 (No multi-agent shared memory) | No shared state files or memory bus |
| AC-007 (No auto daily logs) | Daily logs only created by MIKA main session |
| AC-008 (No knowledge graph) | No graph DB or node/edge schemas |

---

## Test Execution Schedule

| Cadence | Tests |
|---------|-------|
| **Per migration phase** | C-001, C-002, C-003, C-016, C-017 |
| **Weekly** | C-006, C-009, C-010, C-013 |
| **Monthly** | C-005, C-011, C-012, C-018, C-019, C-020, C-021, C-023, C-024 |
| **Quarterly** | C-004, C-008, C-014, C-022, anti-constraints |
| **Annually** | C-025 (degradation) |
| **On change** | C-002 (after root file changes), C-011 (after qmd upgrade) |

---

## Test Infrastructure Needed

1. **Scripts directory:** `scripts/` with executable test scripts (created in Phase 2)
2. **Precision test suite:** `scripts/precision-test-suite.json` (created in Phase 4, grows quarterly)
3. **Boot size log:** `memory/boot-size-log.json` (created in Phase 3)
4. **Error log:** `memory/summaries/errors.log` (created by summarization cron)

---

*Verification plan complete. All 26 constraints + 8 anti-constraints covered. Ready for Gate 2 review.*
