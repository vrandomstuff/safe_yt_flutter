## PERMISSION RULES — READ FIRST

- **NEVER EVER edit, create, overwrite, or delete any file without explicit permission from the user.** Answering a question or describing a change does NOT authorize implementing it — ask first, wait for a yes.
- This includes "harmless" operations that modify files: git commands that touch files (`git checkout --`, `git restore`, `git stash`), etc.
- Your user is the owner of all of the files they have the final say no matter what.
- You may not ever modify this yourself.

# safe_yt_flutter

Flutter client for [safe-yt-viewer](https://github.com/vrandomstuff/safe-yt-viewer).
Upstream API contract (read it before touching `lib/api.dart`):
https://raw.githubusercontent.com/vrandomstuff/safe-yt-viewer/refs/heads/master/API.md

## Commands
- `flutter pub get` — after editing `pubspec.yaml`
- `flutter analyze` — **the only quality gate.** CI does not run it (see CI below), so run it yourself before calling work done.
- `flutter run` — needs a reachable backend URL typed into the in-app prompt. Nothing is configured via `.env` or a build flag.
- There is no `test/` directory and none is tracked. `flutter test` exits 1 with `Test directory "test" not found`. Do not add a test step to CI without first writing tests.

Toolchain: Dart `^3.13.5`, Flutter `3.47.6` (CI pins this), AGP 9.1.0, Kotlin 2.4.0, Java 17.

## API base URL — the easiest thing to get wrong
- The user-entered base URL **must end in `/api`**, and that is by design: the same server also hosts a web app, so every client route lives under `/api`. Do **not** prepend `/api` inside `lib/api.dart` to "fix" the mismatch — the user supplies it.
- `Api.getVideos` builds `"<base>/$route?page=N"` with `route` defaulting to `"videos"` (`"pins"` on the pins screen), so entering `http://host:3000` requests `http://host:3000/videos` — but the server only serves `/api/videos`. The origin alone yields a bare "Could not load videos from …".
- The URL is typed into `ApiUrlPrompt` on first launch and persisted in SharedPreferences under `api_url`. There is no env file, build flag, or default; clearing app data resets it. `_saveApiUrl` only strips trailing slashes.
- Routes the client touches: `videos`, `pins`, `POST watch/{id}`, `m3u8/{id}`. The server also exposes `search`, `channel`, `getAvatar/{id}/{secret}`, `reCache/{id}/{secret}` — none are wired up.
- `m3u8/{id}` playlist segment URIs come back **root-relative** (`/api/m3u8/...`), so they resolve against the origin, not the base URL. The first request spawns `yt-dlp` server-side and can take seconds.

## Known sharp edges in `lib/`
- `Api.getVideos` returns `null` for both "no base URL configured" and "non-200 status" — the UI cannot tell the two apart.
- No `try`/`catch` anywhere around the `http` calls. A connection failure throws an unhandled async error and leaves the loading spinner up forever.
- `POST /watch/{id}` is **not idempotent** server-side; `VideoEntry` fires one on every tap, so a double-tap records twice.
- The server returns a **bare JSON array** with no wrapper and no total count, so there is no end-of-list signal. `_loadMore` just keeps incrementing `_page`.
- `_AppHomeState._fetchVideos` / `_buildBody` and `_ViewPinsState._fetchVideos` / `_buildBody` are near-duplicates. Change one, check the other. `ViewPins` does **not** check for a configured URL, so with none set it just renders the generic error.
- `_VideoPlayerScreenState._initializeVideoPlayer` throws `FlutterError` when the URL or video id is missing, rather than showing an error state.

## Layout
- `lib/main.dart` — `App` → `AppHome`; also `ViewPins` (pushed from the app bar pin icon) and `ApiUrlPrompt`.
- `lib/api.dart` — `Api` (reads the base URL from `Config` via `package:http`) plus `VideoItem.fromJson`.
- `lib/config.dart` — `Config`, a thin `SharedPreferencesAsync` wrapper keyed `api_url`.
- `lib/video_list.dart` — `VideoList`: a `Wrap` grid of `VideoEntry` cards plus a "load more" button.
- `lib/video.dart` — `VideoEntry` card; tap → `postWatch` then push `VideoPlayerScreen`.
- `lib/video_player_screen.dart` — plays `<base>/m3u8/{id}` with `media_kit` + `media_kit_video`.
- No routing framework, no state management, no DI — widgets instantiate `Api`/`Config` directly. Follow that plain-Widget style.

## Conventions that look wrong but are not
- **Dart 3.12 private named parameters.** `VideoEntry({required this._video})` is *called* as `VideoEntry(video: …)`; `VideoList({required this._videos, required this._loadMore})` as `VideoList(videos: …, loadMore: …)`. The underscore is stripped at the call site — renaming either side breaks it.
- `VideoList._loadMore` is typed `dynamic`, so the callback is unchecked at the call site.
- Each `VideoEntry` constructs its own `Api` (→ own `Config` → own `SharedPreferencesAsync`); so do `_AppHomeState` and `_ViewPinsState`. Adding cards multiplies those instances.

## Platform config
- Android ships `usesCleartextTraffic="true"`; iOS ships `NSAppTransportSecurity/NSAllowsArbitraryLoads`. Both exist so the app can reach an `http://` LAN backend — don't remove them.
- Android release builds are signed with the **debug** key (`android/app/build.gradle.kts`); no real signing config exists yet.
- `analysis_options.yaml` excludes every platform directory, so only `lib/` is ever analyzed.
- `.metadata` lists `lib/main.dart` and `ios/Runner.xcodeproj/project.pbxproj` as `unmanaged_files` — `flutter migrate` will not touch them.

## App identity
Display name is "Safe YT"; application/bundle ID is `io.github.vtf6259.safe_yt_flutter` on all six platforms. Changing either means editing each platform separately — Android `build.gradle.kts` (`namespace` + `applicationId`), `AndroidManifest.xml` (`android:label`), and `MainActivity.kt`'s package **and its directory path**; iOS `Info.plist` + `project.pbxproj`; macOS `Configs/AppInfo.xcconfig` (`PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER`); Linux `CMakeLists.txt` `APPLICATION_ID` + `my_application.cc`; Windows `Runner.rc` + `main.cpp`; Web `index.html` + `manifest.json`.

Do **not** change `name:` in `pubspec.yaml` from `safe_yt_flutter` — every `package:safe_yt_flutter/...` import depends on it.

## CI
`.github/workflows/build.yml` — on push/PR to `master` and `workflow_dispatch`, matrix of:
- Android (ubuntu-latest): `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`
- iOS (macos-latest): `flutter build ios --release --no-codesign`, then `ditto` → `build/ios/ipa/Runner.ipa`

Steps are `flutter pub get` + build, nothing else. There is **no** analyze or test step, so lint and test regressions reach `master` silently.