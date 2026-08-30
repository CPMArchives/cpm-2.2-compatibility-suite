Investigation 034 probes
========================

Purpose
-------
These deterministic CP/M 2.2 programs measure the application-visible memory
environment without treating the reference system's numeric addresses as
portable constants.

Required probes
---------------
MEM34.ASM/COM     derives the resident boundary, tests the last advertised TPA
                  byte with restoration, and reports reference boundary bytes.
ZERO34.ASM/COM    captures all 256 page-zero bytes before and after Function 12.
LOAD34.ASM/COM    reports small-COM loaded records and selected boundary bytes.
STACK34.ASM/COM   captures entry SP, RET word, and eight stack bytes, then uses
                  a private stack and finally terminates through the saved RET.
VECTOR34.ASM/COM derives BIOS from WBOOT, calls BIOS CONST directly, and calls
                  BDOS through 0005h.

Additional fixtures
-------------------
OVR34.COM temporarily overwrites the reference CCP base E400h and the derived
last TPA byte, then uses JMP 0000h. It deliberately does not return through the
overwritten CCP and demonstrates WBOOT recovery. OVERLAY34.ASM is its source.
LARGEOK.COM is 453 records and executes. TOOLARGE.COM is 454 records and must be
rejected by the configured DRI CCP. LARGE34.ASM supplies their executable header.

Build
-----
Run ./build.sh. It uses z80asm, expands COMMON34.INC, and
generates the two record-sized fixtures. The recorded rebuild-before.sha256 and
rebuild-after.sha256 files must be identical; rebuild.diff must be empty.

Run
---
run034.exp starts cpmsim against a disposable
directory containing the preserved drive images. It performs the complete
matrix without manually typed input. The accepted transcript is
transcripts/main.txt.

Interpretation limits
---------------------
The numeric E400h CCP, EC06h BDOS entry, and FA00h BIOS describe this 62K
reference configuration only. Writing E400h is safe in this probe solely because
OVR34 has already adopted a private stack and exits through WBOOT. The six bytes
EC00h-EC05h are DRI serialization data below the entry and are reloaded by WBOOT.
Do not run it
on another configuration without adapting the CCP address. The portable boundary
is derived from page zero, not hard-coded.
