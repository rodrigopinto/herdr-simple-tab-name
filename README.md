# Herdr Simple Tab Name

Keep [Herdr](https://herdr.dev) tab names useful at a glance. This plugin names
each tab after the focused pane's current directory and, when present, its
running agent and status:

```text
myproject
myproject · claude
✓ myproject · claude
```

## Features

- Renames a tab when its shell starts or changes directory.
- Tracks the focused pane in split tabs.
- Adds the detected agent's display name.
- Refreshes when an agent starts, exits, or changes status.
- Uses Herdr-style status symbols and allows every label component to be
  configured.
- Installs its Bash and Zsh hooks without requiring manual dotfile edits.

## Requirements

- [Herdr](https://herdr.dev) 0.7.0 or newer
- [`jq`](https://jqlang.github.io/jq/)
- Linux or macOS
- Bash
- Zsh only when using the Zsh directory-change hook

Other shells still receive updates from Herdr events, including agent, pane
focus, and status changes. They do not currently receive immediate updates
when `cd` changes the current directory.

## Install

```sh
herdr plugin install rodrigopinto/herdr-simple-tab-name
```

The plugin's startup hook adds a small, idempotent source block to any existing
`~/.zshrc`, `~/.bashrc`, and `~/.bash_profile` files.

> [!IMPORTANT]
> Herdr runs startup hooks when its **server** starts or restores a session,
> not when a plugin is merely installed or enabled. After installation, run:
>
> ```sh
> herdr server stop
> ```
>
> Starting `herdr` again restores the session and installs the shell hooks.
> Opening another terminal only attaches to the existing server and does not
> run the startup hook.

## Configuration

Find the plugin's configuration directory with:

```sh
herdr plugin config-dir rodrigopinto.simple-tab-name
```

Create a file named `config` in that directory. It is sourced as shell code,
so use normal shell assignments:

```sh
# Text between the directory and agent names.
TAB_NAMER_SEPARATOR=" · "

# Toggle optional label components.
TAB_NAMER_SHOW_AGENT="true"
TAB_NAMER_SHOW_STATUS_ICON="true"

# Symbols used for each agent status.
TAB_NAMER_ICON_DONE="✓"
TAB_NAMER_ICON_BLOCKED="×"
TAB_NAMER_ICON_WORKING="◐"
TAB_NAMER_ICON_IDLE=""
TAB_NAMER_ICON_UNKNOWN=""
```

These are the defaults. Changes apply immediately; no plugin reinstall or
server restart is required.

## How it works

Herdr events handle changes that the plugin API exposes:

- `pane.agent_detected`
- `pane.focused`
- `pane.agent_status_changed`

Herdr does not currently expose a current-directory-change event. The plugin
therefore uses each shell's native mechanism: Zsh's `chpwd` hook and a guarded
Bash `PROMPT_COMMAND`. The Bash hook only contacts Herdr when `$PWD` changes.

### Shell support and file naming

All scripts use the `.sh` extension for consistent repository naming. The
extension does not imply that every file is POSIX `sh` compatible:

- `scripts/install.sh` and `scripts/rename-tab.sh` run under Bash.
- `scripts/lib.sh` is shared by both supported shells.
- `scripts/hooks/bash.sh` is sourced by Bash.
- `scripts/hooks/zsh.sh` is sourced by Zsh.

Separate hook implementations are necessary because Bash and Zsh provide
different APIs for reacting to directory changes. Keeping the shell name in
each filename makes that requirement explicit while retaining one `.sh`
convention throughout the project.

## Local development

Clone the repository and link the checkout into Herdr:

```sh
git clone https://github.com/rodrigopinto/herdr-simple-tab-name.git
cd herdr-simple-tab-name
herdr plugin link "$PWD"
herdr server stop
```

While iterating, you can source the appropriate hook directly instead of
restarting the server:

```sh
# Bash
source /path/to/herdr-simple-tab-name/scripts/hooks/bash.sh

# Zsh
source /path/to/herdr-simple-tab-name/scripts/hooks/zsh.sh
```

## Project layout

| File | Purpose |
| --- | --- |
| `herdr-plugin.toml` | Plugin metadata, startup hook, and event hooks |
| `scripts/install.sh` | Adds the appropriate hook to existing shell startup files |
| `scripts/rename-tab.sh` | Handles Herdr events and renames the affected tab |
| `scripts/lib.sh` | Shared configuration and label-building functions |
| `scripts/hooks/bash.sh` | Bash directory-change integration |
| `scripts/hooks/zsh.sh` | Zsh directory-change integration |

## Platform support

Windows is not currently supported. The event scripts require Bash, and the
directory-change hooks require Bash or Zsh; Herdr does not provide or resolve
those shells on Windows. The plugin manifest therefore supports only `linux`
and `macos`.

## Contributing

[Bug reports](https://github.com/rodrigopinto/herdr-simple-tab-name/issues)
and pull requests are welcome. Please include your operating system, shell,
Herdr version, and reproduction steps when reporting an issue. For code
changes, keep shell-specific behavior in the appropriate hook and shared label
logic in `scripts/lib.sh`.
