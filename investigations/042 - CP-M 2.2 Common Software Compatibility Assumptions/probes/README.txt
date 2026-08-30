Investigation 042 experimental corpus
=====================================

scan_vectors.py screens preserved COM executables for literal instruction
sequences associated with public CP/M gateways and direct page-zero access.
Matches can occur in data and are treated as dependency leads, not proof.

HELLO42.ASM is a deterministic 8080 assembly fixture. It is assembled with the
distributed DRI ASM, loaded with DRI LOAD, and executed through the CCP.

RUN42.SUB is a deterministic SUBMIT/XSUB fixture covering command-tail parsing,
explicit-drive FCB handling, STAT, PIP copy, and DUMP output.

IN42.ASM/COM calls BDOS Function 10 without interactive input. During RUN42,
XSUB supplies the following BATCH42 record from A:$$$.SUB. Build with build.sh.

run042.exp and run042.sh restore fresh z80pack disks, install fixtures, execute
the representative software matrix without manually typed input, preserve
before/after images, and capture the complete console transcript.

The terminal I/O diagnostic after the final harness interrupt is an emulator
shutdown artifact, not a CP/M result.
