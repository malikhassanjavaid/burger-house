# Phone Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Gmail-link verification with secure, resumable Firebase SMS phone verification while retaining email/password login and preventing unverified customers from reaching private data or payment operations.

**Architecture:** `AuthService` will implement small injectable authentication and phone-verification contracts. A testable `PhoneVerificationController` will own Firebase callback, resend, race, and OTP state; a branded modal sheet will render that state; and one `AuthenticatedEntryScreen` will gate registration, login, Google-created sessions, and splash restoration before existing location/home routing. Firestore Rules and payment callables will independently require Firebase's trusted `phone_number` ID-token claim so the Flutter UI is not the security boundary.

**Tech Stack:** Flutter/Dart, Firebase Auth 6.5.6, Cloud Firestore 6.7.1, Firebase Functions v2 on Node.js 22, Firestore Security Rules, Flutter widget tests, Node's built-in test runner, Firebase Rules Unit Testing.

**Spec:** `docs/superpowers/specs/2026-08-29-phone-verification-design.md`

## Global Constraints

- Email/password remains the login and recovery method; do not introduce phone-only login or SMS MFA.
- Firebase's six-digit code is authoritative; do not generate, store, log, or compare OTPs in Flutter, Firestore, or Functions.
- `User.phoneNumber`, the linked `phone` provider, and the Firebase ID-token `phone_number` claim are the only trusted proof of verification.
- Normalize phone numbers to E.164 before Firebase or Firestore use.
- Do not write an unverified phone number into a new Firestore customer profile.
- New, legacy, Google, and restored sessions all pass through the same authenticated-entry gate.
- Preserve checkout, Stripe payment results, location routing, account deletion, and all unrelated UI behavior.
- Account deletion remains available to any authenticated owner, including an incomplete phone-verification account.
- Production requires the Firebase Blaze plan, Phone provider, Android debug/release SHA-1 and SHA-256 fingerprints, and app verification; these are release blockers, not client-side bypasses.
- Never ship fictional numbers, test codes, disabled app verification, raw OTP logs, or full-phone analytics.

---

## File Structure

**Create**

- `lib/features/auth/services/auth_repository.dart` — injectable interfaces shared by auth screens, the entry gate, and the phone controller.
- `lib/features/auth/controllers/phone_verification_controller.dart` — verification state machine, callback generation guard, resend timer, and single-flight behavior.
- `lib/features/auth/widgets/phone_verification_sheet.dart` — branded phone-entry/OTP/success modal with one accessible OTP text source and six visual cells.
- `lib/features/auth/screens/authenticated_entry_screen.dart` — the only post-authentication resolver for phone verification, profile synchronization, location setup, and home.
- `test/phone_verification_controller_test.dart` — deterministic fake-client coverage of callback, resend, stale-session, and race behavior.
- `test/phone_verification_sheet_test.dart` — phone entry, OTP typing/paste, validation, accessibility, keyboard layout, cancel, resend, and success coverage.
- `test/authenticated_entry_screen_test.dart` — verified, unverified, canceled, location, home, and restored-session routing coverage.
- `functions/index.test.js` — callable authorization helper tests.
- `functions/auth_policy.js` — reusable authenticated/verified-customer authorization helpers without exporting a deployable callable.
- `functions/firestore.rules.test.js` — emulator-backed trusted-phone claim tests for profiles and orders.

**Modify**

- `lib/features/auth/services/auth_service.dart` — remove Gmail verification, implement the interfaces, wrap Firebase Phone Auth, refresh tokens, and synchronize only verified profiles.
- `lib/features/auth/screens/register_screen.dart` — accept any valid email, create the auth account, and enter the shared gate with the signup phone.
- `lib/features/auth/screens/login_screen.dart` — remove resend-email UI and enter the shared gate after password login.
- `lib/features/splash/screens/splash_screen.dart` — never send an authenticated session directly to home; use the shared gate, including timeout fallback.
- `test/auth_service_validation_test.dart` — replace Gmail-only validation assertions and add phone-identity/error mapping coverage.
- `test/international_phone_flow_test.dart` — retain country/checkout coverage and assert the registration flow passes E.164 input to verification.
- `firestore.rules` — require the trusted token phone claim for private profiles and orders.
- `functions/index.js` — require the trusted token phone claim for payment creation/verification but not account deletion.
- `functions/package.json` and `functions/package-lock.json` — add Node/rules test commands and rules-test dependencies.
- `firebase.json` — add a fixed localhost Firestore emulator port for rules tests.
- `README.md`, `docs/privacy-policy.html`, and `docs/RELEASE_CHECKLIST.md` — document SMS processing, setup, testing, billing, and deployment gates.

**Delete**

