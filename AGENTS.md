# Flutter client for the [safe-yt-viewer](https://github.com/vrandomstuff/safe-yt-viewer) project
API documentation: https://raw.githubusercontent.com/vrandomstuff/safe-yt-viewer/refs/heads/master/API.md

## Layout
- `lib/main.dart` — entrypoint `App` → `AppHome` (stateful; fetches page 1 of videos in `initState`, shows a spinner while loading). The stock `MyApp`/`MyHomePage` counter demo is still in this file.
- `lib/api.dart` — `Api` (HTTP via `package:http`) and the `VideoItem` model with `fromJson`.
- `lib/config.dart` — `Config`; API base URL persisted in `SharedPreferencesAsync` under key `api_url`.
- `lib/video.dart` — `VideoEntry`, the thumbnail/title/channel card.
- No routing, state management, or DI: `Api`/`Config` are instantiated directly, and even private-backed named params (`required this._video`) are used. Follow this plain-Widget style.

## Commands
- `flutter pub get` — install deps (run after editing `pubspec.yaml`)
- `flutter analyze` — lint gate; run before considering work done
- `flutter test` — full suite; `flutter test test/widget_test.dart` for one file
- `flutter run` — dev server/hot reload

Order matters: `flutter analyze` → `flutter test`.

## Gotchas
- The app needs an API base URL set via `Config.setApiUrl` (SharedPreferences `api_url`). If unset, `AppHome` shows the `ApiUrlPrompt` screen so the user can enter one; the settings icon in the app bar reopens it to change the URL. When the URL is set but `Api.getVideos` returns null, the body shows an error with a Retry button.
- `test/widget_test.dart` still tests the stock `MyApp` counter demo, not the real `App`. Changing `AppHome` won't break it; renaming/removing `MyApp` will.
- Dart SDK `^3.13.5` (Flutter 3.47.6). Dot-shorthand is used intentionally, e.g. `ColorScheme.fromSeed(...)` as `.fromSeed(...)` and `MainAxisAlignment.center` as `.center` — don't "fix" it.
- `analysis_options.yaml` excludes `build/`, `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` — only `lib/` and `test/` are analyzed. `flutter_lints` with no extra rules.
- No codegen, no `.env`, no Makefile/task runner — the commands above are the whole workflow. CI is `.github/workflows/build.yml` (matrix across Android/iOS, runs analyze + test).
- You should not do `flutter build` that breaks vscode.