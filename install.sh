#!/bin/sh
# Install or uninstall the pk-offline-arm service.
# Usage: ./install.sh [install|uninstall|status]
set -eu

SCRIPT_SRC=pk-offline-arm
UNIT_SRC=pk-offline-arm.service
SCRIPT_DST=/usr/local/libexec/pk-offline-arm
UNIT_DST=/etc/systemd/system/pk-offline-arm.service
UNIT=pk-offline-arm.service

usage() {
    echo "Usage: $0 [install|uninstall|status]" >&2
    exit 2
}

need_root() {
    if [ "$(id -u)" -ne 0 ]; then
        if [ -t 0 ]; then
            exec sudo -- sh "$0" "$@"
        fi
        # No TTY available for sudo: use the graphical polkit agent.
        exec pkexec sh "$(realpath "$0")" "$@"
    fi
}

check_host_compatibility() {
    if ! command -v pkcon >/dev/null 2>&1; then
        echo "Refusing to install: PackageKit is not available on this host." >&2
        exit 1
    fi

    if ! command -v systemctl >/dev/null 2>&1; then
        echo "Refusing to install: systemd is not available on this host." >&2
        exit 1
    fi
}

do_install() {
    cd "$(dirname "$0")"
    check_host_compatibility
    install -Dm755 "$SCRIPT_SRC" "$SCRIPT_DST"
    install -Dm644 "$UNIT_SRC" "$UNIT_DST"
    systemctl daemon-reload
    systemctl enable --now "$UNIT"
    echo "Service $UNIT installed and enabled."
}

do_uninstall() {
    if [ -f "$UNIT_DST" ]; then
        # Stopping the service does nothing by itself: the script only acts during system shutdown.
        systemctl disable --now "$UNIT" || true
    fi
    rm -f "$UNIT_DST" "$SCRIPT_DST"
    systemctl daemon-reload
    echo "Service $UNIT uninstalled."
}

do_status() {
    systemctl status --no-pager "$UNIT" || true
    echo
    if [ -L /system-update ]; then
        echo "Offline update: armed ($(cat /var/lib/PackageKit/offline-update-action 2>/dev/null))"
    else
        echo "Offline update: not armed"
    fi
}

action=${1:-install}
case "$action" in
    install)   need_root "$action"; do_install ;;
    uninstall) need_root "$action"; do_uninstall ;;
    status)    do_status ;;
    *)         usage ;;
esac
