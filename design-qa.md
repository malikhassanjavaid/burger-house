# Phone Verification Design QA

## Evidence

- Phone-entry source visual truth: `.dart_tool/design_refs/phone_verification_reference.png`
- Phone-entry implementation: `.dart_tool/design_refs/phone_entry.png`
- OTP source visual truth: `.dart_tool/design_refs/otp_verification_reference.png`
- OTP implementation: `.dart_tool/design_refs/otp_entry.png`
- OTP full-card comparison: `.dart_tool/design_refs/otp_verification_comparison.jpg`
- OTP focused comparison: `.dart_tool/design_refs/otp_verification_focused_comparison.jpg`
- Flutter viewport: 390 x 844 logical pixels at device pixel ratio 1.0
- OTP source image: 1083 x 1453 pixels
- OTP source card crop: 1003 x 1367 pixels, normalized to 370 x 504 pixels
- OTP implementation capture: 390 x 844 pixels
- OTP implementation card crop: 370 x 506 pixels
- Density normalization: source and implementation card crops were compared at the same 370-pixel width
- OTP state: empty six-digit input, first cell focused, resend countdown active, change-number action enabled

## Findings

No actionable P0, P1, or P2 differences remain.

- Fonts and typography: Plus Jakarta Sans reproduces the source hierarchy for the title, two-line delivery message, action labels, countdown, and Cancel. Final title, body, and control placement align within a few pixels after normalization.
- Spacing and layout rhythm: the 370 x 506 implementation card is two pixels taller than the normalized 370 x 504 source. Artwork, title, code cells, Verify action, resend panel, and Cancel follow the same vertical order and rhythm. All six visible OTP cells now have equal decorated widths and separate seven-pixel gaps.
- Colors and visual tokens: Hungry Spot red `#F23846`, blush surfaces, gray borders, white card, and dark overlay preserve the approved brand mapping. The source's slight button gradient remains intentionally represented by the existing solid Hungry Spot red.
- Image quality and asset fidelity: OTP uses a dedicated transparent raster illustration with the required red phone, shield/check badge, pale circular glow, orbit rings, and security accents. It is sharp at the rendered size and has no visible background seam.
- Copy and content: `Enter verification code`, the masked phone number, `Verify`, countdown, `Change number`, and `Cancel` match the supplied design and remain dynamic where appropriate.
- Interaction and responsiveness: six-digit paste, automatic verification, resend timing, change number, cancellation, screen-reader live status, keyboard-safe scrolling, and 200% text scaling remain covered by widget tests.

## Comparison History

### Phone-entry passes

- Earlier P2 findings: the first phone-entry implementation was too tall and dense; privacy copy wrapped excessively and actions were oversized.
- Fixes: compacted type, artwork slot, fields, privacy notice, action height, and bottom spacing while preserving compact-height scrolling.
- Post-fix evidence: `.dart_tool/design_refs/verification_focused_comparison.jpg`.

### OTP pass 1

- Finding: P2 - the initial OTP replica was 370 x 523 pixels after normalization, with oversized title/body spacing, Verify action, resend panel, and Cancel label.
- Fix: reduced OTP-only typography, gaps, action and panel heights, then redistributed bottom padding without changing phone-entry styling.
- Post-fix evidence: the next implementation card matched the source height at 370 x 504 pixels.

### OTP pass 2

- Finding: P2 - controls were approximately 14 pixels wider than the source, inactive cells lacked the faint gray fill, and secondary action labels were visually heavy.
- Fix: matched the source's 39-pixel horizontal inset, added the gray cell surface, reduced border/icon/label weight, and matched the compact secondary panel.
- Post-fix evidence: `.dart_tool/design_refs/otp_verification_comparison.jpg`.

### OTP pass 3

- Finding: P2 - focused comparison showed the first decorated code cell was seven pixels wider because later cells consumed their gaps inside expanded slots.
- Fix: moved all seven-pixel gaps outside the expanded cells and added a regression assertion that measures each visible decorated surface.
- Post-fix evidence: `.dart_tool/design_refs/otp_verification_focused_comparison.jpg` shows six equal-width code cells.

### Final pass

- Finding: no actionable P0, P1, or P2 differences.
- Evidence: the final full-card and focused comparison artifacts listed above.

## Focused Comparison

A focused comparison was required because artwork detail, code-cell geometry, action icon sizing, countdown treatment, and secondary typography were too small to judge reliably in the full-card view. The focused artifact compares both the artwork/title region and the complete interactive control region at enlarged scale.

