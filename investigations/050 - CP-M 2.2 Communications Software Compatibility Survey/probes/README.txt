INVESTIGATION 050 PROBE README

Purpose
  Deterministically exercise a representative CP/M 2.2 communications corpus
  and preserve evidence at the standard-interface, BIOS-device, and direct-port
  layers.

Environment
  Emulator: preserved Mostek CP/M 2.2 emulator from Investigation 049
  System disk: z80pack Mostek CP/M 2.2 image, copied before every run
  Application disk: probes/comms-fixture-before.dsk or
                    probes/imsai-apps-fixture-before.dsk
  Input driver: Expect scripts in this directory

Reproduction
  1. Copy the relevant before-image to work/disks/CPM/comms.dsk.
  2. Ensure work/disks/CPM/system.dsk and work/roms/MostekROM.bin are present.
  3. Run the corresponding run-*.expect script from any directory.
  4. Compare the raw transcript and disk SHA-256 with the recorded artifacts.

Tests
  run-kermit-startup.expect       T01 startup/version/show
  run-kermit-connect.expect       T02 standard logical-device connection
  run-kermit-nopeer.expect        T03 no-peer send and abort
  run-kermit-capabilities.expect  T04 unsupported speed/missing-file failures
  run-kermit-files.expect         T05 local file operation
  run-qterm-profile.expect        T06 wrong-profile direct-port behavior
  run-xmodem-interface.expect     T07 BIOS RDR/PUN path and no-peer boundary

Notes
  T02 uses a BIOS whose RDR/PUN entries alias the console, so it does not prove
  independent serial hardware. T06 intentionally runs an IMSAI-patched binary
  on a nonmatching machine. T07 is bounded and intentionally halted after the
  no-peer state; it is not a successful transfer claim.

  The supplied RZ.COM, SZ.COM, and Kermit3 material is CP/M 3 evidence and is
  excluded from CP/M 2.2 execution conclusions.

Public-distribution note
  QTERM 4.3e, its supplied documentation and patch material, and disk images
  containing QTERM are retained in the private research archive but omitted
  from the public repository. The executable identifies itself as copyright
  DPG 1991, all rights reserved. The test harness, transcript, analysis, and
  hashes remain published as evidence; rerunning T06 requires a lawfully
  obtained QTERM distribution.
