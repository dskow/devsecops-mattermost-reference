# Runbook: Incident Channel Spin-Up

| Field | Value |
|---|---|
| Owner | DevSecOps team lead |
| Last reviewed | 2026-04-12 |
| Trigger | A cyber incident is declared (any severity); an incident channel is needed before triage can proceed |
| Time budget | 5 minutes from declaration to channel posted in `#ops-on-call` |

## Pre-requisites

- You are a member of the `cyber-ops` team in Mattermost
- You have the `incident_commander` Mattermost custom role (granted by SystemAdmin; if you don't have it, page the SystemAdmin first — do not proceed)
- You know the incident severity (SEV1 / SEV2 / SEV3) and a one-line description

## Steps

### 1. Run the slash command

In any channel:

```
/incident-create severity=SEV2 description="Possible credential reuse on jump host"
```

The `incident-create` slash command (Mattermost integration, source in [`02-iac-mattermost`](../02-iac-mattermost/) — added as a follow-up integration in a real engagement) does the following automatically:

- Creates a private channel named `inc-YYYYMMDD-NNN-<short-slug>` in the `cyber-ops` team
- Adds the on-call rotation members from PagerDuty as channel members
- Pins a templated incident header (severity, declared time, IC, scribe, comms lead — slots empty for the IC to fill)
- Posts a notification to `#ops-on-call` with a link to the new channel
- Opens a corresponding incident record in the ticketing system and pins the link

If the slash command is unavailable, fall back to step 1b.

### 1b. Fallback: manual channel creation

1. In the `cyber-ops` team, click the **+** next to "Channels" → **Create New Channel**
2. Type: **Private**
3. Name: `inc-YYYYMMDD-NNN-<short-slug>` — increment NNN by checking the most recent `inc-` channel
4. Add the on-call rotation manually from `#ops-on-call` topic
5. Paste the channel header template from `templates/incident-header.md` (in the program's docs repo)
6. Post the link in `#ops-on-call`

### 2. Assign roles in the channel header

Edit the channel header and fill the role slots:

- **IC** (incident commander) — usually you, unless escalating
- **Scribe** — keeps a timeline; the channel itself is the audit trail but the scribe summarizes
- **Comms lead** — owns external messaging (status page, leadership)
- **SME** — the person closest to the affected system

For SEV1 only: also assign a **liaison** to brief leadership in `#leadership-sync`.

### 3. Post the first situation update

Template:

```
SITREP 1
Time:        <UTC>
What we know: <one or two sentences>
What we're doing: <next concrete action>
Who's doing it: <name>
Next SITREP: <relative time, e.g. +15 min>
```

Subsequent SITREPs every 15 min for SEV1, every 30 for SEV2, every hour for SEV3 — until resolved or stand-down.

### 4. After resolution

1. Post a final SITREP marked `RESOLVED`
2. Run `/incident-close` (or rename the channel to `inc-YYYYMMDD-NNN-<slug>-CLOSED` if the slash command isn't available)
3. The channel **stays** — it's the audit trail. Don't delete it. Archive it after the post-incident review (typically within 5 business days)
4. Schedule the post-incident review meeting via the standard calendar invite

## Common failures

| Symptom | Cause | Fix |
|---|---|---|
| Slash command returns "permission denied" | You're not in the `incident_commander` role | Page SystemAdmin via PagerDuty (don't wait — use the manual fallback in parallel) |
| `#ops-on-call` notification didn't fire | Webhook URL rotated and slash command config is stale | File a P2 ticket; manually @ the on-call group in the new channel for now |
| Can't add a specific person | They're not in the `cyber-ops` team | Add them to the team first (SystemAdmin power needed); for SEV1 this is grounds to page the SystemAdmin |

## What does NOT belong in an incident channel

- Customer PII unless absolutely necessary for response (and never in screenshots — redact)
- Speculation framed as fact ("Someone said it might be..." — be explicit about confidence)
- Side conversations unrelated to the incident (move to a thread or a different channel)
