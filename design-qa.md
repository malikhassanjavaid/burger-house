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

---

# Add Card Preview Design QA

final result: passed

## Comparison Target

- Source visual truth: `.dart_tool/card_reference.png`
- Implementation capture: `.dart_tool/goldens/add_card_preview_actual.png`
- Source pixels: 550 × 333
- Implementation pixels: 550 × 333
- CSS/logical size: 550 × 333
- Device pixel ratio: 1
- Density normalization: none required; both captures use identical pixel dimensions
- State: default Add Card preview before cardholder or card details are entered

## Evidence

### Full-view comparison

The source and implementation were opened together at the same 550 × 333 crop. The card aspect ratio, rounded shape, pale-blue field, abstract curved lines, white chip, overlapping red/orange Mastercard mark, name, grouped number, and expiry occupy the same visual regions.

### Focused-region comparison

A separate crop was not required because the component fills the full 550 × 333 capture and all fidelity-critical details remain clearly readable at 1:1 scale. The number row received an additional position and spacing comparison after the first valid pass.

## Required Fidelity Surfaces

- Fonts and typography: Plus Jakarta Sans closely matches the reference's rounded sans-serif character. Name tracking, heavy tabular number weight, expiry weight, line height, and dark-teal ink are aligned. No wrapping or truncation occurs in the reference state.
- Spacing and layout rhythm: left alignment is 42 px; name, chip, number, and expiry follow the source's vertical rhythm. Number-group spacing was corrected after the first valid comparison. Radius and 550:333 proportions match.
- Colors and visual tokens: the pale-blue background, dark-teal text, white/silver chip, and red/orange mark visually match the supplied source. Contrast remains clear.
- Image quality and asset fidelity: the supplied reference was used to preserve the chip, Mastercard mark, curved artwork, and overall palette. The project asset is high-resolution and downsampled with high-quality filtering.
- Copy and content: default copy matches the source. Widget tests also confirm that cardholder name, last four digits, and expiry remain live when Stripe preview data changes.

## Findings

- No actionable P0, P1, or P2 differences remain.
- [P3] The cleaned high-resolution background is marginally softer than the small source screenshot in some pale-blue tonal areas. This does not change hierarchy, layout, branding, or readability.

## Comparison History

1. First valid comparison
   - Finding: [P2] Number groups were too tightly spaced and ended substantially earlier than the reference.
   - Fix: switched to single semantic spaces with explicit word spacing, increased the number size, and adjusted the row's vertical position; name tracking and expiry position were also tuned.
   - Post-fix evidence: `.dart_tool/goldens/add_card_preview_actual.png` at 550 × 333 shows group starts aligned within a few pixels of the source and matching overall row width.
2. Final comparison
   - Finding: no P0/P1/P2 mismatches. The remaining raster softness is classified as P3.
   - Result: passed.

## Implementation Checklist

- [x] Preserve the selected background artwork and card proportions.
- [x] Match name, number, and expiry placement and typography.
- [x] Preserve live preview data for name, last four digits, and expiry.
- [x] Verify the default reference state at identical pixel dimensions.

## Follow-up Polish

- Optional P3: replace the cleaned raster with an editable original source asset if the designer later provides one.

---

# Checkout Banner Design QA

final result: passed

## Comparison Target

- Source visual truth: `assets/images/checkout_banner_full_hd.png`
- Implementation capture: `test/goldens/checkout_banner.png`
- Source pixels: 1672 × 941
- Implementation pixels: 390 × 204
- CSS/logical viewport: 390 × 844 with a 362 × 204 banner slot after horizontal page padding
- Device pixel ratio: 1
- Density normalization: both artifacts were normalized to the same displayed height in `checkout-banner-qa-comparison-small.jpg`
- State: checkout screen with the banner visible at the top of the scrollable content

## Evidence

- Full-view comparison: the generated source and decoded Flutter render were inspected together. The complete headline, body copy, three benefit badges, character, confirmation elements, drink, fries, and takeaway bag remain visible without distortion or unintended cropping.
- Focused-region comparison: the banner itself is the focused region. Its text and food illustration remain readable at the tested 390 px mobile viewport.

## Required Fidelity Surfaces

- Fonts and typography: all typography is preserved inside the supplied raster artwork, preventing duplicate or drifting Flutter text layers.
- Spacing and layout rhythm: the banner keeps its 16:9 presentation, 14 px page margins, 22 px corner radius, and existing checkout shadow treatment.
- Colors and visual tokens: Hungry Spot red, white, charcoal, blush, green confirmation accents, and warm food tones match the selected artwork.
- Image quality and asset fidelity: the real high-resolution source asset is rendered with high-quality filtering and a density-aware cache width. No placeholder or code-drawn replacement is used.
- Copy and content: the complete “Almost there!”, supporting sentence, and Secure/Fast/Quality labels appear exactly once inside the image; the old coded copy and icons were removed.

## Findings

- No actionable P0, P1, or P2 differences remain.

## Comparison History

1. Initial capture
   - Finding: [P1] The image had not completed decoding before the golden capture, so the implementation evidence showed only the white container.
   - Fix: precached the exact `ImageProvider` and waited for the render to settle before capture.
   - Post-fix evidence: `test/goldens/checkout_banner.png` contains the complete decoded artwork at the mobile viewport.
2. Final comparison
   - Finding: no P0/P1/P2 mismatch between the selected source and rendered banner.
   - Result: passed.

## Implementation Checklist

- [x] Replace the split coded banner with the selected complete image.
- [x] Remove the previous banner heading, supporting copy, feature icons, and illustration asset.
- [x] Preserve responsive sizing, semantics, rounded clipping, and visual depth.
- [x] Verify decoded asset rendering at a 390 × 844 mobile viewport.
