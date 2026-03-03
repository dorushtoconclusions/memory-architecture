#!/bin/bash
# verify-boot-context.sh — C-002 boot context size check
WORKSPACE="/Users/mika/.openclaw/workspace"
TOTAL_CHARS=$(cat "$WORKSPACE"/*.md 2>/dev/null | wc -c | tr -d ' ')
TOTAL_TOKENS=$((TOTAL_CHARS / 4))
CONTEXT_WINDOW=200000
PCT=$((TOTAL_TOKENS * 100 / CONTEXT_WINDOW))
FILE_COUNT=$(ls "$WORKSPACE"/*.md 2>/dev/null | wc -l | tr -d ' ')

echo "=== C-002: Boot Context Size ==="
echo "Files at root: $FILE_COUNT"
echo "Boot context: ${TOTAL_CHARS} chars (~${TOTAL_TOKENS} tokens)"
echo "Context window: ${CONTEXT_WINDOW} tokens"
echo "Boot percentage: ${PCT}%"
echo ""

if [ "$PCT" -le 10 ]; then
  echo "✅ PASS: Boot context ≤ 10% of window"
else
  echo "❌ FAIL: Boot context is ${PCT}% of window (target ≤ 10%)"
  exit 1
fi
