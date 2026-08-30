# Build, archive, and release workflow

## Sources of truth

- Current editable sources: `suite/src/*.ASM`.
- Current host builds: `suite/build/*.COM`.
- Generated compressed sources: `suite/crunched-source/*.MZC` and
  `MANIFEST.tsv`.
- Historical revisions: `suite/archive/dev-versions/<utility>/<devN>/`.
- Third-party build-tool requirements and provenance:
  `suite/build-tools/COMPRESSION-TOOLS.md`. CRUNCH, UNCR, ZSM4, and LINK are
  included.
- Runtime disk: `suite/disk-images/trs80-montezuma/Conformance Suite.dmk`.
- Source disk: `suite/disk-images/trs80-montezuma/Conformance Suite Source.dmk`.
- BIOSTEST OFF scratch disk:
  `suite/disk-images/trs80-montezuma/BIOSTEST OFF Scratch.dmk`.

Individual per-utility DMK images are not release artifacts. Historical
source and binaries must be preserved in `archive/dev-versions`; the archive
manifest is rebuilt from that archive and does not depend on old disk images.

## Local build

Run from the repository root:

```text
./suite/build.sh
```

This runs ZSM4 and Digital Research LINK under z80pack CP/M to assemble every
conformance utility, including SCRATCH, regenerates
`SHA256SUMS.txt` and `SIZES.txt`, and records each current development revision
under `archive/dev-versions`. It requires z80pack `cpmsim`, `expect`, and
`cpmtools`; set `CPMSIM` and `Z80PACK_SYSTEM_DISK` if they are not in the
default z80pack installation beneath the user's home directory.

After changing a source, regenerate the source-disk payload with:

```text
python3 tools/build_crunched_sources.py
```

This produces standard Crunch `.MZC` files under `suite/crunched-source/`.
Their manifest binds each compressed file to the current generated `.MAC`
source, so the source-image builder rejects stale compressed sources. The
bundled `suite/build-tools/CRUNCH.COM` is used by default; `--crunch` or
`CRUNCH_COM` can override it.

The runtime image additionally includes the pinned standalone binary at
`external/sysinfo/SYSINFO.COM`; it is not built or archived here.

## Complete publication

Run:

```text
./suite/release.sh
```

The release command operates directly in the maintained working repository. It
performs the local build, regenerates the compressed source payload, rebuilds
`Conformance Suite.dmk` from canonical inputs, regenerates `Conformance Suite
Source.dmk`, regenerates the blank BIOSTEST OFF scratch image, and verifies the
source/build checksum manifest. It prints final SHA-256 hashes for all three
images. The source image includes the repository's `CRUNCH.COM`, `UNCR.COM`,
`ZSM4.COM`, and Digital Research `LINK.COM`. The release build itself runs
ZSM4 and LINK under CP/M, so the checked-in COM files and the source-disk
recipe use the same toolchain.

The runtime-image builder retains the immediately preceding image as
`Conformance Suite.dmk.bak`. Emulator disk caching is outside the image: after
an update, unmount and remount the DMK before testing it in trs80gp.

## Release verification

Before publication, exercise changed utilities on both Intel 8080 and Z80
processor modes, plus any required target-system manual procedures. After
publication, verify the displayed versions from the remounted runtime image.
Do not delete a historical source or COM after it enters `dev-versions`.

Create disposable z80pack test media with:

```text
python3 tools/prepare_z80pack_test_disks.py /tmp/cpm-compatibility-test
```

The builder copies the single preserved CP/M boot image and constructs fresh
B/C/D work disks; generated IBM 3740 images are never release artifacts.

## Historical development versions

The recovered development revisions do not correspond to commits in this new
Git repository, so GitHub cannot present them as an authentic earlier commit
history. Publish them instead as assets of one clearly labeled historical
pre-release. Run:

```text
python3 tools/prepare_historical_release_assets.py /tmp/cpm-history
```

This creates one archive per utility, containing every preserved `devN`
directory, plus checksums and an asset manifest. After the repository's first
commit exists, create the `historical-development-archive` GitHub pre-release
and attach those generated assets. See `docs/GITHUB-RELEASES.md` for the exact
commands. Do not commit the generated ZIP files to the repository.
