# Hanzi Levels

A native, offline Chinese vocabulary browser for iPhone, built with SwiftUI.

Home displays five HSK level cards with bundled word/character counts and
three preview characters. Each level has searchable Words and Characters lists,
result counts, and an empty search state. The app uses a single typed
`NavigationStack` and the shared system appearance. It
does not request permissions, use the network, or require an account.

## Open and run

Requires **Xcode 16 or later** (Swift 5.10+ source compatibility) and an iOS simulator or iPhone
running **iOS 17 or later**. No package installation or project generation is
needed in a fresh checkout.

1. Open `HanziLevels.xcodeproj`.
2. Select the shared **HanziLevels** scheme and an iPhone simulator.
3. Run with **⌘R**. Run unit tests with **⌘U**.

For a physical iPhone, choose your development team under Signing &
Capabilities for both **HanziLevels** and **HanziLevelsWidget**. Register/enable
the **group.com.chromium7.HanziLevels** App Group for both targets with that team.
Simulator builds do not need a development team.

The build setting `SWIFT_VERSION = 5.0` selects Swift 5 language mode;
the required compiler is Swift 5.10 or newer.

## Structure

```text
HanziLevels.xcodeproj/          Checked-in project and shared scheme
HanziLevels/
  HanziLevelsApp.swift          App entry point and service setup
  ContentView.swift            Root navigation and destination construction
  Screens/                     Screens organized by feature
    Home/                      HSK levels and recent visits
    Levels/                    Word/character browsing and search
    Words/                     Word details
    Characters/                Character details
    History/                   Recent visit management
    Sources/                   Sources and license documents
  ViewModels/                  Observable screen state and loading/search logic
  Components/                  Reusable cards, rows, and document views
    Strokes/                   Stroke canvas and playback controls
  Core/                        Shared application services and domain types
    Browsing/                  Persistent level-mode keys and display modes
    History/                   SwiftData history model and storage
    Library/                   Offline content models, decoding, and search
    Navigation/                Typed routes
    Sources/                   Attribution models and local document loading
    Strokes/                   SVG geometry, caching, timeline, and player
    Widget/                    Shared preferences, catalog, rotation, and URLs
  Assets.xcassets/              Adaptive AccentColor
  Resources/Data/              Bundled vocabulary, strokes, and license texts
HanziLevelsWidget/             Small and medium WidgetKit extension
HanziLevelsTests/              Unhosted library and screen-state unit tests
scripts/                       Offline source check
```

The layout uses feature folders under `Screens`,
reusable SwiftUI elements under `Components`, shared services under `Core`, and
observable screen state under `ViewModels`. `ContentView` constructs the level
and sources view models with their dependencies. SwiftUI presentation state,
accessibility announcements, and `@AppStorage` bindings stay in the views.

The app, widget, and test folders use Xcode's synchronized folders, so their
navigator hierarchy follows the files on disk. Adding a screen, component, or
test inside its target folder normally needs no `project.pbxproj` change.
Files used by more than one target still have explicit membership: the unhosted
tests compile selected core/view-model sources directly, and the widget compiles
its shared catalog/model sources. Add explicit membership when introducing a
new dependency used by those targets. `Resources/Data` remains an explicit folder
resource in all three targets to preserve `Data/Licenses` and existing bundle
URLs. The app and widget `Info.plist` and entitlement files are excluded from
automatic resource discovery.

`Route` uses `level(Int)`, `word(String)`, `character(String)`, `history`, and `sources`.
Word and character identifiers are hanzi. Destinations are registered once
in `ContentView`; SwiftUI supplies the back button and swipe-back behavior.
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
available. Sources & Licenses shows the three bundled data sources, their roles
and license names, and expandable full Arphic Public License and CC BY-SA 3.0
Unported texts. Source notes open expanded and retain the unresolved level-list
permission/replacement decision and missing upstream revisions. Documents load
locally off the main actor; unreadable files show an error and retry without
hiding the remaining documents. Recent is hidden while history is empty and otherwise shows the
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

## Home Screen widget

Choose **Current HSK level** on Home (HSK 1 by default). This is a study preference
independent of which level you browse; opening another level or a widget detail
does not change it. Add **Hanzi Levels → HSK Character** from the iPhone widget
gallery in small or medium size. Both sizes show hanzi, tone-marked pinyin, and a
meaning that truncates to fit; VoiceOver reads the full meaning. Tapping opens
the displayed character's details, including when the app starts cold. The
pending link waits for library loading and history recovery. Missing character
IDs use the existing unavailable-detail screen. Invalid URLs are ignored.

Characters come from the selected level's word membership, matching the app's
Characters list. Rotation is deterministic in eight-hour slots anchored to the
Unix epoch (00:00, 08:00, and 16:00 UTC), so all widgets agree and timezone/DST
changes do not reset it. A week of entries is supplied ahead of time, followed
by a request for the next timeline. Each boundary advances to another character
when the pool has more than one. Changing the study level requests a widget
reload. iOS controls when it renders entries and services reload requests, so
exact display timing cannot be guaranteed; see Apple's
[Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).

The extension reads its own bundled word/character data without decoding
strokes, network access, or access to browsing history. Only the study-level
preference is shared through the App Group. Unreadable or inconsistent data
shows a local unavailable state and requests another timeline in an hour.

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
and playback failure isolation. Source document tests cover complete, unmodified
bundled text, retained release blockers, refusal of remote directories, isolated
missing/invalid/empty documents, and retry after files become readable.

History tests cover timestamp upserts, word/character key uniqueness, newest-first
ordering and trimming, revisits at the limit, deletion, idempotent clearing,
and reopening a local disk store. Preference tests use an isolated defaults suite
to cover per-level keys, persistence, and fallback for unknown mode values.
The SwiftData tests require full Xcode; Command Line Tools alone do not provide
the SwiftData macro plugin.
The save-failure rollback path has no failure-injection test and remains untested.
Detail push/pop ordering and save-alert behavior require simulator verification.

`ViewModelTests` covers level-scoped search, query lifetime, document retries,
and cancellation preserving loaded documents.

`WidgetTests` covers exact rotation boundaries, three changes per 24 hours,
week-long timelines, empty/single-item pools, per-level catalog membership,
bad content, detail URL validation, and study-level persistence/fallback.
With full Xcode, build the app scheme above (which embeds the extension), then
run the unit tests. Verify small/medium widgets in light/dark appearance and
large text, level changes, and warm/cold detail links on a simulator or device.
The `iOS` GitHub Actions workflow builds the app and embedded widget, then runs
the unhosted unit tests on an available iPhone simulator. Local Command Line
Tools alone cannot build the iOS targets or run XCTest. There is no app-launch
automation or UI-test target; visual and interaction checks remain manual.
