#!/bin/sh
cd /home/container || exit 1

# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "src") {print $(i + 1); exit}}')
export INTERNAL_IP

# Check if already installed
if [ ! -e "$HOME/.installed" ]; then
    /usr/local/bin/proot \
    --rootfs="/" \
    -0 -w "/root" \
    -b /dev -b /sys -b /proc \
    --kill-on-exit \
    /bin/sh /install.sh || exit $?
    [ -e "$HOME/.installed" ] || exit 0
fi

# Run the startup helper script
exec /bin/sh /helper.sh
