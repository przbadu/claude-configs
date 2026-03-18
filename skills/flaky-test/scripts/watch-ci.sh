#!/usr/bin/env bash
# Watch CI status for a PR until it passes or fails
# Usage: watch-ci.sh [PR_NUMBER] [MAX_MINUTES]
#
# Exits 0 if CI passes, 1 if CI fails, 2 if timeout

set -euo pipefail

PR_NUMBER="${1:-$(gh pr view --json number -q '.number' 2>/dev/null)}"
MAX_MINUTES="${2:-15}"
INTERVAL=60

if [ -z "$PR_NUMBER" ]; then
  echo "Error: No PR number provided and no PR found for current branch"
  exit 2
fi

echo "Watching CI for PR #${PR_NUMBER} (max ${MAX_MINUTES} minutes)..."

ELAPSED=0
while [ $ELAPSED -lt $((MAX_MINUTES * 60)) ]; do
  # Get check status
  CHECKS=$(gh pr checks "$PR_NUMBER" 2>&1) || true

  # Count statuses
  PASS=$(echo "$CHECKS" | grep -c "pass" || true)
  FAIL=$(echo "$CHECKS" | grep -c "fail" || true)
  PENDING=$(echo "$CHECKS" | grep -c "pending\|queued\|in_progress" || true)

  echo "[$(date +%H:%M:%S)] Pass: $PASS | Fail: $FAIL | Pending: $PENDING"

  if [ "$FAIL" -gt 0 ]; then
    echo "CI FAILED for PR #${PR_NUMBER}"
    echo ""
    echo "$CHECKS" | grep "fail"
    exit 1
  fi

  if [ "$PENDING" -eq 0 ] && [ "$PASS" -gt 0 ]; then
    echo "CI PASSED for PR #${PR_NUMBER}!"

    # Check total CI time
    RUN_ID=$(gh run list --branch "$(gh pr view "$PR_NUMBER" --json headRefName -q '.headRefName')" --limit 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)
    if [ -n "$RUN_ID" ]; then
      DURATION=$(gh run view "$RUN_ID" --json createdAt,updatedAt -q '"\((.updatedAt | fromdate) - (.createdAt | fromdate))"' 2>/dev/null || true)
      if [ -n "$DURATION" ]; then
        MINUTES=$((DURATION / 60))
        echo "Total CI time: ${MINUTES} minutes"
        if [ "$MINUTES" -gt 10 ]; then
          echo "WARNING: CI time exceeds 10-minute target"
        fi
      fi
    fi
    exit 0
  fi

  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo "TIMEOUT: CI did not complete within ${MAX_MINUTES} minutes"
exit 2
