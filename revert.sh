#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/.config"

HAS_WHIPTAIL=0
command -v whiptail &>/dev/null && HAS_WHIPTAIL=1

show_msg() {
    local title="$1" message="$2"
    if [[ $HAS_WHIPTAIL -eq 1 ]]; then
        whiptail --title "$title" --msgbox "$message" 10 60
    else
        echo -e "\n============================================================"
        echo -e "\033[1;32m$title\033[0m"
        echo -e "============================================================"
        echo -e "$message\n"
    fi
}

# Collect all backups created by install.sh (*.bak.TIMESTAMP)
mapfile -t baks < <(find "$CONFIG" -maxdepth 2 -name "*.bak.[0-9]*" | sort -t. -k3 -r)

if [[ ${#baks[@]} -eq 0 ]]; then
    show_msg "Revert Config" "No backups found in $CONFIG.\n\nRun install.sh first to create backups."
    exit 0
fi

# Pick a backup to restore
if [[ $HAS_WHIPTAIL -eq 1 ]]; then
    menu_args=()
    for bak in "${baks[@]}"; do
        orig="${bak%.bak.*}"
        ts="${bak##*.bak.}"
        label="$(basename "$orig")  [${ts:0:4}-${ts:4:2}-${ts:6:2} ${ts:8:2}:${ts:10:2}]"
        menu_args+=("$bak" "$label")
    done
    chosen=$(whiptail --title "Revert Config" \
        --menu "Select backup to restore:\n(newest first)" \
        20 72 12 "${menu_args[@]}" 3>&1 1>&2 2>&3) || exit 0
else
    echo -e "\n------------------------------------------------------------"
    echo -e "\033[1;34m[ Revert Config ]\033[0m"
    echo -e "Available backups (newest first):\n"
    i=1
    declare -a keys=()
    for bak in "${baks[@]}"; do
        orig="${bak%.bak.*}"
        ts="${bak##*.bak.}"
        label="${ts:0:4}-${ts:4:2}-${ts:6:2} ${ts:8:2}:${ts:10:2}"
        echo "  $i) $(basename "$orig")  [$label]"
        echo "     $bak"
        keys+=("$bak")
        ((i++))
    done
    echo -e "------------------------------------------------------------"
    read -rp "Enter number to restore (or q to quit): " sel
    [[ "$sel" == "q" || -z "$sel" ]] && exit 0
    chosen="${keys[$((sel - 1))]}"
fi

orig="${chosen%.bak.*}"

# Confirm
if [[ $HAS_WHIPTAIL -eq 1 ]]; then
    whiptail --title "Confirm Revert" --yesno \
        "Restore backup:\n  $(basename "$chosen")\n\nto:\n  $orig\n\nThe current $orig will be removed." \
        14 72 || exit 0
else
    echo -e "\nRestore: $chosen"
    echo -e "    to:  $orig"
    echo -e "Current $orig will be removed."
    read -rp "Proceed? [y/N]: " r
    case "$r" in [yY]*) ;; *) exit 0 ;; esac
fi

# Restore
if [[ -e "$orig" || -L "$orig" ]]; then
    rm -rf "$orig"
fi
mv "$chosen" "$orig"

show_msg "Done" "Restored:\n  $orig"
