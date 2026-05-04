# NIST SP 800-53 Rev. 5 Control Mapping — Mattermost Stack

Moderate baseline. Subset shown — the controls below are the ones the chat platform most directly affects. Each row points at the artifact that satisfies the control and the evidence an assessor would pull.

## Access Control (AC)

| Control | Title | How it's satisfied | Evidence pointer |
|---|---|---|---|
| AC-2 | Account Management | Mattermost SSO bound to program IdP (SAML/OIDC); admin role granted via IdP group membership, not local accounts | IdP group export + Mattermost role audit log |
| AC-3 | Access Enforcement | Channel `type` field — `O` (open team), `P` (private) — enforced at Mattermost API and re-validated by [`opa/mattermost-channel-policy.rego`](opa/mattermost-channel-policy.rego) | OPA decision log |
| AC-4 | Information Flow Enforcement | ALB SG restricts ingress to enclave management ranges; outbound limited by VPC egress controls | [`02-iac-mattermost/terraform/main.tf`](../02-iac-mattermost/terraform/main.tf) `aws_security_group.alb` |
| AC-7 | Unsuccessful Logon Attempts | OS-level via pam_faillock (hardening role); app-level via Mattermost MaximumLoginAttempts=10, lockout 5 min | Hardening role config + `config.json` |
| AC-17 | Remote Access | SSH allowed only from `var.allowed_cidr_blocks`; password auth disabled | `aws_security_group.app` ingress + `mattermost_hardening` SSH tasks |

## Audit and Accountability (AU)

| Control | Title | How it's satisfied | Evidence pointer |
|---|---|---|---|
| AU-2 | Event Logging | OS auditd rules cover identity files, sudoers, privileged execve; Mattermost audit log enabled (LogSettings.EnableSentry=false, EnableDiagnostics=false, FileLevel=INFO) | `/etc/audit/rules.d/50-stig.rules` (rendered by hardening role) |
| AU-4 | Audit Log Storage Capacity | CloudWatch Logs subscription forwards to enclave SIEM within 60s; local retention 30 days on encrypted EBS | CloudWatch subscription filter (out of scope of this demo, called out in runbook) |
| AU-9 | Protection of Audit Information | Audit log files mode 0640, owner root; CloudWatch log group encrypted with KMS key shared only with SIEM ingestion role | KMS key policy + filesystem perms |
| AU-12 | Audit Record Generation | auditd + Mattermost audit log together cover OS and app events | Same as AU-2 |

## Configuration Management (CM)

| Control | Title | How it's satisfied | Evidence pointer |
|---|---|---|---|
| CM-2 | Baseline Configuration | Terraform state + Ansible playbook are the baseline; reproducible from version control | This repo |
| CM-3 | Configuration Change Control | All infra changes via PR; pipeline scan gates merge (Scenario 1); `#change-management` channel records emergency changes | GitHub PR history + Mattermost audit log |
| CM-6 | Configuration Settings | Settings enforced by Ansible (idempotent — drift gets corrected on next run) | `roles/mattermost_hardening/tasks/main.yml` |
| CM-7 | Least Functionality | fapolicyd application allow-listing, firewalld restricting open ports | Hardening role fapolicyd + firewall tasks |

## Identification and Authentication (IA)

| Control | Title | How it's satisfied | Evidence pointer |
|---|---|---|---|
| IA-2 | Identification and Authentication (Org Users) | SAML/OIDC to program IdP (CAC-backed); no local Mattermost passwords for non-break-glass accounts | Mattermost SAML config |
| IA-2(1) | Multi-Factor Authentication (Privileged) | MFA enforced at IdP for SystemAdmin role group | IdP MFA policy export |
| IA-5 | Authenticator Management | When local accounts exist (break-glass only), pwquality enforces 15-char minimum, 4 character classes | pwquality.conf rendered by hardening role |

## System and Communications Protection (SC)

| Control | Title | How it's satisfied | Evidence pointer |
|---|---|---|---|
| SC-7 | Boundary Protection | ALB is single ingress; app SG only accepts from ALB SG | `02-iac-mattermost/terraform/main.tf` |
| SC-8 | Transmission Confidentiality and Integrity | TLS 1.2+ enforced at ALB (FIPS-validated cipher suites); Mattermost-to-DB TLS via `sslmode=require` | ALB listener policy (set in tfvars per-program) + `config.json` `SqlSettings.DataSource` |
| SC-13 | Cryptographic Protection | FIPS mode enabled on host; KMS keys for at-rest encryption | `fips-mode-setup --enable` task + `aws_kms_key.mattermost` |
| SC-28 | Protection of Information at Rest | RDS, S3, EBS root volume all encrypted with the same KMS key | All resources in main.tf set `encrypted = true` / `storage_encrypted = true` |

## System and Information Integrity (SI)

| Control | Title | How it's satisfied | Evidence pointer |
|---|---|---|---|
| SI-2 | Flaw Remediation | Trivy scan on every build (Scenario 1), HIGH/CRITICAL block merge; OS patches via dnf-automatic security-only schedule | Scenario 1 workflow + dnf-automatic config (out of demo scope, called out in runbook) |
| SI-4 | System Monitoring | CloudWatch metrics on ALB/EC2/RDS; CloudWatch log forwarding to SIEM | Alarms (out of demo scope) |
| SI-7 | Software, Firmware, and Information Integrity | Trivy scan + Mattermost binary checksum verification in Ansible (`get_url` with `checksum:`) | Workflow YAML + ansible site.yml task |

## Notes

- This is the moderate-baseline subset most directly affected by the chat platform. The full SSP for a real engagement would address every applicable control even when the answer is "inherited from the cloud provider" or "not applicable to this system component."
- "Evidence pointer" is intentionally a path or artifact name, not prose. Assessors don't want to read about the control — they want to verify it.
- Several rows reference items "out of scope of this demo" (CloudWatch alarms, dnf-automatic, SAML config). Those are real production requirements; the demo does not implement them to keep the artifact set focused, and each is annotated rather than silently omitted.
