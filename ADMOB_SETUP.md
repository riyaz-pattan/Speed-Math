# Google AdMob Setup & Configuration Guide

This guide explains how to set up your Google AdMob account, register **Mental Calculation Tricks** (Mental Calculation Tricks), create banner and interstitial ad units, configure GDPR/UK user consent via UMP, block sensitive categories, and safely replace the placeholder IDs when ready for production release.

---

## 1. Where to Paste Real AdMob IDs

There are **two places** where real IDs belong:

### A. Dart Code: `lib/core/ads/ad_config.dart`
Open [`lib/core/ads/ad_config.dart`](file:///Users/rameez/Desktop/Speed%20Math/lib/core/ads/ad_config.dart) and replace `REPLACE_WITH_REAL_ID`:

```dart
// Real production App ID
static const String realAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY';

// Real production Banner Unit ID (Adaptive Banner)
static const String realBannerUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB';

// Real production Interstitial Unit ID
static const String realInterstitialUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/IIIIIIIIII';
```

> [!NOTE]
> In debug and profile modes, the app **always** uses Google's official Android test IDs regardless of what is set here. In release mode, if any ID still contains `"REPLACE"`, ads remain **100% disabled** automatically.

### B. Android Configuration: `android/key.properties` (Optional but Recommended)
In [`android/key.properties`](file:///Users/rameez/Desktop/Speed%20Math/android/key.properties), you can also add:
```properties
admobAppId=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
```
Gradle will automatically inject this into the release manifest placeholder `APPLICATION_ID`.

---

## 2. Setting Up Google AdMob Account & App

1. **Sign in**: Go to [Google AdMob](https://admob.google.com/) and sign in with your Google account.
2. **Add App**:
   - Navigate to **Apps > Add App**.
   - Platform: **Android**.
   - Is the app listed on a supported app store?:
     - If already published: Select **Yes** and search for it.
     - If not yet published: Select **No** and enter the app name: **Mental Calculation Tricks**.
3. **Copy App ID**:
   - Note the assigned App ID in the format `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`.

---

## 3. Creating Ad Units

Create strictly **two** ad units:

### Unit 1: Adaptive Banner
- In AdMob dashboard: **Apps > Mental Calculation Tricks > Ad units > Add ad unit**.
- Format: **Banner**.
- Ad unit name: `Home & Content Adaptive Banner`.
- Advanced settings:
  - Automatic refresh: **Google optimized** (default).
- Click **Create ad unit** and copy the Unit ID (`ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB`).

### Unit 2: Interstitial
- Format: **Interstitial**.
- Ad unit name: `Results Session Interstitial`.
- Advanced settings:
  - Frequency capping: While the app internally enforces strict frequency capping (maximum 3/day, 5-minute cooldown, 4 sessions between ads), you can additionally set a server-side cap (e.g. 1 impression per 5 minutes).
- Click **Create ad unit** and copy the Unit ID (`ca-app-pub-XXXXXXXXXXXXXXXX/IIIIIIIIII`).

> [!IMPORTANT]
> The app supports **only** Banner and Interstitial ads. Do **not** create Rewarded, App Open, or Native ad units.

---

## 4. User Consent Setup (GDPR & UK Regulations)

Google AdMob requires a consent message for users in the European Economic Area (EEA) and the UK under Google's EU User Consent Policy.

1. Go to **Privacy & messaging** in the AdMob sidebar.
2. Under **European regulations**, click **Create message** (or Manage).
3. Select your app: **Mental Calculation Tricks**.
4. Languages: English (and any additional languages you target).
5. User choices: Enable **Consent**, **Do not consent**, and **Manage options**.
6. Enter your app's **Privacy Policy URL** (e.g., `https://yourdomain.com/privacy-policy`).
7. Click **Publish**.

The app uses Google's User Messaging Platform (UMP) SDK. It will automatically detect when a user is located in the EEA/UK and present the published consent dialog on first launch before loading ads. Users can also change their consent preferences anytime in **Settings > Privacy and ads > Ad privacy choices**.

---

## 5. Blocking Sensitive Ad Categories (Recommended for Education)

Because **Mental Calculation Tricks** is an educational mental math app, block inappropriate ad categories:

1. In the AdMob console, go to **Blocking controls > Manage Categories**.
2. **Sensitive categories**: Block categories that do not fit an educational tool:
   - Gambling & Betting
   - Dating
   - Alcohol & Tobacco
   - Cosmetic Procedures
   - Get Rich Quick / High-risk Investments
   - Sensitive Social / Political Issues
3. **General categories**: Keep education, games, productivity, and utilities enabled.

---

## 6. Strict Warning: Never Tap Live Ads

> [!CAUTION]
> **NEVER tap your own live ads.**
> Clicking your own live ads violates AdMob policy and can lead to immediate account suspension or termination for invalid traffic.
> - While developing or testing, the app automatically serves Google test ads.
> - If you install a release build on your personal device, register your device as an official **Test Device** in **AdMob > Settings > Test devices** using your Android Advertising ID.