## Open Questions

- None.

## Implementation Checklist

- [x] OTP artwork matches the phone-and-shield reference
- [x] Masked number appears on its own emphasized line
- [x] Six code cells are equal width with the first focused in red
- [x] Verify uses the reference-centered shield action treatment
- [x] Resend countdown and change-number controls share the tinted panel
- [x] Cancel matches the compact reference typography
- [x] Existing verification interactions and accessibility remain functional
- [x] Final full-card and focused comparisons have no actionable P0/P1/P2 findings

## Phone Field Alignment Correction

### Evidence

- User-reported source: `.dart_tool/design_refs/phone_field_alignment_reference.jpg` (720 x 1604 pixels)
- Updated implementation: `.dart_tool/design_refs/phone_entry.png` (390 x 844 pixels at device pixel ratio 1.0)
- Focused comparison: `.dart_tool/design_refs/phone_field_alignment_comparison.jpg`
- Comparison normalization: the source and implementation input-row crops are both 584 x 138 pixels in the focused comparison
- State: United States selected, national phone number filled, phone field focused

### Finding and Fix History

- Finding: P2 - the country selector rendered at 56 logical pixels while the unconstrained phone field rendered at 48 logical pixels. The fixed 116-pixel selector also left too little room for the phone number.
- Root cause: `countryHeight` constrained only the selector `SizedBox`; the sibling `TextFormField` kept its intrinsic decoration height.
- Fix: added an optional phone-field height and configurable row gap to the shared input, then set the verification row to equal 52-pixel heights, a 104-pixel country selector, an 8-pixel gap, and the remaining width for the phone field. Flag, phone icon, type, radius, and following gap were compacted proportionally.
- Follow-up finding: P2 - the first regression measured the 52-pixel `TextFormField` wrapper, while Flutter still painted its `InputDecorator` container at the 48-pixel intrinsic prefix-icon height. This left four unused pixels beneath the visible outline and reproduced the mismatch the user reported.
- Follow-up fix: removed the unnecessary empty counter slot and set the phone prefix-icon constraints to a 52-pixel minimum height. Flutter now paints the outline itself at 52 pixels instead of only enlarging its wrapper.
- Regression evidence: `test/phone_verification_sheet_test.dart` now uses `InputDecorator.containerOf` to measure the actual painted input container at a 390 x 844 viewport. It requires both visible surfaces to be 52 pixels high and the phone input to remain at least 1.65 times wider than the country selector.
- Post-fix visual evidence: `.dart_tool/design_refs/phone_field_alignment_comparison.jpg` shows aligned top and bottom border pixels with a visibly wider number field. Pixel inspection measured both focused phone and country outlines from y=504 through y=555, exactly 52 pixels.

### Fidelity Surfaces

- Fonts and typography: country code and number remain readable without clipping; the slightly reduced scale supports the compact row.
- Spacing and layout rhythm: both fields are 52 pixels tall, share matching 14-pixel radii, and use an 8-pixel gap.
- Colors and visual tokens: existing white surfaces, gray borders, and Hungry Spot-red focus/accent colors are unchanged.
- Image quality and asset fidelity: the platform flag remains a native country-picker glyph; no replacement asset or placeholder was introduced.
- Copy and content: phone number, dialing code, privacy copy, and actions are unchanged.

No actionable P0, P1, or P2 differences remain for the phone-field alignment request.

## Follow-up Polish

- P3: the generated OTP illustration uses slightly stronger Hungry Spot-red saturation than the softer source render; this keeps it consistent with the app's approved brand red.

## New-Account Welcome and First-Order Offer

### Evidence

- Source visual truth: `.dart_tool/design_refs/new_account_welcome_reference.png`
- Rendered implementation: `.dart_tool/design_refs/new_account_welcome_implementation.png`
- Final combined comparison: `.dart_tool/design_refs/new_account_welcome_comparison_final.png`
- Flutter viewport: 390 x 844 logical pixels at device pixel ratio 1.0
- Source card: 421 x 498 pixels
- Implementation capture: 390 x 844 pixels; visible card crop 362 x 430 pixels, including antialiased edge pixels around the nominal 360-pixel card
- Density normalization: the implementation crop was scaled proportionally to 421 x 500 pixels, preserving its aspect ratio rather than stretching it to the source height
- State: newly registered customer `Hassan Ali`, welcome dialog open before the first-order offer

