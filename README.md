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
3. Run with **⌘R**. Run the UI smoke tests with **⌘U**.

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
HanziLevelsUITests/              Launch and navigation smoke tests
scripts/                        Offline source check and simulator CI
```

`Route` uses `level(Int)`, `word(String)`, `character(String)`, and `sources`.
Word and character identifiers are hanzi. Destinations are registered once
in `RootView`; SwiftUI supplies the back button and swipe-back behavior.
Word and character routes are ready for later content screens and have no
links from the empty library. Dataset loading, search, history, and stroke
playback belong to subsequent increments.

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

GitHub Actions builds and runs the UI smoke tests on an available iPhone
simulator, then captures the launch screen in light and dark appearance.
Download the `ios-shell-evidence` artifact for PNG attachments and `.xcresult`
bundles. To reproduce this workflow locally with Xcode 16 or newer:

```sh
bash scripts/ios_ci.sh
```

Xcode 16 is needed for this script's `xcresulttool export attachments` command;
the app and UI tests themselves support Xcode 15.3+.
