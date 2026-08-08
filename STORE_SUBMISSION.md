# RYSE CRM — Store Submission Guide

Everything needed to build signed release binaries and submit to the **Apple
App Store** and **Google Play**. The app name is **RYSE CRM**; the app
identifier is **`com.ryse.crm`** on both platforms.

> **Confirm identity before you submit.** App name (`RYSE CRM`) and bundle ID
> (`com.ryse.crm`) are effectively permanent once the app is created in App
> Store Connect / Play Console. If the store listing should read **Jeeym** (or
> another name/identifier), change it first — see “Rename / rebrand” below.

> **Backend / live sync.** The app runs fully offline via **Continue as guest**
> (local sample data). To sync against your live backend, users tap
> **Continue with Jeeym** and sign in with their workspace URL + credentials.
> Set the default workspace host at build time with
> `--dart-define=JEEYM_API_URL=https://app.jeeym.com` (defaults to
> `https://app.jeeym.com`). The tRPC path is `<host>/api/trpc`.

### ✅ Verified in this repo (Flutter layer)

- `flutter analyze` → **no issues**.
- `flutter test` → **all pass** (49 tests; 7 backend-integration tests skip
  automatically without a live server).
- `flutter build bundle --release` → **compiles the whole app** and bundles the
  `Google Sans` font family correctly.
- **App icons**: real RYSE mark generated for iOS (opaque, no alpha — App Store
  requirement) and Android (legacy + adaptive). The default Flutter icon is
  gone.
- **Export compliance**: `ITSAppUsesNonExemptEncryption = false` set in
  `Info.plist` (skips the encryption prompt on every upload).

> The **iOS `.ipa` archive and the Android `.aab` must still be built on the
> respective toolchains** — a Mac with Xcode for iOS, and a machine with the
> Android SDK for Play. Those steps can’t run in this cloud environment; follow
> the platform sections below.

### A note on the app font

The UI uses a family registered as **`Google Sans`**. Google Sans is a
proprietary Google typeface and cannot be redistributed, so the repo bundles
**DM Sans** (SIL OFL 1.1) under that family name as a visual stand-in. If you
hold a Google Sans license, replace the four TTFs in `assets/fonts/` with the
real weights (same filenames) — no code change needed.

---

## 0. Versioning

Version lives in `pubspec.yaml`:

```yaml
version: 1.0.0+1     #  <marketing version> + <build number>
```

- **`1.0.0`** → CFBundleShortVersionString (iOS) / versionName (Android) — the
  public version.
- **`+1`** → CFBundleVersion (iOS) / versionCode (Android) — the build number.
  **Increment it on every upload**, even for the same public version.

Bump examples: `1.0.0+2`, `1.0.1+3`, `1.1.0+4`.

---

## 1. Android → Google Play (`.aab`)

### One-time: create the upload keystore

```bash
keytool -genkey -v -keystore ~/ryse-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Copy `android/key.properties.example` to `android/key.properties` and fill in
the passwords, alias (`upload`), and the absolute `storeFile` path.
`key.properties` and `*.jks` are already git-ignored — **never commit them, and
back up the keystore; losing it means you can't update the app.**

The Gradle config (`android/app/build.gradle.kts`) automatically signs release
builds with this key when `key.properties` is present, and falls back to debug
signing when it isn't.

### Build the App Bundle

```bash
flutter clean
flutter pub get
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

(Or a universal APK for sideloading: `flutter build apk --release`.)

### Upload

