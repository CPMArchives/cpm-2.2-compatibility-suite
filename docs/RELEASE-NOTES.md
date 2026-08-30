# CP/M 2.2 Compatibility Suite

## Initial public release — 0.1.0-alpha.1

This is the initial public development release of the CP/M 2.2 Compatibility
Suite, its 627-item compatibility ledger, supporting research, documentation,
fixtures, source code, and preserved development revisions.

### Included utilities

Eleven logical Intel 8080-compatible utilities own and report the ledger. They
are delivered as twelve transient programs because the file catalog is split
between `FILETEST` and `RANDTEST` to remain loadable below a `C400h` BDOS:

- `FILETEST`, `RANDTEST`, `DIRTEST`, `CONSTEST`, `BDOSTEST`, and `ENTRYTST` cover the
  application-facing entry, BDOS, file, directory, and character interfaces.
- `CCPTEST`, `DISKTEST`, `BIOSTEST`, `ERRTEST`, `ECOTEST`, and `CPUTEST` cover
  the command environment, disk and BIOS boundaries, error behavior,
  operating environment, and processor baseline.
- `SCRATCH` prepares expendable media for destructive test procedures. It is
  a support utility and does not own ledger items.

The common command interface includes individual item selection, `/SAFE`,
`/ALL`, grouped `/LIST` output, `/GROUP:LIST`, functional group selection,
`/INFO`, `/VER` and `/VERSION`, and `/H` and `/HELP`. Utility-specific groups
and manual/provider procedures are documented in the user's manual.
FILETEST's `/FN:15`, `/FN:16`, and `/FN:20` selectors also accept the grouped
spellings `/GROUP:FN:15`, `/GROUP:FN:16`, and `/GROUP:FN:20`.
Every ledger utility appends a compact `Failed items:` selector list after an
aggregate report with one or more failures. The line is omitted for a clean
run. This makes failures in long reports directly rerunnable even after their
rows have scrolled off screen.
CONSTEST also gives explicit Y/N criteria for the paired Function 6 probes:
`0081` judges immediate nonblocking return, and `0082` separately judges the
no-key value `A=00`.

### Distribution contents

The repository includes:

- canonical assembly sources and current COM builds;
- every preserved development revision available to the project;
- the compatibility ledger, standard, policy, profiles, and research record;
- the CP/M 2.2 Compatibility Suite User's Manual;
- controlled fixtures and reproducible disk-image generators;
- a maintained runtime image, crunched-source image, and blank BIOSTEST
  scratch image for the tested Montezuma Micro format;
- build, checksum, archive, and image manifests.

The source image includes standard CRUNCH 2.4 and UNCR, ZSM4, and Digital
Research LINK. The native build is now
self-contained: `BUILD.SUB` uncrunches one source, assembles and links it, and
removes the temporary `.MAC` and `.REL` files. The current release binaries
are built with that same ZSM4/LINK path. The runtime image does not include
PIP because the suite does not require it.

The controlled `BT*.DAT` files are deterministically generated marked-record
fixtures. Their contents can be reproduced with `tools/build_runtime_payload.py`.

The native sources are relocatable inputs to LINK and therefore do not apply
an `ORG 0100h` themselves. LINK supplies the single standard CP/M transient
load origin. This avoids a second 0100h displacement and the resulting
256-byte gap in generated COM files.

### Validation status

The returning command interface and automated checks have been exercised on
Intel 8080 and Z80 processor modes, with additional testing under Montezuma
Micro CP/M in trs80gp. The retained validation record identifies the exact
procedures completed.

This alpha release is not a certification of any CP/M implementation. Some
provider-assisted, interactive, nonreturning, special-media, profile, restart,
and recovery procedures still require a complete validation campaign. An
unperformed procedure remains visibly untested and is never converted into a
pass.

### Historical development versions

The repository preserves every recovered source and COM revision under
`suite/archive/dev-versions/`. They are retained for research and
reproducibility, not recommended in place of the current build.
