# Hungry Spot deployment and LinkedIn audit

Date: 2026-08-28

## Outcome

The audited Android release boundary is healthy. Hungry Spot now has a
permanent package identity, Firebase registration, private upload signing,
working Stripe release optimization, branded adaptive icons, optimized image
assets, privacy/account controls, and repeatable release documentation.

## Visual evidence

1. `01-onboarding.png` — onboarding hierarchy and branded call to action.
2. `02-login.png` — authentication layout and form styling.
3. `03-login-validation.png` — inline empty-field validation.
4. `04-release-smoke.png` — signed release APK installed and launched on the
   Pixel emulator with optimized artwork and no debug banner.

## Production verification

- Permanent Android package: `com.malikhassanjavaid.hungryspot`.
- Firebase Android app: `1:996721668582:android:873ed7600e4dc4eada2627`.
- Android target SDK: API 36; minimum SDK: API 24.
- `flutter analyze --no-pub`: no issues found.
- `flutter test --no-pub`: all 52 tests passed.
- Functions syntax and ESLint: passed.
- Functions production dependency audit: zero vulnerabilities.
- Signed release AAB: 87.8 MB.
- Signed universal release APK: 82.8 MB.
- AAB SHA-256:
  `EDCC7FABCAB36F53E18D629D01EBD5C217435388EDEA878AD401F43185C565B0`.
- Signing certificate: Hungry Spot upload certificate, SHA384withRSA,
  4096-bit RSA key.
- Packaged image source set: about 22 MB, reduced from 167.15 MB while keeping
  the checkout golden image pixel-identical.

## Required operator steps before Play production

1. Back up the ignored upload keystore and passwords in an encrypted password
   manager. They are intentionally not committed.
2. Create ignored `production.config.json` with the live Stripe publishable
   key and a monitored support email.
3. Enable GitHub Pages from `/docs` and verify both legal URLs publicly.
4. Deploy Firestore rules/indexes and the reviewed Firebase Functions,
   including `deleteAccount`, to the intended Firebase project.
5. Complete Play Data safety, account deletion, content rating, app access,
   financial features, screenshots, description, and staged testing forms.
6. Run the release checklist on a physical Android device, including a low-value
   live payment and deletion of a dedicated test account.

## LinkedIn showcase

Record a captioned 30–45 second 4:5 or vertical demo: home/deal,
customization, cart/coupon, checkout, clearly labeled Stripe test payment, and
order confirmation. Blur all email, phone, address, order/payment IDs, and
terminal output. Link the repository only after the four production commits
are visible and GitHub Pages is enabled.

## Maintenance note

The Android Flutter Stripe package remains intentionally pinned because newer
versions have an unresolved card-field focus regression. The release build
excludes only the unused private TapAndPay push-provisioning artifact and keeps
normal Stripe card payment behavior unchanged. Re-evaluate the pin when the
upstream focus issue is resolved.
