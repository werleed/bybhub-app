# BYBHUB Mobile App — Deployment Guide

## Prerequisites

1. **Flutter SDK** ≥ 3.22.0 (Dart ≥ 3.3.0)
2. **Android Studio** with Android SDK (for Android builds)
3. **Xcode** 15+ (for iOS builds, macOS only)
4. **Firebase project** with Android + iOS apps registered
5. **BYBHUB backend** running with Sanctum installed and migrations applied

---

## Phase 1: Backend Setup

### 1.1 Install Sanctum + dependencies

```bash
cd bybhub
composer install
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
```

### 1.2 Run migrations

```bash
php artisan migrate --force
```

This creates:
- `personal_access_tokens` (Sanctum tokens)
- `device_tokens` (FCM registration)

### 1.3 Configure .env

Add to your `.env`:

```env
# Firebase FCM
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_CREDENTIALS=/path/to/firebase-service-account.json

# Sanctum
SANCTUM_STATEFUL_DOMAINS=bybimport.com,www.bybimport.com
```

### 1.4 CORS is already configured at `config/cors.php`
- Paths: `api/*`
- Supports credentials: `false` (Bearer tokens, not cookies)
- Allowed origins: `*` (tighten in production if needed)

### 1.5 Verify the API is accessible

```bash
curl https://bybimport.com/api/v1/products
```

Should return JSON with `{"success":true,"data":[...]}`.

---

## Phase 2: Flutter App Setup

### 2.1 Install dependencies

```bash
cd mobile/bybhub_app
flutter pub get
```

### 2.2 Generate localization files

```bash
flutter gen-l10n
```

This reads `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb` and generates
`lib/l10n/app_localizations.dart` (replacing the stub).

### 2.3 Configure Firebase

#### Android
1. Go to [Firebase Console](https://console.firebase.google.com) → Project Settings → Your Apps → Android
2. Register app with package name `com.bybimport.bybhub`
3. Download `google-services.json`
4. Replace `android/app/google-services.json` with the downloaded file

#### iOS
1. Firebase Console → Project Settings → Your Apps → iOS
2. Register app with bundle ID `com.bybimport.bybhub`
3. Download `GoogleService-Info.plist`
4. Place it at `ios/Runner/GoogleService-Info.plist`

### 2.4 Update API base URL

Edit `lib/core/constants/app_constants.dart`:

```dart
static const String baseUrl = 'https://bybimport.com';  // Your production URL
```

### 2.5 Update WhatsApp support number

Edit `lib/core/constants/app_constants.dart`:

```dart
static const String whatsappSupportNumber = '+234XXXXXXXXXX';
static const String whatsappSupportUrl = 'https://wa.me/$whatsappSupportNumber';
```

---

## Phase 3: Android Build

### 3.1 Debug APK

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### 3.2 Release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### 3.3 App Bundle (AAB) for Play Store

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### 3.4 App signing

For Play Store upload, configure signing in `android/key.properties`:

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

Create keystore:
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

---

## Phase 4: iOS Build

### 4.1 Open in Xcode

```bash
open ios/Runner.xcworkspace
```

### 4.2 Configure signing
1. Select the `Runner` target
2. Go to Signing & Capabilities
3. Select your team
4. Set Bundle Identifier to `com.bybimport.bybhub`

### 4.3 Build

```bash
flutter build ios --release
```

Then archive from Xcode → Product → Archive → Distribute App.

---

## Phase 5: Testing

### 5.1 Unit tests

```bash
flutter test
```

### 5.2 Integration tests

```bash
flutter test integration_test/
```

### 5.3 Manual testing checklist

- [ ] Register with NG/GH/NE country
- [ ] Login with email + password
- [ ] Browse products (china + local tabs)
- [ ] Search products by name
- [ ] Filter by category
- [ ] View product detail with variants/SKUs
- [ ] Add product to cart
- [ ] Import 1688/Taobao link via scraper
- [ ] Update cart quantity
- [ ] Apply coupon at checkout
- [ ] Place order (wallet debit)
- [ ] View order list with status badges
- [ ] View order detail with tracking timeline
- [ ] Pay assigned shipping fee
- [ ] Request doorstep delivery
- [ ] Confirm pickup
- [ ] Rate delivered order
- [ ] Fund wallet via Paystack card
- [ ] View wallet transactions
- [ ] View notifications
- [ ] Receive FCM push notification
- [ ] Switch language (en/fr)
- [ ] Switch display currency
- [ ] Browse vendor stores
- [ ] Calculate shipping cost
- [ ] Contact WhatsApp support
- [ ] Edit profile
- [ ] Change password
- [ ] Logout

---

## Architecture Overview

```
bybhub_app/
├── lib/
│   ├── core/
│   │   ├── api/          # Dio client, interceptors, exceptions
│   │   ├── constants/    # App constants, enums, config
│   │   ├── theme/        # Material 3 theme, colors, typography
│   │   ├── utils/        # Currency formatter, helpers
│   │   └── routing/      # go_router configuration
│   ├── features/
│   │   ├── auth/         # Login, register, forgot password
│   │   ├── products/     # Catalogue, detail, categories
│   │   ├── scraper/      # 1688/Taobao link importer
│   │   ├── cart/         # Cart CRUD, coupon, checkout summary
│   │   ├── checkout/     # Place order, confirmation
│   │   ├── orders/       # List, detail, tracking, actions
│   │   ├── wallet/       # Balance, fund, transactions
│   │   ├── notifications/# List, FCM registration
│   │   ├── vendor/      # Store browse, buy local
│   │   ├── settings/    # Profile, language, currency
│   │   └── shipping/    # Calculator
│   ├── shared/
│   │   └── widgets/      # Reusable: cards, badges, states
│   └── l10n/             # ARB files (en, fr)
├── android/              # Android config, manifest, gradle
├── ios/                  # iOS config, Info.plist, AppDelegate
└── assets/              # Images, fonts
```

### Key patterns

- **State management:** Riverpod (StateNotifier + AsyncNotifier)
- **API client:** Dio with interceptors (auth token, error normalization, logging)
- **Navigation:** go_router with ShellRoute for bottom nav
- **Secure storage:** flutter_secure_storage for Sanctum tokens
- **Images:** cached_network_image + img-proxy URLs from backend
- **Currency:** All amounts come from server — app never computes totals
- **i18n:** flutter gen-l10n with en/fr ARB files

### API endpoints

All 70+ endpoints are under `/api/v1/*` with Sanctum Bearer auth.
See `mobile/api-integration-plan.md` for the complete list.

### Security

- Sanctum tokens stored in flutter_secure_storage (encrypted)
- No API secrets in the app bundle
- All financial calculations are server-side
- Token cleared on 401 response
- Biometric auth option (platform-specific)

---

## Troubleshooting

### "Sanctum not found"
Run `composer require laravel/sanctum` on the server.

### "CORS error"
Verify `config/cors.php` exists and `paths` includes `api/*`.

### "FCM not working"
1. Verify `FIREBASE_PROJECT_ID` and `FIREBASE_CREDENTIALS` in `.env`
2. Check that `google-services.json` / `GoogleService-Info.plist` is in place
3. Test with Firebase Console → Messaging → Send test message

### "Images not loading"
Images are proxied through `/img-proxy?url=...`. Verify the backend is reachable
and the proxy URL is correct in the API response.
