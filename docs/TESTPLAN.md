# ToneVault — Test Plan

Manual + unit coverage for the flows most likely to break or get rejected. Unit tests live in `ToneVaultTests/`. Everything below is runnable on an iOS 17 simulator; StoreKit uses the bundled `Configuration/ToneVault.storekit`.

## A. Drag-knob save / recall (the core interaction)
1. Add gear "Test Drive", template **3-Knob**.
2. New tone → name "Verse" → drag Drive to ~3.5, Tone to ~6, Level to ~7 → Save.
3. Reopen the tone. **Expect** the knobs render at the saved positions and the value labels match.
4. Toggle Settings → Knob display to **Clock positions**. **Expect** the same tone now shows clock values (e.g. "9 o'clock") without changing stored data.
5. Graphic EQ: add gear template **EQ 10**, set a few faders, save, recall. **Expect** faders restore and the board scrolls horizontally.
6. Selector: template **Rotary Switch**, tap to advance positions, save, recall. **Expect** the saved position is restored.

## B. Clone / tweak
1. On a saved tone → menu → **Clone & tweak**. **Expect** a "<name> copy" appears with identical control values and its own independent edits.
2. Edit the clone's knobs; **expect** the original is unchanged.

## C. Songs — full-rig recall
1. Create song "Test Song". Add 2–3 tones from different gear via the picker.
2. Open the song. **Expect** each tone shows gear name, tone name, and a one-line control summary.
3. Remove one tone (swipe). **Expect** it leaves the song but the tone itself still exists under its gear.

## D. Setlists — gig / stage view
1. Create setlist, add several songs, use **Reorder** to change order. **Expect** order persists after leaving and returning.
2. Tap a song → **Stage View**. **Expect** large, high-contrast text; every gear's controls listed with big values.
3. Delete a song from the setlist. **Expect** it's removed from the setlist only, still present under Songs.

## E. Paywall / free-tier gating
1. Fresh install (free). Add gear up to **5**; the 6th "Add gear" **routes to the paywall**.
2. Add tones up to **10**; the 11th add **routes to the paywall**.
3. Paywall shows: **$5.99**, "not a subscription", the four unlock bullets, **Terms** + **Privacy** links (both open), and **Restore Purchases**.
4. Purchase in the StoreKit test environment. **Expect** paywall dismisses, gating lifts, Settings shows "ToneVault Pro — unlocked".
5. Audio attach + PDF export: locked (show Pro lock) before purchase, available after.

## F. Restore + backup round trip (new-phone scenario)
1. With Pro + several gear/tones/songs/setlists and at least one photo and one audio clip: Settings → **Back up everything** → save the `.tonevault` file to Files.
2. Delete the app (or run **Restore from backup** after wiping data).
3. Reinstall / relaunch, Settings → **Restore from backup** → pick the file.
4. **Expect** the result alert reports the correct counts; all gear/tones/songs/setlists return; photos and the audio clip play back; setlist order is preserved.
5. Verify **backup/restore worked while offline / in Airplane Mode**.

## G. StoreKit restore
1. After a purchase, delete + reinstall. Settings → **Restore Purchases**. **Expect** Pro is restored via `AppStore.sync()` + `currentEntitlements`.
2. On an Apple ID with no purchase, Restore **Expect** the "no previous purchase found" message (not a crash).

## H. Permission-denied paths (must not block the app)
1. Deny **Photos**: attaching a photo simply does nothing harmful; rest of app works.
2. Deny **Microphone**: the recorder screen shows the "microphone is off" message and a Settings hint; no crash; saving a tone without audio works.
3. Run the entire A–F happy path with **all permissions denied**. **Expect** full functionality minus the optional attachments.

## I. Offline guarantee
1. Enable Airplane Mode. Exercise A–D and backup/restore. **Expect** everything works (only App Store purchase/restore needs network).

## J. Release-config sanity
1. Build in **Release**. **Expect** the "Simulate Pro" toggle is absent from Settings (compiled out).
2. No placeholder text, no dead buttons, no "beta"/"coming soon" strings.

## Automated unit tests (`ToneVaultTests`)
- `testKnobClockFormatting` — 0/5/10 map to sane clock strings.
- `testControlValueFormatting` — knob/slider/toggle/selector format correctly.
- `testSyncControlValuesSeedsDefaults` — a new tone gets one value per template control at defaults.
- `testTemplateChangeKeepsAndSeeds` — switching templates keeps overlapping controls, seeds new, drops orphans.
- `testCloneIsIndependent` — cloning duplicates values and edits don't leak back.
- `testBackupRoundTrip` — export → wipe → import restores identical gear/tone/song/setlist graph and control values.
- `testSetlistOrdering` — explicit order round-trips and reconciles added songs.
- `testFreeTierGating` — gear/setting limits enforced for non-Pro, unlimited for Pro.

Run: `⌘U` in Xcode, or
```bash
xcodebuild test -scheme ToneVault -destination 'platform=iOS Simulator,name=iPhone 15'
```
