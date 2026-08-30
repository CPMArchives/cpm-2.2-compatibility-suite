# Deliverable contents

- `INITIAL-DESIGN.md`: architecture, grammar, safety, fixtures, profiles, phases, and release gates.
- `ARCHITECTURE-DECISIONS.md`: accepted implementation-policy decisions, beginning with the 8080 generic-suite baseline.
- `case-to-executable-catalog.tsv`: all 627 frozen RC1 proposition cases mapped to proposed executables.
- `bios-routine-catalog-schema.tsv`: required single-source metadata tying BIOS template routines to tests and documentation.
- `existing-probe-inventory.tsv`: hashed non-rebuild source/binary probe artifacts; no probe is approved merely by appearing here.
- `FILE-DIR-DISK-PROBE-REVIEW.md`: source-reviewed reuse findings and first FILETEST vertical-slice scope.
- `file-dir-disk-probe-reuse-matrix.tsv`: per-logical-probe decisions, source hashes, safety and required adaptations.
- `FILE-DIR-DISK-PROBE-REVIEW-VALIDATION.txt`: review integrity summary.
- `FILETEST-VERTICAL-SLICE-DECOMPOSITION.md`: exact proposition-level first-slice specification.
- `filetest-vertical-slice-scenarios.tsv`: selectors, seeds, prerequisites, fixtures, oracles and evidence for each mapped case.
- `FILETEST-VERTICAL-SLICE-DECOMPOSITION-VALIDATION.txt`: scenario decomposition integrity checks.
- `VALIDATION.txt`: generated integrity checks and counts.

Regenerate with `python3 tools/build_initial_deliverable.py`, `python3 tools/build_file_probe_review.py`, and `python3 tools/build_filetest_scenario_decomposition.py` from the workspace root.
