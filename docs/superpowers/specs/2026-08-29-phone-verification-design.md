# Phone Verification Authentication Design

Date: 2026-08-29

## Objective

Replace mandatory Gmail-link verification with Firebase SMS phone verification while preserving email/password login and password recovery. Every customer who enters the authenticated application must have a phone credential linked to their Firebase Auth user.

## Product Decisions

- Email and password remain the primary credentials for registration, login, and password recovery.
- Google sign-in remains supported.
- Email verification is no longer required and no verification email is sent.
- The registration email field accepts any syntactically valid email address instead of only `@gmail.com` addresses.
- Phone verification is mandatory for new email/password registrations, existing customer accounts, and Google accounts.
- Firebase Auth provider data and `User.phoneNumber` are the source of truth for phone verification. A Firestore boolean must not grant verified access.
- Firebase supplies a six-digit SMS verification code. The app will not implement a custom four-digit OTP service.
- Phone numbers are normalized to E.164 format before they are sent to Firebase or saved to Firestore.

## Firebase Prerequisites

Before real SMS verification can work in a release build:

1. Enable the Phone provider in Firebase Authentication.
2. Use a Firebase Blaze project because production verification SMS is billed.
3. Register the Android debug and release SHA-1 and SHA-256 certificate fingerprints.
4. Keep Android app verification enabled in production; never ship test-verification bypasses or fictional phone numbers in application code.
5. Configure Firebase fictional phone numbers and six-digit codes in the console for development and automated integration testing.
6. If iOS is released later, configure APNs, push notifications, and remote-notification background mode before enabling the flow there.
7. Update privacy disclosures to explain that phone numbers are sent to and stored by Google for spam and abuse prevention.

## Architecture

### `AuthService`

`AuthService` remains responsible for Firebase Auth and profile synchronization but gains explicit phone-verification operations:

- Determine whether the current user has a linked phone provider and a non-empty `phoneNumber`.
- Start `verifyPhoneNumber`, exposing the verification ID, resend token, automatic Android credential, failure, and timeout events through a small result/controller abstraction.
- Link a `PhoneAuthCredential` to the current Firebase user rather than signing in as a separate phone-only user.
- Reject `credential-already-in-use` with a clear message so one phone number cannot silently take over another account.
- Force-refresh the Firebase ID token after linking so protected services immediately receive its trusted `phone_number` claim.
- Synchronize the verified E.164 number and a server-generated `phoneVerifiedAt` timestamp to Firestore after linking succeeds.
- Preserve a successful Firebase Auth login if non-critical Firestore profile synchronization temporarily fails.

The existing Gmail-specific methods and checks are removed: `sendEmailVerification`, resend-email verification, `emailVerified` login gating, Gmail-only validation, and Gmail-specific errors.

### Verification Gate

A single reusable post-authentication gate decides the next screen after email/password login, Google sign-in, registration, and splash restoration:

1. No authenticated user: show onboarding or login as today.
2. Authenticated user without a linked verified phone: show the phone verification flow.
3. Verified user without a delivery location: show location setup.
4. Verified user with a location: enter the home screen.

All entry paths use this gate so Google sign-in, existing sessions, and splash restoration cannot bypass phone verification.

The navigation gate is a UX safeguard, not the security boundary. Firestore Security Rules for customer-private data must also require a non-empty trusted `request.auth.token.phone_number` claim. Authenticated Cloud Functions that expose customer or order operations must reject calls whose verified ID token lacks `phone_number`. Public menu data can retain its existing public-read policy. This prevents a modified client from bypassing the Flutter screens.

### Phone Verification Coordinator

A focused coordinator owns the transient verification session:

- normalized phone number;
- Firebase verification ID;
- Android resend token;
- resend countdown state;
- sending, awaiting-code, verifying, verified, and failure states;
- one in-flight operation at a time.

Widgets render coordinator state and do not call Firebase directly. This keeps callback-heavy phone authentication behavior testable and prevents duplicate SMS requests during rebuilds.

## User Flows

### New Email/Password Registration

1. Validate name, general email syntax, E.164 phone number, and password.
2. Create the Firebase email/password user and retain the authenticated session.
3. Keep the pending profile values in the registration session without publishing an unverified number to Firestore.
4. Send the Firebase verification SMS.
5. Open the OTP sheet immediately.
6. Link the verified phone credential to the current user and force-refresh its ID token.
7. Create the verified Firestore profile and continue directly to location setup.

If SMS delivery or verification is interrupted, the email/password account remains usable only to resume phone verification. The customer is never allowed into authenticated application content until the phone provider is linked.

### Existing Email/Password Account

Email/password authentication succeeds without checking `emailVerified`. The post-authentication gate checks the linked providers. An account without a phone credential is routed to phone entry and verification. A legacy saved number may be offered only when it is already available through an authorized profile path; otherwise the customer enters it again. Unverified Firestore data is never treated as proof of ownership.

### Google Sign-In

Google authentication completes normally. If Firebase does not report a linked phone credential, the same verification gate collects or confirms a phone number and links it before navigation continues.

### Restored Session

Splash restoration checks the linked phone credential rather than `emailVerified`. An incomplete user is routed to verification, not silently signed out and not admitted to the home screen.

## OTP Experience

Use a branded modal sheet that cannot be dismissed accidentally with an outside tap or back gesture. It contains:

- a concise verification heading and security explanation;
- the masked destination number;
- six accessible digit inputs with numeric keyboard, paste support, backspace navigation, and SMS autofill where the platform provides it;
- automatic submission after the sixth digit, plus a visible verify button for accessibility and retry control;
- a 60-second resend countdown;
- `Change number` and explicit `Cancel` actions;
- an inline status region announced by screen readers;
- loading controls that disable duplicate send and verify actions;
- a short verified-success state before navigation.

