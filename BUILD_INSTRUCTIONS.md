# Site Visit Report App — Complete APK Build Guide
## Axiom Technical Services

---

## Prerequisites

### 1. Install Flutter SDK
```bash
# Download from: https://docs.flutter.dev/get-started/install/windows

# Or on Linux/macOS:
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

### 2. Install Android Studio
- Download from https://developer.android.com/studio
- During install, select **Android SDK**, **Android SDK Platform-Tools**, **Android Emulator**
- Accept all SDK licenses:
  ```bash
  flutter doctor --android-licenses
  ```

### 3. Set ANDROID_HOME (if not auto-detected)
```bash
# Linux/macOS (~/.bashrc or ~/.zshrc):
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Windows (System > Environment Variables):
# Add ANDROID_HOME = C:\Users\YourName\AppData\Local\Android\Sdk
```

### 4. Install Java (JDK 17)
```bash
# Linux:
sudo apt install openjdk-17-jdk

# macOS:
brew install openjdk@17

# Windows: Download from https://adoptium.net
```

---

## Project Setup

### Step 1: Open the project
```bash
cd site_visit_report
```

### Step 2: Get dependencies
```bash
flutter pub get
```

### Step 3: Verify everything is OK
```bash
flutter doctor -v
```
All items should show a ✓ checkmark. At minimum, you need:
- Flutter SDK ✓
- Android toolchain ✓

---

## Building the APK

### Option A: Debug APK (for testing — faster build)
```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Option B: Release APK (for production use — optimized, smaller)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Option C: Split APKs by CPU architecture (smallest file size)
```bash
flutter build apk --split-per-abi --release
```
Outputs:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`  ← Use this for modern phones
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` ← For older phones
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`      ← For emulators

> **Recommendation:** Use `app-arm64-v8a-release.apk` for all modern Android phones (2018+).

---

## Signing the APK (Required for sideloading on some devices)

The debug APK is signed with a debug key by default and works for sideloading.
For a production release key:

### Create a keystore
```bash
keytool -genkey -v -keystore ~/site_visit_key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias site_visit_key
```

### Add signing config to `android/app/build.gradle`
```groovy
android {
    signingConfigs {
        release {
            storeFile file('/path/to/site_visit_key.jks')
            storePassword 'your_store_password'
            keyAlias 'site_visit_key'
            keyPassword 'your_key_password'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

## Installing the APK on Android Devices

### Method 1: Direct USB install (easiest)
```bash
# Connect phone via USB with USB Debugging enabled
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Method 2: Manual sideloading (no computer needed after transfer)
1. Copy the APK to the phone (USB, WhatsApp, email, Google Drive, etc.)
2. On the phone: **Settings → Security → Unknown Sources** → Enable
   - On Android 8+: **Settings → Apps → Special App Access → Install Unknown Apps**
   - Allow the file manager app
3. Open the APK file on the phone and tap **Install**

### Method 3: ADB over Wi-Fi
```bash
# On phone: Settings > Developer Options > Wireless Debugging
adb connect <phone-ip>:5555
adb install app-release.apk
```

---

## Database Schema

The app uses SQLite with a single `reports` table:

```sql
CREATE TABLE reports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  report_id TEXT NOT NULL UNIQUE,   -- UUID
  status TEXT NOT NULL DEFAULT 'draft',  -- 'draft' | 'submitted'
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,

  -- Basic Info
  bank_name TEXT,
  loan_number TEXT,
  date_of_visit TEXT,
  customer_name TEXT,

  -- Property Address
  property_address_deed TEXT,
  property_address_site TEXT,

  -- Dimensions (North/South/East/West × Deed/Site)
  dim_north_deed TEXT, dim_south_deed TEXT, dim_east_deed TEXT, dim_west_deed TEXT,
  dim_north_site TEXT, dim_south_site TEXT, dim_east_site TEXT, dim_west_site TEXT,

  -- Boundaries (North/South/East/West × Deed/Site)
  bound_north_deed TEXT, bound_south_deed TEXT, bound_east_deed TEXT, bound_west_deed TEXT,
  bound_north_site TEXT, bound_south_site TEXT, bound_east_site TEXT, bound_west_site TEXT,

  -- Land Details
  land_extent_deed TEXT, land_extent_site TEXT,
  any_changes_in_boundaries TEXT,

  -- Location & Infrastructure
  land_mark TEXT, locality TEXT, age_of_property TEXT,
  road_type TEXT, property_identified TEXT, road_width TEXT,
  nearest_bus_stop TEXT, usage_of_building TEXT,
  railway_station TEXT, no_of_unit TEXT,
  nearest_hospital TEXT, no_of_floor TEXT,
  structure TEXT, occupancy TEXT,

  -- Amenities
  bore_well TEXT, septic_tank TEXT, oht TEXT,
  compound_wall TEXT, sump TEXT, eb_services TEXT,

  -- Building Details
  floor_type TEXT, demarcated TEXT, no_of_tenants TEXT,
  maintenance_of_building TEXT, roof TEXT,
  stage_construction_percent TEXT, type_of_locality TEXT,

  -- GPS
  latitude REAL, longitude REAL, google_point TEXT,

  -- Media
  photos_paths TEXT,     -- JSON array of file paths
  signature_path TEXT,   -- Path to PNG signature image

  -- Inspector
  inspector_name TEXT, company_name TEXT
);

-- Indexes for fast search
CREATE INDEX idx_customer_name ON reports(customer_name);
CREATE INDEX idx_status ON reports(status);
CREATE INDEX idx_created_at ON reports(created_at);
```

---

## Folder Structure

```
site_visit_report/
├── lib/
│   ├── main.dart                          ← App entry point
│   ├── theme/
│   │   └── app_theme.dart                 ← Colors, typography, Material theme
│   ├── models/
│   │   └── site_visit_report.dart         ← Data model with all 50+ fields
│   ├── database/
│   │   └── database_helper.dart           ← SQLite CRUD operations
│   ├── utils/
│   │   └── export_helper.dart             ← JSON/CSV export via Share
│   ├── widgets/
│   │   └── form_widgets.dart              ← AppTextField, AppDropdown, StatusBadge
│   └── screens/
│       ├── home_screen.dart               ← Dashboard with stats
│       ├── form_screen.dart               ← Main data entry (10 sections)
│       ├── saved_reports_screen.dart      ← Search, edit, delete reports
│       └── settings_screen.dart          ← Profile, export, backup
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml            ← Permissions (camera, GPS, storage)
├── pubspec.yaml                           ← Dependencies
└── BUILD_INSTRUCTIONS.md                  ← This file
```

---

## Key Features Summary

| Feature | Implementation |
|---|---|
| Offline-first | SQLite local database, no internet required |
| Auto-save | Timer fires every 30s, also saves on screen exit |
| GPS capture | geolocator package, high accuracy |
| Google Maps | url_launcher opens maps.google.com |
| Camera/Gallery | image_picker, saved to app documents |
| Digital signature | signature package, saved as PNG |
| Export JSON | dart:convert + share_plus |
| Export CSV | csv package + share_plus |
| Search | SQLite LIKE query on 5 fields |
| Status filter | Draft / Submitted chips |
| Form validation | 4 mandatory fields checked on submit |

---

## Troubleshooting

**`flutter doctor` shows Android SDK issues:**
```bash
flutter doctor --android-licenses
# Accept all with 'y'
```

**Build fails with Gradle error:**
```bash
cd android && ./gradlew clean && cd ..
flutter clean
flutter pub get
flutter build apk --release
```

**APK won't install on phone:**
- Enable "Install Unknown Apps" for the file manager app
- Check Android version (app supports Android 5.0+)

**GPS not working:**
- Grant Location permission when prompted
- Ensure Location Services are enabled in phone settings

**Camera not working:**
- Grant Camera permission when prompted
- Some manufacturers require additional storage permission grants
