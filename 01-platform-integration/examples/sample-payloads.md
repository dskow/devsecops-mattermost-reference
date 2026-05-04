# Sample rendered alerts

These are what an analyst sees in `#sec-pipeline-alerts` for the three common cases.

## 1. Build failure (compile / unit test broke)

```
[ci-bot]  Build failed: dod-program/api-gateway@main

  Build:        failure        Scan:         skipped
  Commit:       a3f1c92        Triggered by: jdoe
  CVE summary:  no summary available

  DevSecOps pipeline                          [View pipeline run]
```

Red left border. The "View pipeline run" footer link goes straight to the Actions run page, so the responder doesn't have to navigate from the channel to find logs.

## 2. Vulnerability detected (build passed, Trivy found HIGH/CRITICAL)

```
[ci-bot]  Vulnerabilities found: dod-program/api-gateway@main

  Build:        success        Scan:         failure
  Commit:       9c4e201        Triggered by: jdoe
  CVE summary:  CRITICAL: 1, HIGH: 4

  DevSecOps pipeline                          [View pipeline run]
```

Orange left border. Counts come from the SARIF parse step in the workflow. Full CVE list is on the GitHub Security tab — the alert deliberately stays compact because dumping a 40-line CVE table into chat is the fastest way to train the team to ignore the channel.

## 3. Recovery (next build is clean)

The current workflow does not post recovery messages — only failures. This is a deliberate signal-to-noise choice. If the customer wants explicit "we're back to green" messages (some incident-response teams prefer them for paper-trail reasons), uncomment the success branch in `notify_mattermost.py`'s `build_payload()` and remove the `if: failure()` guard on the `notify-mattermost` job in the workflow.

## What changes in a real engagement

- The webhook posts to a per-program channel (`#cyber-shield-pipeline`, not the example `#sec-pipeline-alerts`).
- The footer link is rewritten to the customer's GitLab/Jenkins URL if not on github.com.
- The bot username and icon are set per-program so analysts who sit in multiple channels can tell at a glance which pipeline fired.
