Investigation 017 probe suite
=============================

STATE017.ASM/COM records raw Function 24, 27, 29, and 31 results across
controlled Function 13, 14, 28, and 37 transitions. It then temporarily
changes one byte through each returned pointer (restoring it immediately),
and records the allocation vector across Make, one sequential Write, Close,
and Delete of ST017.DAT.

Build
-----
  z80asm -fb -oSTATE017.COM STATE017.ASM

The accepted build used z80asm 2.1. `rebuild.sha256` records byte-identical
rebuild verification.

Run
---
Install STATE017.COM on a copy of images-before/drivea.dsk, keep driveb.dsk
beside it, then run:

  ./run-state017.exp /path/to/disk-directory console.txt

The harness uses z80pack cpmsim and requires no keyboard timing. The accepted
raw transcript is transcripts/console.txt. Before/after images and hashes are
preserved. The probe restores temporary RAM changes; its Make/Write/Close/
Delete sequence intentionally changes directory media bytes even though the
file is absent after the run.

The allocation-vector length is derived from DPB DSM as floor(DSM/8)+1. On
this test geometry DSM=242, so 31 bytes are captured. The DPB is 15 bytes.
Exact addresses and geometry are diagnostic observations, not requirements.
