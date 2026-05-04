# Mattermost channel-creation admission policy.
#
# Inputs (passed by the calling Ansible task or the audit-log webhook Lambda):
#   input.action        — "create" | "update"
#   input.channel.name
#   input.channel.display_name
#   input.channel.type  — "O" (open) | "P" (private)
#   input.channel.team  — team name
#   input.channel.purpose
#   input.channel.header
#   input.channel.creator_email
#
# A request is admitted when `deny` is empty.
#
# To test:
#   opa eval -d mattermost-channel-policy.rego -i sample-input.json "data.mattermost.channel.deny"
#
# Wire-up: see ../README.md "OPA as an admission step".

package mattermost.channel

import rego.v1

# Teams that may not contain open (`O`) channels. Anything in these teams must be private.
restricted_teams := {"program-leadership", "incident-response-active"}

# Approved classification markers that must appear in `purpose` or `header`.
classification_markers := {"UNCLASSIFIED", "CUI", "FOUO"}

# Channel names matching this pattern require a named data owner in `purpose`.
sensitive_name_pattern := `(?i)(audit|finance|legal|leadership|compliance|incident)`

# -----------------------------------------------------------------------------
# Rule 1: open channels are forbidden inside restricted teams
# -----------------------------------------------------------------------------

deny contains msg if {
    input.action == "create"
    input.channel.type == "O"
    restricted_teams[input.channel.team]
    msg := sprintf(
        "channel '%s' is type=O (open) but team '%s' only allows private (type=P) channels",
        [input.channel.name, input.channel.team],
    )
}

# -----------------------------------------------------------------------------
# Rule 2: every channel purpose or header must include a classification marker
# -----------------------------------------------------------------------------

deny contains msg if {
    input.action == "create"
    not has_classification_marker
    msg := sprintf(
        "channel '%s' must declare a classification marker (one of: %v) in purpose or header",
        [input.channel.name, classification_markers],
    )
}

has_classification_marker if {
    some marker in classification_markers
    contains(input.channel.purpose, marker)
}

has_classification_marker if {
    some marker in classification_markers
    contains(input.channel.header, marker)
}

# -----------------------------------------------------------------------------
# Rule 3: sensitive-named channels must list a data owner
# -----------------------------------------------------------------------------

deny contains msg if {
    input.action == "create"
    regex.match(sensitive_name_pattern, input.channel.name)
    not data_owner_present
    msg := sprintf(
        "channel '%s' name suggests sensitive content; purpose must contain 'Owner: <name>'",
        [input.channel.name],
    )
}

data_owner_present if {
    regex.match(`Owner:\s*\S+`, input.channel.purpose)
}

# -----------------------------------------------------------------------------
# Rule 4: classification mismatch — channel marked higher than team allows
# -----------------------------------------------------------------------------

# For demo purposes we treat anything not in the cyber-ops team as "U/CUI only".
# In practice the team-to-classification mapping comes from a customer data file.

deny contains msg if {
    input.action == "create"
    input.channel.team != "cyber-ops"
    contains(input.channel.purpose, "SECRET")
    msg := sprintf(
        "channel '%s' references SECRET but team '%s' is approved for UNCLASSIFIED/CUI only",
        [input.channel.name, input.channel.team],
    )
}
