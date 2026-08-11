#!/bin/bash
# ============================================================================
# satellite-menu.sh — Red Hat Satellite Admin Menu
# Launches real commands in the foreground. No wrappers, no restricted shell.
# ============================================================================

set -o pipefail

# --- Guards ---
[[ $EUID -eq 0 ]] || { echo "ERROR: This menu should be run as root."; exit 1; }

command -v satellite-maintain >/dev/null 2>&1 || {
    echo "ERROR: satellite-maintain not found. Are you on a Satellite server?"
    exit 1
}

# --- Configuration ---
# Change this if your organization ID is not 1
# Verify with: hammer organization list
ORG_ID="${SATELLITE_MENU_ORG_ID:-1}"

# Cache Satellite version once at startup
SAT_VERSION=$(rpm -q --qf '%{VERSION}' satellite 2>/dev/null || echo "unknown")

# Check for available dot updates at startup (runs once, cached for session)
echo "Checking for available updates..."
UPDATE_STATUS="No updates available"
AVAIL_UPDATE=$(yum check-update satellite 2>/dev/null | grep -i "^satellite\b" | awk '{print $2}')
if [[ -n "$AVAIL_UPDATE" ]]; then
    UPDATE_STATUS="Update available: ${AVAIL_UPDATE}"
fi

# --- Helpers ---
pause() { echo; read -rp "Press Enter to return to menu..."; }

confirm_cmd() {
    # Show the exact command, then confirm
    local cmd="$1"
    echo
    echo "  Command:  $cmd"
    echo
    read -rp "Run this command? [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

header() {
    clear
    echo "╔══════════════════════════════════════════════╗"
    echo "║       Red Hat Satellite Admin Menu           ║"
    echo "╠══════════════════════════════════════════════╣"
    printf "║  %-44s║\n" "$(hostname -f)"
    printf "║  %-44s║\n" "Satellite $SAT_VERSION  |  Org ID: $ORG_ID"
    printf "║  %-44s║\n" "$UPDATE_STATUS"
    echo "╚══════════════════════════════════════════════╝"
    echo
}

run_cmd() {
    echo ">>> $*"
    echo "────────────────────────────────────────────────"
    "$@"
    local rc=$?
    echo "────────────────────────────────────────────────"
    [[ $rc -ne 0 ]] && echo "Exit code: $rc"
    return $rc
}

# ═══════════════════════════════════════════════
# Main Menu
# ═══════════════════════════════════════════════
menu_main() {
    local PS3=$'\nSelect [1-16, q to quit]: '
    local options=(
        "Service Management"
        "Maintenance Mode"
        "Health Check"
        "Package Protection"
        "Update (patch current version)"
        "Upgrade (major version)"
        "Backup & Restore"
        "Content Management"
        "Capsule Status"
        "Host Overview"
        "Task Monitor"
        "DB Maintenance"
        "Reports"
        "Hammer Shell (interactive)"
        "Drop to Normal Shell"
        "Quit"
    )

    select opt in "${options[@]}"; do
        case $REPLY in
            1)  menu_services;       break ;;
            2)  menu_maintenance;    break ;;
            3)  run_cmd satellite-maintain health check; pause; break ;;
            4)  menu_packages;       break ;;
            5)  menu_update;         break ;;
            6)  menu_upgrade;        break ;;
            7)  menu_backup;         break ;;
            8)  menu_content;        break ;;
            9)  menu_capsules;       break ;;
            10) menu_hosts;          break ;;
            11) menu_tasks;          break ;;
            12) menu_db_maintenance; break ;;
            13) menu_reports;        break ;;
            14) echo "Type 'exit' to return to menu."
                hammer shell
                break ;;
            15) echo "Dropping to shell. Run 'satellite-menu.sh' to return."
                exec "$SHELL" ;;
            16|q|Q) echo "Exiting."; exit 0 ;;
            *)  echo "Invalid option" ;;
        esac
    done
}

