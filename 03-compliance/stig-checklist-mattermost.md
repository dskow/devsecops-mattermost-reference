# Mattermost STIG Checklist (Excerpt)

Findings table format mirrors the DISA STIG Viewer `.ckl` summary. Severity follows DISA convention: CAT I (high), CAT II (medium), CAT III (low). Status: `Open`, `NotAFinding`, `Not_Applicable`, `Not_Reviewed`.

The Mattermost server has no DISA-published STIG of its own at the time of writing, so the application-layer items are derived from the **Application Security and Development STIG** (V-222xxx series) and **General Web Server STIG** as applicable. OS items reference the **RHEL 8 STIG** and are addressed by the Ansible hardening role.

## Application layer (Mattermost)

| Vul-ID | CAT | Title | Status | Mitigation / Evidence |
|---|---|---|---|---|
| MM-001 | I | TLS 1.2 or higher required for all client connections | NotAFinding | ALB listener policy `ELBSecurityPolicy-TLS13-1-2-2021-06`; HTTP listener returns 308 redirect to HTTPS |
| MM-002 | I | Database connection must use TLS | NotAFinding | `config.json` `SqlSettings.DataSource` includes `sslmode=require`; RDS parameter group requires SSL |
| MM-003 | II | Idle session timeout must be configured | NotAFinding | `config.json` `ServiceSettings.SessionLengthWebInDays=1`, `SessionIdleTimeoutInMinutes=15` |
| MM-004 | II | Local password authentication must be disabled when SSO is configured | NotAFinding | `config.json` `EmailSettings.EnableSignInWithEmail=false` once SAML is configured; break-glass admin documented |
| MM-005 | II | Audit log must be enabled and forwarded off-host | NotAFinding | `config.json` `ExperimentalAuditSettings` enabled; CloudWatch Agent forwards `/opt/mattermost/logs/audit.log` |
| MM-006 | II | File uploads must be scanned for malware | Open | Plan: introduce ClamAV sidecar with Mattermost plugin `mattermost-plugin-antivirus`. Tracked in POA&M item PRG-MM-006, target Q3 |
| MM-007 | II | Public file links must be disabled | NotAFinding | `config.json` `FileSettings.EnablePublicLink=false` |
| MM-008 | III | Login banner must display DoD warning | NotAFinding | `config.json` `AnnouncementSettings.BannerText` set to DoD warning; banner enforced before login |
| MM-009 | I | Account lockout after failed login attempts | NotAFinding | `config.json` `ServiceSettings.MaximumLoginAttempts=10` (matches OS-level pam_faillock) |
| MM-010 | II | Webhook URLs must not be discoverable via channel listing API to non-members | NotAFinding | Default Mattermost behavior; verified via API test in [`scripts/verify-mm-010.sh`] (out of demo) |

## Operating system layer (RHEL 8)

These map directly to tasks in the Ansible hardening role. Spot-check shown — full RHEL 8 STIG has 350+ items.

| Vul-ID | CAT | Title | Status | Where addressed |
|---|---|---|---|---|
| V-230223 | II | RHEL 8 must enable FIPS mode | NotAFinding | `mattermost_hardening` `Enable FIPS mode` task |
| V-230229 | I | RHEL 8 must not have any unauthorized SUID/SGID files | Not_Reviewed | Outside Ansible scope; baseline AMI is STIG-hardened, drift checked weekly by OpenSCAP |
| V-230331 | II | RHEL 8 must disable root SSH login | NotAFinding | `mattermost_hardening` `Disable root SSH login` task |
| V-230333 | II | RHEL 8 must require public key authentication for SSH | NotAFinding | `mattermost_hardening` `Disable SSH password authentication` task |
| V-230364 | II | RHEL 8 must enforce minimum password length of 15 | NotAFinding | `mattermost_hardening` pwquality task (`minlen=15`) |
| V-230469 | II | RHEL 8 must audit account modification events | NotAFinding | `mattermost_hardening` `50-stig.rules` (identity key) |
| V-230503 | II | RHEL 8 must use fapolicyd for application allow-listing | NotAFinding | `mattermost_hardening` fapolicyd install + enable |
| V-244549 | II | RHEL 8 must restrict use of `dmesg` to root | NotAFinding | `mattermost_hardening` `kernel.dmesg_restrict=1` sysctl |

## Findings summary (this excerpt)

| Severity | Open | NotAFinding | Not_Reviewed | Not_Applicable |
|---|---|---|---|---|
| CAT I | 0 | 4 | 1 | 0 |
| CAT II | 1 | 11 | 0 | 0 |
| CAT III | 0 | 1 | 0 | 0 |

## Open findings — POA&M

| ID | Vul-ID | Description | Risk | Target | Owner |
|---|---|---|---|---|---|
| PRG-MM-006 | MM-006 | File uploads not scanned for malware | Medium — restricted file-type allowlist mitigates in interim | 2026-Q3 | DevSecOps lead |

## How this gets refreshed

The `.ckl` file is regenerated via:

```bash
# OS layer — OpenSCAP against RHEL 8 STIG profile
oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_stig \
  --results-arf arf.xml --report report.html \
  /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml

# Application layer — manual checklist updated quarterly or on Mattermost upgrade
```

Both runs land their output in `#compliance-evidence` for ISSE review. New "Open" findings auto-create an issue in the program's tracker and post a summary to `#sec-vuln-triage`.
