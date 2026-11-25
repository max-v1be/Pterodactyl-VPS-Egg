#!/bin/sh

. /opt/pterodactyl-vps-egg/common.sh

runtime_dir=/run/pterodactyl-vps-egg
resolver="$HOME/etc/resolv.conf"

# Parse port configuration
parse_ports() {
    config_file="$HOME/vps.config"
    [ -f "$config_file" ] || return 0

    awk -F '=' '
        NF == 2 {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
            port = $2 + 0
            if ($1 ~ /^port[0-9]*$/ && $2 ~ /^[0-9]+$/ && port >= 1 && port <= 65535 && !seen[port]) {
                seen[port] = 1
                printf " -p %d:%d", port, port
            }
        }
    ' "$config_file"
}

# Execute PRoot environment
exec_proot() {
    port_args=$(parse_ports)
    
    exec /usr/local/bin/proot \
    --rootfs="${HOME}" \
    -0 -w "${HOME}" \
    -b /dev -b /sys -b /proc \
    -b "/opt/pterodactyl-vps-egg:$runtime_dir!" \
    $port_args \
    --kill-on-exit \
    /bin/sh "$runtime_dir/run.sh"
}

# Fill in a missing resolver or migrate the default from an older image.
legacy_resolver=$(printf 'nameserver 1.1.1.1\nnameserver 1.0.0.1\n')
if [ -L "$resolver" ]; then
    :
elif [ ! -e "$resolver" ] || { [ -f "$resolver" ] && [ "$(cat "$resolver")" = "$legacy_resolver" ]; }; then
    copy_container_dns "$resolver" || exit 1
fi

exec_proot
