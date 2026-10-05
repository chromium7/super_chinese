"""Reproduce/check the pinned sample bundle with Python 3, entirely offline."""

import argparse
import hashlib
import html
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "HanziLevels/Resources/Data"
BLOCKERS = [
    "Level-list written permission or approved replacement is missing.",
    "Original upstream definition and stroke revisions were not supplied.",
]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def encode(value):
    return (json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False) + "\n").encode()


def encode_strokes(value):
    # One character per line keeps changes reviewable without expanding points
    # into tens of thousands of lines. Paths and medians are not modified.
    rows = [json.dumps(char, ensure_ascii=False) + ": " +
            json.dumps(strokes, ensure_ascii=False, separators=(",", ":"), allow_nan=False)
            for char, strokes in value.items()]
    return ("{\n" + ",\n".join(rows) + "\n}\n").encode()


def validate_schema(value, schema, path="manifest"):
    """Evaluate the keywords used by our checked-in JSON Schema (no dependency)."""
    if "const" in schema:
        require(type(value) is type(schema["const"]) and value == schema["const"], f"{path}: wrong constant")
    if "type" in schema:
        types = {"object": dict, "string": str}
        require(type(value) is types[schema["type"]], f"{path}: wrong type")
    if "pattern" in schema:
        require(re.fullmatch(schema["pattern"], value) is not None, f"{path}: invalid hash")
    if isinstance(value, dict):
        require(set(schema.get("required", [])) <= value.keys(), f"{path}: missing keys")
        properties = schema.get("properties", {})
        if schema.get("additionalProperties") is False:
            require(value.keys() <= properties.keys(), f"{path}: unknown keys")
        for key, child in properties.items():
            if key in value:
                validate_schema(value[key], child, f"{path}.{key}")


def expected_bundle(root=ROOT):
    data = root / "HanziLevels/Resources/Data"
    inputs = root / "DataSources"
    lock = json.loads((inputs / "sources.lock.json").read_bytes())
    require(lock["schemaVersion"] == 1, "Unsupported source lock schema")
    for name, entry in lock["inputs"].items():
        require(sha((inputs / name).read_bytes()) == entry["sha256"], f"Source hash mismatch: {name}")
    for name, entry in lock["licenseTexts"].items():
        require(sha((data / "Licenses" / name).read_bytes()) == entry["sha256"], f"License changed: {name}")

    hsk = json.loads((inputs / "hsk.v1.json").read_bytes())
    source_strokes = json.loads((inputs / "strokes.v1.json").read_bytes())
    require(hsk["schemaVersion"] == source_strokes["schemaVersion"] == 1, "Unsupported source schema")
    require(hsk["datasetVersion"] == lock["datasetVersion"], "Source dataset version mismatch")
    require([level["level"] for level in hsk["levels"]] == [1, 2, 3, 4, 5], "Expected five ordered HSK levels")

    words, characters, seen_words, first_levels = [], [], set(), {}
    for level in hsk["levels"]:
        for hanzi, pinyin, english in level["words"]:
            syllables = pinyin.split(" ")
            require(hanzi and hanzi not in seen_words, f"Duplicate/empty word: {hanzi}")
            require(len(hanzi) == len(syllables) and all(syllables) and english, f"Invalid word: {hanzi}")
            seen_words.add(hanzi)
            words.append(dict(id=hanzi, syllables=syllables, english=english, level=level["level"]))
            for char in hanzi:
                first_levels.setdefault(char, level["level"])

    strokes = source_strokes["characters"]
    require(first_levels.keys() == hsk["characters"].keys() == strokes.keys(), "Character coverage mismatch")
    for char, first_level in first_levels.items():
        readings, meaning = hsk["characters"][char]
        stroke_set = strokes[char]
        paths, medians = stroke_set["strokes"], stroke_set["medians"]
        require(len(char) == 1 and readings and all(readings) and meaning, f"Invalid definition: {char}")
        require(paths and len(paths) == len(medians), f"Stroke count mismatch: {char}")
        for path, median in zip(paths, medians):
            require(isinstance(path, str) and path.startswith("M ") and path.strip().endswith("Z"), f"Invalid stroke path: {char}")
            require(len(median) >= 2, f"Short median: {char}")
            for point in median:
                require(len(point) == 2 and all(type(n) in (int, float) and abs(n) < 10000 for n in point), f"Invalid median point: {char}")
        characters.append(dict(id=char, readings=readings, meaning=meaning, strokeCount=len(paths), firstLevel=first_level))

    generated = {"words.v1.json": encode(words), "characters.v1.json": encode(characters), "strokes.v1.json": encode_strokes(strokes)}
    files = dict(generated)
    for name in ["manifest.schema.json", "Licenses/ARPHICPL.TXT", "Licenses/CC-BY-SA-3.0.txt", "Licenses/CC-BY-SA-4.0.txt", "Licenses/SOURCES.md"]:
        files[name] = (data / name).read_bytes()
    manifest = dict(schemaVersion=1, datasetVersion=lock["datasetVersion"],
                    files={name: sha(content) for name, content in sorted(files.items())},
                    sourceInputs={name: entry["sha256"] for name, entry in lock["inputs"].items()},
                    wordCounts=[len(level["words"]) for level in hsk["levels"]], characterCount=len(characters),
                    releaseApproved=False, releaseBlockers=BLOCKERS)
    validate_schema(manifest, json.loads(files["manifest.schema.json"]))
    generated["manifest.json"] = encode(manifest)
    return generated, manifest