### Findings

No actionable P0, P1, or P2 differences remain.

- Fonts and typography: Plus Jakarta Sans matches the title and body hierarchy; the first name uses the approved Hungry Spot red and the body follows the source's exact three-line wrapping. The italic Plus Jakarta treatment for `Enjoy!` is a P3 approximation of the source's handwritten display face.
- Spacing and layout rhythm: the normalized implementation is two pixels taller than the 421 x 498 source. Handle, artwork, title, three-line body, CTA, dividers, and footer align in the same vertical sequence; horizontal CTA insets and height match within a few pixels.
- Colors and visual tokens: white, blush, dark text, muted gray, and Hungry Spot red use the existing app tokens. The source's subtle CTA gradient is intentionally represented by the app's existing solid red, as requested.
- Image quality and asset fidelity: the production Hungry Spot raster logo is reused at native quality with a matching blush halo. Decorative accents and the arrow use the closest Material icon-library glyphs; no placeholder, handcrafted SVG, or fake asset was introduced.
- Copy and content: `Welcome, Hassan!`, the account-ready description, `Start Ordering`, and `Enjoy!` match the supplied reference. The first name remains dynamic.
- Behavior and accessibility: `Start Ordering` dismisses the welcome card before the 10% offer. The offer is shown on each fresh home entry only when a live Firestore server query confirms empty order history, is hidden after any order exists, and fails closed when history cannot be checked. Startup and notification entry use one guarded path, preventing stacked dialogs. The card remains scroll-usable at 200% text scale, and CTA/close targets meet the 44-pixel mobile minimum.

### Comparison History

- Pass 1 finding: P2 - the description wrapped to two lines instead of three, the title/body block sat too low, and the CTA was wider and taller than the source.
- Pass 1 fix: reduced the artwork slot, constrained and reference-wrapped the description, matched the card's horizontal inset, and corrected CTA height and radius.
- Pass 1 evidence: `.dart_tool/design_refs/new_account_welcome_comparison_pass1.png`.
- Pass 2 finding: P2 - the logo/halo was slightly underscaled and the final word grouping differed from the source.
- Pass 2 fix: increased the real logo and halo modestly and matched the source copy line breaks exactly.
- Post-fix evidence: `.dart_tool/design_refs/new_account_welcome_comparison_final.png` shows a 421 x 500 proportional implementation beside the 421 x 498 source with no actionable P0/P1/P2 drift.
- Post-review recapture: adding the bounded scroll behavior and adaptive CTA for large text preserved the same 362 x 430 visible card crop and 421 x 500 proportional comparison size.

### Focused Comparison

A separate focused crop was not needed: the final combined artifact presents both complete cards at the same 421-pixel width, where the logo, typography, spacing, decorative icons, CTA, and footer remain clearly legible.

### Implementation Checklist

- [x] Welcome card appears only after successful new-account entry
- [x] First name is dynamic and styled in brand red
- [x] Existing Hungry Spot logo asset is reused
- [x] CTA dismisses the welcome before opening the offer
- [x] 10% offer eligibility is based on persistent zero-order history
- [x] Existing-order and lookup-error states suppress the offer
- [x] Live server lookup and notification re-entry share the guarded eligibility path
- [x] Compact-height rendering remains usable at 200% text scale
- [x] Final full-card comparison has no actionable P0/P1/P2 findings

### Follow-up Polish

- P3: a future bundled handwritten font could reproduce the source's `Enjoy!` lettering more exactly; the current italic brand font is stable, readable, and consistent with the app.

## Keyboard-Open Compact Verification Dialogs

### Evidence

- Source visual truth: `.dart_tool/design_refs/keyboard-open-otp-source.jpg`
- OTP keyboard-open implementation: `.dart_tool/design_refs/keyboard-open-otp-implementation.png`
- Secure-account keyboard-open implementation: `.dart_tool/design_refs/keyboard-open-phone-implementation.png`
- Normal secure-account source: `.dart_tool/design_refs/phone_verification_reference.png`
- Normal OTP source: `.dart_tool/design_refs/otp_verification_reference.png`
- State-matched comparison: `.dart_tool/design_refs/keyboard-open-otp-comparison.png`
- Flutter viewport: 390 x 844 logical pixels at device pixel ratio 1.0
- Simulated keyboard inset: 300 logical pixels; visible app region ends at y=544
- Source screenshot: 720 x 1604 pixels
- OTP implementation: 390 x 844 pixels
- Secure-account implementation: 390 x 844 pixels
- Comparison normalization: the source app region above the keyboard was cropped to 720 x 1000 and normalized proportionally to 390 x 542; the implementation app region was cropped to 390 x 544 at 1x density.
- OTP state: code `742918` entered, verification loading, resend countdown active, and change-number disabled in both source and implementation.
- Secure-account state: empty focused phone input with the keyboard open.

