# Memory Map Mobile

Flutter client for Memo.

The app calls the real API by default. Use mock data only when you explicitly
pass `USE_MOCK_DATA=true`.

## Setup

From `apps/mobile`:

```powershell
flutter pub get
flutter devices
```

If Flutter is not on `PATH` on Windows:

```powershell
& 'C:\Users\Admin\dev\flutter\bin\flutter.bat' pub get
& 'C:\Users\Admin\dev\flutter\bin\flutter.bat' devices
```

## Run With Mock Data

```powershell
flutter run --dart-define=USE_MOCK_DATA=true --dart-define=USE_REAL_AUTH=false
```

Pick a specific device:

```powershell
flutter run -d <device-id> --dart-define=USE_MOCK_DATA=true --dart-define=USE_REAL_AUTH=false
```

## Run In Chrome

```powershell
flutter config --enable-web
flutter run -d chrome
```

With the real API on the same machine:

```powershell
flutter run -d chrome
```

Flutter web uses `localhost:5000` from `web_dev_config.yaml`. Keep Chrome on
`http://localhost:5000` for OAuth; using `127.0.0.1:5000` creates a different
browser origin and can break the login callback.

Equivalent explicit command:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 5000
```

## Run On Android Emulator

```powershell
flutter emulators
flutter emulators --launch <emulator-id>
flutter run -d emulator-5554
```

To call the API running on the Windows host from the Android emulator:

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

Use `10.0.2.2` for Android emulator access to the host machine. Use
`localhost:5000` for Windows/web runs on the host.

## Run On macOS iOS Simulator

macOS only, with Xcode installed:

```bash
open -a Simulator
flutter run -d ios
```

With the real API on the same machine:

```bash
flutter run -d ios --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1
```

## Run On Physical Devices

Use the device id from `flutter devices`. For the real API, use the LAN IP of
the machine running the backend:

```powershell
flutter run -d <device-id> --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://<LAN_IP>:3000/api/v1
```

## Desktop Preview

Desktop is not the MVP target. If needed, generate the platform folder first:

```powershell
flutter config --enable-windows-desktop
flutter create --platforms=windows .
flutter run -d windows
```

macOS:

```bash
flutter config --enable-macos-desktop
flutter create --platforms=macos .
flutter run -d macos
```

Linux:

```bash
flutter config --enable-linux-desktop
flutter create --platforms=linux .
flutter run -d linux
```

## Checks

```powershell
flutter analyze
flutter test
```
