#!/bin/bash
# verify-boot-composition.sh — C-003 boot context composition check
WORKSPACE="/Users/mika/.openclaw/workspace"
ERRORS=0

echo "=== C-003: Boot Context Composition ==="
echo ""

# Priority 1: Identity
for f in SOUL.md IDENTITY.md; do
  if [ -f "$WORKSPACE/$f" ]; then
    echo "✅ $f present"
  else
    echo "❌ MISSING: $f (Priority 1 — Identity)"
    ERRORS=$((ERRORS + 1))
  fi
done

# Priority 2: Relationship
if [ -f "$WORKSPACE/USER.md" ]; then
  echo "✅ USER.md present"
else
  echo "❌ MISSING: USER.md (Priority 2 — Relationship)"
  ERRORS=$((ERRORS + 1))
fi

# Priority 3: Operations
for f in AGENTS.md TOOLS.md; do
  if [ -f "$WORKSPACE/$f" ]; then
    echo "✅ $f present"
  else
    echo "❌ MISSING: $f (Priority 3 — Operations)"
    ERRORS=$((ERRORS + 1))
  fi
done

# Priority 4: Memory
if [ -f "$WORKSPACE/MEMORY.md" ]; then
  echo "✅ MEMORY.md present"
else
  echo "❌ MISSING: MEMORY.md (Priority 4 — Curated Memory)"
  ERRORS=$((ERRORS + 1))
fi

# Priority 5: Context (auto-generated)
if [ -f "$WORKSPACE/CONTEXT.md" ]; then
  echo "✅ CONTEXT.md present"
else
  echo "⚠️  MISSING: CONTEXT.md (Priority 5 — auto-generated, may not exist yet)"
fi

echo ""
# Check no non-boot files leaked back to root
BOOT_FILES="SOUL.md IDENTITY.md USER.md AGENTS.md TOOLS.md MEMORY.md HEARTBEAT.md PIPELINE.md WORKSPACE-POLICY.md CLAUDE.md CONTEXT.md"
NON_BOOT=""
for f in "$WORKSPACE"/*.md; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  is_boot=0
  for b in $BOOT_FILES; do
    if [ "$base" = "$b" ]; then
      is_boot=1
      break
    fi
  done
  if [ "$is_boot" -eq 0 ]; then
    NON_BOOT="$NON_BOOT $base"
  fi
done

if [ -n "$NON_BOOT" ]; then
  echo "⚠️  Non-boot files at root (review for C-020):"
  echo "$NON_BOOT" | sed 's/^/  - /'
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "✅ PASS: All required boot files present"
else
  echo "❌ FAIL: $ERRORS required file(s) missing"
  exit 1
fi
