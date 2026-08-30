Investigation 048 deterministic development-toolchain survey
============================================================

Purpose
-------
Exercise CP/M 2.2 development workflows using preserved assemblers, macro
assemblers, relocatable objects, a linker, loader, debuggers, batch command
processing, explicit-drive files, and one generated-file boundary case.

Environment
-----------
z80pack cpmsim 1.39, 64K CP/M 2.2, Z80 CBIOS 1.2.  All tests use private
copies of the preserved A: and B: images.  No keyboard input is required.

Run
---
  ./run048.sh

The script restores probes/case from images-before on every invocation,
runs run048.exp, extracts generated COM and REL files, compares the direct
and SUBMIT builds, checks successful LINK temporary-file cleanup, and saves
before/after disk hashes and directory listings.

Repeatability
-------------
Three fresh-image runs completed.  The second and third after-images were
byte-identical.  The first two transcripts were semantically identical after
removing emulator-only shutdown address/timing text.  DEV48.COM and the
batch-built BATCH48.COM are byte-identical.

Coverage
--------
  ASM -> HEX -> LOAD -> COM
  MAC macro expansion -> HEX -> LOAD -> COM
  RMAC modules -> REL -> LINK -> COM
  linked external resolution
  three-record linked COM boundary
  undefined external diagnostic/recovery
  DDT and SID load/display/breakpoint/restart
  SUBMIT-driven relocatable rebuild
  runtime smoke test of a locally supplied Hi-Tech-C-generated COM

No compiler executable with adequate provenance was available.  SPEED.COM
is runtime evidence only; this investigation does not claim to have compiled
it.  M80/L80, Z80ASM/SLRNK, and ZSID are preserved comparative binaries and
had startup evidence from I042, but their complete workflows were not rerun.

The final colored "can't read console" / "User Interrupt" lines are produced
when Expect ends cpmsim with control-backslash after the final A> prompt.
They are harness shutdown messages, not CP/M or tool failures.

Public-distribution note
------------------------
Microsoft CREF80 and LIB80, and disk images containing the Microsoft Macro-80
tool family, are retained in the private research archive but omitted from the
public repository. The textual observations, listings, and hashes are kept so
the historical result remains reviewable. Reproduction requires a lawfully
obtained Macro-80 tool set.
