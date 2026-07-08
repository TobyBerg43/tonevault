# ToneVault — App Store Submission Guide

Everything you need to take this repo from source to a submitted build. Paste-ready values are in `code blocks`. Cowork can't submit for you, so this is a checklist you run once.

---

## 0. Prerequisites (one-time)

- A Mac with **Xcode 15.3+** (iOS 17 SDK).
- A paid **Apple Developer Program** membership ($99/yr).
- **XcodeGen** (the repo ships a `project.yml`, not an `.xcodeproj`):
  ```bash
  brew install xcodegen
  ```

## 1. Generate the Xcode project

From the repo root:
```bash
xcodegen generate
open ToneVault.xcodeproj
```
Re-run `xcodegen generate` any time you add/rename source files. (The generated `.xcodeproj` is gitignored on purpose — `project.yml` is the source of truth.)

## 2. Set your signing identity

Two values are placeholders and must be set to yours:

1. In `project.yml` → `settings.base.DEVELOPMENT_TEAM`: paste your 10-character **Team ID** (Apple Developer → Membership).
2. Bundle identifier is `com.yourorg.tonevault`. To change it, edit `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` **and** the product IDs below, then re-run `xcodegen generate`.

Then in Xcode: select the **ToneVault** target → Signing & Capabilities → check **Automatically manage signing** → pick your team. Do the same for the **ToneVaultTests** target.

> Do **not** add the iCloud/CloudKit capability. This ship is pure-local by design. The models are already CloudKit-compatible if you choose to add sync in a later version.

## 3. In-App Purchase — create it and attach it to the SAME version

The app sells exactly one product:

| Field | Value |
|---|---|
| Reference name | `ToneVault Pro` |
| Product ID | `com.yourorg.tonevault.pro` |
| Type | **Non-Consumable** |
| Price | **$5.99** (Tier 6 / equivalent) |

