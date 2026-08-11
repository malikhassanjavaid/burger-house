# Hungry Spot Stripe test setup

Hungry Spot uses Stripe PaymentSheet in the Flutter app and Firebase Functions to create and verify payments. The secret key never belongs in Flutter, Firestore, `firebase_options.dart`, or Git.

## Local Stripe demo without Firebase Blaze

Firebase's deployed Cloud Functions and Secret Manager require the Blaze plan.
For this portfolio demo, run the Functions backend locally instead. The local
emulator loads a Stripe test secret from an ignored file and does not require a
Firebase billing account.

If a Stripe secret appeared in a screenshot, rotate it in Stripe Dashboard
first. Use only the new test secret.

1. Copy `functions/.secret.local.example` to `functions/.secret.local`.
2. Put the new test secret in that ignored file:

```dotenv
STRIPE_SECRET_KEY=sk_test_your_new_rotated_test_secret
```

Do not run `firebase functions:secrets:set` for local testing. That command
targets Google Cloud Secret Manager and therefore asks for Blaze.

Start the payment backend in terminal 1:

```powershell
firebase use burger-house-80541
firebase emulators:start --only functions
```

For a physical Android phone connected by USB, use terminal 2:

```powershell
adb reverse tcp:5001 tcp:5001
flutter run --dart-define-from-file=stripe.config.json --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FUNCTIONS_EMULATOR_HOST=127.0.0.1
```

For an Android Studio emulator, omit `adb reverse` and use host `10.0.2.2`.

Keep terminal 1 running while testing. Sign in, add an item, open Checkout,
choose Card, and place the order. Use:

- Card number: `4242 4242 4242 4242`
- Expiry: any future date, such as `12/34`
- CVC: any three digits
- ZIP/postcode: any value

The payment appears in Stripe Dashboard while Test mode is selected.

## 1. Add the publishable test key locally

Copy `stripe.config.example.json` to `stripe.config.json`, then replace the placeholder with the Stripe **test publishable key** (`pk_test_...`). The real local file is ignored by Git.

Run the app with:

```powershell
flutter run --dart-define-from-file=stripe.config.json
```

## 2. Store the secret test key securely

From this project folder, run:

```powershell
firebase login
firebase use burger-house-80541
firebase functions:secrets:set STRIPE_SECRET_KEY
```

Paste the Stripe **test secret key** (`sk_test_...`) only into that secure CLI prompt. Do not paste it into source files, chat, Firestore, or Firebase client configuration.

## 3. Deploy the payment backend and Firestore rules

```powershell
cd functions
npm install
cd ..
firebase deploy --only functions,firestore:rules
```

Firebase Functions that call Stripe may require the Firebase project to use the Blaze billing plan. Stripe remains in test mode and does not charge real money while test keys are used.

## 4. Test the card form

Use Stripe test data:

- Card number: `4242 4242 4242 4242`
- Expiry: any future date
- CVC: any three digits
- ZIP/postcode: any valid value

Delivery allows cash or card. Pickup allows card only.