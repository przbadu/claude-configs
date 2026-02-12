#!/usr/bin/env bash
# Fetch open bugs from GitHub with the "Bug" label
# Usage: fetch_bugs.sh <owner/repo> [--limit N]
#
# Outputs JSON array of issues with key fields for scoring.
# Requires: gh CLI authenticated

set -euo pipefail

REPO="${1:?Usage: fetch_bugs.sh <owner/repo> [--limit N]}"
LIMIT="${2:-100}"

gh issue list \
  --repo "$REPO" \
  --label "Bug" \
  --state open \
  --limit "$LIMIT" \
  --json number,title,body,labels,createdAt,updatedAt,comments,assignees,url \
  --jq '
    [.[] | {
      number,
      title,
      body: (.body // "" | .[0:2000]),
      labels: [.labels[].name],
      created_at: .createdAt,
      updated_at: .updatedAt,
      comment_count: (.comments | length),
      assignees: [.assignees[].login],
      url,
      age_days: (((now - (.createdAt | fromdateiso8601)) / 86400) | floor)
    }]
  '
