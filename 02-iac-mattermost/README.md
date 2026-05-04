# Scenario 2 — IaC for the Mattermost Server

**Goal:** Stand up a Mattermost server and its initial team/channel structure from code, so the deployment is reproducible across environments (dev, staging, prod) and auditable for the ATO package.

## Two-tool split

The two tools handle different problems and the demo uses each for what it's good at:

- **Terraform** ([`terraform/`](terraform/)) provisions the AWS infrastructure: VPC, EC2 instance, RDS PostgreSQL, ALB with TLS, security groups, IAM, KMS, S3 bucket for file storage. Declarative, lifecycle-managed by state.
- **Ansible** ([`ansible/`](ansible/)) configures the EC2 host and bootstraps Mattermost: STIG-aligned OS hardening, Mattermost install, TLS cert placement, initial team/channel/role provisioning via the Mattermost API. Procedural, runs against an instance Terraform created.

A common anti-pattern is to do both with one tool — Terraform configuring the OS via `remote-exec`, or Ansible calling AWS CLI to make EC2s. Both work badly. The split here is deliberate.

## What's in `terraform/`

| File | What it provisions |
|---|---|
| [`main.tf`](terraform/main.tf) | VPC + subnets, EC2 (Mattermost), RDS Postgres, ALB, security groups, S3 bucket for uploads, KMS key for at-rest encryption |
| [`variables.tf`](terraform/variables.tf) | `environment`, `instance_type`, `db_password` (sensitive), `allowed_cidr_blocks` for management access |
| [`outputs.tf`](terraform/outputs.tf) | ALB DNS name, RDS endpoint, EC2 instance ID — consumed by Ansible inventory generation |

## What's in `ansible/`

| File | What it does |
|---|---|
| [`site.yml`](ansible/site.yml) | Top-level play — applies hardening role, installs Mattermost, runs channel-provisioning tasks |
| [`roles/mattermost_hardening/tasks/main.yml`](ansible/roles/mattermost_hardening/tasks/main.yml) | STIG-aligned tasks: disable root SSH, enforce password policy, fapolicyd config, audit rules, FIPS-mode flag, banner |

## Initial channel structure (the "structures.Security" piece)

The Ansible play creates a fixed channel taxonomy on first run. The taxonomy below is the demo default — a real engagement would replace it with the customer's channel naming standard (most Guard programs already have one).

```
Team: cyber-ops
├── #general                  (announcements, town halls)
├── #sec-pipeline-alerts      (Scenario 1 webhook target)
├── #sec-vuln-triage          (CVE response, manned during business hours)
├── #incident-response        (read-only until invoked, see runbook 4.1)
├── #change-management        (CM board notifications)
└── #ops-on-call              (paging integrations, oncall handoffs)

Team: program-leadership
├── #leadership-sync          (private, restricted membership)
└── #compliance-evidence      (private, evidence collection for assessors)
```

## What this demonstrates for the role

- Cloud IaC fluency (Terraform with proper module/variable hygiene, sensitive-var handling)
- Configuration management discipline (Ansible role structure, idempotent tasks, no shell-scripts-in-disguise)
- Understanding that "deploy the chat platform" is two problems — infra and configuration — not one
- Understanding that the channel taxonomy *is* part of the deliverable, not something users figure out post-deploy

## Notes

- The Terraform here targets commercial AWS for demo simplicity. For a real Guard engagement, the same modules apply to GovCloud (`us-gov-west-1`) with `partition = "aws-us-gov"` interpolated into IAM ARNs and the AMI lookup pointed at a STIG-hardened Iron Bank-derived AMI from the customer's image pipeline.
- Mattermost binary install uses the upstream tarball in this demo. In a real ATO context the install would pull the Iron Bank container image (`registry1.dso.mil/ironbank/mattermost/mattermost`) and run it under Podman or in EKS.
- No real secrets in this folder. `db_password` is marked `sensitive` and expected from `TF_VAR_db_password` env var or a remote secret store (AWS Secrets Manager, Vault).
