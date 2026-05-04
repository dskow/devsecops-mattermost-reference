"""Post a structured build/scan alert to a Mattermost incoming webhook.

Reads context from environment variables set by the calling CI workflow. Designed
to run inside a GitHub Actions runner but the only Actions-specific assumption is
the env var names, so it ports cleanly to GitLab CI / Jenkins by remapping them.

Exit codes:
    0 - posted (or skipped intentionally)
    1 - configuration error (missing webhook URL)
    2 - webhook rejected payload after retries
"""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request

WEBHOOK_TIMEOUT_SECONDS = 10
MAX_RETRIES = 3
RETRY_BACKOFF_SECONDS = 2

COLOR_CRITICAL = "#cc0000"
COLOR_HIGH = "#e8a33d"
COLOR_OK = "#3d9970"


def build_payload() -> dict:
    build_status = os.environ.get("BUILD_STATUS", "unknown")
    scan_status = os.environ.get("SCAN_STATUS", "unknown")
    cve_summary = os.environ.get("CVE_SUMMARY", "no summary available")
    repo = os.environ.get("REPO", "unknown/repo")
    branch = os.environ.get("BRANCH", "unknown")
    sha = os.environ.get("SHA", "")[:7]
    actor = os.environ.get("ACTOR", "unknown")
    run_url = os.environ.get("RUN_URL", "")

    if build_status == "failure":
        title = f"Build failed: {repo}@{branch}"
        color = COLOR_CRITICAL
    elif scan_status == "failure":
        title = f"Vulnerabilities found: {repo}@{branch}"
        color = COLOR_HIGH
    else:
        title = f"Pipeline event: {repo}@{branch}"
        color = COLOR_OK

    return {
        "username": "ci-bot",
        "icon_emoji": ":shield:",
        "attachments": [
            {
                "fallback": title,
                "color": color,
                "title": title,
                "title_link": run_url,
                "fields": [
                    {"short": True, "title": "Build", "value": build_status},
                    {"short": True, "title": "Scan", "value": scan_status},
                    {"short": True, "title": "Commit", "value": sha or "n/a"},
                    {"short": True, "title": "Triggered by", "value": actor},
                    {"short": False, "title": "CVE summary", "value": cve_summary},
                ],
                "footer": "DevSecOps pipeline",
            }
        ],
    }


def post_with_retries(webhook_url: str, payload: dict) -> None:
    body = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        webhook_url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    last_error: Exception | None = None
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            with urllib.request.urlopen(request, timeout=WEBHOOK_TIMEOUT_SECONDS) as response:
                if 200 <= response.status < 300:
                    print(f"posted to mattermost (attempt {attempt}, status {response.status})")
                    return
                last_error = RuntimeError(f"HTTP {response.status}")
        except (urllib.error.URLError, TimeoutError) as exc:
            last_error = exc

        if attempt < MAX_RETRIES:
            sleep_for = RETRY_BACKOFF_SECONDS * attempt
            print(f"attempt {attempt} failed ({last_error}); retrying in {sleep_for}s")
            time.sleep(sleep_for)

    print(f"giving up after {MAX_RETRIES} attempts: {last_error}", file=sys.stderr)
    sys.exit(2)


def main() -> None:
    webhook_url = os.environ.get("MATTERMOST_WEBHOOK_URL")
    if not webhook_url:
        print("MATTERMOST_WEBHOOK_URL not set", file=sys.stderr)
        sys.exit(1)

    payload = build_payload()
    post_with_retries(webhook_url, payload)


if __name__ == "__main__":
    main()
