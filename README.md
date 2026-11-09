# Crypto Research App

Crypto Research App is a Flutter app built with Flutter Riverpod 2.x and a
feature-first clean architecture. It consumes the companion FastAPI service and
supports market browsing, coin details and charts, global market metrics, a
per-device watchlist, and persisted display preferences. The Home screen loads a
single top-N market page and applies sorting and filters locally.

## Features

- Browse paginated market and trending coin data; filter and sort the loaded
  market list locally.
- Search coins with debounced API requests.
- View coin market statistics, historical data, line/candlestick charts, and
  selectable chart ranges.
- Inspect global market capitalization, volume, and dominance.
- Maintain a per-device watchlist and choose currency, theme, and refresh
  preferences.
- Use responsive loading, error, offline, and empty states throughout the app.

The backend may serve live CoinGecko data, cached data, or mock fixtures. The
app surfaces the API's data-source indicator. Its real-time-looking price
updates are simulated demo data, not live exchange prices.

## Technology stack

- **Flutter / Dart** for the mobile and web-capable client.
- **Riverpod** for application state and feature controllers.
- **GoRouter** for navigation.
- **Dio** for REST requests; `web_socket_channel` for the demo price stream.
- **fl_chart** for market charts; Flutter SVG and cached network images for
  assets.
- **SharedPreferences** for the device identifier and persisted preferences.
- **flutter_screenutil**, Material, Google Fonts, `intl`, and Shimmer for
  responsive UI and presentation.
- **Flutter test** and `flutter_lints` for testing and static analysis.

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

The test suite includes widget tests for responsive market screens, settings,
watchlist interactions, chart widgets, and repository/provider behavior.

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

## App architecture

```text
Screens and feature widgets
             ▼
Riverpod controllers
             ▼
Feature repositories and domain contracts
             ▼
Dio client ── FastAPI /api endpoints
```

Each feature keeps its domain, data, and presentation code together. Repository
providers connect controllers to repository implementations; reusable
components and coin API mapping live under `lib/shared/`, and app-wide
infrastructure lives under `lib/core/`. The `X-Device-ID` value is generated
once and persisted in SharedPreferences. The Dio client sends it with requests
so the backend can scope watchlists to the app installation. API errors map to
typed failures and response data-source headers are surfaced in the UI.

## Folder overview

- `lib/core/`: design tokens, themes, routing, Dio, error types, providers, and
  formatting helpers.
- `lib/shared/`: reusable components, including shared widgets and coin API
  mapping.
- `lib/features/market/`: Home market list, filtering, sorting, search, bottom
  sheets, controllers, and its repository.
- `lib/features/coin_details/`: coin fundamentals, price chart, and links.
- `lib/features/watchlist/`: device watchlist and optimistic updates.
- `lib/features/settings/`: theme, currency, and auto-refresh preferences.
- `test/`: formatter and repository unit tests plus shared widget tests.
