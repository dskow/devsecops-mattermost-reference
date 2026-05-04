# Security Policy

## Scope

This repository is a reference implementation. The artifacts here are not deployed in production by anyone — fixes for security issues here matter to the extent they prevent someone copying broken patterns into a real engagement.

## Reporting a vulnerability

If you find a security issue in this reference (insecure default, broken control mapping, hardening regression, dependency CVE), please report it privately rather than opening a public issue.

- **Preferred:** [GitHub private vulnerability report](https://github.com/dskow/devsecops-mattermost-reference/security/advisories/new)
- **Email:** david@dskow.com with subject line beginning `[security]`

I will acknowledge receipt within 5 business days. Triage and fix timelines depend on severity, but for a portfolio repo expect days, not weeks.

## What's in scope

- Insecure-by-default IaC (e.g. an ingress that exposes more than the README claims)
- Broken or misleading STIG/NIST control mappings
- OPA policy that fails to deny something it claims to deny
- Pipeline workflow that leaks secrets or misuses permissions
- Dependency CVE in pinned versions (when fixed upstream)

## What's out of scope

- "This is just a reference, not a real deployment" — yes, that's the README. If a pattern is unsafe enough that a copy-paste victim would be hurt by it, that's still in scope.
- "You should split into modules" — design feedback is welcome but not a vulnerability.
- Hypothetical issues that depend on a deployer ignoring the README's scope notes.

## Coordinated disclosure

If you'd like coordinated disclosure (you're publishing a writeup, advisory, talk), I'll work to a reasonable date together. Default is 30 days from report to public disclosure, longer if the fix is genuinely complex.