# ═══════════════════════════════════════════════
# Service Management
# ═══════════════════════════════════════════════
menu_services() {
    header
    echo "── Service Management ──"
    local PS3=$'\nSelect: '
    local options=("Service Status" "Restart All Services" "Stop All Services" "Start All Services" "Back")
    select opt in "${options[@]}"; do
        case $REPLY in
            1) run_cmd satellite-maintain service status ;;
            2) confirm_cmd "satellite-maintain service restart" && run_cmd satellite-maintain service restart ;;
            3) confirm_cmd "satellite-maintain service stop" && run_cmd satellite-maintain service stop ;;
            4) run_cmd satellite-maintain service start ;;
            5) return ;;
            *) echo "Invalid option" ;;
        esac
        pause
    done
}

# ═══════════════════════════════════════════════
# Maintenance Mode
# ═══════════════════════════════════════════════
menu_maintenance() {
    header
    echo "── Maintenance Mode ──"
    local PS3=$'\nSelect: '
    local options=("Status" "Start Maintenance Mode" "Stop Maintenance Mode" "Back")
    select opt in "${options[@]}"; do
        case $REPLY in
            1) run_cmd satellite-maintain maintenance-mode status ;;
            2) confirm_cmd "satellite-maintain maintenance-mode start" && \
               run_cmd satellite-maintain maintenance-mode start ;;
            3) confirm_cmd "satellite-maintain maintenance-mode stop" && \
               run_cmd satellite-maintain maintenance-mode stop ;;
            4) return ;;
            *) echo "Invalid option" ;;
        esac
        pause
    done
}

# ═══════════════════════════════════════════════
# Package Protection
# ═══════════════════════════════════════════════
menu_packages() {
    header
    echo "── Package Protection ──"
    local PS3=$'\nSelect: '
    local options=(
        "Package Lock Status"
        "Check for Available Updates"
        "Lock Packages"
        "Unlock Packages"
        "Back"
    )
    select opt in "${options[@]}"; do
        case $REPLY in
            1) run_cmd satellite-maintain packages status ;;
            2) run_cmd satellite-maintain packages check-update ;;
            3) confirm_cmd "satellite-maintain packages lock" && \
               run_cmd satellite-maintain packages lock ;;
            4) confirm_cmd "satellite-maintain packages unlock" && \
               run_cmd satellite-maintain packages unlock ;;
            5) return ;;
            *) echo "Invalid option" ;;
        esac
        pause
    done
}

# ═══════════════════════════════════════════════
# Update (patch current version)
# ═══════════════════════════════════════════════
menu_update() {
    header
    echo "── Update (Patch Current Version) ──"
    local PS3=$'\nSelect: '
    local options=(
        "Check for Updates (dry run)"
        "Run Satellite Update"
        "Back"
    )
    select opt in "${options[@]}"; do
        case $REPLY in
            1) run_cmd satellite-maintain update check ;;
            2) confirm_cmd "satellite-maintain update run" && \
               run_cmd satellite-maintain update run ;;
            3) return ;;
            *) echo "Invalid option" ;;
        esac
        pause
    done
}

# ═══════════════════════════════════════════════
# Upgrade (major version)
# ═══════════════════════════════════════════════
menu_upgrade() {
    header
    echo "── Upgrade (Major Version) ──"
    echo
    echo "NOTE: This upgrades Satellite to a new major version."
    echo "Ensure you have a verified backup before proceeding."
    echo
    local PS3=$'\nSelect: '
    local options=(
        "Pre-upgrade Check"
        "Run Upgrade"
        "Back"
    )
    select opt in "${options[@]}"; do
        case $REPLY in
            1)
                read -rp "Target version (e.g. 6.16): " ver
                [[ -n "$ver" ]] && run_cmd satellite-maintain upgrade check --target-version "$ver"
                ;;
            2)
                read -rp "Target version (e.g. 6.16): " ver
                [[ -n "$ver" ]] && confirm_cmd "satellite-maintain upgrade run --target-version $ver" && \
                    run_cmd satellite-maintain upgrade run --target-version "$ver"
                ;;
            3) return ;;
            *) echo "Invalid option" ;;
        esac
        pause
    done
}

