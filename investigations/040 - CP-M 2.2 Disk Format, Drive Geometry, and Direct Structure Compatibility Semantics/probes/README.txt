Investigation 040 reproducibility notes
=======================================

The matrix combines native CP/M probes with read-only raw-image analysis.

Build native probes:
  ./build.sh

Create and analyze controlled images:
  ./run-matrix.sh

Run the native BDOS/STAT and direct-BIOS fixtures:
  ./run-native040.sh

DPB040 is the accepted Investigation 017 state/DPB/allocation fixture under
the Investigation 040 name. BIOS040 is the accepted Investigation 019 BIOS
boundary fixture under the Investigation 040 name. Their origins are retained
because this investigation consolidates, rather than silently reinvents,
those lower-level experiments.

analyze040.py understands the controlled IBM 3740 translation table and the
identity-translated z80pack hard-disk definition. It reconstructs logical
directory sectors, parses 32-byte entries, and cross-checks allocation block
ownership. make-empty040.py creates deterministic empty raw media.

The damaged image is intentional: block 2 is assigned to two active entries.
fsck.cpm is an independent host-side cross-check, not evidence of CP/M's own
error presentation. The z80pack-hd host utilities require an explicit raw
driver selection; the Investigation analyzer supplies the retained structural
evidence for that image.

No script writes outside this Investigation directory. Native run directories
are disposable controlled copies. No Compatibility Ledger operation occurs.
