#!/usr/bin/env bash
# fetch-data.sh
# Gathers cross-project status data for the COO Agent.
# Pulls open PRs, open issues, stale branches, milestones, and recent activity
# for every repo listed in consumers.json.
#
# Requires: gh CLI (authenticated via GH_TOKEN), jq
# Output: /tmp/coo-agent-data.json

set -euo pipefail

OUTPUT="/tmp/coo-agent-data.json"
TODAY=$(date -u +%Y-%m-%d)
SEVEN_DAYS_AGO=$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-7d +%Y-%m-%dT%H:%M:%SZ)

echo "=== COO Agent: Fetching Project Status ==="
echo "Date: $TODAY"
echo "Looking back to: $SEVEN_DAYS_AGO"

# --- Load repo list from consumers.json ---
if [ ! -f "consumers.json" ]; then
  echo "ERROR: consumers.json not found"
  exit 1
fi

REPOS=$(jq -r '.[].repo' consumers.json)
REPO_COUNT=$(echo "$REPOS" | grep -c . || echo 0)
echo "Monitoring $REPO_COUNT repos"

# --- Read previous state ---
if [ -f "state.json" ]; then
  PREVIOUS_STATE=$(cat state.json)
  LAST_RUN=$(echo "$PREVIOUS_STATE" | jq -r '.last_run // "never"')
  echo "Last run: $LAST_RUN"
else
  PREVIOUS_STATE='{"last_run": null, "snapshot": {}}'
  echo "No previous state — first run."
fi

# --- Collect per-repo data ---
REPO_DATA="[]"

while IFS= read -r repo; do
  [ -z "$repo" ] && continue
  echo ""
  echo "--- $repo ---"

  # Open PRs
  echo "  Fetching open PRs..."
  OPEN_PRS=$(gh pr list --repo "$repo" --state open --json number,title,createdAt,updatedAt,author,isDraft,headRefName --limit 50 2>/dev/null || echo '[]')
  OPEN_PR_COUNT=$(echo "$OPEN_PRS" | jq 'length')
  echo "  Open PRs: $OPEN_PR_COUNT"

  # Recently merged PRs (last 7 days)
  echo "  Fetching merged PRs..."
  MERGED_PRS=$(gh pr list --repo "$repo" --state merged --json number,title,mergedAt,author --limit 20 2>/dev/null || echo '[]')
  MERGED_PRS=$(echo "$MERGED_PRS" | jq --arg since "$SEVEN_DAYS_AGO" '[.[] | select(.mergedAt >= $since)]')
  MERGED_PR_COUNT=$(echo "$MERGED_PRS" | jq 'length')
  echo "  Merged PRs (7d): $MERGED_PR_COUNT"

  # Open issues
  echo "  Fetching open issues..."
  OPEN_ISSUES=$(gh issue list --repo "$repo" --state open --json number,title,createdAt,updatedAt,labels,assignees --limit 50 2>/dev/null || echo '[]')
  OPEN_ISSUE_COUNT=$(echo "$OPEN_ISSUES" | jq 'length')
  echo "  Open issues: $OPEN_ISSUE_COUNT"

  # Recent commits on default branch
  echo "  Fetching recent commits..."
  RECENT_COMMITS=$(gh api "repos/$repo/commits?since=$SEVEN_DAYS_AGO&per_page=30" --jq '[.[] | {sha: .sha[0:7], message: .commit.message, date: .commit.author.date, author: .commit.author.name}]' 2>/dev/null || echo '[]')
  COMMIT_COUNT=$(echo "$RECENT_COMMITS" | jq 'length')
  echo "  Commits (7d): $COMMIT_COUNT"

  # Last commit date on default branch
  LAST_COMMIT_DATE=$(gh api "repos/$repo/commits?per_page=1" --jq '.[0].commit.author.date' 2>/dev/null || echo "unknown")
  echo "  Last commit: $LAST_COMMIT_DATE"

  # Milestones
  echo "  Fetching milestones..."
  MILESTONES=$(gh api "repos/$repo/milestones?state=open&per_page=20" --jq '[.[] | {number: .number, title: .title, due_on: .due_on, open_issues: .open_issues, closed_issues: .closed_issues}]' 2>/dev/null || echo '[]')
  MILESTONE_COUNT=$(echo "$MILESTONES" | jq 'length')
  echo "  Open milestones: $MILESTONE_COUNT"

  # Branches with no recent activity
  echo "  Fetching branches..."
  BRANCHES=$(gh api "repos/$repo/branches?per_page=50" --jq '[.[] | .name]' 2>/dev/null || echo '[]')
  BRANCH_COUNT=$(echo "$BRANCHES" | jq 'length')
  echo "  Branches: $BRANCH_COUNT"

  # CI status on default branch
  echo "  Checking CI status..."
  DEFAULT_BRANCH=$(gh api "repos/$repo" --jq '.default_branch' 2>/dev/null || echo "main")
  CI_STATUS=$(gh api "repos/$repo/commits/$DEFAULT_BRANCH/check-runs?per_page=5" --jq '{total: .total_count, latest: [.check_runs[:5][] | {name: .name, status: .status, conclusion: .conclusion}]}' 2>/dev/null || echo '{"total": 0, "latest": []}')
  # Validate CI_STATUS is valid JSON; fallback if garbled
  if ! echo "$CI_STATUS" | jq empty 2>/dev/null; then
    CI_STATUS='{"total": 0, "latest": []}'
  fi
  echo "  CI checks: $(echo "$CI_STATUS" | jq '.total')"

  # Compose repo entry
  REPO_DATA=$(echo "$REPO_DATA" | jq \
    --arg repo "$repo" \
    --argjson open_prs "$OPEN_PRS" \
    --argjson merged_prs "$MERGED_PRS" \
    --argjson open_issues "$OPEN_ISSUES" \
    --argjson recent_commits "$RECENT_COMMITS" \
    --arg last_commit "$LAST_COMMIT_DATE" \
    --argjson milestones "$MILESTONES" \
    --argjson branches "$BRANCHES" \
    --argjson ci_status "$CI_STATUS" \
    '. + [{
      repo: $repo,
      open_prs: $open_prs,
      open_pr_count: ($open_prs | length),
      merged_prs: $merged_prs,
      merged_pr_count: ($merged_prs | length),
      open_issues: $open_issues,
      open_issue_count: ($open_issues | length),
      recent_commits: $recent_commits,
      commit_count: ($recent_commits | length),
      last_commit: $last_commit,
      milestones: $milestones,
      milestone_count: ($milestones | length),
      branches: $branches,
      branch_count: ($branches | length),
      ci_status: $ci_status
    }]')

