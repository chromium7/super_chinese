#!/bin/bash
set -euo pipefail

mkdir -p build
xcodebuild -version
python3 scripts/check_offline.py
xcrun simctl list devices available --json > build/simulators.json

SIMULATOR_ID=$(python3 - <<'PY'
import json
from pathlib import Path
import re

devices = json.loads(Path("build/simulators.json").read_text(encoding="utf-8"))["devices"]
runtimes = []
for runtime, entries in devices.items():
    match = re.search(r"\.iOS-(\d+(?:-\d+)*)$", runtime)
    if match:
        version = tuple(int(part) for part in match.group(1).split("-"))
        if version >= (17,):
            runtimes.append((version, entries))
for _, entries in sorted(runtimes, key=lambda entry: entry[0], reverse=True):
    for device in entries:
        if device.get("isAvailable") and device["name"].startswith("iPhone"):
            print(device["udid"])
            raise SystemExit(0)
raise SystemExit("No available iOS 17+ iPhone simulator. Install an iOS runtime in Xcode.")
PY
)

xcrun simctl bootstatus "$SIMULATOR_ID" -b
xcrun simctl status_bar "$SIMULATOR_ID" override --time '9:41' --batteryState charged --batteryLevel 100
xcrun simctl ui "$SIMULATOR_ID" appearance light

xcodebuild build \
  -project HanziLevels.xcodeproj -scheme HanziLevels -configuration Release \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO

xcodebuild test \
  -project HanziLevels.xcodeproj -scheme HanziLevels \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath build/DerivedData -resultBundlePath build/Light.xcresult \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO

xcrun simctl ui "$SIMULATOR_ID" appearance dark
xcodebuild test-without-building \
  -project HanziLevels.xcodeproj -scheme HanziLevels \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath build/DerivedData -resultBundlePath build/Dark.xcresult \
  -only-testing:HanziLevelsUITests/AppShellTests/testLaunchScreenshot \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO

xcrun xcresulttool export attachments --path build/Light.xcresult --output-path build/Screenshots/Light
xcrun xcresulttool export attachments --path build/Dark.xcresult --output-path build/Screenshots/Dark

python3 - <<'PY'
from pathlib import Path

for appearance in ("Light", "Dark"):
    directory = Path("build/Screenshots") / appearance
    if not any(directory.glob("*.png")):
        raise SystemExit(f"Missing {appearance.lower()} launch screenshot in {directory}")
print("Verified light and dark screenshot exports.")
PY
