Investigation 009 probe artifacts
=================================

DSRCH009.ASM exercises BDOS functions 17, 18, and 26 against controlled
directories. It prints the result, current disk, byte 0080h, and the complete
128-byte caller DMA record after every search call.

DSRCH009.COM SHA-256:

  ea1c35a31340d516161daa8eed74b9391a6f5e2c7fe651644feb4d47c874b074

Build:

  z80asm -fb -oDSRCH009.COM DSRCH009.ASM

The disposable test images and exact preparation are described in
observed-output.txt. Run under the identified DRI CP/M 2.2 system with both A
and B mounted:

  A>DSRCH009

No manually timed input is used. The probe does not patch BDOS, BIOS, or the
emulator. The output is intentionally verbose so each result code can be
related directly to all four 32-byte entries in the transferred directory
record. Do not infer valid search data from a line whose result is FFh.

`observed-raw.txt` is the automated full terminal capture. `capture.exp`
repeats that capture when the prepared images are at `/private/tmp/inv009-disk`.