### Findings

No actionable P0, P1, or P2 differences remain.

- Fonts and typography: Plus Jakarta Sans, weight hierarchy, red emphasis, masked-number treatment, and action labels remain consistent with the approved dialogs. Keyboard-open type scales down only enough to preserve legibility and fit; keyboard-closed sizes remain exactly 24/20-pixel headings and their existing body styles.
- Spacing and layout rhythm: the oversized source keeps the card close to the viewport edges and risks top clipping when the OS applies focus scrolling. The compact implementation reduces artwork, section gaps, input/control heights, and bottom padding as one coordinated state, leaving the complete rounded card visible within the 544-pixel app region. No element overlaps the keyboard.
- Colors and visual tokens: white card, dark overlay, Hungry Spot red, blush artwork halo, gray inactive cells, and tinted resend/privacy panels are unchanged between normal and compact modes.
- Image quality and asset fidelity: both dialogs continue to use their existing transparent raster security illustrations. The compact 72-pixel slots remain sharp, centered, and free of seams or clipping.
- Copy and content: all app-specific copy, masked phone data, OTP digits, countdown, privacy message, and cancellation/change-number actions are preserved.
- Icons and controls: Material icon-library glyphs remain optically centered. OTP cells, Verify, resend panel, country selector, phone field, Continue, and Cancel all remain visible and usable above the keyboard.
- Responsiveness and accessibility: widget geometry tests verify every required control is inside the visible app region at 390 x 844 with a 300-pixel keyboard inset. Existing 320 x 640 / 200% text-scale coverage still provides scroll fallback without exceptions or lost live-region semantics.

### Comparison History

- Initial finding: P1 - keyboard focus reduced the available height while the dialogs retained their full normal-state geometry. The scroll view then moved the focused input into view and could push the artwork/card top out of the viewport.
- Root cause: the layout subtracted the keyboard inset from its maximum height but retained a hard 280-pixel minimum and did not adapt any internal dimensions.
- Fix: added a keyboard-presence branch that removes the unsafe minimum, uses the actual visible height, and proportionally compacts artwork, typography, gaps, fields, buttons, privacy notice, OTP cells, and secondary panel. The keyboard-closed branch preserves every original dimension.
- Post-fix evidence: `.dart_tool/design_refs/keyboard-open-otp-comparison.png` shows the matching filled-code/loading state with the entire implementation card and Cancel action visible above the keyboard boundary.
- Secure-account evidence: `.dart_tool/design_refs/keyboard-open-phone-implementation.png` shows the full country/phone row, privacy notice, privacy link, Continue action, and Cancel action inside the visible region.
- Review finding: P2 - the first compact pass made Verify, resend/change-number, privacy-details, and Cancel targets 30–42 logical pixels high.
- Review fix: retained the compact visual treatment while restoring every interactive target to at least 44 logical pixels; the bordered resend panel remains 46 pixels high so its internal buttons have a true 44-pixel hit region.
- Post-review evidence: the final implementation screenshots and regenerated state-matched comparison listed above show that the additional hit area does not reintroduce clipping or hide any control.

### Focused Comparison

A separate focused crop was not required because the normalized comparison already isolates the complete above-keyboard app region at 390 pixels wide. Artwork, typography, six code cells, loading action, resend panel, and Cancel remain readable at that scale.

### Implementation Checklist

- [x] Keyboard detection uses the real bottom view inset
- [x] Both verification dialogs compact only while the keyboard is visible
- [x] Entire card and all persistent controls remain above the keyboard
- [x] Secure-account country and phone fields stay equal height
- [x] OTP cells remain equal width and height
- [x] Every compact-mode interactive target is at least 44 logical pixels high
- [x] Normal keyboard-closed artwork, fields, actions, and panels retain their original dimensions
- [x] Scroll fallback remains available for small screens and large text
- [x] State-matched visual comparison has no actionable P0/P1/P2 findings

### Open Questions

- None.

## Ticket-Style New-Account Welcome Card

### Evidence

