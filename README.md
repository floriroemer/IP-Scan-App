# RMR IP Scan

RMR IP Scan is a Flutter app for scanning your local Wi-Fi network and listing reachable devices on the subnet.

## Features

- Scan the current local network for reachable hosts.
- Modern dark UI with a branded RMR title.
- Progress feedback while the scan is running.
- Android, iOS, and Windows project targets included.

## Tech Stack

- Flutter
- network_info_plus
- lan_scanner
- google_fonts

## Running The App

Install dependencies:

```bash
flutter pub get
```

Run on Windows:

```bash
flutter run -d windows
```

Run on Android with a connected device:

```bash
flutter run -d android
```

Build an Android APK:

```bash
flutter build apk --debug
```

## Android Notes

The app requires network and location-related permissions to resolve the local Wi-Fi IP and scan the LAN. These are already configured in the Android manifest.

## iOS Notes

The app includes the required local network and location usage descriptions in the iOS plist. Building for iOS still requires Xcode on macOS.