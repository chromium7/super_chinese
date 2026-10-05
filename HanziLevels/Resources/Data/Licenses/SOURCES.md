## Release decision: blocked

This is the supplied **2026.10.0-sample**, not the full HSK curriculum.
It contains 131 words across HSK 1–5 and 213 characters. Do not ship this
sample until the level-list permission decision is resolved. No written
permission or approved replacement was supplied. Keep the supplied assignments
for development; obtain written redistribution permission from Zero to Hero
Education, or have the product owner approve an openly licensed replacement
and regenerate the bundle. An agent cannot approve that decision.

## Level membership — Language Player HSK levels

Source named by the supplied brief: Language Player, Zero to Hero Education
(https://languageplayer.io/). The prototype describes representative HSK 2.0
subsets, not a verified export of the site's lists. No open license or written
permission accompanies the attachments. License: **permission pending**.
There is no license text to bundle for this source yet. Do not label it MIT or
"used with permission". No original source revision was provided.

## Definitions and readings — CC-CEDICT

Credit: CC-CEDICT contributors and editor team, maintained by MDBG;
original CEDICT by Paul Andrew Denisowski.
Source: https://cc-cedict.org/wiki/ and https://www.mdbg.net/chinese/dictionary?page=cc-cedict

The supplied brief attributes the short English definitions and character
readings to CC-CEDICT. These are edited for brevity and subsetted. The attachment
does not identify an original CC-CEDICT dump revision; the exact supplied input
is pinned by SHA-256 in `DataSources/sources.lock.json`. Obtain the original
revision/provenance before a production release; do not invent an upstream pin.

On 2026-10-05, the official CC-CEDICT site identifies **CC BY-SA 3.0 Unported**.
Retain that license for these edited definitions/readings. The complete text is
`CC-BY-SA-3.0.txt`, from https://creativecommons.org/licenses/by-sa/3.0/legalcode.txt.
`CC-BY-SA-4.0.txt` is included to match the brief's requested file layout,
but is reference material only; it does not relicense CC-CEDICT or these edits.
The data license does not purport to license the app's Swift code.

## Stroke outlines and medians — Make Me a Hanzi

Source: https://github.com/skishore/makemeahanzi (`graphics.txt` only), via
hanzi-writer-data 2.0 as identified by the supplied stroke attachment.
Derived from Arphic PL KaitiM GB and UKai fonts.
Copyright © 1999 Arphic Technology Co., Ltd. **Arphic Public License**.

Changes: subset to the 213 sample characters; remove the source wrapper to
produce an id-to-StrokeSet JSON object. Preserve every supplied SVG path and
median point unchanged. The modified stroke data remains under the Arphic
Public License and is available as `strokes.v1.json` in this public repository.
No `dictionary.txt` data is imported. The supplied attachment does not specify
an upstream commit; its exact bytes are pinned by SHA-256.

The unmodified English `ARPHICPL.TXT` is bundled from Make Me a Hanzi commit
`bddc96d41bef78427ed0e034e9f7e31d71fd1b92` at
https://github.com/skishore/makemeahanzi/blob/bddc96d41bef78427ed0e034e9f7e31d71fd1b92/APL/english/ARPHICPL.TXT.
This commit pins the license text, not the supplied graphics data.

## Reproduction and attribution display

Run `python3 scripts/prepare_data.py --check` without networking. The manifest
hashes all bundled data, schema, attribution, and license files. Source URLs are
informational strings; the app must read the local texts without fetching them.
The later Sources & Licenses screen must display all three source credits,
the Arphic copyright, modification notes, and the applicable full license texts.
This data-only increment leaves the existing placeholder screen unchanged.
