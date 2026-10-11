# Hanzi Levels

A native, offline Chinese vocabulary browser for iPhone, built with SwiftUI.

Home displays five HSK level cards with bundled word/character counts and
three preview characters. Each level has searchable Words and Characters lists,
result counts, and an empty search state. The app uses a single typed
`NavigationStack` and the shared system appearance. It
does not request permissions, use the network, or require an account.

## Open and run

Requires **Xcode 15.3 or later** (Swift 5.10+) and an iOS simulator or iPhone
running **iOS 17 or later**. No package installation or project generation is
needed in a fresh checkout.

1. Open `HanziLevels.xcodeproj`.
2. Select the shared **HanziLevels** scheme and an iPhone simulator.
3. Run with **⌘R**. Run unit tests with **⌘U**.

For a physical iPhone, choose your development team under Signing &
Capabilities. Simulator builds do not need a development team.

The build setting `SWIFT_VERSION = 5.0` selects Swift 5 language mode;
the required compiler is Swift 5.10 or newer.

## Structure

```text
HanziLevels.xcodeproj/           Checked-in project and shared scheme
HanziLevels/
  App/                          App entry point, root stack, typed Route
  Data/                         Read-only offline library and search index
  Strokes/                      Native SVG geometry, cached preparation, playback and canvas
  Views/                        Home, Level, Word/Character details, Sources placeholder
    Components/                 Cards, rows, detail headings, stroke integration surface
  Resources/Assets.xcassets/     Adaptive AccentColor
HanziLevelsTests/                Unhosted library and browsing unit tests
scripts/                        Offline source check
```

`Route` uses `level(Int)`, `word(String)`, `character(String)`, `history`, and `sources`.
Word and character identifiers are hanzi. Destinations are registered once
in `RootView`; SwiftUI supplies the back button and swipe-back behavior.
Word detail shows tone-marked pinyin, meaning, HSK level, and a two-column grid
of distinct characters in reading order. Character cards open character detail,
which shows readings, meaning, stroke count, first HSK level, and all containing
words across levels. Each containing word opens its word detail. Missing items
and library failures show local unavailable states; loading shows a progress indicator.
`CharacterStrokeArea` loads cached native stroke geometry on a separate actor.
Its 270pt canvas shows a 米字格 guide, pale unplayed outlines, completed strokes,
and the accent-colored current stroke, revealed along its median and clipped to
its outline. Playback starts on appearance; Play/Pause preserves elapsed time,
Replay starts over, and Play after completion restarts. Each stroke takes
`220 + medianLength × 0.9` milliseconds with 140 milliseconds between strokes.
Navigation and backgrounding pause playback. Reduce Motion shows the complete
character; each Play tap highlights the next stroke, and Replay clears that
highlight. Playback failures stay within the card so metadata and search remain
available. Sources & Licenses remains
a placeholder. Recent is hidden while history is empty and otherwise shows the
five newest word/character visits. See All opens History with swipe-to-delete
and a confirmed Clear History action. One SwiftData model stores at most 50
unique visits on this device, refreshing the timestamp once per opened detail.
Returning from a pushed detail leaves visit order unchanged. Each detail attempts
the history write once, including failures; reopening it starts a new attempt.
History writes save immediately; failures show an alert and roll back the change.
Visits to items removed from a later dataset remain in Recent and History and
count toward their limits. These rows show that the item is no longer available
and have no navigation; they can be deleted from History or cleared with the rest.
The container explicitly disables CloudKit and app-group storage.
Each level remembers its last Words/Characters selection across launches using
`@AppStorage("levelMode.<n>")`, independently of other levels. Search text stays
in the current level while switching modes and resets when that screen is closed.

The bundled dataset is a small HSK sample, not the complete HSK vocabulary.
Home displays its version in the on-device content footnote. Loading and bundle
failure states do not trigger network access.

The UI uses system fonts and grouped backgrounds, supports Dynamic Type,
and follows the device's light/dark appearance. The accent asset is
`#B8432C` in light mode and `#FF7A5C` in dark mode.

## Verification

With Xcode installed, build independently of signing:

```sh
xcodebuild -project HanziLevels.xcodeproj -scheme HanziLevels \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

The static offline check also runs with Command Line Tools only:

```sh
python3 scripts/check_offline.py
```

The shared scheme's test action contains only the unhosted `HanziLevelsTests`
target. It does not build or launch the Hanzi Levels app for testing. Tests cover
library loading, content relationships, search normalization, lazy stroke decoding,
independent mode selections, unique detail characters, cross-level detail
relationships, missing detail identifiers, and content immutability while browsing.
Stroke tests cover all 1,640 bundled outlines across 213 characters, coordinate
flip/scale, SVG command and number parsing, median consistency, timing gaps,
pause/resume/replay, reduced-motion stepping, cached geometry, cancellation,
and playback failure isolation.

History tests cover timestamp upserts, word/character key uniqueness, newest-first
ordering and trimming, revisits at the limit, deletion, idempotent clearing,
and reopening a local disk store. Preference tests use an isolated defaults suite
to cover per-level keys, persistence, and fallback for unknown mode values.
The SwiftData tests require full Xcode; Command Line Tools alone do not provide
the SwiftData macro plugin.
The save-failure rollback path has no failure-injection test and remains untested.
Detail push/pop ordering and save-alert behavior require simulator verification.

There is no simulator CI workflow, app-launch automation, or UI-test target.
