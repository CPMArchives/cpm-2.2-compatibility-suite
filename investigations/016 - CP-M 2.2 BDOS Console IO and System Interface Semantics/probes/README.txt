Investigation 016 probe suite
================================

Purpose
-------
These deterministic CP/M 2.2 probes exercise BDOS Functions 1, 2, 6, 9,
10, 11, 12, 25, 26, 32, and (to resolve a numbering error in the request)
35, Compute File Size.  Function 34 is Write Random, not Compute File Size.

Files
-----
OUT003, DIO004, IN005, and BUF006 are rerun source probes from Investigations
003-006.  SYS016 checks system state and DMA independence.  BLOCK016 drives
real emulator console blocking and Ctrl-C cases.  SCROLL016.ASM builds the
8.3-safe SCRL016.COM and substitutes deterministic BIOS console routines to
exercise formatted-output Ctrl-S/resume processing.

Build
-----
Use z80asm 2.1:

  z80asm -fb -oOUT003.COM OUT003.ASM
  z80asm -fb -oDIO004.COM DIO004.ASM
  z80asm -fb -oIN005.COM IN005.ASM
  z80asm -fb -oBUF006.COM BUF006.ASM
  z80asm -fb -oSYS016.COM SYS016.ASM
  z80asm -fb -oBLOCK016.COM BLOCK016.ASM
  z80asm -fb -oSCRL016.COM SCROLL016.ASM

The tested assembler is z80asm.  Rebuilding every COM
file produces the SHA-256 values in artifact-hashes.sha256.

Run
---
run-all-console016.sh creates /private/tmp/inv016-runs, copies a fresh pair
of preserved images for every case, invokes run-console016-case.exp, and
records console output, before/after hashes, directory listings, and final
images.  It requires z80pack cpmsim and cpmtools.  cases/ contains the
preserved result of the accepted run.  Each console.txt is the raw transcript.

Evidence notes
--------------
The emulator's red "can't read console" line occurs only when Expect sends
the emulator interrupt after the CP/M prompt has returned.  It is harness
shutdown, not a BDOS result.  ANSI sequences and CR bytes are deliberately
preserved in raw transcripts.  observed-output.txt provides the decoding.

All accepted runs left both disk images byte-identical to their before
images.  images-after contains a representative post-run pair; every case's
post-run pair is also retained under cases/.
