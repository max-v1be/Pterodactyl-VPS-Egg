#!/bin/sh

# Common color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Common logger function
log() {
    printf '%b[%s]%b %s\n' "${3:-$NC}" "$1" "$NC" "$2"
}

# Function to detect architecture
detect_architecture() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            echo "amd64"
        ;;
        aarch64)
            echo "arm64"
        ;;
        riscv64)
            echo "riscv64"
        ;;
        *)
            log "ERROR" "Unsupported CPU architecture: $ARCH" "$RED" >&2
            return 1
        ;;
    esac
}

# Read a complete console line, accepting CRLF as well as LF.
read_console_line() {
    IFS= read -r REPLY || return 1
    REPLY=${REPLY%"$CONSOLE_CR"}
}

CONSOLE_CR=$(printf '\r')

copy_container_dns() {
    dns_copy=$(mktemp "${1}.XXXXXX") || return 1
    if cat /etc/resolv.conf > "$dns_copy" &&
        chmod 644 "$dns_copy" &&
        mv -fT "$dns_copy" "$1"; then
        return 0
    fi
    rm -f "$dns_copy"
    log "ERROR" "Could not copy the container DNS configuration to $1." "$RED" >&2
    return 1
}

print_help_banner() {
    cat <<'EOF'
Available commands
  help                  Show available commands
  clear, cls            Clear the console
  exit                  Stop the server
  history               Show command history
  status                Show OS and system status
  reinstall             Reinstall the operating system
  install-ssh           Install the custom SSH server
  backup                Create a system backup
  restore <backup_file> Restore a system backup

GUI / remote desktop
  install-gui           Install a desktop environment and VNC
  reinstall-gui         Reinstall the desktop environment and VNC
  start-vnc, stop-vnc   Start or stop VNC
  start-novnc           Start noVNC for browser access
  stop-novnc            Stop noVNC
  gui-status            Show VNC and noVNC status
EOF
}