# ═══════════════════════════════════════════════
# Backup & Restore
# ═══════════════════════════════════════════════
menu_backup() {
    header
    echo "── Backup & Restore ──"
    local PS3=$'\nSelect: '
    local options=(
        "Offline Backup"
        "Online Backup"
        "Restore (dry run)"
        "Restore"
        "Back"
    )
    select opt in "${options[@]}"; do
        case $REPLY in
            1|2)
                read -rp "Backup directory [/var/satellite-backup]: " bdir
                bdir="${bdir:-/var/satellite-backup}"
                mkdir -p "$bdir"
                if [[ $REPLY -eq 1 ]]; then
                    confirm_cmd "satellite-maintain backup offline $bdir" && \
                    run_cmd satellite-maintain backup offline "$bdir"
                else
                    confirm_cmd "satellite-maintain backup online $bdir" && \
                    run_cmd satellite-maintain backup online "$bdir"
                fi
                ;;
            3)
                read -rp "Backup directory to restore from: " rdir
                [[ -n "$rdir" ]] && run_cmd satellite-maintain restore "$rdir" --dry-run
                ;;
            4)
                read -rp "Backup directory to restore from: " rdir
                if [[ -n "$rdir" ]]; then
                    confirm_cmd "satellite-maintain restore $rdir" && \
                    run_cmd satellite-maintain restore "$rdir"
                fi
                ;;
            5) return ;;
            *) echo "Invalid option" ;;
        esac
        pause
    done
}

# ═══════════════════════════════════════════════
# Content Management
# ═══════════════════════════════════════════════
menu_content() {
    header
    echo "── Content Management ──"
    local PS3=$'\nSelect: '
    local options=(
        "List Content Views"
        "List Sync Status (all repos)"
        "Sync a Product"
        "Publish a Content View"
        "Promote a Content View Version"
        "List Lifecycle Environments"
        "Back"
    )
    select opt in "${options[@]}"; do
        case $REPLY in
            1) run_cmd hammer content-view list --organization-id "$ORG_ID" ;;
            2) run_cmd hammer repository list --organization-id "$ORG_ID" --fields "id,name,product,sync state" ;;
            3)
                run_cmd hammer product list --organization-id "$ORG_ID" --fields "id,name"
                echo
                read -rp "Product ID to sync: " pid
                [[ -n "$pid" ]] && run_cmd hammer product synchronize --id "$pid" --organization-id "$ORG_ID"
                ;;
            4)
                run_cmd hammer content-view list --organization-id "$ORG_ID" --fields "id,name,composite"
                echo
                read -rp "Content View ID to publish: " cvid
                [[ -n "$cvid" ]] && confirm_cmd "hammer content-view publish --id $cvid --organization-id $ORG_ID" && \
                    run_cmd hammer content-view publish --id "$cvid" --organization-id "$ORG_ID"
                ;;
            5)
                run_cmd hammer content-view list --organization-id "$ORG_ID" --fields "id,name"
                echo
                read -rp "Content View ID: " cvid
                if [[ -n "$cvid" ]]; then
                    run_cmd hammer content-view version list --content-view-id "$cvid" --fields "id,version,lifecycle-environments"
                    echo
                    read -rp "Version ID to promote: " vid
                    read -rp "Target Lifecycle Environment ID: " leid
                    [[ -n "$vid" && -n "$leid" ]] && confirm_cmd "hammer content-view version promote --id $vid --to-lifecycle-environment-id $leid --organization-id $ORG_ID" && \
                        run_cmd hammer content-view version promote --id "$vid" --to-lifecycle-environment-id "$leid" --organization-id "$ORG_ID"
                fi
                ;;
            6) run_cmd hammer lifecycle-environment list --organization-id "$ORG_ID" ;;
            7) return ;;
            *) echo "Invalid option" ;;
        esac
        pause
    done
}

# ═══════════════════════════════════════════════
# Capsule Status
# ═══════════════════════════════════════════════
menu_capsules() {
    header
    echo "── Capsule Status ──"
    local PS3=$'\nSelect: '
    local options=("List Capsules" "Capsule Sync Status" "Back")
    select opt in "${options[@]}"; do
        case $REPLY in
            1) run_cmd hammer capsule list ;;
            2)
                run_cmd hammer capsule list --fields "id,name"
                echo
                read -rp "Capsule ID: " cid
                [[ -n "$cid" ]] && run_cmd hammer capsule content lifecycle-environments \
                    --id "$cid"
                ;;
            3) return ;;
            *) echo "Invalid option" ;;
        esac
        pause
    done
}

