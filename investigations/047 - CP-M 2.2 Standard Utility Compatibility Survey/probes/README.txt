Investigation 047 deterministic utility survey
================================================

Purpose
-------
Exercise the standard DRI CP/M 2.2 utilities PIP, STAT, ED, ASM, LOAD,
DDT, SUBMIT, and XSUB in one scripted, repeatable reference-system run.

Environment
-----------
z80pack cpmsim 1.39, 64K CP/M 2.2, Z80 CBIOS 1.2.  The run uses private
copies of the preserved IBM-3740 A: and B: images; it does not modify the
z80pack master images.

Run
---
  ./run047.sh

The script restores probes/case from images-before on every invocation,
runs run047.exp, saves the changed disks in images-after, extracts and
checks the PIP copy, and records SHA-256 hashes.  No keyboard input is
required.  Expect terminates the emulator with its normal control-\ exit
after the final prompt; the resulting "User Interrupt" line is a harness
shutdown message, not a CP/M failure.

Rebuild
-------
  ./build.sh

This rebuilds the small IN42 Function-10 consumer with z80asm and compares
it byte-for-byte with the preserved IN42.COM.  HELLO42 is independently
assembled and loaded inside CP/M during run047.sh.  The eight DRI COM files
are preserved distribution binaries; this investigation verifies their
hashes and behavior but does not claim to rebuild DRI's historical toolchain.

Key artifacts
-------------
  run047.exp                         scripted console procedure
  transcripts/utility-survey.txt     complete reference-system transcript
  observed-output.txt                test-by-test findings
  source-analysis.txt                DRI source review
  images-before/, images-after/      preserved disk evidence
  transcripts/COPY47.ASM             extracted PIP result
  transcripts/EDIT47.TXT             extracted ED result
  rebuild-verification.txt           byte-identical fixture rebuild