- `lib/features/auth/widgets/email_verification_sheet.dart` — remove after all imports and Gmail-verification paths are gone.

---

### Task 1: Replace Gmail-only Input Policy With General Email Validation

**Files:**
- Modify: `test/auth_service_validation_test.dart`
- Modify: `lib/features/auth/services/auth_service.dart`
- Modify: `lib/features/auth/screens/register_screen.dart`

**Interfaces:**
- Produces: `String normalizeAuthEmail(String value)` retained unchanged.
- Produces: `bool isValidEmailAddress(String value)` replacing `isValidGmailAddress`.
- Produces: `bool hasVerifiedPhoneIdentity({required Iterable<String> providerIds, required String? phoneNumber})` for later Firebase/session checks.

- [ ] **Step 1: Write failing validation and identity tests**

Replace the Gmail test group with exact expectations:

```dart
group('Registration email validation', () {
  test('accepts normalized addresses from common providers', () {
    expect(isValidEmailAddress('Customer.Name+orders@GMAIL.COM'), isTrue);
    expect(isValidEmailAddress('customer@outlook.com'), isTrue);
  });

  test('rejects malformed and blank addresses', () {
    expect(isValidEmailAddress('customer@'), isFalse);
    expect(isValidEmailAddress('@example.com'), isFalse);
    expect(isValidEmailAddress('not an email@example.com'), isFalse);
    expect(isValidEmailAddress('customer@example'), isFalse);
    expect(isValidEmailAddress(''), isFalse);
  });
});

group('Verified phone identity', () {
  test('requires both the linked provider and Firebase phone number', () {
    expect(
      hasVerifiedPhoneIdentity(
        providerIds: const ['password', 'phone'],
        phoneNumber: '+923001234567',
      ),
      isTrue,
    );
    expect(
      hasVerifiedPhoneIdentity(
        providerIds: const ['password'],
        phoneNumber: '+923001234567',
      ),
      isFalse,
    );
    expect(
      hasVerifiedPhoneIdentity(
        providerIds: const ['password', 'phone'],
        phoneNumber: '',
      ),
      isFalse,
    );
  });
});
```

- [ ] **Step 2: Run the focused test and confirm the old policy fails**

Run: `flutter test --no-pub test/auth_service_validation_test.dart`

Expected: FAIL because `isValidEmailAddress` and `hasVerifiedPhoneIdentity` do not exist.

- [ ] **Step 3: Implement the pure validators**

Replace `isValidGmailAddress` with a normalized local/domain validator and add the identity helper:

```dart
bool isValidEmailAddress(String value) {
  final email = normalizeAuthEmail(value);
  if (email.contains(RegExp(r'\s'))) return false;
  final parts = email.split('@');
  if (parts.length != 2 || parts.first.isEmpty || parts.last.isEmpty) {
    return false;
  }
  final local = RegExp(r"^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+$");
  final domain = RegExp(
    r'^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$',
  );
  return local.hasMatch(parts.first) && domain.hasMatch(parts.last);
}

bool hasVerifiedPhoneIdentity({
  required Iterable<String> providerIds,
  required String? phoneNumber,
}) {
  return providerIds.contains(PhoneAuthProvider.PROVIDER_ID) &&
      phoneNumber?.trim().isNotEmpty == true;
}
```

Update registration validation and `gmail-required` handling to use generic email copy: `Enter a valid email address`.

- [ ] **Step 4: Run validation and registration-field tests**

Run: `flutter test --no-pub test/auth_service_validation_test.dart test/international_phone_flow_test.dart`

Expected: PASS with Gmail and Outlook accepted and the existing international phone UI unchanged.

- [ ] **Step 5: Commit the policy change**

```powershell
git add lib/features/auth/services/auth_service.dart lib/features/auth/screens/register_screen.dart test/auth_service_validation_test.dart
git commit -m "refactor(auth): accept valid email providers"
```

---

### Task 2: Build the Testable Phone Verification State Machine

**Files:**
- Create: `lib/features/auth/services/auth_repository.dart`
- Create: `lib/features/auth/controllers/phone_verification_controller.dart`
- Create: `test/phone_verification_controller_test.dart`

**Interfaces:**
- Produces: `PhoneVerificationClient.sendPhoneVerificationCode` and `confirmPhoneVerificationCode` with the exact signatures below.
- Produces: `AuthRepository` for login/register/gate dependency injection.
- Produces: `PhoneVerificationPhase`, `PhoneVerificationState`, and `PhoneVerificationController` consumed by the modal sheet.

- [ ] **Step 1: Define the repository contracts**

Create `auth_repository.dart` with these exact public signatures:

```dart
import '../../location/models/delivery_location.dart';

abstract interface class PhoneVerificationClient {
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    int? forceResendingToken,
    required Future<void> Function() onAutomaticVerificationCompleted,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(Object error) onVerificationFailed,
    required void Function(String verificationId) onAutoRetrievalTimeout,
  });

  Future<void> confirmPhoneVerificationCode({
    required String verificationId,
    required String smsCode,
  });
}

abstract interface class AuthRepository implements PhoneVerificationClient {
  bool get hasAuthenticatedUser;
  Future<void> signIn({required String email, required String password});
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
  Future<void> signOut();
  Future<bool> hasVerifiedPhoneSession();
  Future<void> syncVerifiedCustomerProfile();
  Future<DeliveryLocation?> getDeliveryLocation();
}
```

- [ ] **Step 2: Write failing controller tests with a deterministic fake**

Cover initial send, code confirmation, wrong code, resend lock, 60-second unlock, change number, stale callbacks, automatic verification racing manual verification, and disposal. The fake exposes the callbacks instead of invoking Firebase:

```dart
final class FakePhoneVerificationClient implements PhoneVerificationClient {
  void Function(String, int?)? codeSent;
  Future<void> Function()? automatic;
  void Function(Object)? failed;
  int sendCount = 0;
  int confirmCount = 0;

  @override
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    int? forceResendingToken,
    required Future<void> Function() onAutomaticVerificationCompleted,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(Object error) onVerificationFailed,
    required void Function(String verificationId) onAutoRetrievalTimeout,
  }) async {
    sendCount += 1;
    codeSent = onCodeSent;
    automatic = onAutomaticVerificationCompleted;
    failed = onVerificationFailed;
  }

  @override
  Future<void> confirmPhoneVerificationCode({
    required String verificationId,
    required String smsCode,
  }) async {
    confirmCount += 1;
  }
}
```

Use `tester.pump(const Duration(seconds: 60))` in a `testWidgets` case to advance the resend timer without real waiting. Assert that callbacks captured before `changePhone()` cannot move the controller back to `awaitingCode`.

- [ ] **Step 3: Run the controller test and confirm it fails**

Run: `flutter test --no-pub test/phone_verification_controller_test.dart`

Expected: FAIL because the state/controller files do not exist.

- [ ] **Step 4: Implement the controller and immutable state**

Use these phases and public commands:

```dart
enum PhoneVerificationPhase {
  phoneEntry,
  sending,
  awaitingCode,
  verifying,
  verified,
  failure,
}

class PhoneVerificationController extends ChangeNotifier {
  PhoneVerificationController({
    required PhoneVerificationClient client,
    String initialPhone = '',
    Duration resendDelay = const Duration(seconds: 60),
  });

  PhoneVerificationState get state;
  Future<void> sendCode(String phoneNumber);
  Future<void> verifyCode(String smsCode);
  Future<void> resendCode();
  void changePhone();
  void clearError();
  @override
  void dispose();
}
```

Increment a private generation number for every send/change operation; every Firebase callback must compare its captured generation before mutating state. Keep separate `_operationInFlight` and `_completionClaimed` guards so manual and Android automatic completion can never link or navigate twice. Start the countdown only from `onCodeSent`, cancel it on change/dispose, and expose only masked phone text to UI status messages.

- [ ] **Step 5: Run controller tests**

Run: `flutter test --no-pub test/phone_verification_controller_test.dart`

Expected: PASS, including the 60-second resend and stale-callback cases.

- [ ] **Step 6: Commit the state machine**

```powershell
git add lib/features/auth/services/auth_repository.dart lib/features/auth/controllers/phone_verification_controller.dart test/phone_verification_controller_test.dart
git commit -m "feat(auth): add phone verification state machine"
```

---

### Task 3: Link Firebase Phone Credentials and Synchronize Verified Profiles

**Files:**
- Modify: `lib/features/auth/services/auth_service.dart`
- Modify: `test/auth_service_validation_test.dart`

**Interfaces:**
- Consumes: `AuthRepository` and `PhoneVerificationClient` from Task 2.
- Produces: `AuthService implements AuthRepository` with the exact Task 2 signatures.
- Produces: `String friendlyAuthError(Object error)` mappings consumed by the controller and sheet.

- [ ] **Step 1: Write failing phone-error mapping tests**

Add exact Firebase exception assertions:

```dart
test('maps phone verification failures to recovery copy', () {
  expect(
    friendlyAuthError(FirebaseAuthException(code: 'invalid-phone-number')),
    'Enter a valid phone number and try again.',
  );
  expect(
    friendlyAuthError(
      FirebaseAuthException(code: 'invalid-verification-code'),
    ),
    'That verification code is incorrect. Try again.',
  );
  expect(
    friendlyAuthError(FirebaseAuthException(code: 'session-expired')),
    'This code has expired. Request a new code.',
  );
  expect(
    friendlyAuthError(
      FirebaseAuthException(code: 'credential-already-in-use'),
    ),
    'This phone number is already linked to another account.',
  );
});
```