# ═══════════════════════════════════════════════
# Host Overview
# ═══════════════════════════════════════════════
menu_hosts() {
    header
    echo "── Host Overview ──"
    local PS3=$'\nSelect: '
    local options=(
        "List All Hosts"
        "Hosts with Available Errata"
        "Search Hosts"
        "Back"
    )
    select opt in "${options[@]}"; do
        case $REPLY in
            1) run_cmd hammer host list --per-page 50 --fields "id,name,operating system,ip" ;;
            2) run_cmd hammer host list --search "applicable_errata > 0" \
                 --fields "id,name,applicable errata count" ;;
            3)
                read -rp "Search string (hammer syntax): " squery
                [[ -n "$squery" ]] && run_cmd hammer host list --search "$squery"
                ;;
            4) return ;;
            *) echo "Invalid option" ;;
        esac
        pause
    done
}

# ═══════════════════════════════════════════════
# Task Monitor
# ═══════════════════════════════════════════════
menu_tasks() {
    header
    echo "── Task Monitor ──"
    local PS3=$'\nSelect: '
    local options=(
        "Running Tasks"
        "Recent Failed Tasks (last 24h)"
        "Paused Tasks"
        "Back"
    )
    select opt in "${options[@]}"; do
        case $REPLY in
            1) run_cmd hammer task list --search "state = running" --per-page 20 \
                 --fields "id,action,state,result,started at" ;;
            2) run_cmd hammer task list --search "state = stopped and result = error" \
                 --order "started_at DESC" --per-page 20 \
                 --fields "id,action,result,started at" ;;
            3) run_cmd hammer task list --search "state = paused" --per-page 20 \
                 --fields "id,action,state,started at" ;;
            4) return ;;
            *) echo "Invalid option" ;;
        esac
        pause
    done
}

# ═══════════════════════════════════════════════
# Reports
# ═══════════════════════════════════════════════
menu_reports() {
    header
    echo "── Reports ──"
    local PS3=$'\nSelect: '
    local options=(
        "Generate Usage Report"
        "Generate Condensed Report (JSON)"
        "Back"
    )
    select opt in "${options[@]}"; do
        case $REPLY in
            1) run_cmd satellite-maintain report generate ;;
            2) run_cmd satellite-maintain report condense ;;
            3) return ;;
            *) echo "Invalid option" ;;
        esac
        pause
    done
}

