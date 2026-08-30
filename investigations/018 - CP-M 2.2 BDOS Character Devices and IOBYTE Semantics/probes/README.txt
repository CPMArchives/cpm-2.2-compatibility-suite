Investigation 018 probe suite
=============================

CHAR018 temporarily replaces only the BIOS CONST, CONIN, CONOUT, LIST, PUNCH,
and READER jump-vector entries, preserving and restoring the original bytes.
The fixture records raw logical-device calls and supplies deterministic input;
it is test machinery, not a modified CP/M claim.

Build:
  z80asm -fb -oCHAR018.COM CHAR018.ASM

Run after installing CHAR018.COM on a disposable A image:
  ./run-char018.exp /path/to/disk-directory console.txt

The accepted run used z80asm 2.1 and z80pack cpmsim 1.39. No manual input or
timing is required. transcripts/console.txt is raw output. Before/after image
hashes demonstrate that the character tests perform no disk mutation.

The fixture deliberately makes READER return C1h, outside the BIOS ASCII
contract, to locate responsibility for parity stripping: BDOS passes it
unchanged, so conforming BIOS/device routing must supply documented 7-bit ASCII.
