"""Gate regressions using disposable git trees and synthetic project references."""

from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import verify_local as gate


class VerificationGateTests(unittest.TestCase):
    def directory(self):
        directory = tempfile.TemporaryDirectory(prefix="gate-regression-")
        self.addCleanup(directory.cleanup)
        return Path(directory.name)

    def repository(self):
        root = self.directory()
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        (root / "fixture.txt").write_text("baseline\n", encoding="utf-8")
        subprocess.run(["git", "add", "fixture.txt"], cwd=root, check=True)
        # This identity belongs only to the disposable fixture commit, never repo config.
        subprocess.run(["git", "-c", "user.name=Gate Fixture", "-c", "user.email=fixture@example.invalid",
                        "commit", "-qm", "baseline"], cwd=root, check=True)
        return root

    def testCleanRevisionIsRecorded(self):
        root = self.repository()
        output = io.StringIO()
        with patch.object(gate, "ROOT", root), redirect_stdout(output):
            gate.record_revision(False)
        self.assertRegex(output.getvalue(), r"Revision: [0-9a-f]{40} CLEAN")

    def testStagedUnstagedAndUntrackedChangesRequireExplicitDirtyOptIn(self):
        for kind in ["unstaged", "staged", "untracked"]:
            with self.subTest(kind=kind):
                root = self.repository()
                if kind == "untracked":
                    (root / "new.swift").write_text("changed\n", encoding="utf-8")
                else:
                    (root / "fixture.txt").write_text("changed\n", encoding="utf-8")
                    if kind == "staged":
                        subprocess.run(["git", "add", "fixture.txt"], cwd=root, check=True)
                output = io.StringIO()
                with patch.object(gate, "ROOT", root), redirect_stdout(output):
                    with self.assertRaisesRegex(ValueError, "Working tree is dirty"):
                        gate.record_revision(False)
                    gate.record_revision(True)
                self.assertIn(" DIRTY", output.getvalue())
                self.assertIn("WARNING: --allow-dirty", output.getvalue())

    def testUnknownSourceReferenceHasTargetDiagnostic(self):
        for source_tree in ["<group>", "SDKROOT"]:
            with self.subTest(source_tree=source_tree):
                project = {
                    "rootObject": "project",
                    "objects": {
                        "project": {"isa": "PBXProject", "mainGroup": "root"},
                        "root": {"isa": "PBXGroup", "children": ["variant"]},
                        "variant": {"isa": "PBXVariantGroup" if source_tree == "<group>" else "PBXFileReference",
                                    "sourceTree": source_tree, "path": "Fixture.swift"},
                        "target": {"isa": "PBXNativeTarget", "name": "Fixture", "buildPhases": ["phase"]},
                        "phase": {"isa": "PBXSourcesBuildPhase", "files": ["build"]},
                        "build": {"isa": "PBXBuildFile", "fileRef": "variant"},
                    },
                }
                with patch.object(gate.subprocess, "check_output", return_value=json.dumps(project)):
                    with self.assertRaisesRegex(ValueError, "Unresolved source reference variant in target Fixture"):
                        gate.target_sources()

    def testSwiftDataProductionAndTestSkipsAreNamedBeforeCompiling(self):
        root = self.directory()
        (root / "build").mkdir()
        (root / "HanziLevels/Data").mkdir(parents=True)
        (root / "HanziLevelsTests").mkdir()
        production = root / "HanziLevels/Data/Persistence.swift"
        production.write_text("import SwiftData\n", encoding="utf-8")
        history = root / "HanziLevelsTests/HistoryTests.swift"
        history.write_text("import SwiftData\nfinal class HistoryTests: XCTestCase {\n"
                           "    func testPersistence() {}\n}\n", encoding="utf-8")
        simple = root / "HanziLevelsTests/SimpleTests.swift"
        simple.write_text("import XCTest\nfinal class SimpleTests: XCTestCase {\n"
                          "    func testSimple() {}\n}\n", encoding="utf-8")
        output = io.StringIO()
        # Inspect skip/discovery behavior before the platform compiler runs.
        with patch.object(gate, "ROOT", root), patch.object(gate, "run") as run, redirect_stdout(output):
            gate.standalone({"HanziLevelsTests": [production, history, simple]})
        self.assertIn("production: HanziLevels/Data/Persistence.swift", output.getvalue())
        self.assertIn("HistoryTests.testPersistence", output.getvalue())
        self.assertNotIn(production, run.call_args_list[0].args)

    def testStagedWhitespaceViolationFailsStaticChecks(self):
        root = self.repository()
        (root / "HanziLevels/Resources/Data").mkdir(parents=True)
        (root / "HanziLevelsTests").mkdir()
        (root / "HanziLevels/Resources/Data/manifest.json").write_text('{"files":{}}', encoding="utf-8")
        (root / "fixture.txt").write_text("trailing whitespace \n", encoding="utf-8")
        subprocess.run(["git", "add", "fixture.txt"], cwd=root, check=True)
        def git_only(*arguments):
            if arguments[0] == "git":
                subprocess.run(arguments, cwd=root, check=True, capture_output=True)

        with patch.object(gate, "ROOT", root), patch.object(gate, "run", side_effect=git_only), redirect_stdout(io.StringIO()):
            with self.assertRaises(subprocess.CalledProcessError):
                gate.static_checks({"HanziLevels": [], "HanziLevelsTests": []})

    def testOfflineScanRejectsNetworkAndCoreFoundationNetworkingSymbols(self):
        root = self.directory()
        (root / "scripts").mkdir()
        (root / "HanziLevels").mkdir()
        (root / "HanziLevels.xcodeproj").mkdir()
        checker = root / "scripts/check_offline.py"
        checker.write_bytes((gate.ROOT / "scripts/check_offline.py").read_bytes())
        (root / "HanziLevels.xcodeproj/project.pbxproj").write_text("", encoding="utf-8")
        for symbol in ["URLSession.shared", "NWConnection", "NWPathMonitor", "CFSocketCreate", "CFStreamCreatePairWithSocket"]:
            with self.subTest(symbol=symbol):
                (root / "HanziLevels/Fixture.swift").write_text(symbol, encoding="utf-8")
                result = subprocess.run([sys.executable, str(checker)], capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Offline check failed", result.stderr)


if __name__ == "__main__":
    unittest.main()
