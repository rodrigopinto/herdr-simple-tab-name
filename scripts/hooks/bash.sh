# herdr-simple-tab-name: relabel the current tab with the folder + any
# running agent of its focused pane. Bash has no native chpwd hook, so this
# checks $PWD via PROMPT_COMMAND (only doing work when it actually changed)
# and once at shell start, which is what labels a freshly created tab.
#
# Source this from ~/.bashrc (or ~/.bash_profile on macOS, where login
# shells don't read ~/.bashrc unless it's sourced from there):
#   [ -f "/path/to/herdr-simple-tab-name/scripts/hooks/bash.sh" ] && source "/path/to/herdr-simple-tab-name/scripts/hooks/bash.sh"

[ -n "${_TAB_NAMER_BASH_LOADED:-}" ] && return
_TAB_NAMER_BASH_LOADED=1

_tab_namer_plugin_id="rodrigopinto.simple-tab-name"
_tab_namer_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

[ -f "$_tab_namer_dir/lib.sh" ] && source "$_tab_namer_dir/lib.sh"

# Resolve the plugin's user-settings dir once per shell (not per prompt) so
# label_for_tab picks up the same config file it does when invoked as a
# Herdr event hook (see `herdr plugin config-dir rodrigopinto.simple-tab-name`).
if [ "${HERDR_ENV:-}" = 1 ] && [ -z "${HERDR_PLUGIN_CONFIG_DIR:-}" ]; then
  export HERDR_PLUGIN_CONFIG_DIR="$(${HERDR_BIN_PATH:-herdr} plugin config-dir "$_tab_namer_plugin_id" 2>/dev/null)"
fi

_tab_namer_last_pwd=""

_herdr_tab_namer_update() {
  [ "${HERDR_ENV:-}" = 1 ] || return
  [ -n "${HERDR_TAB_ID:-}" ] || return
  [ -n "${HERDR_WORKSPACE_ID:-}" ] || return
  [ "$PWD" = "$_tab_namer_last_pwd" ] && return
  _tab_namer_last_pwd="$PWD"
  command -v jq >/dev/null 2>&1 || return
  declare -F label_for_tab >/dev/null 2>&1 || return

  local herdr="${HERDR_BIN_PATH:-herdr}"
  local panes_json label
  panes_json=$("$herdr" pane list --workspace "$HERDR_WORKSPACE_ID" 2>/dev/null) || return
  label=$(label_for_tab "$panes_json" "$HERDR_TAB_ID")
  "$herdr" tab rename "$HERDR_TAB_ID" "$label" >/dev/null 2>&1
}

case ";${PROMPT_COMMAND:-};" in
  *";_herdr_tab_namer_update;"*) ;;
  *) PROMPT_COMMAND="_herdr_tab_namer_update${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac

_herdr_tab_namer_update
