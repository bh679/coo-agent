# dashboard.json Schema

Schema version: **1.0**

This document defines the structure of `dashboard.json`, the machine-readable output of the COO Agent. Downstream consumers use this file to render project status dashboards.

## Root Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schemaVersion` | `string` | Yes | Semantic version of this schema (e.g. `"1.0"`). Consumers should check this before parsing. |
| `generated_at` | `string` (ISO 8601) | Yes | Timestamp when this file was generated. |
| `report_date` | `string` (YYYY-MM-DD) | Yes | The date this report covers. |
| `period` | `object` | Yes | The reporting window. |
| `period.start` | `string` (YYYY-MM-DD) | Yes | Start of the reporting period. |
| `period.end` | `string` (YYYY-MM-DD) | Yes | End of the reporting period. |
| `summary` | `object` | Yes | Aggregate counts across all projects. |
| `projects` | `array` of `Project` | Yes | One entry per monitored repository. |

## Summary Object

| Field | Type | Description |
|-------|------|-------------|
| `total_projects` | `integer` | Total number of projects in the portfolio. |
| `needs_decision` | `integer` | Count of projects with `status: "needs_decision"`. |
| `at_risk` | `integer` | Count of projects with `status: "at_risk"`. |
| `moving_well` | `integer` | Count of projects with `status: "moving_well"`. |
| `total_open_prs` | `integer` | Sum of open PRs across all projects. |
| `total_open_issues` | `integer` | Sum of open issues across all projects. |
| `total_commits_7d` | `integer` | Sum of commits in the last 7 days across all projects. |
| `total_merged_prs_7d` | `integer` | Sum of merged PRs in the last 7 days across all projects. |

## Project Object

| Field | Type | Description |
|-------|------|-------------|
| `repo` | `string` | Repository identifier in `owner/name` format. |
| `name` | `string` | Short display name for the project. |
| `description` | `string` | Project description from `consumers.json`. |
| `status` | `string` | One of: `"needs_decision"`, `"at_risk"`, `"moving_well"`. |
| `status_label` | `string` | Human-readable status label. |
| `status_emoji` | `string` | Status indicator emoji. |
| `metrics` | `Metrics` | Quantitative project metrics. |
| `blockages` | `array` of `Blockage` | Items requiring human decision. |
| `risks` | `array` of `Risk` | Items flagged as at-risk or stalled. |
| `recent_updates` | `array` of `Update` | Notable positive activity. |

## Metrics Object

| Field | Type | Description |
|-------|------|-------------|
| `open_prs` | `integer` | Number of currently open pull requests. |
| `open_issues` | `integer` | Number of currently open issues. |
| `commits_7d` | `integer` | Commits pushed in the last 7 days. |
| `merged_prs_7d` | `integer` | PRs merged in the last 7 days. |
| `last_commit` | `string\|null` | ISO 8601 timestamp of the most recent commit, or `null` if none. |
| `days_since_last_commit` | `integer` | Days elapsed since the last commit. |

## Blockage Object

| Field | Type | Description |
|-------|------|-------------|
| `type` | `string` | One of: `"blocked_pr"`, `"architectural_decision"`, `"priority_conflict"`, `"other"`. |
| `summary` | `string` | What needs a decision. |
| `url` | `string` | Link to the relevant GitHub resource. |
| `issue_url` | `string` | Link to the escalation issue created in bh679/coo-agent. |

## Risk Object

| Field | Type | Description |
|-------|------|-------------|
| `type` | `string` | One of: `"low_activity"`, `"dormant"`, `"stale_pr"`, `"overdue_milestone"`, `"stale_branch"`, `"ci_failure"`. |
| `summary` | `string` | Brief description of the risk. |
| `severity` | `string` | One of: `"low"`, `"medium"`, `"high"`. |
| `since` | `string` (ISO 8601) | When the risk condition began. |
| `url` | `string` (optional) | Link to the relevant GitHub resource. |

## Update Object

| Field | Type | Description |
|-------|------|-------------|
| `type` | `string` | One of: `"commit"`, `"pr_merged"`, `"issue_closed"`, `"milestone_progress"`. |
| `date` | `string` (ISO 8601) | When the update occurred. |
| `summary` | `string` | Brief description of the activity. |
| `url` | `string` (optional) | Link to the relevant GitHub resource. |

---

## Versioning Policy

The `schemaVersion` field uses semantic versioning (`MAJOR.MINOR`):

**Bump MAJOR** (e.g. `1.0` -> `2.0`) when:
- A required field is removed or renamed
- A field's type changes (e.g. `string` to `integer`)
- The structure of a nested object changes in a breaking way
- An enum value is removed from a `type` or `status` field

**Bump MINOR** (e.g. `1.0` -> `1.1`) when:
- A new optional field is added
- A new enum value is added to a `type` or `status` field
- A new object type is added to an array

Consumers should:
1. Read `schemaVersion` before parsing
2. Check that the major version matches what they support
3. Gracefully ignore unknown fields (forward-compatible with minor bumps)

---

## Consumers

| Consumer | Repository | How it uses dashboard.json |
|----------|------------|---------------------------|
| Claude Management Dashboard | [bh679/Claude-Management-Dashboard](https://github.com/bh679/Claude-Management-Dashboard) | Fetches `dashboard.json` from `bh679/coo-agent` to render project status, risk indicators, and activity summaries. |
