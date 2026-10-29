# SteamOS Wi-Fi BSSID Selector

Choose an access point (BSSID) for a SteamOS Wi-Fi connection, preferring higher
frequency bands while still considering signal strength. The selection is
stored in the NetworkManager connection profile and refreshed at boot, after
waking from sleep, and when Wi-Fi reconnects.

## Install

Connect to the Wi-Fi network you want to lock, open Konsole, and run:

```sh
curl -fsSL https://github.com/dylanjphelps/steamos-wifi-locker/releases/latest/download/install.sh | bash
```

The installer downloads the package attached to the latest GitHub release. It
asks for administrator permission to install and enable the service. Run it
while connected to the Wi-Fi network you want to configure; it records that
NetworkManager connection and its Wi-Fi device.

## Behavior

- The selector scans for access points with the saved network's SSID.
- It prefers 6 GHz, then 5 GHz, then 2.4 GHz, choosing the strongest signal in
  the highest band with at least 40% signal.
- If all visible access points are below 40%, it chooses the strongest one. If
  none are visible, it clears the BSSID restriction so NetworkManager can
  reconnect when the network returns.
- It reevaluates at boot, after waking from sleep, and when Wi-Fi reconnects; it
  does not continuously scan while connected.

To select a different network, connect to it and run the installer again.

## Releases

Releases are created when you push a version tag. For example:

```sh
git tag -a v1.0.2 -m "v1.0.2"
git push origin v1.0.2
```

The workflow attaches `install.sh` and `steamos-wifi-locker.tar.gz` to the
release. Pushing to `main` does not create a tag or release. The one-line
install command fetches assets from the latest release.
