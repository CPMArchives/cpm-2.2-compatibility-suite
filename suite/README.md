# CP/M 2.2 compatibility suite

For installation, common commands, result terminology, and instructions for
all eleven ledger-owning tools, see [`../docs/USER-MANUAL.md`](../docs/USER-MANUAL.md).

The suite consists of eleven logical ledger-owning utilities in twelve test
executables, plus the Intel 8080-compatible `SCRATCH` support program:

- `FILETEST`, `RANDTEST`, `DIRTEST`, `CONSTEST`, `BDOSTEST`, `ENTRYTST`, `CCPTEST`,
  `DISKTEST`, `BIOSTEST`, `ERRTEST`, `ECOTEST`, and `CPUTEST` exercise the corresponding
  conformance-ledger areas.
- `SCRATCH` prepares expendable media for tests that require controlled disk
  contents.

The runtime image also bundles the standalone `SYSINFO.COM` utility for
operator convenience. Its source and releases live in the sibling `sysinfo`
repository; it is not a conformance-suite utility.

BIOSTEST boot selectors retain verified two-stage BOOT/WBOOT evidence in
`BTBOOT.DAT` on the utility disk so later `/ALL` runs can include those
nonreturning tests. Delete that file to reset the boot evidence.

BIOSTEST item `0457` uses the expendable scratch disk for a verified 128-byte
write/read/compare, then asks the operator to enable write protection for one
direct BIOS WRITE. Restore the disk to writable when prompted; the test
confirms recovery before deleting its temporary file. Q leaves the physical
fault procedure UNTESTED rather than synthesizing a BIOS error.

BIOSTEST item `0470` is automatic: it verifies graphic and control bytes at
the CONOUT, LIST, and PUNCH logical BIOS boundaries. Item `0471` is a retained
two-run provider procedure. On Montezuma, run `STAT RDR:=PTR:` and then `BIOSTEST /0471`;
press Y and type uppercase R when READER waits. BIOSTEST saves that evidence
in `BTRDR.DAT` and returns. The second run requires a separately configured
READER provider already verified to return Ctrl-Z immediately. `STAT` logical
device assignment is a CP/M/IOBYTE convention, but the named physical drivers
are BIOS-specific; on the tested Montezuma installation both `UR1:` and `UR2:`
block and are not valid stage-two providers. Press Q unless another immediate
EOF provider is available. Delete `BTRDR.DAT` to reset retained evidence.

## Maintained media

`disk-images/trs80-montezuma/Conformance Suite.dmk` is the maintained runtime
disk. `Conformance Suite Source.dmk` is the separate CP/M-native source disk.
Both use Montezuma Micro 80T SUPER DS DATA format (80 tracks, double-sided,
double-density, 880K). `BIOSTEST OFF Scratch.dmk` is a third, blank and
expendable 880K image for BIOSTEST item `0453`; configure its drive with the
matching 80-track SUPER DS system format so `SYSINFO /DPB` reports a nonzero
`OFF`. A freshly formatted SYSTEM disk is already sufficient; use
`SCRATCH /BLANK` only if the disk has subsequently been used.

The source disk contains current sources in standard CP/M Crunch `.MZC`
form, standard `CRUNCH.COM` and `UNCR.COM`, ZSM4, Digital Research LINK,
`BUILD.SUB`, and `README.TXT`. It is therefore self-contained for native
assembly on a Z80 CP/M system. Build one utility at a time with:

```text
SUBMIT BUILD FILETEST
```

`BUILD.SUB` uncrunches the selected source, assembles it with ZSM4, links it
with LINK, and then removes the temporary `.MAC` and `.REL` files. LINK's
additional-memory option is used for every utility because FILETEST requires
it and the option is harmless for the smaller programs. To inspect a source
without building it, use `UNCR FILETEST.MZC /Q`.

The host-side canonical sources remain the `.ASM` files in `src/`. After a
source change, regenerate the compressed payload with:

```text
python3 tools/build_crunched_sources.py
```

The source-image builder verifies every generated-source and compressed-file
hash in `crunched-source/MANIFEST.tsv`, and refuses to use a stale payload.

## Scratch media

Run `SCRATCH /LIST` for the available preparation profiles:

- `SCRATCH /DISK` prepares the data-full DISKTEST layout.
- `SCRATCH /CROSS` prepares `BTBFILE.DAT` for FILETEST and DIRTEST
  cross-drive checks.
- `SCRATCH /BLANK` erases and verifies an otherwise empty expendable disk.

For BIOSTEST `0453`, use `BIOSTEST OFF Scratch.dmk`. The disk image itself
does not select a DPB: the emulator's Montezuma drive-format setting must be a
matching system format with nonzero `OFF`. Confirm that fact with
`SYSINFO /DPB <drive>` before running BIOSTEST.

SCRATCH accepts an operator-selected configured drive B through P, requires a
second destructive confirmation, and never targets A.

## Repository layout

- `src/` — current canonical assembly sources.
- `build/` — current assembled COM files, sizes, and checksums.
- `crunched-source/` — generated `.MZC` sources and their validation manifest.
- `build-tools/` — the native ZSM4/LINK toolchain, standard CRUNCH and UNCR
  utilities, ZSM4's corresponding GPL source, hashes, and provenance notes.
- `runtime-payload/` — canonical non-utility inputs for a fresh runtime disk.
- `disk-images/z80pack/ibm-3740/` — the single preserved cpmsim boot image.
- `archive/dev-versions/` — immutable source/COM development revisions.
- `disk-images/trs80-montezuma/` — the maintained runtime, source, and BIOSTEST
  OFF-scratch 880K images and manifests.
- `tests/` — emulator procedures and retained validation logs.

Run `./suite/build.sh` from the repository root to assemble and archive all
thirteen transient programs. Use `./suite/release.sh <maintained-project-directory>` for a
complete build, archive, image refresh, publication, and checksum verification.
See `RELEASE-WORKFLOW.md` for the exact contract and `INTERFACE-STANDARD.md`
for utility behavior and presentation requirements.

For disposable emulator media, run
`python3 tools/prepare_z80pack_test_disks.py <temporary-directory>`.
