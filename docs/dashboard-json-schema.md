# dashboard.json Schema Reference

The COO agent generates `dashboard.json` at the repository root on every weekly run. This file provides structured, machine-readable project data for the Claude Management Dashboard.

## How to Fetch

The file is committed to `bh679/coo-agent` and accessible via the GitHub Contents API:

```bash
gh api repos/bh679/coo-agent/contents/dashboard.json
```

The response includes base64-encoded content. Decode it:

```javascript
const raw = execSync('gh api repos/bh679/coo-agent/contents/dashboard.json', { encoding: 'utf8' });
const fileData = JSON.parse(raw);
const dashboard = JSON.parse(Buffer.from(fileData.content, 'base64').toString('utf8'));
```

## Update Frequency

- Generated every Monday at ~08:00 UTC (or on manual workflow dispatch)
- The file is overwritten each run — it always reflects the latest state
- Historical data lives in `reports/YYYY-MM-DD.md` markdown files

## Top-Level Structure

| Field | Type | Description |
|---|---|---|
| `generated_at` | string (ISO 8601) | Timestamp when the agent produced this file |
| `report_date` | string (YYYY-MM-DD) | Date of the corresponding markdown report |
| `period.start` | string (YYYY-MM-DD) | Start of the 7-day monitoring window |
| `period.end` | string (YYYY-MM-DD) | End of the monitoring window (= report_date) |
| `summary` | object | Aggregate counts across all projects |
| `projects` | array | Per-project structured data |

## Summary Object

| Field | Type | Description |
|---|---|---|
| `total_projects` | integer | Number of monitored repos |
| `needs_decision` | integer | Projects with status `"needs_decision"` |
| `at_risk` | integer | Projects with status `"at_risk"` |
| `moving_well` | integer | Projects with status `"moving_well"` |
| `total_open_prs` | integer | Sum of open PRs across all repos |
| `total_open_issues` | integer | Sum of open issues across all repos |
| `total_commits_7d` | integer | Total commits in the 7-day window |
| `total_merged_prs_7d` | integer | Total merged PRs in the 7-day window |

**Invariant:** `needs_decision + at_risk + moving_well = total_projects`

## Project Object

Each entry in the `projects` array represents one monitored repository.

| Field | Type | Description |
|---|---|---|
| `repo` | string | Full `owner/name` identifier (e.g., `"bh679/chess-project"`) |
| `name` | string | Short repo name for display |
| `description` | string | From `consumers.json` |
| `parent` | string or null | Parent project `owner/name` from `consumers.json`. `null` or absent for top-level projects |
| `standalone` | boolean | From `consumers.json`. When `true`, sub-repo is also reported independently. Absent or `false` otherwise |
| `status` | enum | `"needs_decision"`, `"at_risk"`, or `"moving_well"` |
| `status_label` | string | Human-readable: `"Needs Decision"`, `"At Risk / Stalled"`, `"Moving Well"` |
| `status_emoji` | string | `"🔴"`, `"🟡"`, or `"🟢"` |
| `metrics` | object | Numeric KPIs for this repo |
| `blockages` | array | Items requiring human decision (maps to 🔴 section) |
| `risks` | array | Items at risk or stalled (maps to 🟡 section) |
| `recent_updates` | array | Notable positive activity (maps to 🟢 section) |

### Status Values

| Value | Emoji | Meaning |
|---|---|---|
| `needs_decision` | 🔴 | Blocked — requires Brennan's immediate input |
| `at_risk` | 🟡 | Stalled or slowing — no blockers but losing momentum |
| `moving_well` | 🟢 | Healthy activity, forward progress |

## Metrics Object

| Field | Type | Description |
|---|---|---|
| `open_prs` | integer | Currently open pull requests |
| `open_issues` | integer | Currently open issues |
| `commits_7d` | integer | Commits in the last 7 days |
| `merged_prs_7d` | integer | PRs merged in the last 7 days |
| `last_commit` | string or null | ISO 8601 timestamp of the most recent commit |
| `days_since_last_commit` | integer | Calendar days since the last commit |

## Blockages Array

Items from the 🔴 Needs Decision section. Empty array if no blockages.

