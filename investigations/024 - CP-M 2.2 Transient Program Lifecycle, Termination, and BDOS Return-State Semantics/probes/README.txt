Investigation 024 probe suite
=============================

TERM24, BDOS024, and JUMP24 terminate immediately by RET, BDOS Function 0,
and JMP 0000h. STATE24 changes drive to B, user to 1, DMA to 0200h, IOBYTE's
LIST field, and installs safe page-zero vector trampolines before selecting a
termination path from argument R/F/J. OBS24 is the Investigation 023 ENTRY23
binary installed under an 8.3 name; it snapshots the next transient boundary.

FILE24 makes and writes one record without Close. CHECK24 then opens and reads
the mode-specific file. CONSOLE24.COM is installed as CONS24.COM because CP/M
2.2 names are limited to eight characters. BAD24 calls out-of-range BDOS
Function 41. BADSP24 safely demonstrates an invalid RET stack by supplying a
0000h return word, thereby entering WBOOT without uncontrolled execution.

Build all original binaries with `./build.sh`. The rebuild/ directory contains
an independent build; rebuild.sha256 and byte comparisons verify identity.

run-case024.exp, run-state024.exp, run-file024.exp, and run-console024.exp take
a disk directory and transcript path (plus command/mode arguments). Every
accepted case uses a separate copy of images-fixture. No manually timed input
is used. The final emulator I/O diagnostic is caused by the harness interrupt
after the last CP/M prompt and is not guest evidence.

Disk cases that do not write are byte-identical to the fixture. FILE cases
change drive A as expected. Each file becomes visible but remains zero-length:
the write's data/length metadata is not implicitly finalized by any termination
path when Close is omitted.

