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

if [[ ! "$wifi_device" =~ ^[[:alnum:]_.:-]+$ ]]; then
    printf 'Could not determine a valid Wi-Fi device name.\n' >&2
    exit 1
fi

printf 'Configuring adaptive BSSID selection for Wi-Fi device %s.\n' "$wifi_device"
sudo install -d -m 0755 \
    /etc/steamos-wifi-locker \
    /etc/NetworkManager/dispatcher.d
sudo install -m 0755 "${tmp_dir}/package/src/lock-bssid" \
    /etc/steamos-wifi-locker/lock-bssid
sudo install -m 0755 "${tmp_dir}/package/src/dispatcher" \
    /etc/NetworkManager/dispatcher.d/90-steamos-wifi-locker
sudo install -m 0644 "${tmp_dir}/package/systemd/steamos-wifi-locker.service" \
    /etc/systemd/system/steamos-wifi-locker.service
sudo rm -f /etc/systemd/system-sleep/steamos-wifi-locker
printf 'WIFI_DEVICE=%s\nSIGNAL_FLOOR=70\n' "$wifi_device" |
    sudo tee /etc/steamos-wifi-locker.conf >/dev/null

sudo systemctl daemon-reload
sudo systemctl disable --now steamos-wifi-locker.service
sudo systemctl start --no-block steamos-wifi-locker.service

printf 'Installed. BSSID selection prefers 6 GHz, then 5 GHz, then 2.4 GHz, with a 70%% signal floor.\n'
