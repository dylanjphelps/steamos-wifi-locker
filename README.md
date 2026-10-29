# SteamOS Wi-Fi BSSID Locker

Lock a SteamOS device's active Wi-Fi connection to the access point (BSSID) it
is currently using. The lock is stored in the NetworkManager connection profile,
so it applies when the device reconnects after boot, waking from sleep, or
toggling Wi-Fi off and on.

## Install

Connect to the Wi-Fi network you want to lock, open Konsole, and run:

```sh
curl -fsSL https://github.com/dylanjphelps/steamos-wifi-locker/releases/latest/download/install.sh | bash
```

The installer downloads the package attached to the latest GitHub release. It
asks for administrator permission to install and enable the service. Run it
while connected to the target network; it locks the active NetworkManager
connection to the BSSID currently in use.

## Behavior

- A system service reapplies the lock at boot.
- A NetworkManager dispatcher hook reapplies it when a Wi-Fi device comes up.
- A system-sleep hook reapplies it after suspend or hibernation.
- The connection profile itself is configured with the chosen BSSID, so the
  access point is selected during reconnection rather than after it.

To select a different access point, connect to it and run the installer again.

## Releases

Push a version tag such as `v1.0.0` to create a GitHub release. The release
workflow attaches `install.sh` and `steamos-wifi-locker.tar.gz`, which are the
assets used by the one-line install command.
