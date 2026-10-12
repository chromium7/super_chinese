# Local release QA gate

Use this checklist on the exact integrated revision intended for release.
Supported baseline: **Xcode 15.3+ / Swift 5.10+ / iOS 17+**, Swift 5 language
mode, iPhone only, no third-party dependencies. The documented minimum is a
project requirement, not a claim that every newer Xcode/iOS combination has
been tested. Record the actual Xcode, SDK, device and iOS versions below.

Automation remains unit-test only. The shared scheme's Test action runs the
unhosted `HanziLevelsTests` target with no app dependency. The separate build
command checks app compilation without launching it. Fresh-install interaction
is a manual check; there is no app-launch CI or UI-test target.

## Automated checks

From the repository root, record the revision and working tree first:

```sh
git rev-parse HEAD
git status --short
xcode-select -p
swift --version
python3 scripts/verify_local.py --standalone
```

The standalone macOS gate works with Command Line Tools. It reads the production
and unit source lists from the checked-in Xcode project, verifies app source
membership and inclusion of every test file, parses Swift syntax, scans offline
APIs/packages, checks all six manifest SHA-256 entries, then compiles the existing
non-SwiftData test bodies and their production dependencies with `swiftc`.
Temporary copies replace XCTest assertions with `StandaloneAssertions.swift`
and point resources at the checkout. No app source or bundled content is rewritten.
Each case and every skipped SwiftData case is printed; any failed assertion,
unexpected thrown error, invalid checksum, compile failure or static violation
returns nonzero. New unsupported test signatures or setup/teardown fail discovery.
This restricted adapter is **not XCTest**, does not validate packaged iOS
resources, and does not type-check the SwiftUI screens.

On a machine with full Xcode, select the desired Xcode using its normal developer
directory configuration, obtain an installed simulator UUID, and run:

```sh
xcodebuild -version
xcrun simctl list devices available
python3 scripts/verify_local.py --ios \
  --destination 'platform=iOS Simulator,id=<installed-simulator-UUID>'
```

The iOS mode repeats the static checks and requires both commands to pass:

```sh
xcodebuild -project HanziLevels.xcodeproj -scheme HanziLevels \
  -destination 'platform=iOS Simulator,id=<installed-simulator-UUID>' \
  -derivedDataPath build/DerivedData \
  -resultBundlePath build/UnitTests-<unique-run-ID>.xcresult \
  CODE_SIGNING_ALLOWED=NO test
xcodebuild -project HanziLevels.xcodeproj -scheme HanziLevels \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Use a new result bundle name for each run. Inspect and retain the `.xcresult`.
The runner stops at the first failing command and never watches external CI.
The source scan is a conservative API gate, not proof against arbitrary custom
networking code. Review new data loaders for file-only URL guards. Physical
device airplane-mode verification below is still required.

| Area | Required cases | Current execution |
| --- | --- | --- |
| Data | Every word character has Hanzi and StrokeSet; all counts match; unique per-level characters preserve first appearance; firstLevel and bidirectional detail relationships | Standalone passed |
| Pinyin/search | `nǚ'ér`, `xuésheng`, apostrophes, combining marks, ü/v; HSK 1 `xue sheng`, `xuesheng`, `student`; Hanzi/English/reading prefix, level scope and no results | Standalone passed |
| Strokes | All 1,640 outlines/213 characters produce non-empty geometry and usable medians; SVG M/L/Q/C/Z, malformed input, transform, timing, cache, cancellation | Standalone passed |
| Playback | Pause/resume/replay/end restart, reduced-motion stepping, status text and local failure isolation | Standalone passed; UI interaction pending |
| Sources | Full local notices/licenses, rejected remote URLs, isolated missing/invalid/empty files and retry | Standalone passed |
| Preferences | Independent per-level modes, recreation, unknown-value fallback | Standalone passed; app relaunch pending |
| History | Upsert, distinct word/character keys, newest-first, 50-entry trim, revisit, selected deletion, idempotent clear, disk reopen | Seven XCTest cases unrun |
| Rollback | Failed insert restores trimmed history; failed revisit restores timestamp/order; failed delete/clear restores entries; fresh context sees committed state; successful retry | Three XCTest cases unrun |
| Offline | Reject URLSession/URLRequest and legacy equivalents, WebKit, networking/CloudKit imports, package dependencies; verify project membership and manifest checksums | Static passed; device offline run pending |

## Fresh-install airplane-mode smoke flow

Run on a physical iPhone with iOS 17+ and repeat the layout checks on a compact
375pt simulator and a typical/larger iPhone. Simulator disconnection alone does
not establish physical airplane mode. Delete only this app from the QA device,
install the candidate build through Xcode, stop it before its first launch,
enable airplane mode, explicitly disable Wi-Fi and cellular, then launch manually.
Record device/OS/build, expected versus actual results, and evidence for failures.

- [ ] First launch opens Home without an account, permission prompt, download or
  crash. Five HSK cards show bundled counts/previews and dataset version. Recent
  is hidden before any detail visits.
