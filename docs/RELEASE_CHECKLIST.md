# Hungry Spot Android release checklist

Complete every blocking item for each production release. Record the date,
operator, artifact hash, and Play release track in the release notes.

## 1. Identity and versioning

- [ ] Confirm package/namespace is `com.malikhassanjavaid.hungryspot`.
- [ ] Increment `version` and build number in `pubspec.yaml`.
- [ ] Confirm Android target SDK is 36 or newer and minimum SDK is 24.
- [ ] Confirm Firebase project `burger-house-80541` selects the Hungry Spot
      Android app, not the retained legacy `com.example...` registration.

## 2. Secrets and signing

- [ ] Back up `android/app/upload-keystore.jks`, alias, and passwords in an
      encrypted password manager; loss of the upload key can block updates.
- [ ] Confirm `android/key.properties`, `*.jks`, `stripe.config.json`, and
      `production.config.json` are ignored and absent from `git status`.
- [ ] Create `production.config.json` from the example with a Stripe live
      publishable key, an actively monitored support email, and public HTTPS
      privacy/deletion URLs.
- [ ] Confirm `STRIPE_SECRET_KEY` is the matching live secret in Firebase
      Secret Manager. Never place it in Dart config.

## 3. Backend and data protection

- [ ] Review and deploy Firestore rules and indexes to the intended project.
- [ ] Review and deploy Firebase Functions from `functions/`.
- [ ] Verify card PaymentIntent creation and verification are authenticated.
- [ ] Verify one test account can delete its data in-app and that another
      account cannot read or delete it.
- [ ] Complete the Play Data safety form for Auth, profile, location, order,
      and payment-verification data.
- [ ] Enable GitHub Pages from `/docs` and verify the privacy and deletion pages
      load in a signed-out browser before adding them to Play Console.

## 4. Automated verification

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
Set-Location functions
npm ci
npm run lint
Set-Location ..
flutter build appbundle --release --dart-define-from-file=production.config.json
flutter build apk --release --dart-define-from-file=production.config.json
```

- [ ] Record SHA-256 hashes and sizes for the AAB and APK.
- [ ] Confirm the AAB is signed by the private upload key, not Android debug.
- [ ] Confirm no `pk_test_`, `sk_test_`, private key, or local emulator flag is
      present in production configuration or logs.

## 5. Device smoke test

- [ ] Install the release APK on Android API 36 and one physical device.
- [ ] Test onboarding, Skip, registration, verification, login, and password reset.
- [ ] Test menu search, favorites, each customization family, cart, coupon,
      delivery/pickup, Cash on Delivery, and Stripe live-mode low-value payment.
- [ ] Test card details after first entering the cardholder name.
- [ ] Test offline/error states, back navigation, keyboard dismissal, and rotation.
- [ ] Test large text, screen reader labels/order, contrast, and 48dp targets.
- [ ] Confirm privacy links open and account deletion requires typing `DELETE`.

## 6. Play Console and rollout

- [ ] Upload screenshots, icon, feature graphic, description, privacy URL, and
      account-deletion URL without personal/test customer data.
- [ ] Complete content rating, ads declaration, target audience, app access,
      and financial/payment declarations.
- [ ] Upload to Internal testing first; review pre-launch report and automated
      device crashes/ANRs.
- [ ] Promote gradually (Internal → Closed/Open → Production) and monitor
      Firebase/Stripe errors, payment discrepancies, crash rate, and ANRs.

## 7. LinkedIn-safe showcase

- [ ] Record a 30–45 second captioned demo in a 4:5 or vertical layout.
- [ ] Label Stripe as test mode and use only Stripe test card data.
- [ ] Blur email, phone, address, order IDs, payment IDs, notifications, and logs.
- [ ] Show the product outcome first, then architecture/testing highlights.
- [ ] Link the repository only after scanning committed history for secrets.