1. [Google Play Console](https://play.google.com/console) → create app **RYSE CRM**.
2. Complete the listing: description, screenshots (`docs/screenshots/`),
   feature graphic, privacy policy URL, content rating, data-safety form.
3. Release → Production (or Internal testing first) → upload the `.aab`.
4. First upload enrolls you in Play App Signing (recommended).

**Requirements met:** `targetSdk` follows Flutter's current default; app ID
`com.ryse.crm`; adaptive launcher icons present under
`android/app/src/main/res/mipmap-*`.

---

## 2. iOS → App Store (requires macOS + Xcode)

### One-time

- Apple Developer Program membership.
- In [App Store Connect](https://appstoreconnect.apple.com): create an app with
  bundle ID **`com.ryse.crm`** and name **RYSE CRM**.
- Open `ios/Runner.xcworkspace` in Xcode → **Runner → Signing & Capabilities** →
  select your Team; let Xcode manage signing (or use a manual distribution
  provisioning profile).

### Build & upload

```bash
flutter clean
flutter pub get
flutter build ipa --release
# → build/ios/archive/Runner.xcarchive and build/ios/ipa/*.ipa
```

Then either:
- Open the archive in **Xcode → Organizer → Distribute App → App Store Connect**, or
- `xcrun altool`/**Transporter** app to upload `build/ios/ipa/ryse_crm.ipa`.

Submit for review from App Store Connect once the build finishes processing.

**Requirements met:** bundle ID `com.ryse.crm`; display name **RYSE CRM**
(`CFBundleDisplayName`); full **opaque** app-icon set (RYSE mark) under
`ios/Runner/Assets.xcassets/AppIcon.appiconset`; launch storyboard present;
`ITSAppUsesNonExemptEncryption = false`.

### App Store review access

Apple reviewers need to reach the app without your backend. On the login
screen, **Continue as guest** opens the full app with local sample data — call
this out in **App Review Information → Notes** ("Tap *Continue as guest* to
explore the app; no account required"). No demo credentials needed.

---

## 2b. Rename / rebrand (e.g. to “Jeeym”) — do this BEFORE first submission

If the store listing should not read “RYSE CRM”:

1. **Display name** — iOS: `CFBundleDisplayName` in `ios/Runner/Info.plist`.
   Android: `android:label` in `android/app/src/main/AndroidManifest.xml`.
2. **Bundle / application ID** — iOS: `PRODUCT_BUNDLE_IDENTIFIER` in
   `ios/Runner.xcodeproj/project.pbxproj` (3 configs). Android: `applicationId`
   in `android/app/build.gradle.kts`.
3. **In-app wordmark** — `RyseWordmark` / “Welcome to RYSE” copy in
   `lib/features/auth/login_screen.dart` and the app-bar logo.
4. **App icon glyph** — edit `test/tools/generate_icons_test.dart`, re-run it,
   then `dart run flutter_launcher_icons`.

Tell me the final name + identifier and I can apply all of this in one pass.

---

## 3. Store listing assets

- **Screenshots:** ready-made in [`docs/screenshots/`](docs/screenshots) —
  login, dashboard, Capture Lead, pipeline Kanban, leads, opportunity (sales
  path), lead detail, AI assistant, tasks, reports, calendar, menu, and the
  full shell (nav bar). Regenerate any time with:
  ```bash
  flutter test test/screenshots/screenshots_test.dart --update-goldens
  ```
  These render at 390×844 @2x (≈780×1688). Apple/Google want specific
  device-frame sizes (e.g. 1290×2796 for 6.7"); capture on a simulator/emulator
  at those sizes, or frame these in a tool like Fastlane `frameit`.
- **App icon:** real RYSE mark, already generated for both platforms (masters in
  `assets/branding/`, rendered by `test/tools/generate_icons_test.dart`). To
  rebrand, edit that test, re-render, then `dart run flutter_launcher_icons`.
- **Privacy:** guest mode stores data only on-device; live mode talks to your
  own Jeeym backend. Fill the Play **Data safety** and Apple **App Privacy**
  forms to match your backend's data handling.

---

## 4. Pre-flight checklist

Already done in this repo:

- [x] `flutter analyze` clean, `flutter test` green (49 tests).
- [x] `flutter build bundle --release` compiles the whole app; fonts bundle.
- [x] Real app icons (iOS opaque + Android adaptive); no default Flutter icon.
- [x] `ITSAppUsesNonExemptEncryption = false` in `Info.plist`.
- [x] Guest access for App Review (no backend needed).

Do before you submit (needs your accounts / a Mac / the Android SDK):

- [ ] Confirm final app name + bundle ID (or rebrand per §2b).
- [ ] Bump version/build number in `pubspec.yaml` for each upload.
- [ ] Set the production `JEEYM_API_URL` (`--dart-define`) if shipping live sync.
- [ ] `android/key.properties` present locally (not committed); keystore backed up.
- [ ] iOS signing team selected in Xcode.
- [ ] Store listings, screenshots, privacy policy, content rating completed.
- [ ] `flutter build appbundle --release` (Android SDK) succeeds.
- [ ] `flutter build ipa --release` (macOS + Xcode) succeeds.
