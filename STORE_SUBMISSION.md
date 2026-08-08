# RYSE CRM — Store Submission Guide

Everything needed to build signed release binaries and submit to the **Apple
App Store** and **Google Play**. The app name is **RYSE CRM**; the app
identifier is **`com.ryse.crm`** on both platforms.

> Set the backend URL before release. In the app, choose **Live Server** on the
> login screen and point it at your production API (or ship a build with
> `--dart-define=RYSE_API_URL=https://api.yourdomain.com`). Demo mode ships too
> and needs no backend.

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
(`CFBundleDisplayName`); full app-icon set under
`ios/Runner/Assets.xcassets/AppIcon.appiconset`; launch storyboard present.

---

## 3. Store listing assets

- **Screenshots:** ready-made in [`docs/screenshots/`](docs/screenshots) — the
  login, dashboard, pipeline Kanban, leads, opportunity (sales path), lead
  detail, AI assistant, and tasks screens. Regenerate any time with:
  ```bash
  flutter test test/screenshots/screenshots_test.dart --update-goldens
  ```
  Apple/Google want device-frame sizes (e.g. 1290×2796 for 6.7"); capture on a
  simulator/emulator or frame these in a tool like [Fastlane frameit].
- **App icon:** already generated for both platforms. To rebrand, drop a
  1024×1024 PNG and use `flutter_launcher_icons`.
- **Privacy:** the app stores data locally (demo mode) or talks to your own
  backend (server mode). Fill the Play **Data safety** and Apple **App Privacy**
  forms to match your backend's data handling.

---

## 4. Pre-flight checklist

- [ ] `flutter analyze` clean, `flutter test` green.
- [ ] Version/build number bumped in `pubspec.yaml`.
- [ ] Production backend URL configured (Live Server or `--dart-define`).
- [ ] `android/key.properties` present locally (not committed); keystore backed up.
- [ ] iOS signing team selected in Xcode.
- [ ] Store listings, screenshots, privacy policy, content rating completed.
- [ ] `flutter build appbundle --release` and `flutter build ipa --release` succeed.
