# Stripe card screen design QA

## Target

- Compact professional add-card experience based on the supplied debit-card and form references.
- Hungry Spot red/white theme with a live, responsive card preview.
- PCI-safe Stripe collection: PAN, expiry, and CVC remain inside Stripe's native CardField.

## Verified

- Responsive layout and keyboard-safe scrolling.
- Cardholder validation and Stripe completion validation.
- Loading, cancellation, and payment error states.
- Successful payment returns the verified PaymentIntent to checkout.
- Checkout persists the order with its PaymentIntent ID; the backend stores verified payment metadata in `stripePayments`.
- `flutter analyze --no-pub`: passed.
- Android debug APK build with Stripe config and Functions emulator defines: passed.

## Runtime visual QA

Static implementation and compilation are verified. Final device screenshot comparison still requires opening the card screen on the connected phone while the Firebase Functions emulator is running.

---

# Explore Menu cart-flow design QA

## Target

- Recreate the supplied compact Explore Menu header with a blue Home back control and a trailing search icon.
- Recreate the supplied red cart summary at the bottom of the menu with product artwork, quantity, subtotal, and a View Cart action.
- Remove the application's regular bottom navigation while the full-screen menu is active.

## Visual comparison

- Compared the supplied header and cart-summary references against a 390 x 844 Flutter render using the real Plus Jakarta Sans and Material icon fonts.
- Header hierarchy, icon color, spacing, white surface, and subtle lower divider match the reference structure.
- Cart summary uses the existing Hungry Spot red, real menu artwork, a compact white thumbnail surface, strong white quantity/price hierarchy, and a white View Cart button.
- The menu content remains responsive and scrollable above the fixed cart summary without overlap.
- P0 issues: none.
- P1 issues: none.
- P2 issues: none.

## Interaction verification

- Back returns from the menu to Home.
- Search icon focuses the existing menu search field.
- View Cart opens the current active cart.
- Explore Menu from the cart returns the user to the menu page.
- The cart summary is omitted when the active cart is empty.

## Build verification

- `flutter analyze`: passed with no issues.
- `flutter test`: all 25 tests passed.
- Android debug APK build with the existing Stripe test defines: passed.

final result: passed