- Selected source visual truth: `.dart_tool/design_refs/new-account-ticket-reference.png`
- Rendered implementation: `.dart_tool/design_refs/new-account-ticket-implementation-full.png`
- Normalized card comparison: `.dart_tool/design_refs/new-account-ticket-comparison.png`
- Flutter viewport: 390 x 844 logical pixels at device pixel ratio 1.0
- Source image: 1086 x 1448 pixels; card crop 828 x 1136 pixels
- Source normalization: card crop scaled proportionally to 360 x 494 pixels
- Implementation card: 360 x 500 logical pixels
- State: newly registered customer `Hassan Ali`, welcome dialog open over the home screen

### Findings

No actionable P0, P1, or P2 differences remain.

- Fonts and typography: Plus Jakarta Sans reproduces the heavy two-line welcome hierarchy, dynamic red first name, muted multiline body copy, and centered CTA label. Title and body positions align closely after width normalization.
- Spacing and layout rhythm: the narrow stitched rail, overlapping logo seal, left-aligned content column, bottom CTA, and lower-right dot motif follow the source proportions. The implementation is six pixels taller than the normalized source, a non-actionable difference that preserves rounded-corner and tap-target geometry.
- Colors and visual tokens: the implementation uses the existing Hungry Spot red, warm off-white surface, yellow logo/accent color, dark text, and muted gray copy. No new competing palette was introduced.
- Image quality and asset fidelity: the production Hungry Spot logo is reused in the seal and low-opacity rail watermark. The celebratory burst and dot motif use the closest Material icon-library glyphs; no screenshot, placeholder, handcrafted SVG, or fake logo was embedded in the UI.
- Ticket geometry: the top and bottom notches are part of the responsive clip path, the rail seam is dashed, and the CTA spans from just inside the rail to the source-aligned right inset.
- Copy and behavior: the first name remains dynamic, `Start Ordering` dismisses the welcome card, and the existing zero-order-history eligibility and first-order offer sequencing are unchanged.
- Responsiveness and accessibility: dimensions are derived from the post-inset SafeArea constraints, capped at exactly 360 x 500 logical pixels, and scale down on smaller screens. A 320 x 480 viewport with 40-pixel top and 28-pixel bottom padding keeps the full card inside the safe area. At 200% text scale the body remains scroll-accessible and the pinned 56-pixel CTA remains hit-testable and dismisses the dialog.

### Comparison History

- Pass 1 finding: P2 - the initial replacement was 360 x 560 pixels, with an oversized rail, narrow CTA, and no ticket notches or stitched seam.
- Pass 1 fix: reduced the card to the source-proportional 500-pixel height, narrowed the rail, widened the CTA, added dashed stitching, increased the title/body scale, and introduced responsive ticket notches.
- Pass 2 finding: P1 - widening the CTA inside the intrinsic scroll column created an unbounded-height layout and placed its hit target outside the card.
- Pass 2 fix: simplified the scrollable content column and pinned the 56-pixel CTA within the card while preserving bottom scroll padding for large text.
- Review finding: P1 - the first responsive calculation used the full MediaQuery height before SafeArea applied system padding, so an unusually short padded viewport could exceed the available height.
- Review fix: moved the card measurements into a LayoutBuilder inside SafeArea and added exact reference-geometry, 200% interaction, and short padded-viewport regression coverage.
- Final evidence: `.dart_tool/design_refs/new-account-ticket-comparison.png` shows the complete source and implementation at the same 360-pixel width with no actionable P0/P1/P2 drift.

### Implementation Checklist

- [x] Previous welcome card is replaced by the selected ticket design
- [x] Existing logo asset is reused in a circular overlapping seal
- [x] Red rail includes ticket notches, stitching, and a subtle watermark
- [x] Dynamic customer name is emphasized in brand red
- [x] CTA is fully tappable and remains inside the card
- [x] Existing first-order eligibility and sequencing remain intact
- [x] 200% text scaling remains usable without layout exceptions
- [x] Short padded viewports constrain the card inside the real SafeArea
- [x] Final normalized comparison has no actionable P0/P1/P2 findings

### Follow-up Polish

- P3: the Material celebration glyph is more compact than the source's hand-drawn yellow burst, but it preserves the same placement, color, and visual role while following the app's icon system.

## Selected First-Order Offer Ticket

### Evidence

