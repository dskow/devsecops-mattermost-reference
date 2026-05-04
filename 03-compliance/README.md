# Scenario 3 — Compliance: RMF and STIG

**Goal:** Show the chat platform meets the controls and configuration baselines required to operate inside the Guard's network — and that the evidence is generated as a byproduct of the deployment, not assembled by hand the week before the assessment.

## What's here

| File | Purpose |
|---|---|
| [`nist-800-53-control-mapping.md`](nist-800-53-control-mapping.md) | Crosswalk from NIST SP 800-53 Rev. 5 controls to where each is satisfied in this stack (IaC, app config, OS hardening, runbook). The "evidence pointer" column tells an assessor exactly where to look. |
| [`stig-checklist-mattermost.md`](stig-checklist-mattermost.md) | DISA STIG-style findings table for the Mattermost application (V-IDs, severity, status, mitigation). Modeled on the Application Security and Development STIG plus Mattermost-specific items. |
| [`opa/mattermost-channel-policy.rego`](opa/mattermost-channel-policy.rego) | Open Policy Agent policy that denies channel-creation requests violating the program's data-handling rules (public channels under restricted teams, classified-marker mismatch, missing data owner). Wired into the channel provisioning step or run as a periodic auditor. |

## How this maps to RMF (briefly)

RMF expects six steps; this demo covers the technical side of three:

| RMF step | What this demo provides |
|---|---|
| **Categorize** | `data_classification` tag on every Terraform resource (CUI by default), feeds inventory tools |
| **Select** | NIST 800-53 control mapping picks the moderate-baseline controls and shows where they're addressed |
| **Implement** | Implementation lives in scenarios 1, 2, 4 — this folder is the *evidence* that implementation matches selection |
| **Assess** | The STIG checklist and OPA policy are the continuous-assessment instruments |
| **Authorize** | Out of scope for the demo (AO sign-off, formal package) |
| **Monitor** | Continuous monitoring covered by the OPA policy + the audit log shipping wired in by hardening role + the alert-tuning runbook |

## How this would actually run in production

- **STIG checklist as a CI gate.** The `.ckl` file (DISA-format) is regenerated nightly by running `stig-manager` or `OpenSCAP` against the deployed instance. Any new "Open" finding posts to `#sec-vuln-triage` (Scenario 1's webhook pattern, different channel).
- **OPA as an admission step.** The Rego policy runs in the Mattermost channel-provisioning Ansible play (Scenario 2) before the API call is made. Out-of-band channel creation by users is also fed through the same policy via an audit Lambda that watches the Mattermost audit log.
- **Evidence collection.** The `#compliance-evidence` private channel (provisioned in Scenario 2) is the dumping ground for screenshots, ARFs, POA&M items. It's restricted to ISSE/ISSO membership — the channel itself is part of the access-control evidence.

## What this demonstrates for the role

- Working knowledge of RMF and the NIST 800-53 control catalog beyond name-dropping
- Familiarity with DISA STIG format and how STIG findings get tracked vs. mitigated vs. accepted
- Policy-as-code mindset (OPA) for compliance that scales beyond manual review
