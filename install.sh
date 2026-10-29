#!/usr/bin/env bash
set -euo pipefail

repo="dylanjphelps/steamos-wifi-locker"
release_base="https://github.com/${repo}/releases/latest/download"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

for command in curl tar nmcli systemctl sudo; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "$command" >&2
        exit 1
    fi
done

printf 'Downloading the latest SteamOS Wi-Fi BSSID Locker release...\n'
curl --fail --location --silent --show-error \
    "${release_base}/steamos-wifi-locker.tar.gz" \
    --output "${tmp_dir}/package.tar.gz"
mkdir "${tmp_dir}/package"
tar -xzf "${tmp_dir}/package.tar.gz" -C "${tmp_dir}/package"

wifi_device="$(nmcli -t --escape no -f DEVICE,TYPE,STATE device status |
    awk -F: '$2 == "wifi" && $3 == "connected" { print $1; exit }')"
if [[ -z "$wifi_device" ]]; then
    printf 'No connected Wi-Fi device found. Connect to the target network and retry.\n' >&2
    exit 1
fi

connection_uuid="$(nmcli -g GENERAL.CON-UUID device show "$wifi_device")"

if [[ ! "$connection_uuid" =~ ^[[:xdigit:]-]+$ ]]; then
    printf 'Could not determine the active NetworkManager connection UUID.\n' >&2
    exit 1
fi
if [[ ! "$wifi_device" =~ ^[[:alnum:]_.:-]+$ ]]; then
    printf 'Could not determine a valid Wi-Fi device name.\n' >&2
    exit 1
fi

printf 'Configuring adaptive BSSID selection for connection %s.\n' "$connection_uuid"
sudo install -d -m 0755 \
    /etc/steamos-wifi-locker \
    /etc/NetworkManager/dispatcher.d \
    /etc/systemd/system-sleep
sudo install -m 0755 "${tmp_dir}/package/src/lock-bssid" \
    /etc/steamos-wifi-locker/lock-bssid
sudo install -m 0755 "${tmp_dir}/package/src/dispatcher" \
    /etc/NetworkManager/dispatcher.d/90-steamos-wifi-locker
sudo install -m 0755 "${tmp_dir}/package/src/sleep-hook" \
    /etc/systemd/system-sleep/steamos-wifi-locker
sudo install -m 0644 "${tmp_dir}/package/systemd/steamos-wifi-locker.service" \
    /etc/systemd/system/steamos-wifi-locker.service
printf 'CONNECTION_UUID=%s\nWIFI_DEVICE=%s\nSIGNAL_FLOOR=40\n' \
    "$connection_uuid" "$wifi_device" |
    sudo tee /etc/steamos-wifi-locker.conf >/dev/null

sudo /etc/steamos-wifi-locker/lock-bssid
sudo systemctl daemon-reload
sudo systemctl enable --now steamos-wifi-locker.service

printf 'Installed. BSSID selection prefers 6 GHz, then 5 GHz, then 2.4 GHz, with a 40%% signal floor.\n'