Steps in **App Store Connect**:
1. My Apps → (create the app record if you haven't) → **Features → In-App Purchases → +**.
2. Create the non-consumable with the exact **Product ID** above. If you changed the bundle ID, change this to match (`<your-bundle-id>.pro`) **and** update `EntitlementManager.productID` + `Configuration/ToneVault.storekit`.
3. Add a localized display name + description, a screenshot of the paywall (required for review), and set the price to $5.99.
4. **Critical:** when you create the app version for review, **add this IAP to that version's submission** (In-App Purchases section on the version page). A first IAP that is *not* attached to a version is the #1 cause of "your in-app purchase was rejected / not submitted." Submit the build and the IAP **together**.

**Local testing before upload:** the scheme already points at `Configuration/ToneVault.storekit`, so the paywall, purchase, and restore all work in the Simulator with no sandbox account. To test the *real* sandbox flow, create a Sandbox Apple ID in App Store Connect → Users and Access → Sandbox.

## 4. Privacy — "Data Not Collected"

ToneVault collects nothing, so in App Store Connect → your app → **App Privacy**:
- Answer **"No, we do not collect data from this app."** → App Privacy shows **Data Not Collected**.
- A `PrivacyInfo.xcprivacy` manifest is already bundled (`Configuration/PrivacyInfo.xcprivacy`) declaring:
  - Tracking = false, no tracking domains, no collected data types.
  - Required-Reason APIs: **UserDefaults** (`CA92.1`), **File timestamp** (`C617.1`), **Disk space** (`E174.1`). These cover the display-preference storage and local file writes. If you add other APIs later, update this manifest or you'll get an automated email after upload.

## 5. Privacy Policy URL — free hosting, no domain

App Store Connect **requires** a reachable Privacy Policy URL. You don't own a domain, and you don't need one. The exact same text is already shown in-app (**Settings → Privacy**), so hosting is only to satisfy the URL field. The text to host is `Docs/PRIVACY_POLICY.md` (and a ready-made `Docs/privacy.html`).

Pick **one** of these free options:

### Option A — GitHub Pages (recommended, gives a clean URL)
1. This repo is already on GitHub (see README). In the repo, add the file `docs/privacy.html` (already provided at `Docs/privacy.html` — copy it to a top-level `/docs` folder, or keep `/docs` as the Pages source).
2. GitHub → repo **Settings → Pages** → Source: **Deploy from a branch** → Branch: `main`, Folder: `/docs` → Save.
3. Wait ~1 minute. Your URL will be:
   ```
   https://<your-github-username>.github.io/tonevault/privacy.html
   ```
4. Open it in a browser to confirm it loads, then **paste that URL** into App Store Connect → App Information → **Privacy Policy URL**, and into `LegalLinks.privacyPolicy` in `PaywallView.swift` (replace the `example.com` placeholder), then re-archive.

### Option B — Public GitHub Gist
1. Go to https://gist.github.com → new **public** gist → filename `tonevault-privacy.md` → paste the contents of `Docs/PRIVACY_POLICY.md` → **Create public gist**.
2. Use the gist's page URL (e.g. `https://gist.github.com/<user>/<id>`) as the Privacy Policy URL. It renders the Markdown and is publicly reachable.

### Option C — Free pastebin-style page (no account needed)
1. Go to https://rentry.co (or https://telegra.ph). Paste the `PRIVACY_POLICY.md` text, publish.
2. Copy the resulting public URL and use it as the Privacy Policy URL.

> Whichever you pick: **open the final URL in a private/incognito window** to confirm it resolves publicly before pasting it into App Store Connect. Then update `LegalLinks.privacyPolicy` in the code so the paywall's link points to the same place.

## 6. Export compliance

Already handled in `Configuration/Info.plist`:
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```
This makes App Store Connect skip the export-compliance questionnaire on every upload.

## 7. Build, archive, upload

1. In Xcode: set the run destination to **Any iOS Device (arm64)**.
2. Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `project.yml` if resubmitting; re-run `xcodegen generate`.
3. **Product → Archive**.
4. In the Organizer: **Distribute App → App Store Connect → Upload**.
5. In App Store Connect, attach the build to your version, attach the **IAP** to the version (step 3.4), fill metadata + screenshots, and **Submit for Review**.

## 8. Screenshots

Provided ready-to-upload in `Marketing/screenshots/` at **1290 × 2796** (iPhone 6.7"/6.9" — the required primary size). Regenerate any time with:
```bash
cd Marketing && python3 make_screenshots.py
```

| # | File | Message |
|---|---|---|
| 1 | `01_library.png` | Every tone, instantly recalled |
| 2 | `02_knobs.png` | Drag the knobs — no camera scanning |
| 3 | `03_song.png` | Your whole rig for a song |
| 4 | `04_stage.png` | Stage-ready in dark venues |
| 5 | `05_data.png` | No account, no cloud, own your data |
| 6 | `06_pro.png` | One-time $5.99, no subscription |

**Required sizes in App Store Connect:** you must supply **6.7"/6.9"** (1290×2796 — provided). iPad screenshots are only required if you keep iPad support advertised; the app supports iPad, so either add 12.9" iPad shots (2048×2732) or, to skip them, set `TARGETED_DEVICE_FAMILY` to `1` (iPhone only) in `project.yml`. Apple auto-scales the 6.7" set down to smaller iPhone sizes, so you don't need the 6.5"/5.5" sets.

## 9. Metadata — copy/paste

See `ASO.md` for the full name/subtitle/keywords set (generic terms only, no trademarks). App name `ToneVault`, EULA = Apple standard (already linked in-app and below).

- **Terms of Use (EULA):** use Apple's standard EULA — no custom text needed:
  `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
  (Already linked from the paywall and Settings.)

## 10. Known rejection triggers — pre-flight checklist

- [ ] IAP created as **Non-Consumable**, product ID matches `EntitlementManager.productID`, and **attached to the version** being submitted.
- [ ] Paywall shows **price**, **what unlocks**, that it's **not a subscription**, and has tappable **Terms** + **Privacy** links (all in-binary — see `PaywallView`).
- [ ] **Restore Purchases** present on the paywall **and** in Settings (both call `AppStore.sync()`).
- [ ] Privacy Policy URL **resolves publicly** (step 5) and matches `LegalLinks.privacyPolicy`.
- [ ] App Privacy set to **Data Not Collected**; `PrivacyInfo.xcprivacy` bundled.
- [ ] `ITSAppUsesNonExemptEncryption = false`.
- [ ] App runs fully with **camera, photos, and microphone permissions denied** (all attachment features degrade gracefully — see `AudioRecorderView`, `GearEditorView`).
- [ ] No placeholder/lorem content, no dead buttons, no "beta"/"coming soon" language.
- [ ] The **DEBUG "Simulate Pro"** toggle is compiled out of Release (`#if DEBUG`) — verify it does **not** appear in an App Store build.
- [ ] No manufacturer trademarks/logos in name, icon, screenshots, or keywords. "Not affiliated…" line present in About.
- [ ] Free tier is genuinely usable (5 gear / 10 tones) and **backup/export is never gated**.