- [ ] **Step 2: Run the mapping test and confirm it fails**

Run: `flutter test --no-pub test/auth_service_validation_test.dart`

Expected: FAIL because the current messages are generic.

- [ ] **Step 3: Remove email-verification behavior from AuthService**

Make `AuthService implements AuthRepository`, add `hasAuthenticatedUser`, and change registration/login behavior:

```dart
bool get hasAuthenticatedUser => _auth.currentUser != null;

Future<void> register({
  required String name,
  required String email,
  required String phone,
  required String password,
}) async {
  final cleanEmail = normalizeAuthEmail(email);
  if (!isValidEmailAddress(cleanEmail)) {
    throw FirebaseAuthException(
      code: 'invalid-email',
      message: 'Enter a valid email address.',
    );
  }
  final credential = await _auth.createUserWithEmailAndPassword(
    email: cleanEmail,
    password: password,
  );
  final user = credential.user;
  if (user == null) {
    throw FirebaseAuthException(
      code: 'user-not-created',
      message: 'The account could not be created.',
    );
  }
  await user.updateDisplayName(name.trim());
}
```

Delete `sendEmailVerification`, `resendEmailVerification`, `_requiresEmailVerification`, email-verification sign-out, and the email-verification rejection in `signIn`. Defer all Firestore profile writes from registration and Google authentication until `syncVerifiedCustomerProfile()` runs behind the verified-phone gate.

- [ ] **Step 4: Implement Firebase send, manual confirmation, and automatic linking**

Wrap `verifyPhoneNumber` with the Task 2 callbacks. Both manual and automatic paths call one private method:

```dart
Future<void> _linkPhoneCredential(PhoneAuthCredential credential) async {
  final user = _auth.currentUser;
  if (user == null) {
    throw FirebaseAuthException(
      code: 'user-not-found',
      message: 'Sign in again before verifying your phone.',
    );
  }
  try {
    await user.linkWithCredential(credential);
  } on FirebaseAuthException catch (error) {
    if (error.code != 'provider-already-linked') rethrow;
  }
  await user.reload();
  final refreshed = _auth.currentUser;
  if (refreshed == null ||
      !hasVerifiedPhoneIdentity(
        providerIds: refreshed.providerData.map((item) => item.providerId),
        phoneNumber: refreshed.phoneNumber,
      )) {
    throw FirebaseAuthException(
      code: 'phone-not-verified',
      message: 'The phone number could not be verified.',
    );
  }
  await refreshed.getIdToken(true);
}
```

Never print the credential or SMS code. Propagate `credential-already-in-use`, `too-many-requests`, `quota-exceeded`, `app-not-authorized`, and network failures to the controller.

- [ ] **Step 5: Implement verified-session and profile synchronization**

`hasVerifiedPhoneSession()` reloads the user and calls `hasVerifiedPhoneIdentity`. `syncVerifiedCustomerProfile()` must first re-check the verified phone, then read the user document to preserve an existing `createdAt`, and finally merge `uid`, display name, normalized email, verified Firebase phone number, `role: customer`, `phoneVerifiedAt`, `profileUpdatedAt`, and `lastLoginAt`. Add `createdAt` only when the document does not exist.

- [ ] **Step 6: Add all phone-specific friendly errors and run tests**

Run: `flutter test --no-pub test/auth_service_validation_test.dart test/phone_verification_controller_test.dart`

Expected: PASS with specific messages and no Gmail-verification cases.

- [ ] **Step 7: Commit Firebase phone linking**

```powershell
git add lib/features/auth/services/auth_service.dart test/auth_service_validation_test.dart
git commit -m "feat(auth): link verified Firebase phone credentials"
```

---

### Task 4: Build the Branded Accessible OTP Sheet

**Files:**
- Create: `lib/features/auth/widgets/phone_verification_sheet.dart`
- Create: `test/phone_verification_sheet_test.dart`
- Modify: `lib/core/theme/app_theme.dart` only if an existing token cannot express the approved red/yellow surface.

**Interfaces:**
- Consumes: `PhoneVerificationController` from Task 2.
- Produces: `Future<bool> showPhoneVerificationSheet(BuildContext context, {required PhoneVerificationClient client, String initialPhone, Duration resendDelay})`.
- Produces keys: `phone-verification-number-input`, `phone-verification-send`, `phone-otp-input`, `phone-otp-verify`, `phone-otp-resend`, `phone-otp-change-number`, and `phone-verification-cancel`.

