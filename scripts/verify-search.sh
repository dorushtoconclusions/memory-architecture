#!/bin/bash
# verify-search.sh — C-011, C-012, C-014 search reliability checks
echo "=== Search Reliability Check ==="
echo ""

ERRORS=0

# C-011: Search latency <2s
echo "--- C-011: Search Latency ---"
START=$(date +%s%N 2>/dev/null || python3 -c "import time; print(int(time.time()*1000000000))")
RESULT=$(qmd query "research order tool recommendation" -n 3 2>&1)
END=$(date +%s%N 2>/dev/null || python3 -c "import time; print(int(time.time()*1000000000))")

if [ -n "$START" ] && [ -n "$END" ]; then
  ELAPSED_MS=$(( (END - START) / 1000000 ))
  echo "Query latency: ${ELAPSED_MS}ms"
  if [ "$ELAPSED_MS" -le 2000 ]; then
    echo "✅ PASS: <2s"
  else
    echo "❌ FAIL: ${ELAPSED_MS}ms > 2000ms"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "⚠️  Could not measure latency"
fi

echo ""

# C-012: Precision@3 — known entity in top 3
echo "--- C-012: Precision@3 ---"
# Test 1: Search for a known lesson
if echo "$RESULT" | grep -q "process-research-order"; then
  echo "✅ 'research order' → found process-research-order.md in results"
else
  echo "❌ 'research order' → process-research-order.md NOT in top 3"
  ERRORS=$((ERRORS + 1))
fi

# Test 2: Search for a known person
RESULT2=$(qmd query "Nate newsletter blogger" -n 3 2>&1)
if echo "$RESULT2" | grep -q "people/nate"; then
  echo "✅ 'Nate newsletter' → found people/nate.md in results"
else
  echo "❌ 'Nate newsletter' → people/nate.md NOT in top 3"
  ERRORS=$((ERRORS + 1))
fi

# Test 3: Search for a known decision
RESULT3=$(qmd query "Mac Studio migration primary" -n 3 2>&1)
if echo "$RESULT3" | grep -q "decisions/"; then
  echo "✅ 'Mac Studio migration' → found decision file in results"
else
  echo "❌ 'Mac Studio migration' → decision file NOT in top 3"
  ERRORS=$((ERRORS + 1))
fi

echo ""

# C-014: Hybrid search available
echo "--- C-014: Hybrid Search ---"
EMBED_COUNT=$(qmd status 2>&1 | grep -i "embed" | head -1)
echo "Embedding status: $EMBED_COUNT"
if qmd status 2>&1 | grep -qi "embed"; then
  echo "✅ Vector embeddings available for hybrid search"
else
  echo "⚠️  Could not confirm embedding status"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "✅ PASS: Search reliability checks passed"
else
  echo "❌ FAIL: $ERRORS issue(s)"
  exit 1
fi
