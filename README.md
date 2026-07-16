# Burger House

A Flutter customer ordering application for Burger House. Customers can create
accounts, sign in securely, choose a delivery address, search the menu, and—once
the ordering features are complete—place and track orders in real time.

## Current features

- Branded splash screen
- Three-page onboarding flow
- Firebase email/password registration and login
- Password reset emails
- Customer profiles stored in Cloud Firestore
- Persistent authentication sessions and sign out
- Premium customer homepage with best sellers and food categories
- Dedicated menu search and saved-items navigation
- Product customization with sizes, add-ons, quantity and instructions
- Shopping cart with minimum-order and delivery-fee calculations
- Validated checkout with delivery details and Cash on Delivery
- Firestore order creation and customer-owned order security rules
- USD pricing throughout the ordering flow
- Responsive black-and-white bottom navigation
- Responsive Material 3 interface

## Technology

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Core

## Android hot reload

Some Honor devices do not automatically expose Flutter's Dart VM service.
For the configured development phone, start a reliable hot-reload session with:

```powershell
powershell -ExecutionPolicy Bypass -File ".\tools\run_hot_reload.ps1"
```

Keep the terminal open, save Dart changes, and press `r` to hot reload or `R`
to hot restart.

## Project structure

```text
lib/
├── core/              # Shared routes, theme, and widgets
├── features/
│   ├── auth/          # Authentication screens and Firebase service
│   ├── home/          # Customer home screen
│   ├── onboarding/    # Introductory pages
│   └── splash/        # Startup screen
├── app.dart           # Application routes and theme configuration
├── firebase_options.dart
└── main.dart          # Application entry point and Firebase initialization
```

## Getting started

1. Install Flutter and configure an Android or iOS development environment.
2. Clone this repository.
3. Run `flutter pub get`.
4. Connect a configured device or start an emulator.
5. Run `flutter run`.

The repository contains Firebase client configuration. Firebase security is
enforced through Authentication and Firestore security rules; private service
account credentials must never be committed.

## Roadmap

- Burger menu and categories
- Product details and customization
- Shopping cart and checkout
- Real-time order tracking
- Staff/admin application
- Rider delivery application
- Push notifications