- [ ] **Step 1: Write failing widget tests for phone-entry mode**

Pump the sheet with an empty initial phone and a fake client. Assert that the international country selector and number field appear, an invalid number shows `Enter a valid phone number`, and a valid `+923001234567` send invokes the fake once.

```dart
await tester.tap(find.byKey(const ValueKey('phone-verification-send')));
await tester.pump();
expect(find.text('Enter a valid phone number'), findsOneWidget);

await tester.enterText(
  find.byKey(const ValueKey('phone-verification-number-input')),
  '3001234567',
);
await tester.tap(find.byKey(const ValueKey('phone-verification-send')));
await tester.pump();
expect(fake.sendCount, 1);
```

- [ ] **Step 2: Write failing OTP interaction and accessibility tests**

Start with `initialPhone: '+923001234567'`, trigger `codeSent`, then assert:

- six visual cells and one semantic text input;
- `AutofillHints.oneTimeCode`, numeric keyboard, six-character limit, full-code paste, and backspace;
- automatic verification after six digits plus a visible verify action;
- masked copy that does not expose `+923001234567` in a `Text` widget;
- resend countdown, disabled duplicate taps, change-number preservation, inline live-region errors, explicit cancel, and a verified success state;
- no overflow at 320x640 with the keyboard inset and at 200% text scale.

Use this success assertion:

```dart
await tester.enterText(
  find.byKey(const ValueKey('phone-otp-input')),
  '123456',
);
await tester.pump();
expect(fake.confirmCount, 1);
expect(find.text('Phone verified'), findsOneWidget);
```

- [ ] **Step 3: Run sheet tests and confirm they fail**

Run: `flutter test --no-pub test/phone_verification_sheet_test.dart`

Expected: FAIL because the modal widget does not exist.

- [ ] **Step 4: Implement the modal and visual OTP cells**

`showPhoneVerificationSheet` must use `isDismissible: false`, `enableDrag: false`, a transparent background, `SafeArea`, and `PopScope(canPop: allowExplicitPop)`. Outside taps, drag, and system back keep `allowExplicitPop` false; the visible cancel action sets it true before calling `Navigator.pop(context, false)`. Use one real `TextField` as the OTP source with `FilteringTextInputFormatter.digitsOnly`, `LengthLimitingTextInputFormatter(6)`, `keyboardType: TextInputType.number`, and `autofillHints: const [AutofillHints.oneTimeCode]`; render six visual cells from its controller value so paste and deletion stay reliable. Before the first SMS send, show consent copy explaining that Firebase/Google processes the number to deliver the security code and prevent abuse, with a link to the existing privacy page.

Listen to controller state once. Pop `true` only after `verified`; pop `false` only from the explicit cancel action. The change-number action clears the code and shows `InternationalPhoneInput` inside the same modal without losing controller state.

- [ ] **Step 5: Run the sheet and existing phone-field tests**

Run: `flutter test --no-pub test/phone_verification_sheet_test.dart test/international_phone_flow_test.dart`

Expected: PASS with no overflow and the country picker still half-height.

- [ ] **Step 6: Commit the OTP experience**

```powershell
git add lib/features/auth/widgets/phone_verification_sheet.dart lib/core/theme/app_theme.dart test/phone_verification_sheet_test.dart
git commit -m "feat(auth): add secure phone OTP experience"
```

---

### Task 5: Route Every Authentication Path Through One Verified Entry Gate

