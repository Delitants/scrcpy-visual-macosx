# Scrcpy Visual for macOS

A native macOS remote for Fire TV and other Android TV devices with authorized
ADB access. The remote sends Home, Back, navigation, Select, media, and volume
keys. A separate [scrcpy](https://github.com/Genymobile/scrcpy) window provides
optional screen mirroring and mouse control.

The app connects directly to the device over the local network; it does not
require a Linux relay. The Fire TV must have network ADB enabled, and its ADB
authorization prompt must already have been accepted for the key used by this
Mac. This app cannot bypass ADB authorization or pair a Bluetooth remote.
On first-generation AFTB devices, Scrcpy Visual selects the tested VP8 encoder
at 800 pixels because the device's H.264 encoder rejects screen capture.

## Build

Requires macOS 13 or later, Apple Command Line Tools or Xcode, and the official
macOS scrcpy release. Download and extract the correct architecture from
[scrcpy releases](https://github.com/Genymobile/scrcpy/releases). Then run:

```sh
SCRCPY_DIR=/path/to/extracted/scrcpy-directory ./build.sh
open "dist/Scrcpy Visual.app"
```

The entire official scrcpy release directory, including `adb` and
`scrcpy-server`, is copied into the app bundle. Its own license is included in
that directory. The remote also works without the bundled scrcpy files when
`adb` is installed at `/opt/homebrew/bin/adb` or `/usr/local/bin/adb`, but
mirroring requires a bundled scrcpy release.

Enter your device's LAN address in the app and select **Connect**. The default
ADB TCP port is `5555`; an explicit `host:port` is also accepted. The app
remembers the last address locally in macOS preferences. It uses a separate
local ADB server port so it does not interfere with your usual ADB session.

## ADB key privacy

This repository and its distributable build contain **no ADB private key**,
device address, or device serial. The app normally uses the Mac's existing ADB
key and asks the device for authorization if that key has not been approved.
For a private, local-only installation, the app also supports a key placed at:

```text
Scrcpy Visual.app/Contents/Resources/Private/home/.android/adbkey
```

The matching `adbkey.pub` may be placed alongside it. Never upload, share,
sign for distribution, or publish a copy of the app containing these files.
Anyone who obtains an authorized ADB private key could control devices that
trust it. File permissions help protect against other local users but do not
encrypt the key.

## Limitations

- ADB and scrcpy depend on a working USB or network connection and an already
  authorized key; they cannot repair a disabled ADB service.
- The remote does not replace the device's stock launcher or change what its
  Home key opens.
- Audio forwarding is disabled for compatibility with older Fire OS devices.
- The included app build is unsigned. macOS may require you to allow a locally
  built app in Privacy & Security before opening it.

The app's own source is MIT licensed. scrcpy and Android platform-tools retain
their respective upstream licenses.