Changing the number preserves the already-entered name, email, and password during initial registration. Canceling returns to the authentication screen without granting application access. A subsequent login resumes the required verification.

## Errors and Abuse Protection

- Invalid or incomplete code: keep the sheet open, clear the code, return focus to the first box, and show an inline message.
- Expired verification session: explain that a new code is required and enable resend when allowed.
- Invalid phone number: return to phone editing with the country selector preserved.
- Existing linked phone: explain that the number already belongs to another account; do not merge accounts automatically.
- Network failure: preserve the current step and permit a safe retry.
- SMS quota or throttling: show a wait-and-retry message without repeatedly calling Firebase.
- Too many code attempts: require a new verification code.
- Android automatic verification: link the supplied credential once; ignore later manual completion callbacks.
- Resend: permit only after 60 seconds and pass the Firebase resend token when available.
- Concurrency: guard send, resend, link, and navigation so every action completes at most once.
- Logs and analytics must never contain raw OTP values, passwords, or full phone numbers.

Firebase remains responsible for code generation, expiry, attempt validation, app verification, and provider uniqueness. No SMS secret or OTP comparison is implemented in Flutter or Firestore.

## Profile Data and Migration

The Firestore customer document contains:

- `phone`: the verified E.164 number after successful linking;
- `phoneVerifiedAt`: a server timestamp written after linking;
- existing identity and profile fields;
- no trusted client-controlled `phoneVerified` access flag.

Existing `emailVerified` fields may remain as historical data but are no longer read for navigation or authorization. New profile writes stop depending on them. Existing accounts are migrated lazily at their next login by the shared verification gate; no bulk account mutation is required.

Checkout continues to prefill the verified account number. A delivery contact number changed only for an order does not change the authenticated phone identity. Changing the account’s verified phone later is a separate re-verification feature and is outside this change.

## Files and Responsibilities

Expected implementation areas:

- `lib/features/auth/services/auth_service.dart`: remove email-verification policy; add phone send/link/provider checks and friendly errors.
- `lib/features/auth/screens/register_screen.dart`: initiate the resumable signup verification flow.
- `lib/features/auth/screens/login_screen.dart`: remove Gmail-verification handling and use the shared post-authentication gate.
- `lib/features/splash/screens/splash_screen.dart`: route based on linked phone verification.
- New focused authentication widgets/coordinator: phone collection when needed, OTP modal sheet, verification state management, and the shared gate.
- Existing international phone input: reuse its E.164 output and country-selection UX.
- Firestore Security Rules and authenticated Cloud Functions: require the trusted Firebase ID-token `phone_number` claim for private customer/order access.
- Authentication tests: replace email-verification expectations with phone-gate expectations.
- Privacy and release documentation: add Firebase phone-processing, billing, certificate, provider, and test-number requirements.

The existing `email_verification_sheet.dart` is removed once no route imports it.

## Testing Strategy

### Unit Tests

- Detect linked and unlinked Firebase phone providers.
- Confirm protected Rules/Function authorization accepts a trusted phone claim and rejects an authenticated token without one.
- Map Firebase phone errors to customer-safe messages.
- Enforce resend countdown and single-flight operations.
- Normalize and mask international numbers without exposing full values.
- Reject invalid, incomplete, and stale codes.

### Widget Tests

- Signup opens the OTP sheet after SMS is sent.
- Six-digit entry, paste, deletion, focus movement, loading, error, resend, edit-number, cancel, success, and screen-reader semantics behave correctly.
- Email/password, Google, existing-account, and splash flows cannot bypass the verification gate.
- Verified users still follow the existing location/home routing.
- Small-screen and keyboard-open layouts do not overflow.

### Integration and Manual Tests

- Use Firebase fictional numbers for repeatable success, wrong-code, resend, duplicate-number, and interrupted-session testing.
- Verify Android automatic SMS retrieval and manual entry on a real device.
- Verify debug and release-signed APK app verification.
- Verify airplane-mode recovery and app restart during an incomplete verification.
- Confirm no Gmail verification email is sent and no Gmail-specific copy remains.
- Run Flutter analysis, the full automated test suite, and a release/debug Android build before completion.

## Acceptance Criteria

- No customer can reach authenticated application content without a linked Firebase phone credential.
- Private Firestore and authenticated backend operations reject valid Firebase users whose ID tokens lack the trusted `phone_number` claim, even if the client UI is bypassed.
- New registration completes through a secure six-digit Firebase SMS code and continues to location setup without an email-verification detour.
- Login remains email/password, password reset remains available, and Google sign-in continues to work.
- Interrupted signup or verification can be resumed without permanently blocking the email address.
- The verification UI is branded, accessible, keyboard-safe, and gives specific recovery actions.
- Resend and verification actions are protected from accidental duplicates and abuse-prone rapid retries.
- Gmail-only validation, email-verification sending, email-verification gates, and Gmail-specific messages are removed.
- Existing checkout phone-prefill behavior continues to use the verified profile number without changing payment or navigation functionality.

## Out of Scope

- Phone-only login.
- Custom four-digit OTP generation or a third-party SMS backend.
- SMS multi-factor authentication through Firebase Identity Platform.
- Automatic merging of accounts that already own the same phone number.
- Self-service change of the linked account phone after onboarding.

## References

- Firebase Flutter phone authentication: <https://firebase.google.com/docs/auth/flutter/phone-auth>
- Firebase Authentication limits: <https://firebase.google.com/docs/auth/limits>
- Firebase Android phone authentication and fictional numbers: <https://firebase.google.com/docs/auth/android/phone-auth>
