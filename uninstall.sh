#!/usr/bin/env bash
set -euo pipefail

config_file="/etc/steamos-wifi-locker.conf"
service_file="/etc/systemd/system/steamos-wifi-locker.service"

for command in sudo systemctl nmcli; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "$command" >&2
        exit 1
    fi
done

if [[ -e "$service_file" ]]; then
    sudo systemctl disable --now steamos-wifi-locker.service
fi

sudo rm -f \
    /etc/NetworkManager/dispatcher.d/90-steamos-wifi-locker \
    /etc/systemd/system-sleep/steamos-wifi-locker

connections="$(sudo nmcli -t --escape no -f UUID,TYPE connection show)"
cleared_profiles=0
while IFS=: read -r connection_uuid connection_type; do
    [[ "$connection_type" == "802-11-wireless" || "$connection_type" == "wifi" ]] || continue
    if [[ ! "$connection_uuid" =~ ^[[:xdigit:]-]+$ ]]; then
        printf 'Skipping Wi-Fi profile with invalid UUID: %s\n' "$connection_uuid" >&2
        continue
    fi
    current_bssid="$(sudo nmcli -g 802-11-wireless.bssid connection show uuid "$connection_uuid")"
    if [[ -n "$current_bssid" && "$current_bssid" != "--" ]]; then
        sudo nmcli connection modify uuid "$connection_uuid" 802-11-wireless.bssid ""
        cleared_profiles=$((cleared_profiles + 1))
    fi
done <<< "$connections"

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
printf 'Cleared BSSID restrictions from %s Wi-Fi profile(s).\n' "$cleared_profiles"
printf 'Uninstalled. NetworkManager will select an access point automatically on the next connection.\n'
