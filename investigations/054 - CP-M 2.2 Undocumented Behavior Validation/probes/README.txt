INVESTIGATION 054 PROBES

This directory preserves fresh reruns of selected I041-I043 probes used to
validate undocumented and de facto behaviors.

- source/: assembly, include, submission, and scripted runner inputs.
- binaries/: rebuilt COM fixtures.
- transcripts/: raw console output, executable-pattern screen, and rebuild logs.
- images/: restored before and captured after disk images.
- undocumented-behavior-inventory.tsv: 21-behavior evidence/classification review.
- validation-records.txt: seven controlled tests with required fields.
- observed-output.txt: concise result summary.
- rebuild-verification.txt: byte-identity results for 11 rebuilt probes.
- images-sha256.txt and SHA256SUMS: preserved hashes.
- validate054.sh and validation-audit.txt: deterministic artifact/result audit.

Reproduction uses fresh copies of the standard z80pack CP/M 2.2 images and the
preserved I041-I043 runners. No manual input is required. DIRECT41 is intentionally
isolated; its private-target result is an observation, not a compatibility promise.
