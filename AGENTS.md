# Flutter client for the [safe-yt-viewer](https://github.com/vrandomstuff/safe-yt-viewer) project
API documentation: https://raw.githubusercontent.com/vrandomstuff/safe-yt-viewer/refs/heads/master/API.md

## Layout
- `lib/main.dart` — entrypoint `App` → `AppHome` (stateful). On init, checks `Config.getApiUrl()` (SharedPreferences `api_url`); if unset/empty shows `ApiUrlPrompt`, otherwise loads first page of videos. `AppHome` manages loading/error states, pagination, and exposes API settings via the app bar. The legacy `MyApp`/`MyHomePage` counter demo remains in this file.
- `lib/api.dart` — `Api` uses `package:http`, reads base URL from `Config`, returns `List<VideoItem>?` for `/videos?page=N`; `postWatch(id)` hits `/watch/$id`. `VideoItem` has `fromJson`.
- `lib/config.dart` — `Config` wraps `SharedPreferencesAsync` with key `api_url` (`get/set/clearApiUrl`).
- `lib/video.dart` — `VideoEntry` (card). Taps call `Api.postWatch(video.id)` then navigate to `VideoPlayerScreen`.
- `lib/video_player_screen.dart` — plays HLS at `$apiBaseUrl/m3u8/$videoId` via `media_kit` + `media_kit_video` (`Player`/`VideoController`).
- No routing framework, state management, or DI; widgets instantiate `Api`/`Config` directly. Follow this plain-Widget style.

## Commands
- `flutter pub get` — install deps after editing `pubspec.yaml`
- `flutter analyze` — lint gate; run before considering work done
- `flutter test` — run tests (if any exist in `test/`)
- `flutter run` — dev server/hot reload

Order matters: `flutter analyze` → `flutter test`.

## CI
`.github/workflows/build.yml` builds on `push`/`PR` to `master` (and manual dispatch) with a matrix:
- Android (ubuntu-latest): `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`
- iOS (macos-latest): `flutter build ios --release --no-codesign`, then `ditto` to `build/ios/ipa/Runner.ipa`

Both jobs run `flutter pub get`, `flutter analyze`, `flutter test`.

## Gotchas
- API base URL is required. No URL → `AppHome` shows `ApiUrlPrompt` (validates http(s) with authority). Settings icon reopens it prefilled (with Cancel). If URL set but `Api.getVideos` returns null, body shows error with Retry.
- Android: `INTERNET` + `usesCleartextTraffic="true"` in `AndroidManifest.xml` (release/debug/profile include INTERNET). iOS: `NSAppTransportSecurity` allows arbitrary loads.
- Dart SDK `^3.13.5`, Flutter `3.47.6`. Dot-shorthand is used intentionally (`ColorScheme.fromSeed(...)` as `.fromSeed(...)`, alignment `.center` etc.) — don't "fix" it.
- `analysis_options.yaml` excludes `build/`, `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`; only `lib/` and `test/` are analyzed. Uses `flutter_lints`.
- No codegen, no `.env`, no Makefile/task runner. Current test suite is the stock counter test (`test/widget_test.dart`) which is tracked in git; the repo previously deleted it locally but the tracked copy still exists. Avoid breaking it if you work with tests.
- Keep changes minimal and in repo style. Always run `flutter analyze` before committing logical changes.
