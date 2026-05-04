# Scenario 4 — Runbooks and Documentation

**Goal:** The collaboration platform's value collapses if no one knows how to use it well. These runbooks are the operational documentation that lives next to the platform — short, opinionated, and written for the person running the play at 2am, not for marketing.

## What's here

| File | Audience | When it gets used |
|---|---|---|
| [`runbook-incident-channel-creation.md`](runbook-incident-channel-creation.md) | Incident commander, on-call SRE | Cyber incident declared and a dedicated channel + roles need to spin up in under 5 minutes |
| [`runbook-alert-tuning.md`](runbook-alert-tuning.md) | DevSecOps engineer | A pipeline-alerts channel has gone noisy and the team is starting to ignore it |
| [`user-guide-secure-collaboration.md`](user-guide-secure-collaboration.md) | All Mattermost users | Onboarding to the platform; periodic refresher when a phishing or exfil incident reminds people the rules exist |

## Documentation principles used here

- **Action-first.** Each runbook leads with steps. Background and rationale go after, not before.
- **Authoritative but small.** Each is one screen of useful content, not a 30-page Confluence page no one reads. If a section grows past one screen, it's the wrong artifact — split it.
- **Owned, dated, versioned.** Every runbook has an owner and a "last reviewed" date in the header. Anything older than 6 months is presumed stale and gets re-reviewed before being trusted.
- **Tied to the system.** Channel names, command syntax, and tool names match what's actually deployed in Scenarios 1–3. A runbook that uses a hypothetical channel name is fiction, not a runbook.

## How these stay current

- Runbooks live in the same Git repo as the IaC. PRs that change `site.yml` channel structure must update the runbook in the same commit, enforced by a CODEOWNERS rule and a CI check that greps for any unchanged channel name when `site.yml` is touched.
- A quarterly tabletop exercise walks one runbook end-to-end. Anything the IC stumbles over becomes a PR.
- The `#ops-on-call` channel topic links to this folder. New on-call hires read every runbook on their first day.

## What this demonstrates for the role

- Treating documentation as a deliverable, not a sidebar
- Operational empathy: the runbooks are written for the person at 2am, not the architect at the design review
- Understanding that the chat platform is also the *vehicle* for incident response, not just a product to be deployed
