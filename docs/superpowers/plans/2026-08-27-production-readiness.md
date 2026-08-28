# Hungry Spot Production Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a signed, optimized Android release candidate with permanent identity, branded icons, privacy/account deletion foundations, and portfolio-ready documentation.

**Architecture:** Preserve the current Flutter ordering and Stripe behavior while hardening release boundaries in Android Gradle, Firebase Functions, and focused Flutter legal/account services. Legal values are compile-time configuration; secrets and signing material remain ignored local files.

**Tech Stack:** Flutter 3.44, Dart 3.12, Android Gradle/Kotlin, Firebase Auth/Firestore/Functions, Stripe, Node.js 22.

**Spec:** `docs/superpowers/specs/2026-08-27-production-readiness-design.md`

## Global Constraints

- Android application ID and namespace: `com.malikhassanjavaid.hungryspot`.
- Target API 36; minimum API 24.
- Keep `flutter_stripe` 12.1.1 and existing platform overrides.
- Never commit keystores, key passwords, Stripe secrets, or private service credentials.
- Do not change cart, checkout, navigation, or payment behavior.

---

### Task 1: Reproduce and fix the release boundary

**Files:**
- Create: `android/app/proguard-rules.pro`
- Modify: `android/app/build.gradle.kts`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: generated R8 rules from `build/app/outputs/mapping/release/missing_rules.txt`.
- Produces: release build that reaches signing without Stripe missing-class errors.

- [ ] Record the failing `flutter build appbundle --release --no-pub` output.
- [ ] Add the five generated Stripe `-dontwarn` rules.
- [ ] Configure release ProGuard files and strict upload-key loading.
- [ ] Generate an ignored local upload keystore and `key.properties`.
- [ ] Re-run the release build and confirm the R8 failure is gone.

### Task 2: Migrate the permanent Android/Firebase identity

**Files:**
- Modify: `android/app/build.gradle.kts`
- Move: `android/app/src/main/kotlin/com/example/flutter_application_1/MainActivity.kt`
- Replace: `android/app/google-services.json`
- Modify: `lib/firebase_options.dart`
- Modify: `firebase.json`

**Interfaces:**
- Produces: package `com.malikhassanjavaid.hungryspot` registered to Firebase project `burger-house-80541`.

- [ ] Register the new Android app with Firebase CLI without deleting the old app.
- [ ] Run FlutterFire configuration for the new package.
- [ ] Move MainActivity and update its package declaration.
- [ ] Build debug and release variants to prove Google Services matching.

### Task 3: Brand launcher surfaces and optimize images

**Files:**
- Create: `assets/branding/hungry_spot_app_icon.png`
- Modify: `pubspec.yaml`
- Replace: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Replace: `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`
- Modify: all Dart asset-path consumers under `lib/` and tests under `test/`.

**Interfaces:**
- Produces: adaptive/legacy launcher icons and WebP asset paths.

- [ ] Generate a square brand icon from the existing Hungry Spot mark.
- [ ] Generate Android/iOS launcher assets reproducibly.
- [ ] Convert packaged photos to transparent-capable WebP with max dimension 1440px.
- [ ] Update asset paths, remove replaced originals, and report size reduction.
- [ ] Run asset/widget tests and visually inspect key screens.

### Task 4: Add secure account deletion

**Files:**
- Create: `lib/features/account/services/account_service.dart`
- Create: `lib/features/account/screens/privacy_account_screen.dart`
- Create: `test/account_service_test.dart`
- Create: `test/privacy_account_screen_test.dart`
- Modify: `functions/index.js`
- Modify: `lib/features/home/widgets/profile_tab.dart`
- Modify: `lib/features/home/screens/home_screen.dart`

**Interfaces:**
- Produces: `AccountService.deleteAccount()` and callable function `deleteAccount`.

- [ ] Write a failing service test for success, unauthenticated, and re-login errors.
- [ ] Write a failing widget test for confirmation-gated deletion.
- [ ] Add the authenticated callable function with bounded Firestore cleanup.
- [ ] Implement the minimal Flutter service and screen.
- [ ] Wire Profile navigation and post-deletion login reset.
- [ ] Run focused tests, Functions lint, then the full suite.

### Task 5: Add public privacy/deletion material

**Files:**
- Create: `lib/core/config/app_config.dart`
- Create: `docs/privacy-policy.html`
- Create: `docs/delete-account.html`
- Create: `production.config.example.json`
- Modify: `lib/features/auth/screens/login_screen.dart`
- Modify: `.gitignore`

**Interfaces:**
- Produces: compile-time `SUPPORT_EMAIL`, `PRIVACY_POLICY_URL`, and `ACCOUNT_DELETION_URL` values.

- [ ] Write failing configuration/legal-link widget tests.
- [ ] Implement configuration and an unauthenticated Privacy Policy entry point.
- [ ] Add the public pages with app/data/deletion disclosures.
- [ ] Add ignored local production config and validate every URL/email before release.

### Task 6: Accessibility and portfolio polish

**Files:**
- Modify: `lib/features/onboarding/screens/onboarding_screen.dart`
- Modify: `README.md`
- Create: `docs/RELEASE_CHECKLIST.md`
- Modify: relevant onboarding tests.

**Interfaces:**
- Produces: 48dp onboarding Skip target, current README, and repeatable release checklist.

- [ ] Write and fail the onboarding target/semantics test.
- [ ] Apply the minimal accessibility change and pass the focused test.
- [ ] Replace stale README roadmap text with shipped architecture and setup.
- [ ] Document Play Console, Firebase, Stripe test/live, privacy, screenshots, and LinkedIn demo steps.

### Task 7: Final production verification

**Files:**
- Verify only.

- [ ] Run `dart format --output=none --set-exit-if-changed lib test`.
- [ ] Run `flutter analyze --no-pub`.
- [ ] Run `flutter test` and confirm all tests pass.
- [ ] Run Functions lint/tests.
- [ ] Build a signed release AAB and release APK.
- [ ] Install the release APK on API 36 and smoke-test onboarding/login/legal links.
- [ ] Inspect git diff for secrets, generated clutter, and unrelated changes.
