#!/usr/bin/env bash
# Herdr startup hook: idempotently wires the shell hook into whichever shell
# rc files already exist, so `herdr plugin install` is the only manual step.
# Runs once per Herdr server start/session-restore for this enabled plugin
# (see the "Startup hooks" section of the Herdr plugins docs) and then exits;
# it does not itself relabel anything.
set -uo pipefail

plugin_id="${HERDR_PLUGIN_ID:-rodrigopinto.simple-tab-name}"
marker_begin="# >>> herdr-simple-tab-name >>>"
marker_end="# <<< herdr-simple-tab-name <<<"

# install_into <rc_file> <hook_path>
install_into() {
  local rc_file="$1" hook_file="$2"

  [ -f "$rc_file" ] || return 0
  grep -qF "$marker_begin" "$rc_file" 2>/dev/null && return 0

  {
    printf '\n%s\n' "$marker_begin"
    printf '# Managed by the herdr-simple-tab-name plugin; edits here are safe to\n'
    printf '# remove, but will come back on the next Herdr restart while installed.\n'
    printf 'if [ "${HERDR_ENV:-}" = 1 ]; then\n'
    printf '  _tab_namer_root="$(herdr plugin list --plugin %s --json 2>/dev/null | jq -r '"'"'.result.plugins[0].plugin_root // empty'"'"')"\n' "$plugin_id"
    printf '  [ -n "$_tab_namer_root" ] && [ -f "$_tab_namer_root/%s" ] && source "$_tab_namer_root/%s"\n' "$hook_file" "$hook_file"
    printf '  unset _tab_namer_root\n'
    printf 'fi\n'
    printf '%s\n' "$marker_end"
  } >> "$rc_file"
}

install_into "$HOME/.zshrc" "scripts/hooks/zsh.sh"
install_into "$HOME/.bashrc" "scripts/hooks/bash.sh"
install_into "$HOME/.bash_profile" "scripts/hooks/bash.sh"

exit 0
