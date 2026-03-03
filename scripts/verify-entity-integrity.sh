#!/bin/bash
# verify-entity-integrity.sh — C-013, C-016, C-018, C-019 entity file checks
WORKSPACE="/Users/mika/.openclaw/workspace"
ERRORS=0

echo "=== Entity Integrity Check ==="
echo ""

# Check directories exist
for dir in lessons people decisions summaries archive; do
  if [ -d "$WORKSPACE/memory/$dir" ]; then
    count=$(ls "$WORKSPACE/memory/$dir"/*.md 2>/dev/null | wc -l | tr -d ' ')
    echo "✅ memory/$dir/ exists ($count files)"
  else
    echo "❌ MISSING: memory/$dir/"
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""

# Frontmatter audit
bash "$WORKSPACE/scripts/metadata-audit.sh"
AUDIT_RESULT=$?
if [ "$AUDIT_RESULT" -ne 0 ]; then
  ERRORS=$((ERRORS + 1))
fi

echo ""

# Check MEMORY.md has pointer (not inline lessons)
if grep -q "memory/lessons/" "$WORKSPACE/MEMORY.md" 2>/dev/null; then
  echo "✅ MEMORY.md references memory/lessons/ (pointer, not inline)"
else
  echo "❌ MEMORY.md may still have inline lessons (check manually)"
  ERRORS=$((ERRORS + 1))
fi

# Check daily log immutability (C-010) — logs >8 days old should not be modified
echo ""
echo "--- Daily Log Immutability (C-010) ---"
STALE_EDITS=0
CUTOFF=$(date -v-8d +%Y-%m-%d 2>/dev/null || date -d "8 days ago" +%Y-%m-%d 2>/dev/null)
if [ -n "$CUTOFF" ]; then
  for f in "$WORKSPACE"/memory/202[0-9]-[0-9][0-9]-[0-9][0-9].md; do
    [ -f "$f" ] || continue
    logdate=$(basename "$f" .md)
    if [[ "$logdate" < "$CUTOFF" ]]; then
      # Check if modified after creation (rough: compare mtime vs filename date)
      mtime=$(stat -f %Sm -t %Y-%m-%d "$f" 2>/dev/null || stat -c %y "$f" 2>/dev/null | cut -d' ' -f1)
      if [[ "$mtime" > "$CUTOFF" ]]; then
        echo "⚠️  $logdate was modified on $mtime (>8 days old)"
        STALE_EDITS=$((STALE_EDITS + 1))
      fi
    fi
  done
  if [ "$STALE_EDITS" -eq 0 ]; then
    echo "✅ No stale daily log edits detected"
  fi
else
  echo "⚠️  Could not determine cutoff date"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "✅ PASS: Entity integrity checks passed"
else
  echo "❌ FAIL: $ERRORS issue(s) found"
  exit 1
fi
