# Maintained media

The release contains three maintained Montezuma Micro 880K images under
`trs80-montezuma/`:

- `Conformance Suite.dmk` — current runtime utilities and required static
  support files. The logical FILETEST utility is divided between `FILETEST.COM`
  and `RANDTEST.COM` so each loads on systems whose BDOS begins at `C400h`.
- `Conformance Suite Source.dmk` — current CP/M-native sources in Crunch
  `.MZC` form, `CRUNCH.COM`, `UNCR.COM`, `ZSM4.COM`, Digital Research `LINK.COM`,
  `BUILD.SUB`, and build instructions. Run `SUBMIT BUILD name` on a working
  copy; the build removes its temporary `.MAC` and `.REL` files.
- `BIOSTEST OFF Scratch.dmk` — blank expendable media for BIOSTEST item 0453.
  Configure it as a matching 80-track SUPER DS system-format drive and verify
  that `SYSINFO /DPB` reports nonzero `OFF` before `SCRATCH /BLANK` and
  `BIOSTEST /0453`.

Other test-specific expendable media are prepared by SCRATCH and are not
maintained as versioned fixture images. Disposable z80pack media are generated
from the single boot image under `suite/disk-images/z80pack/ibm-3740`. Per-utility
image trees are not maintained.
