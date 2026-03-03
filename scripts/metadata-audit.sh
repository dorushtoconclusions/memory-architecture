#!/bin/bash
# metadata-audit.sh — Check frontmatter coverage on entity files
# WU-08 artifact. Run periodically to ensure all entity files have proper YAML frontmatter.

WORKSPACE="/Users/mika/.openclaw/workspace"
PASS=0
FAIL=0
TOTAL=0

check_frontmatter() {
  local dir="$1"
  local required_field="$2"
  local label="$3"

  for f in "$dir"/*.md; do
    [ -f "$f" ] || continue
    TOTAL=$((TOTAL + 1))
    # Check for YAML frontmatter (starts with ---)
    if head -1 "$f" | grep -q "^---$"; then
      # Check for required field
      if head -20 "$f" | grep -q "^${required_field}:"; then
        PASS=$((PASS + 1))
      else
        echo "FAIL (missing $required_field): $f"
        FAIL=$((FAIL + 1))
      fi
    else
      echo "FAIL (no frontmatter): $f"
      FAIL=$((FAIL + 1))
    fi
  done
}

echo "=== Memory Entity Frontmatter Audit ==="
echo ""

echo "--- Lessons ---"
check_frontmatter "$WORKSPACE/memory/lessons" "type" "lessons"

echo "--- People ---"
check_frontmatter "$WORKSPACE/memory/people" "type" "people"

echo "--- Decisions ---"
check_frontmatter "$WORKSPACE/memory/decisions" "type" "decisions"

echo ""
echo "=== Results ==="
echo "Total: $TOTAL | Pass: $PASS | Fail: $FAIL"

if [ "$FAIL" -eq 0 ]; then
  echo "✅ All entity files have proper frontmatter"
  exit 0
else
  echo "❌ $FAIL file(s) missing frontmatter or required fields"
  exit 1
fi
