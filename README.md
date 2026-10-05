# Hanzi Levels

A native, offline Chinese vocabulary browser for iPhone, built with SwiftUI.

The app shell provides five HSK level cards, a single
typed `NavigationStack`, placeholder level/word/character/source destinations,
and the shared system appearance. A validated development sample is now bundled;
the placeholder screens will be connected to it in subsequent increments. It
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
  Resources/Data/               Manifest, sample vocabulary, characters, strokes, licenses
  Data/BundledDataFiles.swift    Local resource integrity reader
DataSources/                    Immutable sample inputs and SHA-256 lock
HanziLevelsTests/                Unhosted unit tests with a copied Data folder
scripts/                        Offline conversion and verification
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
target. It does not build or launch the Hanzi Levels app for testing. Resource
tests use `Bundle(for:)`; production loading defaults to `Bundle.main`.

Verify/reproduce the content with Python 3 and Command Line Tools:

```sh
python3 scripts/prepare_data.py --check
python3 scripts/test_prepare_data.py
python3 scripts/check_bundle_loading.py
python3 scripts/prepare_data.py --check --report build/resource-verification.html
```

The Swift probe compiles the production reader into a temporary macOS app bundle,
loads its resources through `Bundle.main` with networking denied by `sandbox-exec`,
and checks six damaged fixtures.
It is useful with Command Line Tools, but does not replace an iOS simulator build.
The Xcode project copies `Resources/Data` as a folder reference into both app and
test bundles, preserving `Licenses/`. The reader throws on missing resources,
unknown schema, invalid manifest metadata, or SHA-256 mismatch; a later Library
will decode/index these verified bytes in a background task and show errors.

**Release blocked:** `2026.10.0-sample` contains 131 words and 213 characters.
The level list lacks written redistribution permission or an approved replacement;
upstream definition/stroke revisions were not supplied. The precise attachments
are pinned for reproducible development. All three source attributions and full
Arphic / Creative Commons license texts are bundled. CC-CEDICT currently names
CC BY-SA 3.0, so the 4.0 text requested in the brief is included as reference only.
See `Resources/Data/Licenses/SOURCES.md` and `DataSources/README.md` for details.
`python3 scripts/prepare_data.py --check --require-release-approved` intentionally
fails until a reviewed permission/provenance decision and schema update are made.

There is no simulator CI workflow, app-launch automation, or UI-test target.
