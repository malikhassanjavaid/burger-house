# Hungry Spot

Hungry Spot is a production-oriented Flutter food-ordering app with a branded
onboarding flow, configurable menu items, cart and coupons, delivery/pickup,
Stripe card payments, Cash on Delivery, and customer order history.

![Hungry Spot onboarding](audit/linkedin-release/01-onboarding.png)

## Highlights

- Firebase email/password and Google authentication with mandatory six-digit
  Firebase SMS phone verification
- Searchable restaurant menu, favorites, deals, and product customization
- Cart persistence, coupon validation, delivery fees, and checkout validation
- Stripe PaymentIntents created and verified by authenticated Cloud Functions
- Cash on Delivery and customer-owned Firestore order history
- Shared branded navigation, action bars, notifications, and form components
- In-app privacy/account controls and public privacy/deletion documentation
- API 36 Android configuration, upload signing, R8 protection, and adaptive icons
- 115 optimized WebP assets (about 21 MB, reduced from about 167 MB)
- Widget and service regression coverage for ordering, checkout, card input,
  navigation, notifications, account controls, and responsive layouts

## Architecture

```text
Flutter UI
├── core/                 theme, routes, config, reusable widgets
├── features/auth/        Firebase authentication
├── features/home/        menu, cart, checkout, Stripe, orders, profile
├── features/account/     privacy and deletion controls
├── features/location/    optional map/location address setup
└── features/onboarding/  first-run experience
        │
        ├── Firebase Auth + Firestore
        ├── Firebase callable Functions
        └── Stripe PaymentIntents
```

Card details are collected by Stripe’s native SDK. Secret Stripe keys stay in
Firebase Secret Manager and never ship in the app or repository.

## Local setup

1. Install the Flutter SDK and an Android API 36 development environment.
2. Clone the repository and run `flutter pub get`.
3. Copy `stripe.config.example.json` to the ignored `stripe.config.json` and
   add a Stripe **test** publishable key.
4. Connect an Android device or start an emulator.
5. Run `flutter run --dart-define-from-file=stripe.config.json`.

For the configured Honor development device, the helper below starts the local
Stripe Functions emulator, establishes ADB forwarding, and runs hot reload:

```powershell
powershell -ExecutionPolicy Bypass -File ".\tools\run_hot_reload.ps1"
```

## Firebase phone verification setup

Real SMS verification is a release prerequisite, not a client-side test mode:

1. Enable the **Phone** provider in Firebase Authentication and use a Blaze
   project for production SMS billing.
2. Register debug and release SHA-1 and SHA-256 certificate fingerprints for
   `com.malikhassanjavaid.hungryspot`.
3. Keep Android app verification enabled. Configure Firebase fictional phone
   numbers and six-digit codes only in Firebase Console for development.
4. Never commit fictional numbers/codes, disable app verification in a release,
   or log OTP values and full phone numbers.

## Quality checks

```powershell
flutter analyze --no-pub
flutter test --no-pub
npm.cmd test --prefix functions
npm.cmd run lint --prefix functions
firebase emulators:exec --only firestore --project hungry-spot-phone-rules-test "npm.cmd run test:rules --prefix functions"
```

The Firestore emulator requires Java. Android Studio's bundled JBR can be used
locally when `java` is not already on `PATH`.

## Android release

The permanent package is `com.malikhassanjavaid.hungryspot`. Release signing
uses ignored local files `android/key.properties` and
`android/app/upload-keystore.jks`; never commit or share either file.

Create `production.config.json` from the checked-in example, supply the live
publishable key and support email, and then build:

```powershell
flutter build appbundle --release --dart-define-from-file=production.config.json
```

Before publishing, complete every item in
[`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md). The public documents
are [`docs/privacy-policy.html`](docs/privacy-policy.html) and
[`docs/delete-account.html`](docs/delete-account.html); enable GitHub Pages from
the `/docs` directory before entering their URLs in Play Console.

## Firebase deployment

The repository contains public Firebase client configuration, Firestore rules,
indexes, and callable Function source. Service-account credentials and Stripe
secret keys must never be committed.

```powershell
firebase deploy --only firestore:rules,firestore:indexes
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase deploy --only functions
```

Use separate Stripe test/live keys and verify the active Firebase project before
every deployment. Deploy the phone-claim Firestore rules and payment Functions
together, then confirm an authenticated account without a verified phone is
rejected by both boundaries.

## Portfolio demo

Record a captioned 30–45 second mobile demo showing: home/deal selection,
customization, cart/coupon, checkout, a clearly labeled Stripe **test** payment,
and order confirmation. Do not show personal addresses, email addresses, API
keys, terminal secrets, or real card information.
