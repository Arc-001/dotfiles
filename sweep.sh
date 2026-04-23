#!/usr/bin/env bash

# Check if whiptail is available
HAS_WHIPTAIL=0
if command -v whiptail &> /dev/null; then
    HAS_WHIPTAIL=1
fi

# Helper function for Yes/No prompts
# Usage: ask_yes_no "Title" "Message" "Context/Command"
ask_yes_no() {
    local title="$1"
    local message="$2"
    local context="$3"

    if [ "$HAS_WHIPTAIL" -eq 1 ]; then
        if [ -n "$context" ]; then
            whiptail --title "$title" --yesno "$message\n\n$context" 12 60
        else
            whiptail --title "$title" --yesno "$message" 12 60
        fi
        return $?
    else
        # Plain text fallback
        echo -e "\n------------------------------------------------------------"
        echo -e "\033[1;34m[ $title ]\033[0m"
        echo -e "$message"
        if [ -n "$context" ]; then
            echo -e "\033[0;36m$context\033[0m"
        fi
        echo -e "------------------------------------------------------------"
        read -p "Proceed? [y/N]: " response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# Helper function for Message boxes
show_msg() {
    local title="$1"
    local message="$2"
    if [ "$HAS_WHIPTAIL" -eq 1 ]; then
        whiptail --title "$title" --msgbox "$message" 10 60
    else
        echo -e "\n============================================================"
        echo -e "\033[1;32m$title\033[0m"
        echo -e "============================================================"
        echo -e "$message\n"
    fi
}

# Introductory Message
show_msg "Workstation Deep Clean" "Welcome to the interactive deep cleaning utility.\n\nSudo privileges will be required for system-level tasks."

# 1. DNF Cache
if ask_yes_no "DNF Cache" "Clear downloaded packages and metadata?" "Command: sudo dnf clean all"; then
    echo -e "\n---> Cleaning DNF Cache..."
    sudo dnf clean all
fi

# 2. Flatpak Unused
if ask_yes_no "Flatpak Runtimes" "Remove orphaned and unused Flatpak runtimes?" "Command: flatpak uninstall --unused"; then
    echo -e "\n---> Removing unused Flatpaks..."
    flatpak uninstall --unused -y
fi

# 3. DNF Autoremove
if ask_yes_no "DNF Autoremove" "Remove orphaned system dependencies?\n\nWARNING: Review the list carefully in the terminal before confirming the DNF prompt." ""; then
    echo -e "\n---> Running DNF Autoremove..."
    sudo dnf autoremove
fi

# 4. Cargo / Rust
if command -v cargo &> /dev/null; then
    if ask_yes_no "Cargo Cache" "Clear Rust/Cargo registry and git checkouts?" "Target: ~/.cargo/registry and ~/.cargo/git"; then
        echo -e "\n---> Cleaning Cargo cache..."
        rm -rf ~/.cargo/registry
        rm -rf ~/.cargo/git
    fi
fi

# 5. Go
if command -v go &> /dev/null; then
    if ask_yes_no "Go Module Cache" "Clear Go downloaded module cache?" "Command: go clean -modcache"; then
        echo -e "\n---> Cleaning Go cache..."
        go clean -modcache
    fi
fi

# 6. Python / Pip
if command -v pip &> /dev/null || command -v pip3 &> /dev/null; then
    if ask_yes_no "Pip Cache" "Clear global Python pip cache?" "Target: ~/.cache/pip"; then
        echo -e "\n---> Cleaning Pip cache..."
        rm -rf ~/.cache/pip
    fi
fi

# 7. Containers (Podman/Docker)
if command -v podman &> /dev/null; then
    if ask_yes_no "Podman Prune" "Remove ALL unused Podman containers, networks, and dangling images?" "Command: podman system prune -a --volumes"; then
        echo -e "\n---> Pruning Podman..."
        podman system prune -a --volumes -f
    fi
elif command -v docker &> /dev/null; then
    if ask_yes_no "Docker Prune" "Remove ALL unused Docker containers, networks, and dangling images?" "Command: docker system prune -a --volumes"; then
        echo -e "\n---> Pruning Docker..."
        docker system prune -a --volumes -f
    fi
fi

# 8. Systemd Journal
if ask_yes_no "Systemd Journal" "Vacuum old system logs, keeping only the last 2 weeks?" "Command: sudo journalctl --vacuum-time=2weeks"; then
    echo -e "\n---> Vacuuming system logs..."
    sudo journalctl --vacuum-time=2weeks
fi

# 9. NCDU Finale
if ask_yes_no "Visual Inspection (ncdu)" "Cleanup phase complete.\n\nWould you like to launch 'ncdu' to visually inspect your home directory for any remaining large files?" ""; then
    clear
    if ! command -v ncdu &> /dev/null; then
        echo "ncdu is not installed. Installing it now via DNF..."
        sudo dnf install -y ncdu
    fi
    
    # Launch ncdu in the home directory
    ncdu ~
else
    show_msg "Done" "Cleanup complete! Exiting."
    clear
fi
