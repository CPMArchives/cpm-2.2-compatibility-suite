INVESTIGATION 051 PROBE README

Purpose
  Compare portable CP/M calls with software that reaches direct ports or
  memory-mapped hardware, including controlled unsupported-profile behavior.

Environment
  Preserved Investigation 049 Mostek CP/M 2.2 emulator and system image.
  Application fixture: hardware-fixture-before.dsk.
  Emulator option -i traps access to unsupported I/O ports.

Build
  z80asm -fb -oBASE051.COM BASE051.ASM

Rebuild verification
  Rebuild BASE051.COM with the command above and compare its SHA-256 or bytes
  with the preserved executable.

Runs
  run-base-control.expect
  run-qterm-unsupported-port.expect
  run-kscope-unsupported-port.expect
  run-viopen-profile-mismatch.expect
  run-prommer-startup.expect (inconclusive; retained for evidence discipline)

For each run, copy hardware-fixture-before.dsk to
work/disks/CPM/comms.dsk before starting. Raw transcripts are in transcripts/.
All after-images from completed tests match the before-image.

Limit
  The tests intentionally establish unsupported-profile behavior. They do not
  emulate or claim a successful Dazzler, VIO, EPROM programmer, or IMSAI modem.
