# Accessibility and appearance verification

APE-196 builds on `master` at `26b12014513906454304aca3d401cbef6b60f56d`.
The app still targets iOS 17+, using Swift 5 language mode with Swift 5.10+.

## Implemented behavior

- Word character cards use an adaptive grid at standard text sizes and a
  single column at accessibility sizes. Character metadata stacks at those sizes.
  Readings and first-level information are each displayed once on character detail.
- Level preview text wraps and uses the system secondary color. Large-text
  level mode selection uses a menu with the same persisted Words/Characters value.
  Recent's heading and See All link can stack; See All has a 44pt minimum height.
- Playback controls stack at accessibility sizes and allow vertical wrapping.
  Their accessible status distinguishes playing, paused, complete, and highlighted
  strokes. User actions, completion, and Reduce Motion changes post announcements;
  animation frames do not post announcements. Canvas guides remain decorative.
- Word/character rows and cards identify the item kind, readings, and meaning.
  Native navigation controls retain their system traits and back behavior.
- Startup, unavailable detail, empty history, and empty/search-failure states
  are scrollable. Empty levels explain how to find content; a library error
  is not presented as an unsuccessful search. Clear History uses a labeled trash
  control and keeps its confirmation. Successful deletion/clear is announced.
- Startup recovery, unavailable strokes, and missing bundled documents announce
  their resulting states. Document Retry identifies the document it reloads.
  Bundled-content failures describe the need for corrected app content when
  reopening does not help. No network fallback was added.

System grouped backgrounds, primary/secondary text, adaptive accent colors,
Reduce Motion stepping, and Differentiate Without Color outlines remain in use.
History's per-instance recording guard, explicit saves/rollback, CloudKit-off
container, per-level preferences, and playback cancellation/pause are preserved.

## Checks performed on 2026-10-12

Environment: macOS arm64, Apple Swift 5.10, active developer directory
`/Library/Developer/CommandLineTools`; no Xcode app or `simctl` available.

Passed:

```sh
python3 scripts/check_offline.py
plutil -lint HanziLevels.xcodeproj/project.pbxproj
swiftc -frontend -parse HanziLevels/Views/*.swift \
  HanziLevels/Views/Components/*.swift HanziLevels/App/*.swift \
  HanziLevels/Strokes/*.swift
git diff --check
```

35 standalone Swift cases passed with zero failed assertions. A temporary harness
compiled the existing Library, Browsing, Detail, Stroke, and SourceDocument cases
and their production dependencies using `swiftc -parse-as-library`. Copies replaced
XCTest imports/assertions with a small assertion shim and resolved resources from
the checkout. It ran real data, geometry, search, playback, cancellation, mode
preferences, and document loading logic. The two added `StrokeTests` cases cover
spoken pause/resume/completion/replay status and reduced-motion reset/empty data.
This harness is not XCTest, an iOS build, or a persistence/UI test. It excluded
the seven SwiftData history tests.

Unavailable checks:

```sh
xcodebuild -version
swift test --package-path build/APE-196-checks
xcrun simctl io booted screenshot build/APE-196-after.png
```

These respectively reported that full Xcode is required, XCTest is unavailable,
and `simctl` cannot be found. Syntax parsing does not type-check SwiftUI APIs.
No iOS build/XCTest success or screenshot evidence is claimed. The owner's
unit-test-only automation preference is preserved: no UI-test target or app-launch
CI was added, and CI was not watched.

## Pending manual verification and screenshot set

Use Xcode 15.3+ with iOS 17+ on the compact supported iPhone (375pt width),
a typical 393pt layout, and a 430pt layout. Include landscape and the largest
accessibility text size. Perform interaction checks with VoiceOver on a device
when possible. Capture matching before/after images from the base revision and
this branch; prior screenshots do not establish the new layouts.

| Screen/state | Evidence to collect |
| --- | --- |
| Home and Recent | Light/dark, default/largest text; level previews and See All reachable |
| Level | Large-text menu, both modes, search/clear, no results, empty level; row navigation and result count spoken |
| Word detail | Long word/definition and large-text single-column cards; no required text clipped |
| Character detail | Stacked metadata; Play/Pause/Replay reachable; status and completion announced |
| Reduce Motion | Completed character initially; one highlight per Play; Replay clears it; toggling never starts animation |
| History | Long rows, labeled Clear History, cancel/confirm, VoiceOver delete, empty state and save failure |
| Sources | Largest text, expanded notices and full licenses, isolated missing document and retry |
| Startup/local errors | Small landscape viewport; descriptions and retry reachable; no network fallback |

Fresh-install airplane-mode checks remain pending: open all screens, search,
play/pause/replay, navigate away during playback, background the app, then relaunch
to verify history and per-level preferences. Verify the per-instance history guard
when returning from a pushed detail. SwiftData rollback and save-alert interaction
also remain unverified. APE-197 should verify this change's exact revision alongside
its final QA work once integrated or on an explicit dependent branch.

Release remains blocked by the unresolved level-list permission/replacement
decision and upstream definition/stroke provenance recorded in bundled source
notes. UI hardening does not resolve those facts or authorize release.