# ═══════════════════════════════════════════════
# DB Maintenance
# ═══════════════════════════════════════════════
menu_db_maintenance() {
    header
    echo "── DB Maintenance ──"
    local PS3=$'\nSelect: '
    local CRON_FILE="/etc/cron.d/satellite-db-maintenance"
    local options=(
        "Expire Audit Records (default: > 90 days)"
        "Expire Audit Records (custom days)"
        "Anonymize Audit Records (default: > 90 days)"
        "Expire Report Records (default: > 90 days)"
        "Expire Report Records (custom days)"
        "Clean Task Records (completed)"
        "Clean Task Records (custom search)"
        "Check Task Auto-Cleanup Status"
        "Reclaim Repository Space"
        "Deploy DB Maintenance Cron"
        "View DB Maintenance Cron"
        "Remove DB Maintenance Cron"
        "Back"
    )
    select opt in "${options[@]}"; do
        case $REPLY in
            1) confirm_cmd "foreman-rake audits:expire" && \
               run_cmd foreman-rake audits:expire ;;
            2)
                read -rp "Keep audit records newer than (days): " days
                [[ -n "$days" ]] && confirm_cmd "foreman-rake audits:expire days=$days" && \
                    run_cmd foreman-rake audits:expire days="$days"
                ;;
            3) confirm_cmd "foreman-rake audits:anonymize" && \
               run_cmd foreman-rake audits:anonymize ;;
            4) confirm_cmd "foreman-rake reports:expire" && \
               run_cmd foreman-rake reports:expire ;;
            5)
                read -rp "Keep report records newer than (days): " days
                [[ -n "$days" ]] && confirm_cmd "foreman-rake reports:expire days=$days" && \
                    run_cmd foreman-rake reports:expire days="$days"
                ;;
            6) confirm_cmd "foreman-rake foreman_tasks:cleanup STATES='stopped'" && \
               run_cmd foreman-rake foreman_tasks:cleanup STATES='stopped' ;;
            7)
                echo "Examples:"
                echo "  label = Actions::Katello::Repository::Sync"
                echo "  result = error"
                echo "  state = stopped AND result = success"
                echo
                read -rp "Task search filter: " tsearch
                [[ -n "$tsearch" ]] && confirm_cmd "foreman-rake foreman_tasks:cleanup TASK_SEARCH='$tsearch'" && \
                    run_cmd foreman-rake foreman_tasks:cleanup TASK_SEARCH="$tsearch"
                ;;
            8) run_cmd satellite-installer --help | grep -i "tasks-automatic-cleanup" && \
               echo && echo "To enable: satellite-installer --foreman-plugin-tasks-automatic-cleanup true" ;;
            9)
                echo "Reclaims space from on-demand repositories."
                echo "Navigate to Content > Products > Repository > Select Actions > Reclaim Space"
                echo "Or use the API/hammer. This is best done from the web UI."
                ;;
            10)
                if [[ -f "$CRON_FILE" ]]; then
                    echo "Cron file already exists at $CRON_FILE:"
                    echo
                    cat "$CRON_FILE"
                    echo
                    confirm_cmd "Overwrite $CRON_FILE" || { pause; continue; }
                fi
                local audit_days report_days
                read -rp "Expire audit records older than (days) [180]: " audit_days
                audit_days="${audit_days:-180}"
                read -rp "Expire report records older than (days) [90]: " report_days
                report_days="${report_days:-90}"
                echo
                echo "  File:     $CRON_FILE"
                echo "  Schedule: Weekly on Sunday, 20:00 and 20:15"
                echo "  Audits:   Expire records older than ${audit_days} days"
                echo "  Reports:  Expire records older than ${report_days} days"
                echo
                read -rp "Deploy this cron? [y/N]: " ans
                if [[ "$ans" =~ ^[Yy]$ ]]; then
                    cat > "$CRON_FILE" << CRONEOF
# Satellite DB Maintenance - deployed by satellite-menu.sh
# Runs weekly on Sunday, offset from the 19:45 task cleanup
SHELL=/bin/sh
RAILS_ENV=production
FOREMAN_HOME=/usr/share/foreman

# Expire audit records older than ${audit_days} days
0 20 * * 0    foreman    /usr/sbin/foreman-rake audits:expire days=${audit_days} >>/var/log/foreman/cron.log 2>&1

# Expire report records older than ${report_days} days
15 20 * * 0   foreman    /usr/sbin/foreman-rake reports:expire days=${report_days} >>/var/log/foreman/cron.log 2>&1
CRONEOF
                    chmod 644 "$CRON_FILE"
                    echo "Deployed: $CRON_FILE"
                    echo
                    cat "$CRON_FILE"
                fi
                ;;
            11)
                if [[ -f "$CRON_FILE" ]]; then
                    cat "$CRON_FILE"
                else
                    echo "No DB maintenance cron deployed ($CRON_FILE not found)."
                    echo "Use 'Deploy DB Maintenance Cron' to create one."
                fi
                ;;
            12)
                if [[ -f "$CRON_FILE" ]]; then
                    echo "Current cron:"
                    echo
                    cat "$CRON_FILE"
                    echo
                    confirm_cmd "rm $CRON_FILE" && rm -f "$CRON_FILE" && echo "Removed."
                else
                    echo "No DB maintenance cron to remove ($CRON_FILE not found)."
                fi
                ;;
            13) return ;;
            *) echo "Invalid option" ;;
        esac
        pause
    done
}

# --- Main loop ---
while true; do
    header
    menu_main
done
