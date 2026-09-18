#!/usr/bin/env bash
# Herdr event hook: relabels a tab as "[<icon> ]<folder>" or
# "[<icon> ]<folder> · <agent>". Fired on pane.agent_detected (an agent
# appears in, or leaves, a pane), pane.focused, and pane.agent_status_changed
# (idle/working/blocked/done transitions, so the status icon stays current).
set -uo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")" || exit 0
source ./lib.sh

herdr=$(herdr_bin)
event_json="${HERDR_PLUGIN_EVENT_JSON:-}"

command -v jq >/dev/null 2>&1 || exit 0
[ -n "$event_json" ] || exit 0

pane_id=$(jq -r '.data.pane_id // empty' <<<"$event_json")
workspace_id=$(jq -r '.data.workspace_id // empty' <<<"$event_json")
[ -z "$pane_id" ] && pane_id="${HERDR_PANE_ID:-}"
[ -z "$workspace_id" ] && workspace_id="${HERDR_WORKSPACE_ID:-}"
[ -n "$pane_id" ] && [ -n "$workspace_id" ] || exit 0

panes_json=$("$herdr" pane list --workspace "$workspace_id" 2>/dev/null) || exit 0

tab_id=$(jq -r --arg p "$pane_id" '.result.panes[]? | select(.pane_id == $p) | .tab_id' <<<"$panes_json" | head -n1)
[ -n "$tab_id" ] || exit 0

label=$(label_for_tab "$panes_json" "$tab_id")
"$herdr" tab rename "$tab_id" "$label" >/dev/null 2>&1
