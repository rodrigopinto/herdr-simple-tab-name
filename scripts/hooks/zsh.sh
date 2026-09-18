# herdr-simple-tab-name: relabel the current tab with the folder + any
# running agent of its focused pane. Runs on chpwd (cd) and once at shell
# start, which is what labels a freshly created tab.
#
# Source this from ~/.zshrc:
#   [ -f "/path/to/herdr-simple-tab-name/scripts/hooks/zsh.sh" ] && source "/path/to/herdr-simple-tab-name/scripts/hooks/zsh.sh"

[ -n "${_TAB_NAMER_ZSH_LOADED:-}" ] && return
_TAB_NAMER_ZSH_LOADED=1

_tab_namer_plugin_id="rodrigopinto.simple-tab-name"
_tab_namer_dir="${${(%):-%x}:A:h:h}"

[ -f "$_tab_namer_dir/lib.sh" ] && source "$_tab_namer_dir/lib.sh"

# Resolve the plugin's user-settings dir once per shell (not per cd) so
# label_for_tab picks up the same config file it does when invoked as a
# Herdr event hook (see `herdr plugin config-dir rodrigopinto.simple-tab-name`).
if [ "${HERDR_ENV:-}" = 1 ] && [ -z "${HERDR_PLUGIN_CONFIG_DIR:-}" ]; then
  export HERDR_PLUGIN_CONFIG_DIR="$(${HERDR_BIN_PATH:-herdr} plugin config-dir "$_tab_namer_plugin_id" 2>/dev/null)"
fi

_herdr_tab_namer_update() {
  [ "${HERDR_ENV:-}" = 1 ] || return
  [ -n "${HERDR_TAB_ID:-}" ] || return
  [ -n "${HERDR_WORKSPACE_ID:-}" ] || return
  command -v jq >/dev/null 2>&1 || return
  typeset -f label_for_tab >/dev/null 2>&1 || return

  local herdr="${HERDR_BIN_PATH:-herdr}"
  local panes_json label
  panes_json=$("$herdr" pane list --workspace "$HERDR_WORKSPACE_ID" 2>/dev/null) || return
  label=$(label_for_tab "$panes_json" "$HERDR_TAB_ID")
  "$herdr" tab rename "$HERDR_TAB_ID" "$label" >/dev/null 2>&1
}

autoload -Uz add-zsh-hook 2>/dev/null && add-zsh-hook chpwd _herdr_tab_namer_update
_herdr_tab_namer_update
