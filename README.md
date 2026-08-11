# satellite-menu

Interactive admin menu for Red Hat Satellite servers. Wraps `satellite-maintain`, `hammer`, and `foreman-rake` commands behind a navigable terminal menu that shows every command before execution — so operators learn the CLI while using the shortcut.

```
╔══════════════════════════════════════════════╗
║       Red Hat Satellite Admin Menu           ║
╠══════════════════════════════════════════════╣
║  sat-01.example.com                          ║
║  Satellite 6.19.3  |  Org ID: 1              ║
║  No updates available                        ║
╚══════════════════════════════════════════════╝
```

## Design Philosophy

- **Transparency over convenience.** Every destructive or mutating command is displayed in full before confirmation. The menu teaches the CLI — it doesn't hide it.
- **No wrappers, no restricted shell.** Commands run in the foreground with full live output. When they finish, you return to the menu.
- **Keystroke reduction, not knowledge replacement.** Same principle as typing the commands yourself, minus the memorization and typos.

## Features

| Menu | What It Covers |
|---|---|
| Service Management | Start, stop, restart, status via `satellite-maintain service` |
| Maintenance Mode | Start, stop, status — blocks port 443 to lock out users during work |
| Health Check | `satellite-maintain health check` |
| Package Protection | Lock, unlock, status, check-update via `satellite-maintain packages` |
| Update | Patch current version — check and run via `satellite-maintain update` |
| Upgrade | Major version upgrade with target version prompt and backup warning |
| Backup & Restore | Offline/online backup, restore with dry-run option |
| Content Management | List/sync/publish/promote content views, lifecycle environments |
| Capsule Status | List capsules, sync status per capsule |
| Host Overview | List hosts, errata status, hammer search |
| Task Monitor | Running, failed, and paused tasks via `hammer task list` |
| DB Maintenance | Expire/anonymize audit records, expire reports, clean tasks, deploy automated maintenance cron |
| Reports | Generate usage and condensed reports |
| Hammer Shell | Interactive `hammer shell` session |

Additional header features:

- Satellite version detected from RPM at startup
- Organization ID displayed (configurable)
- Update availability checked via `yum check-update` at launch (cached for session)

## Requirements

- Red Hat Satellite 6.x (tested on 6.19)
- Root access
- `satellite-maintain` and `hammer` CLI available

## Installation

```bash
# Copy the script
sudo cp satellite-menu.sh /usr/local/bin/satellite-menu.sh
sudo chmod +x /usr/local/bin/satellite-menu.sh

# Run it
satellite-menu.sh
```

### Optional: Auto-launch on SSH login

Add to the target user's `~/.bashrc`:

```bash
# Satellite admin menu on SSH login
if [[ -n $SSH_CONNECTION && -z $SATELLITE_MENU_RAN && $- == *i* ]]; then
    export SATELLITE_MENU_RAN=1
    /usr/local/bin/satellite-menu.sh
fi
```

This only triggers on interactive SSH sessions and will not interfere with `scp`, `sftp`, or non-interactive commands.

## Configuration

### Organization ID

Defaults to `1`. Override per-session with an environment variable:

```bash
SATELLITE_MENU_ORG_ID=2 satellite-menu.sh
```

Or edit the `ORG_ID` variable in the script. Verify your org ID with:

```bash
hammer organization list
```

### DB Maintenance Cron

The menu can deploy an automated cron job (`/etc/cron.d/satellite-db-maintenance`) that runs weekly to expire old audit and report records. This supplements the built-in task auto-cleanup (`/etc/cron.d/foreman-tasks`) which only handles `foreman_tasks`.

Use **DB Maintenance > Deploy DB Maintenance Cron** to configure retention days and deploy.

## Safety

- Read-only operations (status, list, check) execute immediately
- Mutating operations (restart, stop, update, backup, publish, promote) require explicit confirmation
- All submenus stay open after each action — run multiple commands without bouncing back to the main menu. Select "Back" to return.
- Every confirmation shows the exact command that will run:

```
  Command:  satellite-maintain service restart

Run this command? [y/N]:
```

- Root check at startup prevents accidental execution as non-root
- `satellite-maintain` guard prevents running on non-Satellite systems

## Known Limitations

- `hammer --fields` syntax may vary between Satellite versions — if field names error, adjust to match your release
- Update check at startup uses `yum check-update` which adds a few seconds to launch
- No automated major upgrade version detection — `satellite-maintain upgrade list-versions` was removed in recent Satellite releases
- The SCA (Simple Content Access) subscription model may cause `yum check-update` to emit a misleading "not receiving updates" warning — this does not affect functionality

## License

MIT