done <<< "$REPOS"

# --- Compose final output ---
echo ""
echo "Writing output to $OUTPUT..."

jq -n \
  --arg date "$TODAY" \
  --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg period_start "$(date -u -d '7 days ago' +%Y-%m-%d 2>/dev/null || date -u -v-7d +%Y-%m-%d)" \
  --arg period_end "$TODAY" \
  --argjson repos "$REPO_DATA" \
  --argjson previous_state "$PREVIOUS_STATE" \
  '{
    generated_at: $generated_at,
    date: $date,
    period: {start: $period_start, end: $period_end},
    repo_count: ($repos | length),
    summary: {
      total_open_prs: ([$repos[].open_pr_count] | add // 0),
      total_merged_prs_7d: ([$repos[].merged_pr_count] | add // 0),
      total_open_issues: ([$repos[].open_issue_count] | add // 0),
      total_commits_7d: ([$repos[].commit_count] | add // 0),
      repos_with_no_activity: [$repos[] | select(.commit_count == 0 and .merged_pr_count == 0) | .repo]
    },
    repos: $repos,
    previous_state: $previous_state
  }' > "$OUTPUT"

echo ""
echo "=== Done ==="
echo "Output: $OUTPUT"
echo "Repos: $REPO_COUNT"
echo "Total open PRs: $(jq '.summary.total_open_prs' "$OUTPUT")"
echo "Total merged PRs (7d): $(jq '.summary.total_merged_prs_7d' "$OUTPUT")"
echo "Total open issues: $(jq '.summary.total_open_issues' "$OUTPUT")"
echo "Total commits (7d): $(jq '.summary.total_commits_7d' "$OUTPUT")"
echo "Repos with no activity: $(jq -r '.summary.repos_with_no_activity | join(", ")' "$OUTPUT")"
