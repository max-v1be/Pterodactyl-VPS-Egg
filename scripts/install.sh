#!/bin/sh

# Source common functions and variables
. /opt/pterodactyl-vps-egg/common.sh

# Configuration variables
ROOTFS_DIR="/home/container"
IMAGE_SERVER="https://images.linuxcontainers.org"

# Define all available distributions
# Format: "number:display_name:distro_id:variant:post_config:custom_handler"
distributions="
1:Debian:debian:default::
2:Ubuntu:ubuntu:default::
3:Void Linux:voidlinux:all::
4:Alpine Linux:alpine:default::
5:CentOS:centos:default::
6:Rocky Linux:rockylinux:default::
7:Fedora:fedora:default::
8:AlmaLinux:almalinux:default::
9:Slackware Linux:slackware:default::
10:Kali Linux:kali:default::
11:openSUSE:opensuse:default::
12:Gentoo Linux:gentoo:all::
13:Arch Linux:archlinux:default:archlinux:
14:Devuan Linux:devuan:default::
15:Chimera Linux:chimera:custom::chimera_handler
16:Oracle Linux:oracle:default::
17:Amazon Linux:amazonlinux:default::
18:Plamo Linux:plamo:default::
19:Linux Mint:mint:default::
20:Alt Linux:alt:default::
21:Funtoo Linux:funtoo:default::
22:openEuler:openeuler:default::
23:Springdale Linux:springdalelinux:default::
"

# Error handling function
error_exit() {
    log "ERROR" "$1" "$RED"
    exit 1
}

download_rootfs() {
    archive=$(mktemp "$ROOTFS_DIR/.rootfs.XXXXXX") || error_exit "Could not create a temporary archive"
    trap 'rm -f "$archive"' EXIT
    trap 'exit 1' HUP INT TERM

    log "INFO" "Downloading rootfs..." "$GREEN"
    curl -fLSs --connect-timeout 15 "$1" -o "$archive" ||
        error_exit "Failed to download rootfs from $1"

    log "INFO" "Extracting rootfs..." "$GREEN"
    tar -xf "$archive" -C "$ROOTFS_DIR" || error_exit "Failed to extract rootfs"
}

# Use the same architecture and version fields as the Linux Containers download client.
install_image() {
    if [ -z "$image_index" ]; then
        image_index=$(curl -fLSs --connect-timeout 15 --max-time 30 "$IMAGE_SERVER/meta/1.0/index-system") ||
            error_exit "Failed to fetch the Linux Containers image index"
        [ -n "$image_index" ] || error_exit "The Linux Containers image index is empty"
    fi

    images=$(printf '%s\n' "$image_index" |
        awk -F ';' -v distro="$distro_id" -v arch="$image_arch" -v variant="$distro_variant" '
            $1 == distro && $3 == arch && (variant == "all" || $4 == variant) &&
            $2 != "" && $4 != "" && $5 != "" && $6 ~ /^\/images\// {
                key = $2 ";" $4
                if (!(key in build) || $5 > build[key]) {
                    build[key] = $5
                    path[key] = $6
                }
            }
            END { for (key in path) print key ";" path[key] }
        ' | sort -V)
    if [ -z "$images" ]; then
        log "ERROR" "No $display_name images are available for $image_arch." "$RED"
        return 1
    fi

    version_count=$(printf '%s\n' "$images" | wc -l)
    version_choice=1
    if [ "$version_count" -gt 1 ]; then
        printf '\nAvailable versions of %s (%s)\n' "$display_name" "$image_arch"
        printf '%s\n' "$images" | awk -F ';' -v distro="$display_name" '
            { printf "* [%d] %s %s", NR, distro, $1 }
            $2 != "default" { printf " (%s)", $2 }
            { print "" }
        '
        printf '* [0] Go back\n'
        while :; do
            printf 'Enter the desired version (0-%d):\n' "$version_count"
            read_console_line || exit 0
            case "$REPLY" in
                exit) exit 0 ;;
                0) return 1 ;;
                ''|*[!0-9]*) ;;
                *)
                    if [ "$REPLY" -ge 1 ] 2>/dev/null && [ "$REPLY" -le "$version_count" ]; then
                        version_choice=$REPLY
                        break
                    fi
                    ;;
            esac
            log "ERROR" "Invalid version selection. Please try again." "$RED"
        done
    fi

    selected_image=$(printf '%s\n' "$images" | awk -v choice="$version_choice" 'NR == choice')
    IFS=';' read -r version variant image_path <<EOF
