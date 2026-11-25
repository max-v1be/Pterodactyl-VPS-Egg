#!/bin/sh

# Source common functions and variables
runtime_dir=${0%/*}
. "$runtime_dir/common.sh"

# Configuration
HOSTNAME="MyVPS"
HISTORY_FILE="${HOME}/.custom_shell_history"
MAX_HISTORY=1000

if [ ! -e "/autorun.sh" ]; then
    touch /autorun.sh && chmod +x /autorun.sh || exit 1
fi

# Function to handle cleanup on exit
cleanup() {
    log "INFO" "Session ended. Goodbye!" "$GREEN"
    exit 0
}

print_prompt() {
    case "$PWD" in
        "$HOME"|"$HOME"/*) prompt_dir="~${PWD#"$HOME"}" ;;
        *) prompt_dir=$PWD ;;
    esac
    printf '%broot@%s%b:%b%s%b#\n' "$GREEN" "$HOSTNAME" "$NC" "$RED" "$prompt_dir" "$NC"
}

save_to_history() {
    if [ -n "$1" ] && [ "$1" != "exit" ]; then
        printf '%s\n' "$1" >> "$HISTORY_FILE"
        tail -n "$MAX_HISTORY" "$HISTORY_FILE" > "$HISTORY_FILE.tmp" &&
            mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
    fi
}

# Function reinstall the OS
reinstall() {    
    log "INFO" "Reinstalling the OS..." "$YELLOW"
    
    find / -mindepth 1 -xdev ! -path "$runtime_dir" ! -path "$runtime_dir/*" -delete > /dev/null 2>&1
}

install_wget() {
    distro=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    
    case "$distro" in
        "debian"|"ubuntu"|"devuan"|"linuxmint"|"kali")
            apt-get update -qq && apt-get install -y -qq wget > /dev/null 2>&1
        ;;
        "void")
            xbps-install -Syu wget > /dev/null 2>&1
        ;;
        "centos"|"fedora"|"rocky"|"almalinux"|"openEuler"|"amzn"|"ol")
            yum install -y -q wget > /dev/null 2>&1
        ;;
        "opensuse"|"opensuse-tumbleweed"|"opensuse-leap")
            zypper install -y -q wget > /dev/null 2>&1
        ;;
        "alpine"|"chimera")
            apk add -q --no-interactive --no-scripts wget > /dev/null 2>&1
        ;;
        "gentoo")
            emerge --sync -q && emerge -q wget > /dev/null 2>&1
        ;;
        "arch")
            pacman -Syu --noconfirm --quiet wget > /dev/null 2>&1
        ;;
        "slackware")
            yes | slackpkg install wget > /dev/null 2>&1
        ;;
        *)
            log "ERROR" "Unsupported distribution: $distro" "$RED"
            return 1
        ;;
    esac
}

GUI_CONFIG_FILE="/gui_config.yml"
VNC_DIR="$HOME/.vnc"

vnc_is_running() {
    pgrep -x 'Xtigervnc|Xvnc|Xtightvnc|x11vnc' > /dev/null 2>&1
}

install_gui() {
    if [ -f "/gui_config.yml" ]; then
        log "WARNING" "GUI is already installed. Run 'reinstall-gui' to reinstall." "$YELLOW"
        return 1
    fi
    
    if [ -f "$runtime_dir/vnc_install.sh" ]; then
        sh "$runtime_dir/vnc_install.sh" install
    else
        log "ERROR" "GUI installation script not found." "$RED"
        return 1
    fi
}

reinstall_gui() {
    rm -f "$GUI_CONFIG_FILE"
    rm -rf "$VNC_DIR"
    rm -f "$HOME/.xsession"
    install_gui
}

parse_gui_config() {
    if [ -f "$GUI_CONFIG_FILE" ]; then
        GUI_SERVER_TYPE="vnc"
        GUI_DE_STARTUP=$(grep -E '^\s*startup_command:' "$GUI_CONFIG_FILE" | sed 's/.*: *"\?\([^"]*\)"\?/\1/' | tr -d ' ')
        GUI_DE=$(grep -E '^\s*environment:' "$GUI_CONFIG_FILE" | sed 's/.*: *"\?\([^"]*\)"\?/\1/' | tr -d ' ')
        VNC_PORT=$(grep -A5 '^vnc:' "$GUI_CONFIG_FILE" | grep -E '^\s*port:' | head -1 | sed 's/.*: *"\?\([^"]*\)"\?/\1/' | tr -d ' ')
        VNC_PASSWORD=$(grep -A5 '^vnc:' "$GUI_CONFIG_FILE" | grep -E '^\s*password:' | sed 's/.*: *"\?\([^"]*\)"\?/\1/' | tr -d ' ')
        NOVNC_PORT=$(grep -A3 '^novnc:' "$GUI_CONFIG_FILE" | grep -E '^\s*port:' | sed 's/.*: *"\?\([^"]*\)"\?/\1/' | tr -d ' ')
        
        VNC_PORT="${VNC_PORT:-5901}"
        NOVNC_PORT="${NOVNC_PORT:-6080}"
        
        if [ -z "$GUI_DE_STARTUP" ]; then
            case "$GUI_DE" in
                "xfce4") GUI_DE_STARTUP="startxfce4" ;;
                "lxde") GUI_DE_STARTUP="startlxde" ;;
                "lxqt") GUI_DE_STARTUP="startlxqt" ;;
                "mate") GUI_DE_STARTUP="mate-session" ;;
                *) GUI_DE_STARTUP="startxfce4" ;;
            esac
        fi
    fi
}

start_vnc() {
    if [ ! -f "$GUI_CONFIG_FILE" ]; then
        log "ERROR" "GUI not installed. Run 'install-gui' first." "$RED"
        return 1
    fi
    
    parse_gui_config
    
    if [ "$GUI_SERVER_TYPE" != "vnc" ] && [ "$GUI_SERVER_TYPE" != "both" ]; then
        log "ERROR" "VNC server not configured. Server type: $GUI_SERVER_TYPE" "$RED"
        return 1
    fi
    
    if vnc_is_running; then
        log "WARNING" "VNC server is already running." "$YELLOW"
        return 0
    fi
    
    log "INFO" "Starting VNC server on port $VNC_PORT..." "$YELLOW"
    
    VNC_DISPLAY_NUM=$((VNC_PORT - 5900))
    if [ "$VNC_DISPLAY_NUM" -lt 1 ]; then
        VNC_DISPLAY_NUM=1
    fi
    
    mkdir -p "$HOME/.vnc" 2>/dev/null
    mkdir -p /tmp/.X11-unix 2>/dev/null || true
    
    pkill -f "Xtigervnc.*:$VNC_DISPLAY_NUM" > /dev/null 2>&1 || true
    pkill -f "Xvnc.*:$VNC_DISPLAY_NUM" > /dev/null 2>&1 || true
    pkill -f "tint2" > /dev/null 2>&1 || true
    sleep 1
    
    start_desktop_env() {
        export DISPLAY=":$VNC_DISPLAY_NUM"
        export HOME="$HOME"
        export XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"
        mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null || true
        chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || true

        # Start D-Bus session if available
        if command -v dbus-launch > /dev/null 2>&1; then
            eval "$(dbus-launch --sh-syntax)" 2>/dev/null || true
        fi

        # Helper: use tint2 as panel fallback if primary panel fails
        start_panel_with_fallback() {
            primary_panel="$1"
            if command -v "$primary_panel" > /dev/null 2>&1; then
                "$primary_panel" 2>/dev/null &
                sleep 2
                # Check if it's still running
                if ! pgrep -x "$primary_panel" > /dev/null 2>&1; then
                    log "WARNING" "$primary_panel crashed (likely D-Bus), falling back to tint2" "$YELLOW"
                    tint2 2>/dev/null &
                fi
            else
                tint2 2>/dev/null &
            fi
        }

        case "$GUI_DE" in
            xfce4)
                xfwm4 --compositor=off 2>/dev/null &
                sleep 1
                start_panel_with_fallback xfce4-panel
                # Skip xfdesktop — requires D-Bus, causes black screen in containers
                ;;
            lxde)
                openbox 2>/dev/null &
                sleep 1
                start_panel_with_fallback lxpanel
                # Skip pcmanfm --desktop — requires D-Bus
                ;;
            lxqt)
                openbox 2>/dev/null &
                sleep 1
                start_panel_with_fallback lxqt-panel
                # Skip pcmanfm-qt --desktop — requires D-Bus
                ;;
            mate)
                marco 2>/dev/null &
                sleep 1
                start_panel_with_fallback mate-panel
                ;;
            *)
                if command -v openbox > /dev/null 2>&1; then
                    openbox 2>/dev/null &
                elif command -v xfwm4 > /dev/null 2>&1; then
                    xfwm4 --compositor=off 2>/dev/null &
                fi
                tint2 2>/dev/null &
                ;;
        esac

        log "INFO" "Desktop started: $GUI_DE" "$YELLOW"
        sleep 2
    }
    
    set -- -SecurityTypes None
    if [ -n "$VNC_PASSWORD" ] && { command -v Xtigervnc || command -v Xvnc; } > /dev/null 2>&1; then
        if ! (umask 077; printf '%s\n' "$VNC_PASSWORD" | vncpasswd -f > "$VNC_DIR/passwd"); then
            log "ERROR" "Failed to configure VNC authentication." "$RED"
            return 1
        fi
        set -- -SecurityTypes VncAuth -PasswordFile "$VNC_DIR/passwd"
    fi
    
    if command -v Xtigervnc > /dev/null 2>&1; then
        Xtigervnc ":$VNC_DISPLAY_NUM" -geometry 1280x720 -depth 24 -rfbport "$VNC_PORT" "$@" -pn -ac &
        sleep 2
        start_desktop_env
        
    elif command -v Xvnc > /dev/null 2>&1; then
        Xvnc ":$VNC_DISPLAY_NUM" -geometry 1280x720 -depth 24 -rfbport "$VNC_PORT" "$@" -pn -ac &
        sleep 2
        start_desktop_env
        
    elif command -v x11vnc > /dev/null 2>&1; then
        pkill -f "Xvfb.*:$VNC_DISPLAY_NUM" > /dev/null 2>&1 || true
        
        Xvfb ":$VNC_DISPLAY_NUM" -screen 0 1280x720x24 -ac &
        sleep 2
        start_desktop_env
        
        if [ -n "$VNC_PASSWORD" ]; then
            x11vnc -display ":$VNC_DISPLAY_NUM" -rfbport "$VNC_PORT" -forever -shared -passwd "$VNC_PASSWORD" -bg
        else
            x11vnc -display ":$VNC_DISPLAY_NUM" -rfbport "$VNC_PORT" -forever -shared -nopw -bg
        fi
        sleep 2
    else
        log "ERROR" "No VNC server found (Xtigervnc, Xvnc, or x11vnc)." "$RED"
        return 1
    fi
    
    if vnc_is_running; then
        log "SUCCESS" "VNC server started on port $VNC_PORT (display :$VNC_DISPLAY_NUM)" "$GREEN"
        log "INFO" "Connect using: <server-ip>:$VNC_PORT" "$YELLOW"
    else
        log "ERROR" "VNC server failed to start. Check logs at ~/.vnc/" "$RED"
        return 1
    fi
}

stop_vnc() {
    if [ ! -f "$GUI_CONFIG_FILE" ]; then
        log "ERROR" "GUI not installed. Run 'install-gui' first." "$RED"
        return 1
    fi

    log "INFO" "Stopping VNC server..." "$YELLOW"
    
    parse_gui_config
    VNC_DISPLAY_NUM=$((VNC_PORT - 5900))
    if [ "$VNC_DISPLAY_NUM" -lt 1 ]; then
        VNC_DISPLAY_NUM=1
    fi
    
    if command -v vncserver > /dev/null 2>&1; then
        vncserver -kill ":$VNC_DISPLAY_NUM" > /dev/null 2>&1
    fi
    
    pkill -f "Xvnc" > /dev/null 2>&1
    pkill -f "Xtigervnc" > /dev/null 2>&1
    pkill -f "x11vnc" > /dev/null 2>&1
    pkill -f "Xvfb" > /dev/null 2>&1
    pkill -f "tint2" > /dev/null 2>&1 || true
    
    log "SUCCESS" "VNC server stopped." "$GREEN"
}

start_novnc() {
    if [ ! -f "$GUI_CONFIG_FILE" ]; then
        log "ERROR" "GUI not installed. Run 'install-gui' first." "$RED"
        return 1
    fi
    
    parse_gui_config
    
    if pgrep -f "websockify" > /dev/null 2>&1; then
        log "WARNING" "noVNC is already running." "$YELLOW"
        return 0
    fi
    
    if ! command -v websockify > /dev/null 2>&1; then
        log "ERROR" "websockify not found. noVNC may not be installed." "$RED"
        return 1
    fi

    if [ -f "/usr/share/novnc/vnc.html" ]; then
        NOVNC_PATH="/usr/share/novnc"
    elif [ -f "/usr/share/webapps/novnc/vnc.html" ]; then
        NOVNC_PATH="/usr/share/webapps/novnc"
    else
        log "ERROR" "noVNC web files were not found." "$RED"
        return 1
    fi

    start_vnc || return 1
    log "INFO" "Starting noVNC on port $NOVNC_PORT..." "$YELLOW"
    websockify --web="$NOVNC_PATH" "$NOVNC_PORT" "127.0.0.1:$VNC_PORT" </dev/null &
    novnc_pid=$!
    sleep 1
    if ! kill -0 "$novnc_pid" 2>/dev/null; then
        wait "$novnc_pid" 2>/dev/null
        log "ERROR" "noVNC failed to start on port $NOVNC_PORT." "$RED"
        return 1
    fi
    log "SUCCESS" "noVNC started on port $NOVNC_PORT" "$GREEN"
    log "INFO" "Open in browser: http://<server-ip>:$NOVNC_PORT/vnc.html" "$YELLOW"
}

stop_novnc() {
    log "INFO" "Stopping noVNC..." "$YELLOW"
    pkill -f "websockify" > /dev/null 2>&1
    log "SUCCESS" "noVNC stopped." "$GREEN"
}

gui_status() {
    printf "\n${CYAN}GUI Server Status:${NC}\n\n"
    
    if [ ! -f "$GUI_CONFIG_FILE" ]; then
        log "INFO" "GUI not installed. Run 'install-gui' to install." "$YELLOW"
        return
    fi
    
    parse_gui_config
    
    printf '  Desktop: %s\n\n' "$GUI_DE_STARTUP"
    
    printf "  ${YELLOW}VNC:${NC}\n"
    if vnc_is_running; then
        printf "    Status: ${GREEN}Running${NC}\n"
    else
        printf "    Status: ${RED}Stopped${NC}\n"
    fi
    printf '    Port: %s\n\n' "$VNC_PORT"
    
    printf "  ${YELLOW}noVNC:${NC}\n"
    if pgrep -f "websockify" > /dev/null 2>&1; then
        printf "    Status: ${GREEN}Running${NC}\n"
    else
        printf "    Status: ${RED}Stopped${NC}\n"
    fi
    printf '    Port: %s\n' "$NOVNC_PORT"
}

# Function to install SSH from the repository
install_ssh() {
    # Check if SSH is already installed
    if [ -s "/usr/local/bin/ssh" ]; then
        log "ERROR" "SSH is already installed." "$RED"
        return 1
    fi

    # Install wget if not found
    if ! command -v wget > /dev/null 2>&1; then
        log "INFO" "Installing wget." "$YELLOW"
        install_wget || return 1
    fi
    
    log "INFO" "Installing SSH." "$YELLOW"
    
    # Determine the architecture
    arch=$(detect_architecture) || return 1
    
    # URL to download the SSH binary
    url="https://github.com/ysdragon/ssh/releases/latest/download/ssh-$arch"
    
    mkdir -p /usr/local/bin || return 1
    ssh_download=$(mktemp /usr/local/bin/.ssh.XXXXXX) || return 1
    if ! wget -q -O "$ssh_download" "$url" ||
        [ ! -s "$ssh_download" ] ||
        ! chmod +x "$ssh_download" ||
        ! mv -f "$ssh_download" /usr/local/bin/ssh; then
        rm -f "$ssh_download"
        log "ERROR" "Failed to download or install SSH." "$RED"
        return 1
    fi

    log "SUCCESS" "SSH installed successfully." "$GREEN"
}

print_system_versions() {
    os_name=$(
        if [ -r /etc/os-release ]; then
            . /etc/os-release
        elif [ -r /usr/lib/os-release ]; then
            . /usr/lib/os-release
        fi
        printf '%s' "${PRETTY_NAME:-${NAME:-Linux}${VERSION_ID:+ $VERSION_ID}}"
    )
    printf 'OS: %s\nKernel: %s\nArchitecture: %s\n' "$os_name" "$(uname -r)" "$(uname -m)"
    if [ -n "${PROOT_VERSION:-}" ]; then
        printf 'PRoot: %s\n' "$PROOT_VERSION"
    fi
}

show_system_status() {
    print_system_versions
    printf '\n'
    uptime
    free -h 2>/dev/null || free
    df -h
    { ps aux --sort=-%mem 2>/dev/null || ps; } | head -n 10
}

# Function to create a backup
create_backup() (
    # Check if tar is installed
    if ! command -v tar > /dev/null 2>&1; then
        log "ERROR" "tar is not installed. Please install tar first." "$RED"
        return 1
    fi

    backup_file="/backup_$(date +%Y%m%d%H%M%S).tar.gz"
    if [ -e "$backup_file" ]; then
        log "ERROR" "Backup already exists at $backup_file." "$RED"
        return 1
    fi
    backup_archive=$(mktemp "$backup_file.XXXXXX") || return 1
    exclude_file=$(mktemp /tmp/vps-backup-excludes.XXXXXX) || {
        rm -f "$backup_archive"
        return 1
    }
    trap 'rm -f "$backup_archive" "$exclude_file"' EXIT
    trap 'exit 1' HUP INT TERM

    # Create a file with a list of patterns to exclude. This is more
    # compatible with different versions of tar, including busybox tar.
    # We use relative paths for exclusion as we'll be running tar from /.
    cat > "$exclude_file" <<EOF || return 1
./${backup_file#/}
./${backup_archive#/}
./proc
./tmp
./dev
./sys
./run
./vps.config
EOF

    log "INFO" "Starting backup process..." "$YELLOW"
    if cd / && tar --numeric-owner -czf "$backup_archive" -X "$exclude_file" . &&
        mv "$backup_archive" "$backup_file"; then
        log "SUCCESS" "Backup created at $backup_file" "$GREEN"
    else
        log "ERROR" "Backup failed." "$RED"
        return 1
    fi
)

# Function to restore a backup
restore_backup() {
    backup_file="$1"

    # Check if tar is installed
    if ! command -v tar > /dev/null 2>&1; then
        log "ERROR" "tar is not installed. Please install tar first." "$RED"
        return 1
    fi

    if [ -z "$backup_file" ]; then
        log "INFO" "Usage: restore <backup_file>" "$YELLOW"
        log "INFO" "Example: restore backup_20250620024221.tar.gz" "$YELLOW"
        return 1
    fi

    if [ -f "/$backup_file" ]; then
        log "INFO" "Starting restore process..." "$YELLOW"
        if tar --numeric-owner -xzf "/$backup_file" -C / --exclude="$backup_file"; then
            log "SUCCESS" "Backup restored from $backup_file" "$GREEN"
        else
            log "ERROR" "Restore failed for $backup_file." "$RED"
            return 1
        fi
    else
        log "ERROR" "Backup file not found: $backup_file" "$RED"
    fi
}

execute_command() {
    save_to_history "$1"

    case "$1" in
        '') ;;
        clear|cls) printf '\033[2J\033[H' ;;
        exit) cleanup ;;
        history) [ ! -f "$HISTORY_FILE" ] || cat "$HISTORY_FILE" ;;
        reinstall)
            reinstall
            exit 2
            ;;
        sudo|su|sudo[[:blank:]]*|su[[:blank:]]*)
            log "ERROR" "You are already running as root." "$RED"
            ;;
        install-ssh) install_ssh ;;
        install-gui) install_gui; [ "$?" -ne 2 ] || cleanup ;;
        reinstall-gui) reinstall_gui; [ "$?" -ne 2 ] || cleanup ;;
        start-vnc) start_vnc ;;
        stop-vnc) stop_vnc ;;
        start-novnc) start_novnc ;;
        stop-novnc) stop_novnc ;;
        gui-status) gui_status ;;
        status) show_system_status ;;
        backup) create_backup ;;
        restore) restore_backup "" ;;
        "restore "*) restore_backup "${1#restore }" ;;
        help) print_help_banner ;;
        *) eval "$1" ;;
    esac
}

trap cleanup INT TERM

printf 'Pterodactyl VPS Egg\n'
print_system_versions
log "INFO" "Type 'help' to view the available commands." "$YELLOW"
printf 'Starting VPS console\n'

if ! sh /autorun.sh; then
    log "ERROR" "autorun.sh failed. The console is available." "$RED"
fi

print_prompt
while read_console_line; do
    execute_command "$REPLY"
    print_prompt
done

cleanup
