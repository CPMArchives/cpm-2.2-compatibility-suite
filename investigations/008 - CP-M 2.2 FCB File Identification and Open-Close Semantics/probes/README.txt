Investigation 008 probe artifacts
=================================

FCB008.ASM tests BDOS functions 15 (Open File) and 16 (Close File) with
controlled 33-byte sequential FCBs on disposable CP/M 2.2 disk images.

FCB008.COM SHA-256:

  b42b6416579a25b849af29d2001bb239cd4a49853b8dd85e5bae0170e709d95e

Build:

  z80asm -fb -oFCB008.COM FCB008.ASM

The test disk must contain on A:

  OPENME.DAT   a small existing file
  CLOSE.DAT    a one-record disposable file
  LARGE.DAT    more than 128 128-byte records

and on B:

  BFILE.DAT    a small existing file

Install FCB008.COM on A, boot the identified DRI CP/M 2.2 system with both
drives mounted, and run A>FCB008.

Each output record contains the BDOS result followed by bytes 0 through 32 of
the post-call FCB. The DIRTYCL case deliberately changes CLOSE.DAT's record
count on the disposable image from one to two before close, then REOPEN tests
whether it persisted. Do not run this probe against valuable media.

The probe does not patch BDOS, BIOS, or emulator code. It uses no manually
timed input. Raw preparation commands, hashes, observations, interpretations,
and limitations are preserved in observed-output.txt.
