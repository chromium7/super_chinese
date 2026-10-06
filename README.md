# Hanzi Levels

A native, offline Chinese vocabulary browser for iPhone, built with SwiftUI.

This first increment provides the app shell: five HSK level cards, a single
typed `NavigationStack`, placeholder level/word/character/source destinations,
and the shared system appearance. The app works with no bundled dataset. It
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
  Views/                        Home and placeholder destinations
    Components/                 Level cards and shared empty state
  Resources/Assets.xcassets/     Adaptive AccentColor
HanziLevelsTests/                Unhosted unit-test target for subsequent features
scripts/                        Offline source check
```

`Route` uses `level(Int)`, `word(String)`, `character(String)`, and `sources`.
Word and character identifiers are hanzi. Destinations are registered once
in `RootView`; SwiftUI supplies the back button and swipe-back behavior.
Word and character routes have individual SwiftUI previews and are ready for
later content screens, with no links from the empty library. Dataset loading,
search, history, and stroke playback belong to subsequent increments.

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
target. It does not build or launch the Hanzi Levels app for testing. The target
is intentionally scaffolded with no test cases until data and feature logic
land. Add those Swift files to the unit-test target when their tests are added.

There is no simulator CI workflow, app-launch automation, or UI-test target.