$selected_image
EOF
    if [ "$variant" != "default" ]; then
        version="$version ($variant)"
    fi
    log "INFO" "Selected version: $display_name $version ($image_arch)" "$GREEN"
    download_rootfs "$IMAGE_SERVER${image_path%/}/rootfs.tar.xz"
}

chimera_handler() {
    chimera_url="https://repo.chimera-linux.org/live/latest"
    listing=$(curl -fLSs --connect-timeout 15 --max-time 30 "$chimera_url/") ||
        error_exit "Failed to fetch the Chimera Linux image listing"
    latest_file=$(printf '%s\n' "$listing" |
        grep -o "chimera-linux-$machine_arch-ROOTFS-[0-9]\{8\}-bootstrap\.tar\.gz" | sort -V | tail -n 1)
    if [ -z "$latest_file" ]; then
        log "ERROR" "No Chimera Linux image is available for $machine_arch." "$RED"
        return 1
    fi
    version=$(printf '%s\n' "$latest_file" | grep -o '[0-9]\{8\}')
    log "INFO" "Selected version: Chimera Linux $version ($image_arch)" "$GREEN"
    download_rootfs "$chimera_url/$latest_file"
}

# Function to handle post-install configuration for specific distros
post_install_config() {
    distro="$1"
    
    case "$distro" in
        "archlinux")
            log "INFO" "Configuring Arch Linux specific settings..." "$GREEN"
            sed -i -e '/^#RootDir/s/^#//' -e 's|/var/lib/pacman/|/var/lib/pacman|' \
                -e '/^#DBPath/s/^#//' "$ROOTFS_DIR/etc/pacman.conf"
        ;;
    esac
}

machine_arch=$(uname -m)
image_arch=$(detect_architecture) || exit 1
image_index=""

while :; do
    printf '\nPterodactyl VPS Egg\nChoose a Linux distribution (%s)\n\n' "$image_arch"
    printf '%s\n' "$distributions" | awk -F ':' 'NF { printf "* [%s] %s\n", $1, $2 }'
    printf '\nEnter a distribution number or type exit:\n'
    read_console_line || exit 0
    [ "$REPLY" = "exit" ] && exit 0

    case "$REPLY" in
        ''|*[!0-9]*) distro_data="" ;;
        *) distro_data=$(printf '%s\n' "$distributions" | awk -F ':' -v choice="$REPLY" '$1 != "" && $1 == choice') ;;
    esac
    if [ -z "$distro_data" ]; then
        log "ERROR" "Invalid distribution selection. Please try again." "$RED"
        continue
    fi
    IFS=':' read -r number display_name distro_id distro_variant post_config custom_handler <<EOF
$distro_data
EOF
    if [ -n "$custom_handler" ]; then
        "$custom_handler" || continue
    else
        install_image || continue
    fi
    break
done

if [ -n "$post_config" ]; then
    post_install_config "$post_config" || error_exit "Failed to configure $display_name"
fi

mkdir -p "$ROOTFS_DIR/home/container" || error_exit "Failed to create the guest home directory"
copy_container_dns "$ROOTFS_DIR/etc/resolv.conf" || exit 1
touch "$ROOTFS_DIR/.installed" || error_exit "Failed to mark the installation complete"
