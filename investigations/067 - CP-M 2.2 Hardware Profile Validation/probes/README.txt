Investigation 067 hardware-profile validation
=============================================

This directory preserves fresh I067 controls plus copied I051/I065 evidence
needed for matched and mismatched peripheral cases.

Fresh probes:

  BASE051.ASM/.COM  portable BDOS Function 9/12 control
  CPU8080.ASM/.COM  documented Intel 8080 instruction control
  CPUZ80.ASM/.COM   documented Z80-profile discriminator

Build:

  z80asm -fb -oBASE051.COM BASE051.ASM
  z80asm -8 -fb -oCPU8080.COM CPU8080.ASM
  z80asm -fb -oCPUZ80.COM CPUZ80.ASM

Run:

  ./run-all067.sh

The Cromemco and IMSAI emulators open local device sockets and may require
permission outside a restricted sandbox.  Every run uses copied profiles and
disposable images; no source z80pack or BetterCP/M file is changed.

Records:

  hardware-profile-corpus.tsv
  hardware-profile-validation-records.tsv
  observed-output.txt
  transcripts/
  images-before/ and images-after/
  listings/
  reference/ (copied prior experimental transcripts/peer log)

The failed initial socket-bound run and two IMSAI harness-alignment attempts
are not evidence records; the accepted transcripts are the final files named
in the records.  T02's disk difference is caused by startup submit processing,
not by the read-only BASE051 probe; directory listings are preserved.