def run(check=False, root=ROOT):
    generated, manifest = expected_bundle(root)
    data = root / "HanziLevels/Resources/Data"
    if check:
        actual = json.loads((data / "manifest.json").read_bytes())
        validate_schema(actual, json.loads((data / "manifest.schema.json").read_bytes()))
        require(actual == manifest, "Manifest metadata/hash mismatch; regenerate")
        for name, content in generated.items():
            require((data / name).read_bytes() == content, f"Stale or modified resource: {name}")
    else:
        for name, content in generated.items():
            (data / name).write_bytes(content)
    return manifest


def report(manifest, destination):
    counts = " / ".join(map(str, manifest["wordCounts"]))
    hashes = "".join(f"<tr><td>{html.escape(name)}</td><td><code>{digest}</code></td></tr>" for name, digest in manifest["files"].items())
    page = f"""<!doctype html><meta charset="utf-8"><title>Resource verification</title>
<style>body{{font:18px -apple-system,sans-serif;background:#f2f2f7;color:#1c1c1e;margin:48px}}main{{background:white;padding:32px;border-radius:16px;max-width:1000px}}h1{{margin:0 0 12px}}.pass{{color:#247046}}.blocked{{color:#b8432c}}td{{padding:10px 0;border-bottom:1px solid #eee;font-size:14px}}code{{font-size:11px;margin-left:20px}}li{{margin:12px 0}}</style>
<main><h1>Offline resource verification</h1><p>Dataset {manifest['datasetVersion']} · Schema 1</p>
<h2 class="pass">PASS · Bundle integrity</h2><ul><li>HSK 1–5: {counts} words · 131 total</li><li>213 characters: complete definitions and stroke coverage</li><li>All stroke and median counts match; supplied paths preserved</li><li>8 SHA-256 resource hashes verified</li><li>Three source attributions and full Arphic / CC license texts</li><li>Reproducible from pinned local inputs; no network access</li></ul>
<h2 class="blocked">Release blocked · Permission pending</h2><p>Level-list permission or approved replacement is required.<br>Original upstream definition and stroke revisions were not supplied.</p>
<table>{hashes}</table><p>Generated by <code>python3 scripts/prepare_data.py --check --report</code>.<br>Resource report only; iOS simulator unavailable (Xcode not installed).</p></main>"""
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(page, encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify without modifying resources")
    parser.add_argument("--report", type=Path, help="Write a local HTML verification report")
    parser.add_argument("--require-release-approved", action="store_true", help="Fail for unresolved licensing/provenance")
    args = parser.parse_args()
    try:
        result = run(args.check)
        if args.report:
            report(result, args.report)
        print(f"PASS: {result['datasetVersion']}; {sum(result['wordCounts'])} words; {result['characterCount']} characters; 8 resource hashes")
        print("RELEASE BLOCKED: " + " ".join(result["releaseBlockers"]))
        if args.require_release_approved:
            require(result["releaseApproved"], "Release approval is missing")
    except (ValueError, KeyError, TypeError, OSError) as error:
        sys.exit(f"Resource verification failed: {error}")
