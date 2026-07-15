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
- Home screen with delivery address selection and menu search
- Responsive Material 3 interface

## Technology

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Core

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
