# Checkout Visual Refresh Design

## Goal

Refresh the Hungry Spot checkout screen so it feels cohesive with the app's red-led brand, improves the top banner and iconography, and remains easy to scan on mobile. All checkout behavior, validation, navigation, payment handling, and order placement must remain unchanged.

## Visual Direction

Use a warm, brand-first palette built from Hungry Spot red, deep charcoal, white, and soft blush. Red identifies interactive elements and brand emphasis. Green is reserved for confirmed or successful states; unrelated blue and purple section accents are removed. The page background becomes subtly warm so white surfaces have clear separation without heavy shadows.

## Header and Hero

- Retain the existing back action and `Checkout` title, with cleaner spacing and a lighter button treatment.
- Recompose the existing checkout food image as the visual focus of a taller, responsive hero.
- Use a red-to-deep-red backdrop with a controlled dark overlay behind text to guarantee contrast.
- Replace the small split-card copy with a larger `Ready to order?` heading, concise review guidance, and one compact secure-checkout badge.
- Keep the image decorative in accessibility semantics while exposing the banner message as readable text.

## Checkout Sections

- Present location, phone, and payment as a consistent family of white cards using the same radius, border, padding, icon tile, action treatment, and trailing affordance.
- Use red/blush icon tiles throughout instead of green, blue, and purple category colors.
- Strengthen the title/subtitle hierarchy and keep all important labels readable without changing their meaning.
- Keep existing bottom sheets, validation messages, selected values, and tap targets wired exactly as they are.
- Use green only for genuine success or confirmation indicators.

## Bottom Order Bar

- Preserve item count, total, tax copy, loading state, and place-order action.
- Simplify the surface styling and align it with the same rounded-card language.
- Retain a strong Hungry Spot red primary button with a clear forward/confirmation icon.

## Responsive and Accessibility Requirements

- Support the screen's existing mobile layouts without overflow at narrow widths or larger text settings.
- Maintain at least 44 logical-pixel interactive targets.
- Preserve semantic labels and visible validation feedback.
- Ensure text and icons have sufficient contrast against their surfaces.

## Scope Boundaries

- Modify checkout presentation only, primarily `lib/features/home/screens/checkout_screen.dart`.
- Reuse existing bundled imagery; do not introduce a network dependency.
- Do not alter data models, Firebase calls, Stripe behavior, form rules, navigation, or order totals.
- Do not refactor unrelated screens or overwrite the user's unrelated local changes.

## Verification

- Format the edited Dart source.
- Run Flutter static analysis without fetching new packages.
- Run relevant existing checkout/order tests and the broader test suite when practical.
- Inspect the rendered checkout screen at a representative mobile viewport and check for overflow, contrast, hierarchy, and tap-target consistency.
