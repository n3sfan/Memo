# Memory Map Mobile

Flutter client for Memo.

## Run On Android Emulator

From `apps/mobile`:

```powershell
flutter pub get
flutter run -d emulator-5554
```

The app uses mock repositories by default, so it can launch without the backend.

To call the API running on the Windows host from the Android emulator:

```powershell
flutter run -d emulator-5554 --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://10.0.2.2:3021/api/v1
```

Use `10.0.2.2` for Android emulator access to the host machine. Use
`127.0.0.1` only for Windows/web runs on the host.

## Checks

```powershell
flutter analyze
flutter test
```