**Files:**
- Create: `lib/features/auth/screens/authenticated_entry_screen.dart`
- Create: `test/authenticated_entry_screen_test.dart`
- Modify: `lib/features/auth/screens/register_screen.dart`
- Modify: `lib/features/auth/screens/login_screen.dart`
- Modify: `lib/features/splash/screens/splash_screen.dart`
- Modify: `test/international_phone_flow_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `AuthRepository`, `PhoneVerificationClient`, and `showPhoneVerificationSheet`.
- Produces: `AuthenticatedEntryScreen({AuthRepository? repository, String initialPhone = '', bool showWelcome = false, String? welcomeName})`.

- [ ] **Step 1: Write failing verified-entry routing tests**

Create a fake `AuthRepository` with configurable `authenticated`, `verified`, and `location`. Cover these exact outcomes:

```dart
testWidgets('verified customer with location enters home', (tester) async {
  final repository = FakeAuthRepository(
    authenticated: true,
    verified: true,
    location: const DeliveryLocation(
      label: 'Home',
      area: 'Gulberg',
      addressLine: 'Test address',
      latitude: 31.5204,
      longitude: 74.3587,
    ),
  );
  await tester.pumpWidget(
    MaterialApp(home: AuthenticatedEntryScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
});
```

Also assert: verified/no-location routes to `LocationSetupScreen`; unverified opens the OTP sheet before any home widget; successful OTP synchronizes the profile once; cancel signs out and returns to login; a profile-sync Firestore failure does not revoke the verified Firebase session; and repeated async completion cannot navigate twice.

- [ ] **Step 2: Run the entry tests and confirm they fail**

Run: `flutter test --no-pub test/authenticated_entry_screen_test.dart`

Expected: FAIL because the shared entry screen does not exist.

- [ ] **Step 3: Implement AuthenticatedEntryScreen**

Use a private `_resolve()` that executes this sequence once:

```dart
if (!repository.hasAuthenticatedUser) {
  replaceWithLogin();
  return;
}
var verified = await repository.hasVerifiedPhoneSession();
if (!verified && mounted) {
  verified = await showPhoneVerificationSheet(
    context,
    client: repository,
    initialPhone: widget.initialPhone,
  );
}
if (!verified) {
  await repository.signOut();
  replaceWithLogin();
  return;
}
try {
  await repository.syncVerifiedCustomerProfile();
} on FirebaseException catch (error) {
  showProfileSyncWarning(error);
}
final location = await repository.getDeliveryLocation();
routeToLocationOrHome(location);
```

Show the existing branded loader during resolution. Use a `_navigationClaimed` guard and mounted checks after every await. A verified Firebase session remains valid when non-critical profile synchronization fails: show the existing top-right warning and continue through location/home resolution. An unverified session never reaches application content.

- [ ] **Step 4: Rewire registration and login**

Inject an optional `AuthRepository` into `RegisterScreen` and `LoginScreen`, defaulting to `AuthService()`. After `register`, replace the route stack with `AuthenticatedEntryScreen(repository: repository, initialPhone: _phoneNumber, showWelcome: true, welcomeName: _name.text.trim())`. After `signIn`, use the same screen without an initial phone. Delete Gmail-verification imports, resend UI, error branching, and copy.

The registration loading text changes from `Creating your account` to `Securing your account` only while Firebase creates credentials; the shared entry screen owns SMS progress.

- [ ] **Step 5: Rewire splash, including its timeout fallback**

Inject an optional `AuthRepository` into `SplashScreen`. A missing user retains onboarding/login behavior. Every authenticated user is replaced with `AuthenticatedEntryScreen(repository: repository)`; remove `emailVerified`, `hasVerifiedSession`, direct home fallback, and direct location lookup from splash. On startup timeout, an authenticated user still goes to the verified entry gate—never directly home.

- [ ] **Step 6: Add registration and restored-session regression assertions**

In `international_phone_flow_test.dart`, submit the registration form with a fake repository and assert `initialPhone == '+923001234567'` reaches the fake phone client. In `widget_test.dart`, assert an authenticated but unverified splash fake renders the verification sheet and never `HomeScreen`.

- [ ] **Step 7: Run all auth and startup tests**

Run: `flutter test --no-pub test/authenticated_entry_screen_test.dart test/phone_verification_sheet_test.dart test/international_phone_flow_test.dart test/widget_test.dart`

Expected: PASS with no email-verification UI and no unverified home route.

- [ ] **Step 8: Commit the shared gate**

```powershell
git add lib/features/auth/screens/authenticated_entry_screen.dart lib/features/auth/screens/register_screen.dart lib/features/auth/screens/login_screen.dart lib/features/splash/screens/splash_screen.dart test/authenticated_entry_screen_test.dart test/international_phone_flow_test.dart test/widget_test.dart
git commit -m "feat(auth): gate customer entry on verified phone"
```

---

### Task 6: Enforce Verified Phone Claims in Firestore and Payment Functions

**Files:**
- Modify: `firestore.rules`
- Modify: `functions/index.js`
- Create: `functions/auth_policy.js`
- Create: `functions/index.test.js`
- Create: `functions/firestore.rules.test.js`
- Modify: `functions/package.json`
- Modify: `functions/package-lock.json`
- Modify: `firebase.json`

**Interfaces:**
- Produces: Firestore Rules helper `hasVerifiedPhone()`.
- Produces: `authenticatedUid(request)` and `verifiedCustomerUid(request)` from `functions/auth_policy.js` for production callables and direct unit tests.
- Preserves: `authenticatedUid(request)` for `deleteAccount`.

- [ ] **Step 1: Add backend test dependencies and scripts**

From the repository root run:

```powershell
npm.cmd install --prefix functions --save-dev @firebase/rules-unit-testing firebase
```

Set scripts to:

```json
{
  "test": "node --test index.test.js",
  "test:rules": "node --test firestore.rules.test.js",
  "lint": "eslint ."
}
```

Add Firestore emulator host `127.0.0.1` and port `8080` to `firebase.json`.

- [ ] **Step 2: Write failing callable authorization tests**

Import both helpers directly from `./auth_policy`. Test with Node's strict assertions:

```javascript
test("verifiedCustomerUid requires a trusted phone claim", () => {
  assert.equal(
    verifiedCustomerUid({
      auth: {uid: "customer-1", token: {phone_number: "+923001234567"}},
    }),
    "customer-1",
  );
  assert.throws(
    () => verifiedCustomerUid({auth: {uid: "customer-1", token: {}}}),
    (error) => error.code === "failed-precondition",
  );
});

test("account deletion keeps the authenticated-only helper", () => {
  assert.equal(
    authenticatedUid({auth: {uid: "incomplete-customer", token: {}}),
    "incomplete-customer",
  );
});
```

- [ ] **Step 3: Write failing Firestore emulator tests**

Use `initializeTestEnvironment` with `../firestore.rules`. Seed owned orders with `withSecurityRulesDisabled`. Assert a user context with `{phone_number: '+923001234567'}` can create/read its own profile and read/create its own valid order, while the same UID without the claim cannot. Assert neither context can read another customer's document and public policy remains unchanged.

Use this valid cash-order fixture and trusted/untrusted assertions:

```javascript
function validCashOrder(customerId) {
  return {
    customerId,
    status: "placed",
    fulfillmentMethod: "delivery",
    paymentMethod: "cash_on_delivery",
    paymentStatus: "pending",
    orderNumber: "HS-TEST-1",
    customerEmail: "customer@example.com",
    receiverName: "Customer",
    phone: "+923001234567",
    deliveryAddress: "Test address",
    items: [{id: "burger-1", quantity: 1}],
    subtotal: 10,
    deliveryFee: 2,
    serviceFee: 1,
    discount: 0,
    etaMinMinutes: 30,
    etaMaxMinutes: 40,
    total: 13,
  };
}

test("private profiles and orders require a verified phone claim", async () => {
  const verified = testEnv.authenticatedContext("customer-1", {
    phone_number: "+923001234567",
  }).firestore();
  const unverified = testEnv.authenticatedContext("customer-1").firestore();

  await assertSucceeds(setDoc(doc(verified, "users/customer-1"), {
    uid: "customer-1",
    phone: "+923001234567",
  }));
  await assertFails(setDoc(doc(unverified, "users/customer-1"), {
    uid: "customer-1",
  }));
  await assertSucceeds(addDoc(
    collection(verified, "orders"),
    validCashOrder("customer-1"),
  ));
  await assertFails(addDoc(
    collection(unverified, "orders"),
    validCashOrder("customer-1"),
  ));
  await assertFails(getDoc(doc(verified, "users/customer-2")));
});
```

- [ ] **Step 4: Run backend tests and confirm they fail**

Run:

```powershell
npm.cmd test --prefix functions
firebase emulators:exec --only firestore --project hungry-spot-phone-rules-test "npm.cmd run test:rules --prefix functions"
```

Expected: callable test FAIL because `verifiedCustomerUid` is absent; rules test FAIL because signed-in users without phones are currently allowed.

- [ ] **Step 5: Enforce the phone claim in callables**

Add:

```javascript
function verifiedCustomerUid(request) {
  const uid = authenticatedUid(request);
  const phoneNumber = request.auth && request.auth.token &&
    request.auth.token.phone_number;
  if (typeof phoneNumber !== "string" || phoneNumber.length < 8) {
    throw new HttpsError(
      "failed-precondition",
      "Verify your phone number before making a payment.",
    );
  }
  return uid;
}
```

Place both helpers in `functions/auth_policy.js`, importing `HttpsError` there. Import and use `verifiedCustomerUid` in `createPaymentIntent` and `verifyPaymentIntent`; keep `deleteAccount` on `authenticatedUid`. Do not expose either helper through `exports` in `index.js`, and do not log token contents.

- [ ] **Step 6: Enforce the phone claim in Firestore Rules**

Add:

```text
function hasVerifiedPhone() {
  return signedIn()
    && request.auth.token.phone_number is string
    && request.auth.token.phone_number.size() >= 8;
}

function ownsVerifiedDocument(userId) {
  return hasVerifiedPhone() && request.auth.uid == userId;
}
```

Use `ownsVerifiedDocument` for user create/read/update. Require `hasVerifiedPhone()` for order create/read in addition to existing ownership, totals, and payment constraints. Do not add client access to `stripePayments` and do not weaken order validation.

- [ ] **Step 7: Run backend tests and lint**

Run:

```powershell
npm.cmd test --prefix functions
npm.cmd run lint --prefix functions
firebase emulators:exec --only firestore --project hungry-spot-phone-rules-test "npm.cmd run test:rules --prefix functions"
```

Expected: all PASS.

- [ ] **Step 8: Commit backend enforcement**

```powershell
git add firestore.rules firebase.json functions/auth_policy.js functions/index.js functions/index.test.js functions/firestore.rules.test.js functions/package.json functions/package-lock.json
git commit -m "security(auth): require verified phone for customer operations"
```

---

### Task 7: Remove Email Verification Artifacts and Document Production Setup

**Files:**
- Delete: `lib/features/auth/widgets/email_verification_sheet.dart`
- Modify: `README.md`
- Modify: `docs/privacy-policy.html`
- Modify: `docs/RELEASE_CHECKLIST.md`
- Modify: any auth test still asserting Gmail-verification copy.

**Interfaces:**
- Consumes: the completed client/backend behavior from Tasks 1–6.
- Produces: release instructions that match the shipping authentication contract.

- [ ] **Step 1: Scan for obsolete verification behavior**

Run:

```powershell
rg -n "Gmail|gmail-required|sendEmailVerification|resendEmailVerification|emailVerified|EmailVerificationSheet|email-not-verified" lib test README.md docs
```

Expected: only the historical design/spec references remain; production Dart/tests still contain matches before cleanup.

- [ ] **Step 2: Delete the unused sheet and update product documentation**

Remove the sheet after imports are gone. Change README authentication copy to “email/password identity with mandatory Firebase phone verification.” Add privacy-policy language stating that the phone number is sent to and stored by Google for authentication abuse prevention. Do not claim that Hungry Spot receives or stores the OTP.

- [ ] **Step 3: Add release-blocking Firebase checks**

Add checklist items for:

- Blaze billing enabled and budget alerts configured;
- Phone provider enabled and intended SMS regions allowed;
- debug, upload, and Play App Signing SHA-1/SHA-256 fingerprints registered;
- debug and release APK verification tested on a real Android device;
- fictional console numbers used for development and absent from source;
- Firestore Rules and Functions deployed together before the client rollout;
- privacy/Data Safety disclosures include phone-auth processing;
- SMS quota/throttling and duplicate-phone messages smoke-tested;
- no raw OTP or full phone number appears in logs.

- [ ] **Step 4: Run the complete static and automated verification**

Run:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
npm.cmd test --prefix functions
npm.cmd run lint --prefix functions
firebase emulators:exec --only firestore --project hungry-spot-phone-rules-test "npm.cmd run test:rules --prefix functions"
```

Expected: formatting, analysis, Flutter tests, Node tests, lint, and Firestore rules tests all PASS.

- [ ] **Step 5: Build Android and perform Firebase fictional-number smoke tests**

Run:

```powershell
flutter build apk --debug
flutter build apk --release --dart-define-from-file=production.config.json
```

On a real Android device verify: new signup, code autofill/manual entry, wrong code, resend countdown, number edit, app restart before verification, legacy login, verified login, location setup, checkout phone prefill, Stripe test payment, and account deletion from an incomplete account. Use only Firebase Console fictional numbers until production Phone Auth configuration is confirmed.

Expected: both builds succeed; unverified accounts cannot read/write private profile/order data or call payment functions; deletion remains available.

- [ ] **Step 6: Re-run the obsolete-copy scan**

Run:

```powershell
rg -n "Gmail|gmail-required|sendEmailVerification|resendEmailVerification|email-not-verified|EmailVerificationSheet" lib test README.md docs/RELEASE_CHECKLIST.md docs/privacy-policy.html
```

Expected: no matches.

- [ ] **Step 7: Commit cleanup and production documentation**

```powershell
git add README.md docs/privacy-policy.html docs/RELEASE_CHECKLIST.md lib/features/auth/widgets test
git commit -m "docs(auth): finalize phone verification release checks"
```

---

## Final Review Checklist

- [ ] Compare every acceptance criterion in `docs/superpowers/specs/2026-08-29-phone-verification-design.md` with a passing test or documented real-device check.
- [ ] Inspect `git status --short` and stage only phone-verification files; preserve all unrelated user changes already present in the worktree.
- [ ] Inspect the branch diff for secrets, fictional numbers, OTP values, full-phone logging, disabled app verification, weakened Firestore rules, and accidental checkout/payment navigation edits.
- [ ] Confirm Firebase Console configuration remains an explicit deployment prerequisite; never report real SMS as working until it is tested against the configured project.
- [ ] Record any environment-only blocker separately from code/test completion.
