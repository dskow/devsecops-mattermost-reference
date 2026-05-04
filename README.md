# DevSecOps Reference: Mattermost on a Hardened Enclave

A reference implementation for taking one collaboration platform — Mattermost — through the full DevSecOps lifecycle on a DoD-style network: pipeline integration, infrastructure provisioning, RMF/STIG compliance, and operational documentation.

Each folder is self-contained and runnable enough to demo or adapt.

| # | Scenario | Folder | What's in it |
|---|---|---|---|
| 1 | **Platform Integration** — pipeline alerts to Mattermost | [`01-platform-integration/`](01-platform-integration/) | GitHub Actions workflow that runs Trivy on a build, posts pass/fail and CVE summary to a Mattermost channel via incoming webhook |
| 2 | **Infrastructure as Code** — Mattermost server + channel structure | [`02-iac-mattermost/`](02-iac-mattermost/) | Terraform for the EC2 + RDS + ALB stack, Ansible role for STIG-aligned hardening and initial channel/team provisioning |
| 3 | **Compliance** — RMF and STIG evidence | [`03-compliance/`](03-compliance/) | NIST 800-53 control mapping, STIG checklist for the Mattermost application, OPA policy preventing public/unclassified-mismatch channels |
| 4 | **Operational Support** — runbooks for the teams using it | [`04-runbooks/`](04-runbooks/) | Runbook for incident-channel spin-up, runbook for alert-fatigue tuning, end-user guide for secure collaboration |

## Why Mattermost

Mattermost is the chat platform with a clear DoD ATO path (used across multiple programs and available on Iron Bank). It self-hosts inside the enclave, which is why the rest of the reference treats it as a workload to harden and integrate rather than a SaaS to subscribe to.

## How the four scenarios fit together

```
   pipeline (01) ──posts alerts──▶  Mattermost server  ◀──provisioned by──  IaC (02)
                                          │
                                          ├── governed by ──▶  controls + STIG (03)
                                          │
                                          └── operated via ──▶  runbooks (04)
```

## Notes on scope

This is a reference, not a turnkey deployment. Credentials are placeholders, the Terraform targets a generic AWS account rather than a real GovCloud tenancy, and the STIG checklist references public DISA guidance rather than a customer-specific baseline. Everything is structured so a real engagement would swap in the customer's account IDs, KMS keys, STIG version, and channel taxonomy without restructuring.

## License

MIT. Use, fork, adapt — attribution appreciated but not required.
