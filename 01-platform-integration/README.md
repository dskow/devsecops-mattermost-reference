# Scenario 1 — Pipeline Alerts to Mattermost

**Goal:** When a build fails or a security scan finds a vulnerability above threshold, a structured alert lands in a Mattermost channel within seconds — with enough context that the responder doesn't have to open the pipeline UI to triage.

## What's here

| File | Purpose |
|---|---|
| [`.github/workflows/build-with-security-scan.yml`](.github/workflows/build-with-security-scan.yml) | CI workflow that builds a container, runs Trivy, and notifies Mattermost on failure or HIGH/CRITICAL findings |
| [`scripts/notify_mattermost.py`](scripts/notify_mattermost.py) | Webhook poster — formats build/scan results into a Mattermost message card, retries on transient failure |
| [`examples/sample-payloads.md`](examples/sample-payloads.md) | Examples of the rendered messages (build failure, vulnerability detected, recovery) |

## Design choices

- **Webhook over bot account.** Incoming webhooks are scoped to one channel and one purpose, which is easier to justify in an ATO package than a bot user with broad token scope.
- **Posting from the runner, not a separate service.** Keeps the alert path on the same network/identity as the build itself — fewer moving parts to harden, fewer cross-boundary credentials.
- **Structured fields, not freeform text.** The Python script emits Mattermost message attachments with `color`, `title`, `fields`. That gives consistent visual triage cues (red border = failure, orange = HIGH CVE, green = recovery) and lets channel members filter.
- **Threshold-based, not noise-based.** Only HIGH/CRITICAL CVEs trigger a notification. MEDIUM and below go to the SARIF artifact uploaded to GitHub Security tab. This is the single biggest lever against alert fatigue (see [runbook 4.2](../04-runbooks/runbook-alert-tuning.md)).
- **Webhook URL stored as a GitHub Actions secret.** Never in the repo, never in the script. The script reads `MATTERMOST_WEBHOOK_URL` from the environment.

## Wiring it up (real engagement)

1. In Mattermost: **Integrations → Incoming Webhooks → Add**, scope to channel `#sec-pipeline-alerts`.
2. Copy the webhook URL into the GitHub repo or org secret store as `MATTERMOST_WEBHOOK_URL`.
3. Drop the workflow into `.github/workflows/` of the target repo.
4. Tune the Trivy severity threshold in the workflow's `severity:` input to match the team's risk tolerance (Guard programs typically run HIGH,CRITICAL during steady-state and tighten to MEDIUM,HIGH,CRITICAL pre-release).

## What this demonstrates for the role

- Hands-on CI/CD wiring (GitHub Actions, but the pattern ports to GitLab CI / Jenkins / Tekton)
- Container vulnerability scanning in the build path
- Treating alerting as a product (signal-to-noise, channel taxonomy) rather than a fire-and-forget integration
