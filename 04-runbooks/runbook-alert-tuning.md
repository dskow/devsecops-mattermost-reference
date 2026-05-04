# Runbook: Alert Channel Tuning

| Field | Value |
|---|---|
| Owner | DevSecOps team lead |
| Last reviewed | 2026-04-12 |
| Trigger | A pipeline-alerts channel (e.g. `#sec-pipeline-alerts`) is being ignored, muted, or generating complaints |
| Time budget | One focused afternoon to diagnose and tune |

## Why this runbook exists

A channel that fires constantly is worse than a channel that fires nothing — people learn to dismiss it, and the one alert that mattered gets dismissed with the rest. This is the single most common failure mode of pipeline-to-chat integrations and it tends to creep in slowly: the integration was useful at week 1 and is noise by month 3 as more pipelines are wired in.

## Diagnose first

### 1. Pull the last 7 days of alerts

In the affected channel:

```
/sec-pipeline-alerts export from=-7d
```

(Or use the Mattermost API: `GET /api/v4/channels/<id>/posts?since=<epoch_ms>`)

### 2. Categorize each alert

Bucket every alert into one of:

| Bucket | Definition | Action target |
|---|---|---|
| **Actionable** | Someone took an action because of this alert (filed an issue, paged, fixed) | Keep |
| **Informational** | Useful to know, didn't change behavior | Move to a digest |
| **Recurring known issue** | Same flaky test / unfixable transitive dependency CVE firing repeatedly | Suppress with a reason |
| **Misfire** | Alert fired without a real underlying condition | Fix the alert source |

### 3. Compute the actionable percentage

```
actionable / total
```

Targets:
- **>50%** healthy
- **20%–50%** noisy but salvageable — proceed to "Tune"
- **<20%** the channel has been broken for a while — proceed to "Reset"

## Tune

### Raise the threshold

In the workflow that posts the alerts ([01-platform-integration/.github/workflows/build-with-security-scan.yml](../01-platform-integration/.github/workflows/build-with-security-scan.yml)):

```yaml
env:
  TRIVY_SEVERITY: HIGH,CRITICAL    # was MEDIUM,HIGH,CRITICAL
```

Most "alerts that nobody acts on" are MEDIUM CVEs in transitive dependencies. They belong in the SARIF artifact (still uploaded to the Security tab), not in chat.

### Suppress known issues with a reason

Add to the project's `.trivyignore` with a comment that includes the ticket number and review date:

```
# CVE-2024-12345 — false positive in golang.org/x/crypto, upstream fixed in v0.18 (PRG-1234)
# review-by 2026-09-01
CVE-2024-12345
```

The `review-by` comment lets the next person re-evaluate the suppression instead of inheriting it forever. Add a CI check that fails if any `review-by` date is in the past.

### Move informational alerts to a digest

Replace the per-event webhook post with a daily summary:

- A scheduled Lambda (or GitHub Actions cron job) queries pipeline runs from the last 24h
- Posts one message to `#sec-pipeline-digest` with totals (builds, failures, scan findings) and links

The original alert channel keeps only the high-signal events.

### Verify

After tuning, run for one week and recompute the actionable percentage. If still <50%, repeat from "Diagnose."

## Reset (last resort)

If actionable percentage is below 20% and the team has stopped reading the channel:

1. Post a clear "this channel is being reset" message in the channel and in `#general`
2. Pause the integration (remove the webhook from GitHub secrets, do not delete it — keep the value for audit)
3. Hold a 30-minute working session with the team to redefine: what *should* land here, who *should* read it, what's the SLA on response
4. Re-implement the integration with the new threshold
5. Re-enable; commit to revisiting in 30 days

The reset is psychologically expensive but cheaper than the alternative, which is the team continuing to ignore a channel labeled "security alerts."

## What this runbook explicitly does not do

- It does not change the underlying scan tool or pipeline platform. Those are bigger decisions that belong in an architecture review, not an alerting tuning pass.
- It does not advise turning off the channel entirely. If alerts have value at all, the answer is fewer-and-better alerts, not none.