- Selected source visual truth: `.dart_tool/design_refs/first-order-offer-selected.png`
- Connected-device implementation: `.dart_tool/design_refs/first-order-offer-device.png`
- Native card crop: `.dart_tool/design_refs/first-order-offer-device-card.png`
- Final normalized comparison: `.dart_tool/design_refs/first-order-offer-comparison-final.jpg`
- Device: NIC LX2 at 720 x 1600 physical pixels
- Comparison normalization: source and implementation card crops were scaled proportionally to the same 900-pixel height
- State: authenticated zero-order customer, first-order offer open over the live home screen

### Findings

No actionable P0, P1, or P2 differences remain.

- Fonts and typography: the Material typography context restores Plus Jakarta Sans throughout the ticket. `FIRST ORDER`, the large `10%`, red `OFF`, detail hierarchy, coupon code, and CTA follow the selected source without fallback-font decoration or clipping.
- Spacing and layout rhythm: the gold hero, notched seam, white details section, centered coupon, and narrowed pill CTA match the source proportions. The final measured pass aligns the detail title, coupon, and CTA within a few normalized pixels.
- Colors and visual tokens: the card uses the existing Hungry Spot red, brand yellow/gold, warm white, dark ink, and muted gray. The dimmed and blurred live home screen matches the selected modal treatment.
- Image quality and asset fidelity: the existing Hungry Spot logo is reused in the circular seal. A dedicated transparent raster burger-and-red-fries asset was generated for the selected hero and remains crisp with no visible matte or seam on the gold background. It is delivery-optimized to 768 x 588 / 695 KB and decoded at a 512-pixel cache width.
- Ticket geometry: rounded corners, symmetric seam notches, gold dashed divider, dashed coupon border, circular close action, and red pill CTA all reproduce the selected card structure.
- Copy and behavior: `Your first bite is on us`, `BURGER10`, and `START ORDERING` match the source. Close and Start Ordering both dismiss the modal, while the existing zero-order-history eligibility and fresh-entry behavior remain unchanged.
- Responsiveness and accessibility: the ticket scales proportionally inside the post-SafeArea constraints and stays usable at 320 x 480 with system padding. Independent interaction overlays preserve at least 44 logical pixels after visual scaling, global transformed bounds are asserted in tests, and a 200% user text scale is retained through an accessibility-safe 1.2x cap rather than disabled.

### Comparison History

- Pass 1 finding: P1 - the first native capture inherited Flutter's fallback overlay text style because the custom physical shape lacked a Material typography ancestor. This produced monospaced text and yellow debug-style underlines.
- Pass 1 fix: restored a transparent Material context around the ticket, returning all text to Plus Jakarta Sans and removing every fallback decoration.
- Pass 2 finding: P2 - the generated food composition was too large and covered the final `F` in `OFF`; the coupon and CTA were also wider than the selected source.
- Pass 2 fix: resized and moved the transparent food asset, then measured and narrowed the coupon and CTA against the normalized reference.
- Pass 3 finding: P1 - narrower controls exposed differing headless-test font metrics and could overflow even though the device render fit.
- Pass 3 fix: positioned the detail surfaces deterministically and used scale-down wrappers only inside bounded text rows. Device proportions remain unchanged while all short-viewport and headless tests pass.
- Accessibility review finding: P1 - the first proportional implementation scaled its interaction renderers with the artwork, so the declared 44-pixel close target measured 41.17 pixels globally at 360 x 640 and approximately 36 pixels at 320 x 480. It also replaced the user's text scaler with no scaling.
- Accessibility review fix: moved close and CTA interaction layers outside the decorative FittedBox, asserted their transformed global bounds at both viewports, retained user scaling through a 1.2x cap, and added a 200% text-scale interaction regression. Independent re-review found no remaining critical or important issues.
- Final evidence: `.dart_tool/design_refs/first-order-offer-comparison-final.jpg` shows the selected source and live connected-device result together with no actionable P0/P1/P2 drift.

### Implementation Checklist

- [x] Previous first-order card is removed
- [x] Selected gold-and-white ticket design is applied
- [x] Real Hungry Spot logo asset appears in the circular seal
- [x] Dedicated transparent burger and red-fries raster asset is used
- [x] `10% OFF`, first-order copy, and `BURGER10` match the source
- [x] Close and Start Ordering controls dismiss the modal
- [x] Existing zero-order eligibility logic remains unchanged
- [x] Short SafeArea viewport remains fully usable
- [x] Final device comparison has no actionable P0/P1/P2 findings

final result: passed
