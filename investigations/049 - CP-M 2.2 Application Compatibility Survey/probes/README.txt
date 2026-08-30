Investigation 049 reproducibility notes
=======================================

Purpose
-------
Exercise preserved CP/M 2.2 applications in isolated copies of the local
z80pack Mostek disk set.  No source disk is opened by the emulator.

Local prerequisites
-------------------
- <local-home>/z80pack at the version identified in hashes/source-inputs.sha256
- <local-home>/Library/Mobile Documents/com~apple~CloudDocs/Books/Software/cpm-advent.zip
- make, a C compiler, Expect, and cpmtools

Harnesses
---------
- prepare-fixtures.sh restores system, WordStar, and games working disks and
  removes nonessential WordStar sample/dictionary files for the success case.
- run-wordstar.expect creates B:APP49.TXT, saves it, returns to CP/M, lists it,
  and types its contents.
- run-wordstar-full.expect repeats a save on the unmodified, nearly full
  WordStar distribution disk and stops after the visible E12 disk-full error.
- run-wumpus.expect starts Microsoft BASIC-80 with WUMP.BAS, declines
  instructions, reaches the first move prompt, interrupts BASIC, and returns
  to CP/M.
- run-adventure.expect starts Adventure A02 with seed 123, declines
  instructions, reaches the first location, quits, and returns to CP/M.
- scan_vectors.py reports literal page-zero instruction byte patterns.  It is
  a screening aid, not a disassembler; a match can be embedded data.

Terminal evidence
-----------------
Raw transcript files preserve carriage returns and terminal control bytes.
The WordStar transcript therefore intentionally contains ESC sequences.

Fixture policy
--------------
All writes target copies in work/disks or preserved after-images in probes.
The original z80pack and Adventure files are read-only inputs.  Hashes show
that the Wumpus and Adventure no-save runs leave their application disks
byte-identical.  WordStar success and failure after-images are retained.

Scope limit
-----------
No adequate local spreadsheet, database, communications, or packaged
business-application executable was available.  Those categories were not
executed, and no behavior is inferred for them.

Public-distribution note
------------------------
Microsoft BASIC-80, MicroPro WordStar, and disk images containing either
product are retained in the private research archive but omitted from the
public repository. Test procedures, transcripts, directory listings, and
hashes remain published as the investigation record. Reproduction of those
cases requires lawfully obtained copies of the applications.
