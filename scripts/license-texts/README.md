# Vendored licence texts

`generate_licenses.py` embeds these into `sample-ui`'s notices asset, so the text ships with the
binary rather than behind a link — Apache-2.0 §4 asks the notice to travel with the distribution.

| File | Text | Provenance |
|---|---|---|
| `apache-2.0.txt` | Apache License 2.0, verbatim | The canonical file as distributed with the licence (sha256 `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`) |
| `mit.txt` | MIT, the SPDX template | The copyright line is a placeholder: MIT is parameterised by its holder, and every component's own line is in its own source |
| `bsd-3-clause.txt` | BSD 3-Clause, the SPDX template | Same — the holder is the component's, not ours to assert |
| `bouncy-castle.txt` | Bouncy Castle Licence | Not vendored; the text ships inside the jar as `org/bouncycastle/LICENSE.class` and the notices link it instead. Add the file here if that changes |

Two placeholder texts are a deliberate limit, not an omission: filling in a copyright holder we did
not read would be a worse notice than a template plus the component's own URL.
