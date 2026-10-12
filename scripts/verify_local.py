"""Repeatable local verification; standalone results do not certify an iOS app run."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
import uuid

ROOT = Path(__file__).resolve().parent.parent
PROJECT = ROOT / "HanziLevels.xcodeproj/project.pbxproj"


def run(*arguments):
    print("+ " + shlex.join(list(map(str, arguments))), flush=True)
    subprocess.run(list(map(str, arguments)), cwd=ROOT, check=True)


def record_revision(allow_dirty):
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    status = subprocess.check_output(
        ["git", "status", "--porcelain", "--untracked-files=all"], cwd=ROOT, text=True)
    print("Revision: " + revision + (" DIRTY" if status else " CLEAN"), flush=True)
    if status:
        print(status, end="", flush=True)
        if not allow_dirty:
            raise ValueError("Working tree is dirty; commit changes or explicitly use --allow-dirty")
        print("WARNING: --allow-dirty tests local changes, not the recorded commit alone.", flush=True)


def target_sources():
    project = json.loads(subprocess.check_output(
        ["plutil", "-convert", "json", "-o", "-", str(PROJECT)]))
    objects = project["objects"]
    paths = {}

    def visit(identifier, parent):
        obj = objects[identifier]
        source_tree = obj.get("sourceTree", "<group>")
        if source_tree == "SOURCE_ROOT":
            parent = ROOT
        elif source_tree != "<group>":
            # Product/SDK refs are irrelevant here; fail if a Sources phase needs one.
            return
        path = parent / obj.get("path", "")
        if obj["isa"] == "PBXGroup":
            for child in obj["children"]:
                visit(child, path)
        elif obj["isa"] == "PBXFileReference":
            paths[identifier] = path

    visit(objects[project["rootObject"]]["mainGroup"], ROOT)
    targets = {}
    for obj in objects.values():
        if obj["isa"] != "PBXNativeTarget":
            continue
        sources = []
        for phase_id in obj["buildPhases"]:
            phase = objects[phase_id]
            if phase["isa"] == "PBXSourcesBuildPhase":
                for build in phase["files"]:
                    reference = objects[build]["fileRef"]
                    if reference not in paths:
                        raise ValueError(f"Unresolved source reference {reference} in target {obj['name']}; "
                                         "unsupported group or sourceTree")
                    sources.append(paths[reference])
        targets[obj["name"]] = sources
    return targets


def static_checks(sources):
    run(sys.executable, "scripts/check_offline.py")
    run("plutil", "-lint", PROJECT)
    # Prevent a source from silently dropping out of either target's verification.
    expected = set((ROOT / "HanziLevels").rglob("*.swift"))
    if set(sources["HanziLevels"]) != expected:
        raise ValueError("App target source membership differs from HanziLevels/*.swift")
    tests = set((ROOT / "HanziLevelsTests").glob("*.swift"))
    if not tests <= set(sources["HanziLevelsTests"]):
        raise ValueError("A unit test file is missing from the test target")
    run("swiftc", "-frontend", "-parse", *sorted(expected | tests))
    data = ROOT / "HanziLevels/Resources/Data"
    manifest = json.loads((data / "manifest.json").read_text(encoding="utf-8"))
    for name, expected_digest in manifest["files"].items():
        path = (data / name).resolve()
        if data.resolve() not in path.parents:
            raise ValueError("Manifest path leaves bundled Data directory")
        if hashlib.sha256(path.read_bytes()).hexdigest() != expected_digest:
            raise ValueError("Bundled file checksum mismatch: " + name)
    print(f"Verified {len(manifest['files'])} bundled SHA-256 checksums.", flush=True)
    run("git", "diff", "--check")
    run("git", "diff", "--cached", "--check")


def standalone(sources):
    with tempfile.TemporaryDirectory(prefix="standalone-", dir=ROOT / "build") as directory:
        directory = Path(directory)
        production, copies, calls, skipped = [], [], [], []
        for source in sources["HanziLevelsTests"]:
            text = source.read_text(encoding="utf-8")
            if source.parent.name != "HanziLevelsTests":
                if "import SwiftData" in text:
                    skipped.append("production: " + str(source.relative_to(ROOT)))
                else:
                    production.append(source)
                continue
            cases = re.findall(r"^    func (test\w+)\(\)([^\n{]*)\{", text, re.MULTILINE)
            if len(cases) != len(re.findall(r"\bfunc test\w+\b", text)) or re.search(r"\bfunc (setUp|tearDown)\b", text):
                raise ValueError("Unsupported standalone test structure: " + source.name)
            if "import SwiftData" in text:
                skipped.extend(source.stem + "." + name for name, _ in cases)
                continue
            # Fail closed if discovery misses a new parameterized/multiline/lifecycle case.
            cls = re.search(r"final class (\w+): XCTestCase", text)
            if not cls or not cases:
                raise ValueError("Unsupported standalone test file: " + source.name)
            copy = directory / source.name
            copy.write_text(text.replace("import XCTest", "import Foundation")
                            .replace("Bundle(for: Self.self)", "VerificationResources()"), encoding="utf-8")
            copies.append(copy)
            for name, modifiers in cases:
                invocation = ("try " if "throws" in modifiers else "")
                invocation += ("await " if "async" in modifiers else "")
                invocation += f"{cls[1]}().{name}()"
                body = f'''do {{
                    let before = VerificationChecks.failures
                    {invocation}
                    print("\\(VerificationChecks.failures == before ? "PASS" : "FAIL") {cls[1]}.{name}")
                }}'''
                if "throws" in modifiers:
                    body += f' catch {{ XCTFail("{cls[1]}.{name}: \\(error)") }}'
                calls.append(body)
        if not calls:
            raise ValueError("No standalone test cases discovered")
        main = directory / "Runner.swift"
        main.write_text('import Foundation\n@main struct Runner {\n@MainActor static func main() async {\n'
                        + "\n".join(calls)
                        + f'\nprint("{len(calls)} standalone cases; \\(VerificationChecks.failures) failed assertions.")\n'
                        + 'if VerificationChecks.failures > 0 { exit(1) }\n}}\n', encoding="utf-8")
        print("SKIPPED SwiftData (requires full Xcode):\n  " + "\n  ".join(skipped), flush=True)
        binary = directory / "checks"
        run("swiftc", "-swift-version", "5", "-parse-as-library", *production, *copies,
            ROOT / "scripts/StandaloneAssertions.swift", main, "-o", binary)
        run(binary, ROOT / "HanziLevels/Resources")
        print("PASS: standalone gate only. iOS build, XCTest, SwiftData and manual QA remain unverified.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--standalone", action="store_true", help="CLT fallback; excludes SwiftData, does not use XCTest")
    modes.add_argument("--ios", action="store_true", help="Full Xcode unit tests and separate simulator app build")
    parser.add_argument("--destination", help="Installed simulator destination, e.g. platform=iOS Simulator,id=<UUID>")
    parser.add_argument("--allow-dirty", action="store_true", help="Development-only: label local changes DIRTY in the log")
    args = parser.parse_args()
    if args.ios and not args.destination:
        parser.error("--ios requires --destination")
    (ROOT / "build").mkdir(exist_ok=True)
    record_revision(args.allow_dirty)
    run("swift", "--version")
    sources = target_sources()
    static_checks(sources)
    run(sys.executable, "-m", "unittest", "discover", "-s", "scripts", "-p", "test_verify_local.py")
    if args.standalone:
        standalone(sources)
    else:
        run("xcodebuild", "-version")
        run("xcodebuild", "-project", "HanziLevels.xcodeproj", "-scheme", "HanziLevels",
            "-destination", args.destination, "-derivedDataPath", "build/DerivedData",
            "-resultBundlePath", "build/UnitTests-" + str(uuid.uuid4()) + ".xcresult",
            "CODE_SIGNING_ALLOWED=NO", "test")
        run("xcodebuild", "-project", "HanziLevels.xcodeproj", "-scheme", "HanziLevels",
            "-sdk", "iphonesimulator", "-destination", "generic/platform=iOS Simulator",
            "-derivedDataPath", "build/DerivedData", "CODE_SIGNING_ALLOWED=NO", "build")
        print("PASS: iOS unit tests and app build. Manual airplane-mode QA and release permission are separate gates.")


if __name__ == "__main__":
    try:
        main()
    except (subprocess.CalledProcessError, ValueError, OSError, KeyError) as error:
        sys.exit("Verification failed: " + str(error))
