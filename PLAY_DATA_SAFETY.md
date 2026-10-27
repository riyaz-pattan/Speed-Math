# Google Play Console — Data Safety & Content Rating Cheat Sheet

**App Name:** Mental Calculation Tricks (Adaptive Coach)  
**Package Name:** `com.speedmathwithai`  
**Privacy Policy URL:** `https://riyaz-pattan.github.io/speed-math-pro-privacy/`  
**Last Updated:** October 25, 2026  

This document provides exact, question-by-question answers for completing the **Data safety**, **App content**, and **Target audience** questionnaires in the **Google Play Console**. Answers strictly adhere to Google's official [AdMob Google Play Data Disclosure Guide](https://developers.google.com/admob/android/data-safety).

---

## 1. App Content: Ads & Target Audience

### A. Ads Declaration
* Navigate to **Policy > App content > Ads**.
* **Does your app contain ads?**  
  👉 **Yes, my app contains ads** *(Banners and interstitials via Google AdMob).*

### B. Target Audience and Content
* Navigate to **Policy > App content > Target audience and content**.
* **Target age groups:**  
  👉 **16–17, 18 and over** *(Check both).*  
  *(Do NOT check age groups under 13).*
* **Appeal to children:**  
  👉 **No** *(Neutral, non-childish design aimed at students, exam aspirants, and adult mental calculation learners).*

### C. News & Financial Features
* **Is this a news app?** 👉 **No**
* **Is this a financial or government app?** 👉 **No**
* **COVID-19 contact tracing:** 👉 **No**

---

## 2. Data Safety: Overview & Global Questions

Navigate to **Policy > App content > Data safety > Start**.

### Section: Data collection and security
1. **Does your app collect or share any of the required user data types?**  
   👉 **Yes** *(Because Google Mobile Ads SDK collects diagnostic and advertising data when online).*
2. **Is all of the user data collected by your app encrypted in transit?**  
   👉 **Yes** *(All communication between Google Mobile Ads SDK and Google servers uses TLS/HTTPS).*
3. **Do you provide a way for users to request that their data be deleted?**  
   👉 **Yes** *(Users can reset or delete their advertising ID in device Settings > Google > Ads, and can delete all local practice data via Settings > Reset all data or app uninstall).*

---

## 3. Data Safety: Data Types Breakdown

The **developer collects 0 bytes of user data**. All user calculation numbers, answers, scores, and streak data stay strictly local in an on-device SQLite database.

However, the third-party **Google Mobile Ads (AdMob)** SDK processes the following data types. Check **ONLY** the following:

### 1. Location
* **Approximate location** (network-based coarse location):
  * Check **Approximate location**.
  * **Collected?** 👉 **Yes**
  * **Shared?** 👉 **Yes** *(Transmitted to Google AdMob for ad delivery).*
  * **Is this data processed ephemerally?** 👉 **Yes**
  * **Is this data required for your app, or can users choose whether it’s collected?**  
    👉 **Data collection is required** *(Required by SDK for serving geographically relevant ads).*
  * **Why is this user data collected?**  
    👉 Check **Advertising or marketing**, **Analytics**, and **Fraud prevention, security, and compliance**.

### 2. App info and performance
* **Crash logs**:
  * Check **Crash logs**.
  * **Collected?** 👉 **Yes**
  * **Shared?** 👉 **No**
  * **Processed ephemerally?** 👉 **No**
  * **Required or optional?** 👉 **Data collection is required**
  * **Why is this data collected?** 👉 Check **Analytics** and **App functionality**.
* **Diagnostics** (e.g. battery, launch time, latency):
  * Check **Diagnostics**.
  * **Collected?** 👉 **Yes**
  * **Shared?** 👉 **No**
  * **Processed ephemerally?** 👉 **Yes**
  * **Required or optional?** 👉 **Data collection is required**
  * **Why is this data collected?** 👉 Check **Analytics** and **App functionality**.

### 3. Device or other IDs
* **Device or other IDs** (specifically the Google Advertising ID):
  * Check **Device or other IDs**.
  * **Collected?** 👉 **Yes**
  * **Shared?** 👉 **Yes** *(Shared with Google AdMob).*
  * **Processed ephemerally?** 👉 **No**
  * **Required or optional?**  
    👉 **Data collection is optional** *(Users can delete/reset their Advertising ID in Android Settings, or opt out via the UMP consent form in EEA/UK).*
  * **Why is this user data collected?**  
    👉 Check **Advertising or marketing**, **Analytics**, and **Fraud prevention, security, and compliance**.

---

## 4. Other Data Types to Leave UNCHECKED

Verify that all of the following categories remain **UNCHECKED** (None collected, None shared):
* ❌ Personal info (No name, email, phone, address, user IDs)
* ❌ Financial info (No bank details, credit cards, purchase history)
* ❌ Health and fitness (None)
* ❌ Messages (None)
* ❌ Photos and videos (None)
* ❌ Audio files (None)
* ❌ Files and docs (None)
* ❌ Calendar (None)
* ❌ Contacts (None)
* ❌ Web browsing (None)

---

## 5. Summary Table for Quick Play Console Entry

| Category | Data Type | Collected | Shared | Ephemeral | Purpose |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Location** | Approximate location | Yes | Yes | Yes | Advertising, Analytics, Fraud prevention |
| **App info** | Crash logs | Yes | No | No | Analytics, App functionality |
| **App info** | Diagnostics | Yes | No | Yes | Analytics, App functionality |
| **Device IDs** | Device or other IDs (Advertising ID) | Yes | Yes | No | Advertising, Analytics, Fraud prevention |
