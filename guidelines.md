# COO Agent Output Guidelines

<!-- This file is read by the agent before producing output. -->
<!-- It governs quality, tone, and format — not what the agent does. -->

## Tone and Voice

- Write in third person, present tense ("The chess project has stalled", not "I noticed the chess project stalled").
- Be direct and actionable. Every item should make it obvious what needs to happen next.
- Professional but concise — this is an executive briefing, not a narrative.
- Use plain language. Avoid jargon unless it's a GitHub-specific term (PR, milestone, issue).

## Format

- Use the four required sections in order: 🔴 Needs Decision, 🟡 At Risk / Stalled, 🟢 Moving Well, 📋 Full Project Status.
- Use H2 (`##`) for the four main sections.
- Use H3 (`###`) for individual project sub-sections within 📋 Full Project Status.
- Use bullet lists for individual items within each section.
- Each bullet should start with the **repo name in bold** followed by a dash and the observation.
- Include links to relevant PRs, issues, and milestones where applicable.
- File naming: `reports/YYYY-MM-DD.md` (date of the report run).

## Length

- Keep the report concise. Aim for 200–500 words total.
- Each 🔴 item: 1–3 sentences with clear context and a recommended action.
- Each 🟡 item: 1–2 sentences identifying the risk.
- Each 🟢 item: 1 sentence summarising momentum.
- 📋 Full Project Status: a brief metrics table or bullet list per repo — not paragraphs.

## What to Include

- Open PRs older than 3 days (potentially stalled).
- Issues with no activity in the last 7 days that are assigned or in-progress.
- Branches with no commits in the last 7 days.
- Overdue milestones.
- Recently merged PRs (signs of momentum).
- Repos with zero activity since last run.
- Any failed CI checks on the default branch.

## What to Exclude

- Dependabot PRs and automated dependency updates (unless they're failing).
- Draft PRs (unless older than 14 days).
- Issues labelled `wontfix`, `duplicate`, or `backlog` with no recent activity.
- Internal bot commits (state.json updates, CI config changes).

## Dashboard JSON Consistency

When generating `dashboard.json`, ensure the status categorisation for each project matches the markdown report exactly. If a project appears in the 🟡 section of the report, its `status` in the JSON must be `"at_risk"`. The `blockages`, `risks`, and `recent_updates` arrays should reflect the same items described in the report sections.

## Output Naming

Save reports as `reports/YYYY-MM-DD.md` using the date the report was generated.
