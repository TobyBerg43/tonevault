# ToneVault 1.1.0

## App Store "What's New" text (paste-ready)

```
Stage mode, rebuilt for real gigs:
• True blackout view — huge type and high-contrast amber values you can read from your amp in a dark venue
• Swipe between songs in your setlist without leaving the stage view
• The screen never auto-locks while stage mode is open

Also new:
• Share any tone as a clean image card — send your settings to a bandmate in one tap (free)
• Search your library — find gear, tones, and songs instantly
• A welcome tour with a live draggable knob, plus an optional example pedal so you can try everything immediately
• Polished paywall, launch screen, and dozens of small refinements

As always: 100% offline, no account, no subscription. Backup and export stay free.
```

## Detailed changes

### Stage mode (the headline)
- New full-screen `StageView`: pure black background, forced dark scheme, 42pt song titles, 30pt amber values readable from meters away.
- Swipe (or use chevron buttons) to page through every song in the setlist; title shows "3 of 12".
- `isIdleTimerDisabled` while on stage — the screen never locks mid-gig; restored on exit.
- Song performance notes now appear on the stage page.
- "Start stage mode" button on every setlist; a single-song stage view is available from each song's menu.

### Sharing (growth lever)
- "Share as image" on every tone: renders a dark, branded card (mini knob dials, fader bars, values) via ImageRenderer and opens the system share sheet. Free for everyone.

### First-run experience
- Welcome screen with a live, draggable demo knob and the app's pitch in four bullets.
- Optional one-tap "Start with an example pedal" seeds a generic 3-knob pedal with two saved tones (clearly labeled, deletable, no brand names).

### Search
- Library: search gear and tones (name, gear, notes — case/diacritic-insensitive).
- Songs: search by title or artist.

### Fixes and polish
- Fixed all SwiftData unit tests crashing on iOS 18+/26 runtimes (ModelContext no longer retains its ModelContainer).
- Launch screen now uses a proper background color (white/black following system appearance) instead of an unset value.
- Paywall benefits rewritten benefit-led with detail lines.
- Tests target now generates its Info.plist (fixes test signing under Xcode 26).

### Versioning
- MARKETING_VERSION 1.1.0, CURRENT_PROJECT_VERSION 2.

### Test status
- 11 unit tests, all passing (7 original + sample-content, search, and share-card rendering).
