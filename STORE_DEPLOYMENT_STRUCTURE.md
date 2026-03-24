# MediConnect From-Scratch Store Deployment Guide

Use this as a complete step-by-step checklist to publish on both Google Play and Apple App Store.

## A) Folder Structure You Need

### Flutter root

- `healthlink_connect_flutter/pubspec.yaml` (app version)
- `healthlink_connect_flutter/assets/` (icons, splash, images)

### Android (Play Store)

- `healthlink_connect_flutter/android/app/build.gradle.kts`
- `healthlink_connect_flutter/android/app/src/main/AndroidManifest.xml`
- `healthlink_connect_flutter/android/key.properties` (create)
- `healthlink_connect_flutter/android/app/upload-keystore.jks` (create)

### iOS (App Store)

- `healthlink_connect_flutter/ios/Runner.xcworkspace/`
- `healthlink_connect_flutter/ios/Runner.xcodeproj/project.pbxproj`
- `healthlink_connect_flutter/ios/Runner/Info.plist`
- `healthlink_connect_flutter/ios/Runner/Assets.xcassets/`

## B) Step-by-Step for Google Play (Android)

### Step 1: Set final package name

In `android/app/build.gradle.kts`, set a unique production package id:

- `applicationId = "com.yourdomain.mediconnect"`

### Step 2: Set app version

In `pubspec.yaml`, update:

- `version: 1.0.0+1` -> `version: 1.0.1+2` (example)

Rule:

- `x.y.z` = user-visible version
- `+build` = must increase every upload

### Step 3: Create upload keystore

Run from project root:

`keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`

### Step 4: Create `android/key.properties`

Create file `android/key.properties`:

`storePassword=YOUR_STORE_PASSWORD`
`keyPassword=YOUR_KEY_PASSWORD`
`keyAlias=upload`
`storeFile=app/upload-keystore.jks`

### Step 5: Confirm signing config

`android/app/build.gradle.kts` is already wired to use `key.properties` for release signing.

### Step 6: Build release bundle (.aab)

Run:

`flutter clean`

`flutter pub get`

`flutter build appbundle --release`

Output file:

- `build/app/outputs/bundle/release/app-release.aab`

### Step 7: Create Play Console listing

In Google Play Console:

- Create app
- Fill store listing (title, description, screenshots, icon, feature graphic)
- Fill privacy policy URL
- Complete Data Safety form
- Complete App Content forms

### Step 8: Upload and release

- Go to Production (or Internal testing first)
- Upload `app-release.aab`
- Add release notes
- Roll out release

## C) Step-by-Step for Apple App Store (iOS)

Important: iOS release/upload requires macOS + Xcode + Apple Developer account.

### Step 1: Set iOS bundle identifier

In Xcode (`ios/Runner.xcworkspace` -> Runner target -> Signing & Capabilities):

- Set Bundle Identifier to the same style as Android, e.g. `com.yourdomain.mediconnect`

### Step 2: Set team and signing

In Xcode:

- Select your Apple Developer Team
- Keep Signing = Automatic (recommended)

### Step 3: Set app version/build

Use `pubspec.yaml` version and build number (Flutter maps these values).

### Step 4: Build iOS release

From project root:

`flutter clean`

`flutter pub get`

`flutter build ios --release`

### Step 5: Archive in Xcode

- Open `ios/Runner.xcworkspace`
- Select Any iOS Device (arm64)
- Product -> Archive

### Step 6: Upload to App Store Connect

- In Organizer, select archive
- Click Distribute App -> App Store Connect -> Upload

### Step 7: Complete App Store listing

In App Store Connect:

- Create app record
- Add screenshots, subtitle, description, keywords, support URL, privacy policy URL
- Fill App Privacy questionnaire
- Add age rating and compliance details

### Step 8: Submit for review

- Select uploaded build
- Submit for Apple review

## D) Final Pre-Submission Checklist (Both Stores)

- Production API URLs set correctly
- Debug logs/keys removed
- App icon and splash final
- Notification permissions tested
- Login/payment flow tested on real devices
- Version/build number increased from previous release
- Privacy policy URL working

## E) Suggested Final IDs

- Android: `com.yourdomain.mediconnect`
- iOS: `com.yourdomain.mediconnect`

Use your real domain/company so IDs stay unique forever.