- [ ] Open each HSK level and switch Words/Characters. Counts and first-appearance
  character ordering agree with the bundled content. Search clears correctly;
  `xue sheng`, `xuesheng`, `xuésheng`, and `student` find 学生 in HSK 1. Check
  Hanzi, uppercase English, ü/v reading equivalence and a no-result query.
- [ ] Open 学生 Word detail, inspect pinyin/meaning/level and unique character
  cards; open 学 Character detail and follow an Appears in word back to detail.
  Back/swipe-back reaches Level and Home without changing visit order merely
  because an already-open detail reappears.
- [ ] Strokes start automatically. Pause freezes progress, Play resumes, Replay
  restarts, completion shows the full character, and Play after completion
  restarts. Navigate away while playing and background/foreground the app;
  playback pauses and never keeps an orphan animation running.
- [ ] Enable Reduce Motion: the complete character appears immediately, each
  Play tap highlights one stroke, Replay clears the highlight, and toggling
  Reduce Motion does not unexpectedly start animation.
- [ ] Recent shows the five newest visits. See All opens History, repeated visits
  update one key, word/character keys stay separate, and more than 50 distinct
  visits retain only the newest 50. Swipe-delete removes only the chosen entry.
  Clear History cancellation retains entries; confirmation removes all and the
  empty view is understandable. Home hides Recent again.
- [ ] Before clearing, terminate/relaunch while still offline: history and each
  level's selected mode persist independently; search text is not persisted.
  After clearing, terminate/relaunch again: cleared history remains empty.
- [ ] Sources & Licenses shows all three source roles and full local license
  texts/source notes. Scroll to the end of each expanded document. Notices
  retain the permission and provenance blockers.
- [ ] Repeat Home, both Level modes, Word/Character details, playback, History,
  Sources and empty search/history in light and dark mode. Include landscape
  and the largest accessibility text size: required text and controls remain
  reachable. Use VoiceOver to navigate, read readings/meanings and operate
  playback/delete/clear/retry; state changes are announced without per-frame noise.
- [ ] Inspect loading/startup error, unavailable detail/strokes and document
  retry states using a separate local QA fixture with a missing/malformed bundle
  file (never alter the release dataset). Errors stay readable and local; intact
  documents/details still work where designed. Injected save failures are covered
  by unit tests; visible save-alert behavior still needs a debug QA session.
- [ ] Capture screenshots of representative Home/Level/details/History/Sources
  states, including dark mode and largest text, plus a playback recording.
  Keep APE-196 before/after evidence tied to that branch's revision. Attach files
  to the issue/PR; do not treat screenshots as interaction or persistence proof.

## Recorded verification: 2026-10-12

Integration baseline: `master` at `26b12014513906454304aca3d401cbef6b60f56d`
plus APE-196 commit `3e4e82ff20268b50763414b11ab2d68f0a6c762b` on explicit
dependent branch `chore/APE-197-offline-qa`. APE-196 is awaiting review; this QA
branch preserves its committed screens. Review APE-197 against
`fix/APE-196-accessibility-appearance` so only its verification changes appear.
If APE-196 changes before merge, rerun this gate on the new integrated revision.

Environment: macOS arm64; Apple Swift 5.10 (`swiftlang-5.10.0.13`),
Python 3.14; active developer directory `/Library/Developer/CommandLineTools`.
No full Xcode app, iOS SDK or `simctl` is available. Actual Xcode/iOS runtime
versions tested: **none**.

Performed commands: `python3 scripts/verify_local.py --standalone` (35 cases,
zero failed assertions, all static checks and six checksums passed),
`xcodebuild -version`, and `xcrun simctl list devices available`.
The latter two fail because full Xcode and `simctl` are unavailable.
The gate prints the exact revision, dirty tree, expanded compiler commands and
case names; final commit and log are recorded in the issue delivery.

All ten SwiftData XCTest cases, the complete iOS XCTest action, iOS app build,
packaged-resource verification, simulator/device screenshots, fresh install,
relaunch, save alerts, VoiceOver, Dynamic Type, appearance and Reduce Motion
interaction remain **unverified**. No visible QA result is claimed; screenshots
are not applicable to these tests/docs changes. APE-196's visual evidence remains
pending as documented in `accessibility-verification.md`.

## Ship blockers and sign-off

Bundled source notes still record **no written level-list redistribution
permission or approved replacement**, and **no pinned original upstream
definition/stroke revisions**. Keep the simplified static data and existing
license texts. Passing any technical gate does not resolve these blockers.
This issue does not authorize release or App Store submission.

- [ ] Full iOS unit suite and app build passed at recorded revision.
- [ ] Manual checklist completed with device/OS and evidence recorded.
- [ ] APE-196 and final QA changes reviewed and integrated; gate rerun if changed.
- [ ] Permission/replacement decision and upstream provenance resolved by owner.
- [ ] Human release acceptance recorded separately.
