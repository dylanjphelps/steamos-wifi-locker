#!/usr/bin/env bash
set -euo pipefail

config_file="/etc/steamos-wifi-locker.conf"
service_file="/etc/systemd/system/steamos-wifi-locker.service"

for command in sudo systemctl; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "$command" >&2
        exit 1
    fi
done

connection_uuid=""
if [[ -r "$config_file" ]]; then
    connection_uuid="$(sed -n 's/^CONNECTION_UUID=//p' "$config_file" | head -n 1)"
    if [[ ! "$connection_uuid" =~ ^[[:xdigit:]-]+$ ]]; then
        printf 'Invalid connection UUID in %s; refusing to remove the locker.\n' "$config_file" >&2
        exit 1
    fi
    if ! command -v nmcli >/dev/null 2>&1; then
        printf 'Required command not found: nmcli; cannot clear the saved BSSID restriction.\n' >&2
        exit 1
    fi
else
    printf 'No locker config found; no NetworkManager BSSID restriction was changed.\n' >&2
fi

if [[ -e "$service_file" ]]; then
    sudo systemctl disable --now steamos-wifi-locker.service
fi

sudo rm -f \
    /etc/NetworkManager/dispatcher.d/90-steamos-wifi-locker \
    /etc/systemd/system-sleep/steamos-wifi-locker
if [[ -n "$connection_uuid" ]]; then
    sudo nmcli connection modify uuid "$connection_uuid" 802-11-wireless.bssid ""
fi

sudo rm -f \
    /etc/systemd/system/steamos-wifi-locker.service \
    /etc/steamos-wifi-locker/lock-bssid \
    "$config_file"
if [[ -d /etc/steamos-wifi-locker ]]; then
    if ! sudo rmdir /etc/steamos-wifi-locker; then
        printf 'Left /etc/steamos-wifi-locker in place because it is not empty or could not be removed.\n' >&2
    fi
fi

sudo systemctl daemon-reload
printf 'Uninstalled. NetworkManager will select an access point automatically on the next connection.\n'
