# Hungry Spot Stripe test setup

Hungry Spot uses Stripe PaymentSheet in the Flutter app and Firebase Functions to create and verify payments. The secret key never belongs in Flutter, Firestore, `firebase_options.dart`, or Git.

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