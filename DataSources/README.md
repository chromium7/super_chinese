The two JSON files are the exact attachments supplied on the parent issue.
They are retained as immutable conversion inputs, pinned by SHA-256 and
attachment identifier in `sources.lock.json`. They are development sample data,
not a complete HSK curriculum or a claim of cleared redistribution rights.

The lock also pins the downloaded full license texts. The Make Me a Hanzi
commit identifies the **license text revision only**. Original upstream
dictionary and stroke revisions were not supplied; the source attachment's
`hanzi-writer-data 2.0` label is retained in the input, without inventing a
more precise pin. The CC texts are exact snapshots from the official license
URLs recorded in the lock.

Run `python3 scripts/prepare_data.py` to regenerate resources. No build-time
downloads or runtime networking are needed. `--check` checks bytes, schema,
definitions/readings, first appearances, stroke coverage, and all manifest
hashes without changing the bundle. Use `--require-release-approved` as a
release gate; it currently fails intentionally. Resolving permissions requires
documented owner approval and a reviewed data/schema update, not flipping a
boolean in the manifest.

See `HanziLevels/Resources/Data/Licenses/SOURCES.md` for the three attributions,
applicable licenses, modifications, and unresolved release requirements.
