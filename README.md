<div align="center">

<img src="web/og-card.png" alt="LeadUnity" width="620">

**The academic portal for thesis and project proposals.**

Form a team, submit a proposal, get matched with a supervisor, and track every approval in one place.

[**leadunity.vercel.app**](https://leadunity.vercel.app) · Flutter Web + Android

</div>

---

## What it is

LeadUnity replaces the email-and-spreadsheet scramble that surrounds final-year thesis and project proposals. Students form teams and submit proposals; supervisors review, accept, and mark them; the department admin oversees the whole cycle from a separate web panel.

The app ships to two surfaces from one codebase — a **web build** deployed on Vercel and an **Android APK** — and stays usable on flaky campus connections through an aggressive cache-first data layer.

## Features

### For students
- Register with a student ID, then sign in with ID + password
- Request or join a team, and view current team composition
- Browse available supervisors and courses
- Download the official proposal template, and submit a proposal against a course
- Track proposal status and marks as supervisors act on them
- See the submission deadline set by the department

### For supervisors
- Sign in with a capitalized abbreviation (e.g. `EBH`) and a temporary password issued by the admin
- Forced password change on first login
- Browse assigned teams and drill into team details
- Award marks against submitted proposals

### Shared
- Push notifications (Firebase Cloud Messaging) with an in-app notification centre and unread badge
- Light/dark theme following the system setting
- Built-in chatbot assistant for common questions
- Offline-tolerant: cached data renders instantly, then refreshes in the background
- Connectivity overlay when the network drops

> **Admin actions** — account management, supervisor assignment, and triggering notifications — live in a **separate web panel**, not in this app.

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter **3.41.6** (Dart 3.11.4), Material 3 |
| State | `provider` — `AuthProvider`, `DataProvider`, `ThemeProvider` |
| Networking | `dio` with a 401 interceptor that force-logs-out on token expiry |
| Auth storage | `flutter_secure_storage` (JWT) |
| Cache | `shared_preferences` (JSON snapshots) |
| Push | Firebase Cloud Messaging + `flutter_local_notifications` |
| Hosting | Vercel (web), APK sideload (Android) |
| Backend | NestJS on Vercel — **separate repository** |

About **12,000 lines** of Dart across 41 files.

## Architecture

```
lib/
├── main.dart                 # Firebase init, FCM handlers, MultiProvider, app entry
├── home_page.dart            # Post-login role router
├── chatbot_screen.dart       # Chatbase assistant in a WebView
│
├── authentication/           # Login, forgot password, reset password
├── student/                  # Dashboard, registration, team request, proposal submit, template
├── supervisor/               # Dashboard, team list, team details, marking, temp-password change
│
├── providers/
│   ├── auth_provider.dart    # JWT lifecycle, auto-login, role resolution
│   └── data_provider.dart    # Cache-first fetches for every shared entity
├── services/
│   ├── api_services.dart     # Every backend call lives here
│   └── notification_service.dart
├── models/                   # user_model.dart
├── theme/                    # app_theme.dart, theme_provider.dart
└── widgets/                  # Shared UI: dialogs, snackbars, skeletons, overlays
```

### The data layer

`DataProvider` follows one pattern for every entity — **render the cache instantly, then refresh in the background**:

1. Read the last JSON snapshot from `SharedPreferences` and emit it immediately
2. Fire the network request
3. On success, overwrite the cache and re-emit

Each entity exposes a `fetchXIfNeeded({forceRefresh})` method plus an `isLoadingX` flag: teams, supervisors, courses, my proposals, deadline, notifications, and my team. Pull-to-refresh passes `forceRefresh: true`.

This is why the app feels instant on a second launch and stays readable with no connection.

### Backend

All calls go through `ApiService` against:

```
https://leading-unity-nest-backend.vercel.app/api
```

Endpoints cover `/auth/*` (login, register, change/forgot/reset password, OTP), `/users`, `/courses`, `/settings`, `/proposals` (including paginated listing and `/my`, `/my-team`, `/:id/marks`), and `/notifications`.

> The backend is owned by a teammate and lives in its own repo. **Do not change API contracts unilaterally.** Field spellings vary between endpoints, so the client defensively checks several key variants (`abbreviation` / `abbr` / `shortName`, `studentId` / `student_id`).

## Getting started

**Prerequisites** — Flutter `3.41.6` (the version CI pins; other 3.x releases will likely work) and a device, emulator, or Chrome.

```bash
git clone https://github.com/arifhaxn/lead_unity.git
```

```bash
cd lead_unity && flutter pub get
```

Run on Chrome:

```bash
flutter run -d chrome
```

Run on Android:

```bash
flutter run -d android
```

### Local web development and CORS

The backend does not allow `localhost` origins, so a plain `flutter run -d chrome` fails CORS. Use the bundled VS Code launch configuration **“LeadUnity Web (No CORS)”**, which passes `--web-browser-flag=--disable-web-security`. See `.vscode/launch.json`.

## Building

```bash
flutter build web --release
```

```bash
flutter build apk --release
```

## Deployment

The web app deploys to Vercel **automatically on every push to `main`**. No manual step.

Vercel builds Flutter itself, driven by [`vercel.json`](vercel.json):

- `tool/vercel_install.sh` downloads a **version-pinned** Flutter SDK (3.41.6) and runs `flutter pub get`
- `tool/vercel_build.sh` runs `flutter build web --release`
- Output directory is `build/web`; a rewrite sends all routes to `index.html` for client-side routing

A build takes roughly three minutes. A manual deploy remains available as a fallback:

```bash
cd build/web && vercel --prod
```

## Conventions and gotchas

Things that will bite you if you don't know them.

**Filename case.** Development happens on Windows, where git runs with `core.ignorecase=true` — but Vercel builds on Linux, which is case-sensitive. An asset named `logo.PNG` referenced as `logo.png` builds fine locally and **fails every CI build**. After touching assets, confirm the on-disk name matches the reference exactly.

**Android identifiers.** `applicationId` is `com.example.leadunity` and must keep matching `google-services.json`, or push notifications break. It deliberately differs from `namespace` (`com.example.link_unity`), which is internal and not worth renaming — the `MainActivity.kt` directory path would have to move with it.

**Web builds are not optional.** Every change must work on web, not just Android. Guard platform-specific code with `kIsWeb` and avoid `dart:io`.

**Layout.** Wrap main screen bodies in the custom `WebConstraint` (max width 700) so the web build doesn't stretch across a desktop monitor.

**Theming.** Read colors from `Theme.of(context).colorScheme` rather than hardcoding. Brand color is emerald `#10B981`.

**Shared UI.** Prefer the existing widgets — `AnimatedSubmitButton` for form submission, `CustomSnackBar` for toasts, `FadeScaleRoute` for transitions, and the skeleton loaders for pending states.

**Android 12+ splash** is configured through native XML — `windowSplashScreenBackground` in `res/values-night-v31/styles.xml`, with `launch_background` drawables for older versions. Do not add a splash package. The in-app `SplashScreen` widget is a separate 1-second brand animation.

## Project layout beyond `lib/`

| Path | Purpose |
|---|---|
| `web/` | Web shell: `index.html` (Open Graph tags, iOS icon), `manifest.json`, icons, FCM service worker |
| `tool/` | Vercel build scripts |
| `assets/logo/` | Logo and share card |
| `assets/template/` | Proposal template pages and crew photos |
| `apk/` | Separate sub-project, unrelated to the app |

## Team

Built by **Arif Hasan**, **Shomo Shahriar Araf**, and **Omio Mahim** — Batch 61.
