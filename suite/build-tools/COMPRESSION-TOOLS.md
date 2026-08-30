# CP/M source-disk tools

The project distributes Steven Greenberg's standard CRUNCH 2.4 compressor and
UNCR on its source image. CRUNCH produces the standard CP/M `.?Z?` source
files; UNCR restores them. The host generator uses the bundled `CRUNCH.COM` by
default, while `--crunch` or `CRUNCH_COM` may select another verified copy.

The source image includes ZSM4 and Digital Research LINK, which replace the
previous Microsoft M80/L80 build path. ZSM4 itself requires a Z80-compatible
processor; the emitted suite programs continue to use the Intel 8080 subset.
The complete native source-build path requires a Z80-compatible processor.

| Maintainer-tested file | SHA-256 | Archived source |
| --- | --- | --- |
| `CRUNCH.COM` | `f29121a2b38b7f49d1b1c00efc8e35cae8793d1acdf9be9e63c64e5f1e48f0b0` | `squsq/crunch24.lbr` |
| `UNCR.COM` | `c834ad4a89b45200e8220ce84a5837dcc876ce4a6326267b342d8c0055fd810c` | `squsq/crunch24/uncr.com` |
| `ZSM4.COM` | `3dbeed62bc303a07c62e0fd41a5df44d023c2f82c05b76785a97d20a633f6ef8` | ZSM4 upstream commit `96a9ac1081172e1c08291521b77d2a715ec59c8b` |
| `LINK.COM` | `82df88a9bcfb1068eb37df08df6d664711d20c73ddae66b81577dfed02642677` | Digital Research LINK 1.3, z80pack `hd-tools.dsk` |

Archive mirror:
`https://dflund.se/~pi/cpm/files/ftp.mayn.de/pub/cpm/archive/`

ZSM4 upstream: `https://github.com/hperaza/ZSM4`. ZSM4 is licensed under the
GNU GPL version 2; the exact corresponding source and license for the bundled
binary are retained in `build-tools/zsm4-source/`.

The source-disk workflow uses `UNCR NAME.MZC /Q`, `ZSM4 =NAME`, and
`LINK NAME[A]`. Both CRUNCH and UNCR are included in this repository and its
source image, with the hashes above recording the exact distributed binaries.
Their embedded notice permits reproduction for non-profit use only. Complete
attribution, license, and redistribution details for every bundled tool are
recorded in the repository's `../../THIRD-PARTY-NOTICES.md`.
