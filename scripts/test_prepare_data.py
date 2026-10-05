"""Regression tests for corrupt input, stale resources, and release gating."""

import copy
import json
from pathlib import Path
import shutil
import tempfile
import unittest

import prepare_data as bundle


class BundleTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        shutil.copytree(bundle.ROOT / "DataSources", self.root / "DataSources")
        shutil.copytree(bundle.DATA, self.root / "HanziLevels/Resources/Data")
        self.data = self.root / "HanziLevels/Resources/Data"

    def test_reproduction_preserves_words_readings_definitions_and_strokes(self):
        manifest = bundle.run(check=True, root=self.root)
        source = json.loads((self.root / "DataSources/hsk.v1.json").read_bytes())
        words = json.loads((self.data / "words.v1.json").read_bytes())
        self.assertEqual([(w["id"], " ".join(w["syllables"]), w["english"], w["level"]) for w in words],
                         [(h, p, e, level["level"]) for level in source["levels"] for h, p, e in level["words"]])
        characters = json.loads((self.data / "characters.v1.json").read_bytes())
        self.assertEqual({c["id"]: [c["readings"], c["meaning"]] for c in characters}, source["characters"])
        self.assertEqual(json.loads((self.data / "strokes.v1.json").read_bytes()),
                         json.loads((self.root / "DataSources/strokes.v1.json").read_bytes())["characters"])
        strokes = json.loads((self.data / "strokes.v1.json").read_bytes())
        for character in characters:
            self.assertEqual(character["firstLevel"], min(w["level"] for w in words if character["id"] in w["id"]))
            self.assertEqual(character["strokeCount"], len(strokes[character["id"]]["strokes"]))
            self.assertEqual(character["strokeCount"], len(strokes[character["id"]]["medians"]))
        self.assertFalse(manifest["releaseApproved"])
        self.assertEqual(len(manifest["releaseBlockers"]), 2)
        before = {p: p.read_bytes() for p in self.data.rglob("*") if p.is_file()}
        bundle.run(root=self.root)
        self.assertEqual(before, {p: p.read_bytes() for p in before})

    def test_changed_resource_is_rejected(self):
        with (self.data / "words.v1.json").open("ab") as file:
            file.write(b" ")
        with self.assertRaisesRegex(ValueError, "modified resource"):
            bundle.run(check=True, root=self.root)

    def test_changed_source_or_license_is_rejected(self):
        for path in [self.root / "DataSources/hsk.v1.json", self.data / "Licenses/ARPHICPL.TXT"]:
            original = path.read_bytes()
            path.write_bytes(original + b" ")
            with self.assertRaisesRegex(ValueError, "hash mismatch|License changed"):
                bundle.run(check=True, root=self.root)
            path.write_bytes(original)

    def test_unknown_schema_invalid_hash_and_approval_are_rejected(self):
        manifest = json.loads((self.data / "manifest.json").read_bytes())
        schema = json.loads((self.data / "manifest.schema.json").read_bytes())
        for key, value in [("schemaVersion", 2), ("schemaVersion", True), ("releaseApproved", True),
                           ("files", {"../escape": "0" * 64}), ("files", {**manifest["files"], "words.v1.json": "bad"})]:
            altered = copy.deepcopy(manifest)
            altered[key] = value
            with self.assertRaises(ValueError):
                bundle.validate_schema(altered, schema)

    def test_stroke_median_mismatch_is_rejected_even_after_source_repin(self):
        path = self.root / "DataSources/strokes.v1.json"
        strokes = json.loads(path.read_bytes())
        strokes["characters"]["学"]["medians"].pop()
        path.write_bytes(bundle.encode(strokes))
        lock_path = self.root / "DataSources/sources.lock.json"
        lock = json.loads(lock_path.read_bytes())
        lock["inputs"][path.name]["sha256"] = bundle.sha(path.read_bytes())
        lock_path.write_bytes(bundle.encode(lock))
        with self.assertRaisesRegex(ValueError, "Stroke count mismatch"):
            bundle.run(root=self.root)


if __name__ == "__main__":
    unittest.main()
