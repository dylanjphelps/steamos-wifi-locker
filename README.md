# SteamOS Wi-Fi BSSID Selector

Choose an access point (BSSID) for whichever SteamOS Wi-Fi network is currently
connected, preferring higher frequency bands while still considering signal
strength. The selection is stored in that NetworkManager profile and refreshed
when the Wi-Fi connection changes, at boot, and after waking from sleep. A
changed selection applies on the next connection; the selector does not force
an active connection to reconnect.

## Install

Connect to the Wi-Fi network you want to lock, open Konsole, and run:

```sh
curl -fsSL https://github.com/dylanjphelps/steamos-wifi-locker/releases/latest/download/install.sh | bash
```

The installer downloads the package attached to the latest GitHub release. It
asks for administrator permission to install and enable the service. Run it
while connected to Wi-Fi; it records the Wi-Fi device, not a particular SSID.

## Uninstall

Open Konsole and run:

```sh
curl -fsSL https://github.com/dylanjphelps/steamos-wifi-locker/releases/latest/download/uninstall.sh | bash
```

The uninstaller stops and disables the service, clears BSSID restrictions from
all saved Wi-Fi profiles, and removes the locker files.

## Behavior

- When a Wi-Fi connection goes down, the selector clears that profile's BSSID
  restriction. When a connection comes up, it scans for access points matching
  the active profile's SSID.
- It prefers 6 GHz, then 5 GHz, then 2.4 GHz, choosing the strongest signal in
  the highest band with at least 70% signal.
- If all visible access points are below 70%, it chooses the strongest one. If
  none are visible, it clears the BSSID restriction so NetworkManager can
  reconnect when the network returns.
- If NetworkManager cannot scan, the selector reports an error and leaves the
  profile's current BSSID restriction unchanged.
- It reevaluates at boot, after waking from sleep, and when Wi-Fi reconnects; it
  does not continuously scan while connected.

Changing to another saved network automatically triggers a scan and selection
for that network; reinstalling is not necessary.

## Releases

Releases are created when you push a version tag. For example:

```sh
git tag -a v1.0.4 -m "v1.0.4"
git push origin v1.0.4
```

The workflow attaches `install.sh`, `uninstall.sh`, and
`steamos-wifi-locker.tar.gz` to the release. Pushing to `main` does not create a
tag or release. The one-line install command fetches assets from the latest
release.
