Investigation 041 probe corpus
================================

Purpose
-------
These probes distinguish documented CP/M 2.2 gateways and data locations
from direct, implementation-specific access behind those gateways.

Probe inventory
---------------
BDOS41   Calls representative BDOS functions through 0005h and records the
         register/stack observations established by Investigation 027.
BIOS41   Derives the BIOS vector from the 0000h WBOOT jump, inspects all 17
         entries, directly exercises character vectors under deterministic
         fixtures, and restores every patched vector.
ZERO41   Snapshots documented page-zero fields before and after BDOS Function 12.
VECTOR41 Records the two page-zero JMP gateways.
MOD41    Reversibly interposes the 0005h JMP, chains its saved target, counts one
         call, and restores the original three bytes.
DIRECT41 Deliberately calls the private target stored at 0006h, then calls direct
         BIOS SELDSK with invalid drive FFh. It is isolated in the failure run.

Build
-----
Run ./build.sh in this directory. It uses z80asm unless
Z80ASM names another compatible assembler. The generated .lis files are build
listings. The completion audit compares rebuilt COM files byte-for-byte.

Run
---
Run ./run041.sh. It restores fresh z80pack drive images, installs the probes on
drive A, preserves before-images, runs the normal matrix and isolated failure
case, preserves after-images, and records SHA-256 values. No typed input is
required. The expect harness supplies deterministic console characters and
terminates the emulator after the intended observation.

Interpretation cautions
-----------------------
The terminal I/O diagnostic follows deliberate harness interruption after the
last observation; it is not a CP/M result. DIRECT41's private BDOS call is an
observation of this DRI layout only. The invalid direct SELDSK result is a raw
BIOS-boundary observation and supplies no higher-level BDOS/CCP recovery promise.

