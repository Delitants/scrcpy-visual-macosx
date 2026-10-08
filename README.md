# Scrcpy Visual

A native macOS remote for Android TV devices and Android boxes. It sends navigation, media, and volume keys over ADB and opens a separate scrcpy mirror window.

## Get started

1. Download the [Apple Silicon app](https://github.com/Delitants/scrcpy-visual-macosx/releases/latest) for macOS 13 or later.
2. Enable network ADB on your Android device and authorize your Mac's ADB key.
3. Open Scrcpy Visual, enter the device's address, and select **Connect**.

Use the remote buttons for control. Choose **Mirror Size** before opening the screen mirror; changes take effect when you reopen it. Automatic uses the device resolution, except on first-generation AFTB devices, where it uses the tested 800 px VP8 setting. Higher sizes may not work on older devices.

## Build from source

Install Xcode Command Line Tools, then download and extract the appropriate [official scrcpy release](https://github.com/Genymobile/scrcpy/releases):

```sh
SCRCPY_DIR=/path/to/extracted/scrcpy ./build.sh
```

The public app does not include an ADB key. Scrcpy Visual is MIT licensed; bundled scrcpy and ADB retain their upstream licenses.