| Field | Type | Description |
|---|---|---|
| `type` | enum | `"blocked_pr"`, `"architectural_decision"`, `"priority_conflict"`, `"other"` |
| `summary` | string | What needs to be decided |
| `url` | string | Link to the relevant PR/issue on GitHub |
| `issue_url` | string | Link to the `[Decision Needed]` issue opened in `bh679/coo-agent` |

## Risks Array

Items from the 🟡 At Risk / Stalled section. Empty array if no risks.

| Field | Type | Description |
|---|---|---|
| `type` | enum | `"low_activity"`, `"dormant"`, `"stale_pr"`, `"overdue_milestone"`, `"stale_branch"`, `"ci_failure"` |
| `summary` | string | Brief description of the risk |
| `severity` | enum | `"low"`, `"medium"`, `"high"` |
| `since` | string (ISO 8601) | When the risk condition started |
| `url` | string (optional) | Link to the relevant GitHub resource |

### Severity Guidelines

- **high** — Dormant (zero activity 7+ days), overdue milestone, failing CI on default branch
- **medium** — Low activity (minimal commits, no functional changes), stale PRs (3-7 days)
- **low** — Minor concerns (stale feature branches, slow review cycles)

## Recent Updates Array

Notable positive activity from the 🟢 Moving Well assessment. Empty array if no updates.

| Field | Type | Description |
|---|---|---|
| `type` | enum | `"commit"`, `"pr_merged"`, `"issue_closed"`, `"milestone_progress"` |
| `date` | string (ISO 8601) | When the activity occurred |
| `summary` | string | Brief description |
| `url` | string (optional) | Link to the commit/PR/issue on GitHub |

## Example

```json
{
  "generated_at": "2026-03-02T04:31:30Z",
  "report_date": "2026-03-02",
  "period": {
    "start": "2026-02-23",
    "end": "2026-03-02"
  },
  "summary": {
    "total_projects": 5,
    "needs_decision": 0,
    "at_risk": 2,
    "moving_well": 3,
    "total_open_prs": 0,
    "total_open_issues": 0,
    "total_commits_7d": 27,
    "total_merged_prs_7d": 2
  },
  "projects": [
    {
      "repo": "bh679/Claude-Max-Usage-Analytics",
      "name": "Claude-Max-Usage-Analytics",
      "description": "Claude Max Usage Analytics — personal usage dashboard",
      "parent": "bh679/Claude-Management-Dashboard",
      "standalone": true,
      "status": "moving_well",
      "status_label": "Moving Well",
      "status_emoji": "🟢",
      "metrics": {
        "open_prs": 0,
        "open_issues": 0,
        "commits_7d": 22,
        "merged_prs_7d": 2,
        "last_commit": "2026-03-02T03:28:05Z",
        "days_since_last_commit": 0
      },
      "blockages": [],
      "risks": [],
      "recent_updates": [
        {
          "type": "pr_merged",
          "date": "2026-03-01T18:30:00Z",
          "summary": "feat: add daily usage breakdown chart",
          "url": "https://github.com/bh679/Claude-Max-Usage-Analytics/pull/5"
        }
      ]
    },
    {
      "repo": "bh679/house-sitting-agent",
      "name": "house-sitting-agent",
      "description": "Autonomous house-sitting listing monitor and applicant",
      "status": "at_risk",
      "status_label": "At Risk / Stalled",
      "status_emoji": "🟡",
      "metrics": {
        "open_prs": 0,
        "open_issues": 0,
        "commits_7d": 0,
        "merged_prs_7d": 0,
        "last_commit": "2026-02-22T18:04:16Z",
        "days_since_last_commit": 8
      },
      "blockages": [],
      "risks": [
        {
          "type": "dormant",
          "summary": "Zero commits since 2026-02-22. Project appears dormant.",
          "severity": "high",
          "since": "2026-02-22T18:04:16Z"
        }
      ],
      "recent_updates": []
    }
  ]
}
```

## Dashboard Integration Notes

- Fetch `dashboard.json` on page load or on a refresh interval
- Use `summary` counts for top-level status badges/counters
- Render `projects` as cards sorted by status priority: `needs_decision` first, then `at_risk`, then `moving_well`
- Use `status_emoji` and `status_label` for visual indicators
- Link to the full markdown report via `report_date` → `reports/{report_date}.md`
- The `blockages[].issue_url` field links to the GitHub issue created for that decision item
