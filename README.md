# GeckoLite

GeckoLite is a Flutter crypto research app built with Flutter Riverpod 2.x and a
feature-first clean architecture. It consumes the companion FastAPI service and
supports market browsing, coin details and charts, global market metrics, a
per-device watchlist, and persisted display preferences. The Home screen loads a
single top-N market page and applies sorting and filters locally.

## Requirements

- Flutter SDK compatible with Dart 3.13 or later
- The FastAPI backend running locally or deployed

## Setup and run

From this directory:

```bash
flutter pub get
flutter run
```

The app uses the deployed API at `https://crypto-api-hyqi.onrender.com` by
default. To use a local backend instead, pass its URL with
`--dart-define=API_BASE_URL=...`. `10.0.2.2` routes from the Android emulator to
the development computer. For a physical device, use the computer's LAN IP and
ensure both devices are on the same network:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
# Physical device example:
flutter run --dart-define=API_BASE_URL=http://192.168.1.25:8000
```

Run tests and static analysis:

```bash
flutter test
flutter analyze
```

## Android APK builds

Every push to `main` (including a pull request merge) runs the
[Android APK workflow](.github/workflows/android-apk.yml). It analyzes the app,
runs tests, builds a release-mode APK, and stores it as a GitHub Actions
artifact for 30 days. Open the successful workflow run under the repository's
**Actions** tab and download the `crypto-research-release-...` artifact.
You can also start a build manually from the workflow's **Run workflow** option.

The Android release build currently uses the debug signing configuration in
`android/app/build.gradle.kts`; use this APK for testing, not Play Store
distribution. Configure a protected production keystore and release signing
before publishing.

## Architecture

```text
Presentation (screens, widgets, Notifier / AsyncNotifier controllers)
             │ watches state; controllers depend on interfaces only
             ▼
Domain (entities and abstract repository contracts)
             ▲
             │ repository implementations map DTOs and failures
Data (DTOs, remote data sources, repository implementations)
             │
             ▼
Core Dio client ── FastAPI /api endpoints
```

Each feature owns its domain contracts, data mapping, and presentation code.
Riverpod providers bind repository interfaces to their implementations.
`X-Device-ID` is generated once and stored in SharedPreferences; the Dio client
adds it to every request. Settings are persisted locally. API failures are
mapped to typed `Failure` values, and source headers are surfaced in the UI.

## Folder overview

- `lib/core/`: design tokens, themes, routing, Dio, error types, providers, and
  formatting helpers.
- `lib/shared/widgets/`: common loading, error, empty, market tile, chart, and
  connectivity UI.
- `lib/features/market/`: Home market list, filtering, sorting, search, bottom
  sheets, controllers, and its repository.
- `lib/features/coin_details/`: coin fundamentals, price chart, and links.
- `lib/features/watchlist/`: device watchlist and optimistic updates.
- `lib/features/settings/`: theme, currency, and auto-refresh preferences.
- `test/`: formatter and repository unit tests plus shared widget tests.
