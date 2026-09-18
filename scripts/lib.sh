# Shared helpers for tab-namer plugin scripts. Sourced, not executed.

herdr_bin() {
  printf '%s' "${HERDR_BIN_PATH:-herdr}"
}

# _tab_namer_config <default-var-name> <fallback-value>
# Reads a setting from $HERDR_PLUGIN_CONFIG_DIR/config (a plain shell file
# defining TAB_NAMER_* variables), falling back if unset or absent.
_tab_namer_config() {
  local var_name="$1" fallback="$2"

  if [ -n "${HERDR_PLUGIN_CONFIG_DIR:-}" ] && [ -f "$HERDR_PLUGIN_CONFIG_DIR/config" ]; then
    # shellcheck disable=SC1090
    source "$HERDR_PLUGIN_CONFIG_DIR/config"
  fi

  local value
  eval "value=\"\${$var_name:-}\""
  printf '%s' "${value:-$fallback}"
}

# icon_for_status <agent_status>
# Maps a Herdr AgentStatus (idle|working|blocked|done|unknown) to the glyph
# shown ahead of the label. These are Herdr's own status glyphs (see the
# "symbols" `status_indicators` style, e.g. src/client/shell.rs::status_icon
# in herdr itself) so a renamed tab reads as part of the app instead of a
# plugin pasting emoji on top of it. Raw ANSI codes aren't an option either
# way — Herdr renders tab labels as literal text, not a terminal stream — so
# a plain, single-width glyph also avoids emoji font/width inconsistencies
# across terminals. Idle and unknown stay silent by default so a quiet tab
# stays quiet.
icon_for_status() {
  local agent_status="$1"

  case "$agent_status" in
    done) _tab_namer_config TAB_NAMER_ICON_DONE "✓" ;;
    blocked) _tab_namer_config TAB_NAMER_ICON_BLOCKED "×" ;;
    working) _tab_namer_config TAB_NAMER_ICON_WORKING "◐" ;;
    idle) _tab_namer_config TAB_NAMER_ICON_IDLE "" ;;
    *) _tab_namer_config TAB_NAMER_ICON_UNKNOWN "" ;;
  esac
}

# label_for_tab <panes_json> <tab_id>
# panes_json: output of `herdr pane list --workspace <ws>`
# Prints "[<icon> ]<folder>" or "[<icon> ]<folder><separator><agent>" for the
# given tab, using its currently focused pane so a split tab has one
# unambiguous name instead of reflecting whichever pane last happened to
# change.
label_for_tab() {
  local panes_json="$1" tab_id="$2" row folder agent agent_status icon
  local separator show_agent show_status_icon

  separator=$(_tab_namer_config TAB_NAMER_SEPARATOR " · ")
  show_agent=$(_tab_namer_config TAB_NAMER_SHOW_AGENT "true")
  show_status_icon=$(_tab_namer_config TAB_NAMER_SHOW_STATUS_ICON "true")

  row=$(jq -r --arg t "$tab_id" --arg sep $'\x1f' '
    [.result.panes[]? | select(.tab_id == $t)] as $panes
    | ($panes | map(select(.focused == true))) as $focused
    | (if ($focused | length) > 0 then $focused[0] else $panes[0] end) as $pane
    | {
        cwd: ($pane.cwd // $pane.foreground_cwd),
        agent: (if $pane.agent != null then ($pane.display_agent // $pane.agent) else null end),
        status: ($pane.agent_status // "")
      }
    | [(.cwd // ""), (.agent // ""), (.status // "")]
    | join($sep)
  ' <<<"$panes_json")

  # \x1f (not a tab) so bash `read` doesn't collapse the empty middle field
  # when agent is unset — tab is "IFS whitespace" and runs of it get merged,
  # silently shifting status into agent's slot.
  IFS=$'\x1f' read -r folder agent agent_status <<<"$row"

  if [ -n "$folder" ]; then
    folder=$(basename -- "$folder")
  else
    folder="~"
  fi

  icon=""
  if [ "$show_status_icon" = "true" ] && [ -n "$agent_status" ]; then
    icon=$(icon_for_status "$agent_status")
  fi

  local label
  if [ "$show_agent" = "true" ] && [ -n "$agent" ]; then
    label=$(printf '%s%s%s' "$folder" "$separator" "$agent")
  else
    label="$folder"
  fi

  if [ -n "$icon" ]; then
    printf '%s %s' "$icon" "$label"
  else
    printf '%s' "$label"
  fi
}
