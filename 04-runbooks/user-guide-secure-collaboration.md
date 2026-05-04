# User Guide: Secure Collaboration on Mattermost

| Field | Value |
|---|---|
| Audience | All Mattermost users on the program |
| Owner | DevSecOps team lead |
| Last reviewed | 2026-04-12 |
| Read time | 4 minutes |

The chat platform is a system of record. What you post is logged, retained, and discoverable in audits and FOIA-equivalent requests. This guide is the short version of how to use it without creating a security or compliance problem.

## The five rules

### 1. Match the channel to the data

Each channel has a classification marker in its purpose or header (`UNCLASSIFIED`, `CUI`, `FOUO`). Do not post content above that marker. If the conversation drifts higher, stop and move it — request a more restricted channel from the SystemAdmin if one doesn't exist. Posting SECRET content in a CUI channel is a spillage event and triggers the data-spill runbook (not in this folder; lives with the security team).

### 2. Files follow the same rule as messages

A spreadsheet attached to a CUI channel inherits the channel's classification. Don't attach a file that's marked higher than the channel allows, even if "everyone in the channel could see it anyway."

### 3. No credentials, ever

Do not post:

- Passwords, tokens, API keys, certificate private keys
- AWS access keys, even temporary ones
- Database connection strings with embedded credentials
- Anything that looks like a credential, even as an example or a "fake" placeholder

If you accidentally posted one: rotate it first, delete the message second, file an incident third — in that order. Deletion does not remove the message from server-side audit logs or backups; rotation is what protects you.

### 4. Direct messages are not private

DMs are subject to the same retention, audit, and discovery rules as channels. They are private from other users, not private from the system. Treat them like a meeting room with a recording light on.

### 5. External integrations need approval

Don't add a personal Slack/Teams/Zoom bridge, RSS reader, or webhook integration. Every integration is a new data egress point and gets ATO-impact review. Ask in `#change-management` if you have a use case.

## How channels are organized

| Prefix | What it is | Who can post |
|---|---|---|
| `#sec-*` | Security-relevant alerts and triage | Anyone in the team; integrations post from `ci-bot` |
| `#inc-*` | Active incident channels | Members added by the IC; do not self-add |
| `#ops-*` | Operations and on-call | Anyone in the team |
| `#change-*` | Change management board | Mostly read — post structured CRs only |
| `#compliance-*` | Evidence collection (private) | ISSE/ISSO members only |

Channels named `inc-YYYYMMDD-NNN-*` are active or recent incident channels. Don't browse them to satisfy curiosity — incident metadata is sensitive and channel access is logged.

## Notifications without burnout

- Use `@channel` only when the situation requires every member's eyes within minutes. Most things are not that.
- Use `@here` for "people online right now should see this," not "I want a faster response."
- Mute channels you don't actively need. A channel you're in but ignore is worse than one you've left, because your name appears in the member list and people assume you're paying attention.

## When something looks wrong

If you see:

- A message from a `ci-bot`-style account that doesn't match the integration you'd expect → screenshot, post in `#sec-vuln-triage`
- A new channel in a team you didn't expect → fine to ignore, but flag if the name suggests it's collecting sensitive content (`#leadership-mirror`, `#audit-bypass`, etc.)
- A DM from someone you don't recognize asking for credentials, links, or "verification" → do not respond; report to `#sec-vuln-triage` and forward the DM ID

## What this guide does not cover

- Phishing handling (separate runbook owned by the security team)
- CAC card enrollment (covered in onboarding)
- Mobile app installation (the Guard's MDM policy controls this; ask `#ops-on-call`)

## Questions

`#ops-on-call` for "how do I do X." `#sec-vuln-triage` for "I think something is wrong." For anything that's actually an incident, see [`runbook-incident-channel-creation.md`](runbook-incident-channel-creation.md).
