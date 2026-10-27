# Release & Signing Guide — Mental Calculation Tricks (Adaptive Coach)

This document provides exact, step-by-step instructions for generating an Android upload keystore, configuring release signing credentials, building the Google Play App Bundle (`.aab`), and publishing to the Google Play Console.

---

## 1. Create Your Upload Keystore

Generate an Android upload keystore using the standard `keytool` utility bundled with Java/JDK.

Open a terminal and run the following command (on macOS, Linux, or Windows PowerShell):

```bash
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

You will be prompted to:
1. **Enter a keystore password**: Choose a strong, memorable passphrase.
2. **Answer certificate questions**: (Name, Organization, City, State, Country code e.g. `US` or `IN`).
3. **Confirm**: Type `yes`.

The keystore file will be created at:
`android/upload-keystore.jks`

> [!CAUTION]
> ### BACK UP YOUR KEYSTORE & PASSWORDS IMMEDIATELY
> **Store your `upload-keystore.jks` file and passwords in at least TWO secure locations** (e.g., an encrypted password manager like 1Password/Bitwarden, a secure offline USB drive, or a private cloud backup).
>
> If you lose your upload keystore or password, Google Play cannot recover it, and you will have to request a reset through Google Play Support, which delays app updates.

---

## 2. Configure `android/key.properties`

Create a file named `key.properties` inside the `android/` directory (`android/key.properties`).

> [!IMPORTANT]
> `android/key.properties` and all `*.jks` / `*.keystore` files are already included in `.gitignore`. They must **NEVER** be committed to Git.

Add your keystore details to `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

*(Note: Because `storeFile=upload-keystore.jks` is placed in `android/`, the relative path is resolved directly by Gradle).*

---

## 3. Version Bumping

App version and build numbers come from `pubspec.yaml`:

```yaml
version: 1.12.0+19
```

- `1.12.0`: The user-visible version name (`versionName`).
- `19`: The internal integer build number (`versionCode`) required by Google Play.

Whenever you publish an update to Google Play:
1. Increment the build number: `version: 1.12.1+20` (Google Play rejects bundles with existing or lower version codes).
2. Update `AppConstants.appVersion` in `lib/core/constants/app_constants.dart` if the semver changes.

---

## 4. Build the Release App Bundle

Run the following command in the project root:

```bash
flutter build appbundle --release
```

What Gradle does automatically:
- Compiles with **Android 16 SDK (`compileSdk = 36`, `targetSdk = 36`)**.
- Applies **R8 minification and resource shrinking** using keep rules in `android/app/proguard-rules.pro`.
- Signs the bundle using the credentials from `android/key.properties`.
- Pulls `versionName` and `versionCode` directly from `pubspec.yaml`.

The final release bundle will be located at:
`build/app/outputs/bundle/release/app-release.aab`

---

## 5. Google Play Console Upload Checklist

1. **Google Play Console Setup**:
   - Go to [Google Play Console](https://play.google.com/console).
   - Select your app: **Mental Calculation Tricks**.
2. **Play App Signing**:
   - Navigate to **Release > Setup > App integrity**.
   - Ensure **Play App Signing** is enabled (Google manages the master app signing key; your `upload-keystore.jks` signs the upload bundle).
3. **Upload Release Bundle**:
   - Go to **Release > Production** (or **Closed testing** / **Internal testing**).
   - Click **Create new release**.
   - Drag and drop `build/app/outputs/bundle/release/app-release.aab`.
   - Enter release notes (highlighting 100% offline practice, visual shortcut notebooks, and habit streak tracking).
4. **Content & Store Listing**:
   - **App Title**: `Mental Calculation Tricks`
   - **Short Description**: Fast mental calculation shortcuts, visual notebooks, and adaptive daily math drills.
   - **Category**: Education.
   - **Target Audience**: Students, professionals, and mental math learners.
   - **Data Safety**:
     - Does this app collect data? **No** (100% offline, zero internet permission).
     - Does this app share data? **No**.
   - **Permissions**: Verify that the manifest only requests `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, and `POST_NOTIFICATIONS`. No internet, no exact alarm, no camera, no location.
5. **Review and Rollout**:
   - Review warnings, submit the release for review, and start the rollout.
