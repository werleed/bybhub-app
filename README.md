# BYBHUB Mobile App

A premium Flutter mobile application for BYBHUB (bybimport.com) — China-to-West-Africa importation, shopping, logistics and marketplace platform.

## Features

- **Authentication** — Register, login, password reset (Sanctum Bearer tokens)
- **Product Catalogue** — Browse china + local products, search, filter, categories
- **Link Importer** — Paste 1688/Taobao/Alibaba URLs to import products
- **Shopping Cart** — Add/remove items, apply coupons, save for later
- **Checkout** — Place orders with wallet payment, two-phase shipping model
- **Order Management** — Track orders with 10-step timeline, pay shipping, request doorstep, confirm pickup, rate
- **Wallet** — Balance, fund via Paystack card, transactions, transfers
- **Notifications** — In-app + FCM push notifications
- **Vendor Marketplace** — Browse local stores, buy local products
- **Shipping Calculator** — Estimate shipping costs
- **Settings** — Language (EN/FR), currency (NGN/GHS/XOF/USD/CNY), profile
- **Offline-friendly** — Cached products, orders, wallet

## Quick Start

```bash
flutter pub get
flutter gen-l10n
flutter run
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for full setup and build instructions.

## Tech Stack

- Flutter 3.22+ / Dart 3.3+
- Riverpod (state management)
- go_router (navigation)
- Dio (HTTP client with interceptors)
- Firebase Cloud Messaging (push notifications)
- flutter_secure_storage (token storage)
- cached_network_image (image caching)
- Hive (local cache)

## API

All endpoints under `/api/v1/*` with Sanctum Bearer auth.
See `../api-integration-plan.md` for the complete API specification.

## Backend Requirements

The BYBHUB Laravel backend must have:
1. Laravel Sanctum installed and configured
2. The v1 API controllers and routes (already included)
3. Firebase credentials for FCM push
4. CORS configured for `api/*`

See `../DEPLOYMENT.md` for backend setup steps.
