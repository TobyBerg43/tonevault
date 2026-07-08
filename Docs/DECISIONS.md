# ToneVault — Design Decisions

Where the spec left room, here's what was chosen and why. Guiding rule: **the simplest version a gigging guitarist finds obviously correct.**

## Architecture
- **SwiftData, local-only.** `ModelConfiguration(cloudKitDatabase: .none)`. Models are written CloudKit-compatible anyway (every property has a default, every relationship is optional) so optional iCloud sync could be added later with no migration. Sync is deliberately **not** built.
- **No third-party dependencies.** StoreKit 2, SwiftData, PhotosUI, AVFoundation, PDFKit/UIKit rendering — all first-party.
- **XcodeGen `project.yml`** instead of a committed `.xcodeproj`, so the project is diffable and regenerates cleanly. The `.xcodeproj` is gitignored.

## Data model
- **`ControlValue` snapshots label + kind** at save time, so exports and old tones still read correctly even if you later rename a gear's controls.
- **Gear "custom labels" stored as JSON in a String** rather than a child entity — keeps the schema tiny and CloudKit-trivial for a handful of labels.
- **Setlist ordering** is an explicit `orderJSON` array of song UUIDs, because SwiftData relationships are unordered. `orderedSongs` reconciles the relationship with the saved order and appends any stragglers.
- **Knob value model is a single `Double`** interpreted by control kind: knob 0–10, slider 0–100, toggle 0/1, selector 0…n-1. One code path, easy to format and diff.

## The core interaction (drag knobs)
- **Vertical drag** maps to value (up = higher), ~180 pt for full travel, with **half-unit haptic detents**. This is the standard, precise audio-UI gesture — more reliable than angular dragging near the center. Angular dragging was rejected as fiddly.
- **Accessibility:** every control is an `.accessibilityElement` with an adjustable action (VoiceOver users can increment/decrement), and knobs expose their formatted value.
- **Draft-first editor:** the "New tone" editor inserts a real draft `ToneSetting` up front so knob drags bind to persisted `ControlValue`s immediately; Cancel deletes the draft. This avoids a parallel in-memory value model.

## Monetization
- **Free tier = 5 gear / 10 tones**, everything else usable, so the value is felt before paying. Gating happens at the *add* action, which routes to the paywall.
- **Backup, restore, and full JSON export are never gated** — this is the trust wedge, so it stays free even though it's the most "valuable" data feature. Only **PDF cheat-sheets** and **audio attachments** are Pro (nice-to-haves, not ownership).
- **DEBUG "Simulate Pro"** is `#if DEBUG` so it cannot ship in Release.

## Backup format
- **Single `.tonevault` JSON file with attachments embedded as base64.** Chosen over a zip archive because Foundation has no dependency-free zip that's pleasant to use, and a single self-contained file is the most portable "email it to yourself / restore on a new phone" story. Live app storage still keeps photos/audio as **files** (filenames referenced in SwiftData, never blobs) exactly as specified — only the *backup* inlines them.
- **Restore replaces** the current library (with a clear result summary) rather than merging, because merge semantics for hand-tuned knob settings are ambiguous and surprising. A gigging user restoring from backup wants their backup, verbatim.

## Copyright / trademark
- **No bundled brand database, no logos.** Only generic control templates (3-knob, amp head, graphic EQ, etc.). Gear names are user-entered. "Not affiliated…" line in About and in the PDF footer.

## Privacy / no domain
- Privacy policy text lives **in-app** (Settings → Privacy) and as `Docs/PRIVACY_POLICY.md` + `docs/privacy.html` for free hosting (GitHub Pages / Gist / rentry). Terms use **Apple's standard EULA** URL. See `SUBMISSION.md`.

## Open follow-ups (intentionally deferred)
- Optional iCloud sync (models are ready; capability intentionally off).
- Reordering controls within a template / fully custom templates (current templates cover the common cases).
- Localizations beyond English.
