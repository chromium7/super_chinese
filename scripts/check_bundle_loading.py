"""Compile the production Swift reader and verify local Bundle.main loading."""

from pathlib import Path
import plistlib
import shutil
import subprocess

root = Path(__file__).resolve().parent.parent
app = root / "build/ResourceBundleProbe.app"
resources = app / "Contents/Resources"
executable = app / "Contents/MacOS/ResourceBundleProbe"
resources.mkdir(parents=True, exist_ok=True)
executable.parent.mkdir(parents=True, exist_ok=True)
shutil.copytree(root / "HanziLevels/Resources/Data", resources / "Data", dirs_exist_ok=True)
with (app / "Contents/Info.plist").open("wb") as file:
    plistlib.dump({"CFBundleIdentifier": "com.chromium7.ResourceBundleProbe",
                  "CFBundleName": "ResourceBundleProbe", "CFBundlePackageType": "APPL",
                  "CFBundleExecutable": "ResourceBundleProbe"}, file)
subprocess.run(["swiftc", "-swift-version", "5", "-warnings-as-errors",
                str(root / "HanziLevels/Data/BundledDataFiles.swift"),
                str(root / "scripts/ResourceBundleProbe.swift"), "-o", str(executable)], check=True)
# Deny socket/network operations while using the actual production reader.
subprocess.run(["sandbox-exec", "-p", "(version 1) (allow default) (deny network*)",
                str(executable)], check=True)
