Investigation 015 probes
========================

Investigation 033 extension
---------------------------
READERR33, WRITEERR33, DIRERR33, RECOVER33, and CCPERR33 are named,
rebuildable views over the extended PHYS033 body. Modes K and L add injected
directory Search-read and Delete-write failures. recovery-runs/ proves both
ignore-return and Control-C warm-boot paths can subsequently run DIR and a
healthy sequential read in this reference environment. Each named probe's
purpose/procedure/observation/conclusion is summarized in observed-output-033.txt.
repeated-runs/A-A-N/ arms and ignores two read failures in one session, then
proves that an unarmed healthy read still succeeds.

Contents
--------
PHYS015.ASM/COM              CP/M probe
run-all-phys015.sh           fresh-image orchestration
run-phys015-case.exp         deterministic console harness
build-emulator.sh            rebuilds the local fault-injection cpmsim
emulator-src/                complete source needed for that local build
images-before/drivea.dsk     preserved accepted base image
images-after/                accepted post-run images
cases/                       raw transcripts, hashes, directory listings
observed-output.txt          decoded accepted observations

Probe build
-----------
  z80asm -fb -oPHYS015.COM PHYS015.ASM

Expected hashes:
  PHYS015.ASM  84b2ec892d070f363da5f0590f7a9aa74e379cf4052359124e434e14dd2349d2
  PHYS015.COM  63e560e7de38a7792186831d7757e17ae8b2500d5283806ba559383f30c209d8

Emulator build
--------------
Run ./build-emulator.sh. The preserved source is z80pack 1.39 with only
emulator-src/cpmsim/srcsim/simio.c changed for Investigation 015. Unused output
port 18 arms a one-shot failure: 1 fails the next FDC read; 2 fails the next
FDC write. The injected operation returns the same nonzero CBIOS-visible status
used for host read/write failures, but deliberately performs no media or DMA
transfer. Expected binary SHA-256:

  55c26df111af31e99cecdeeffd0a774ea71c6e0555d618e074e9ef954b303461

This test hook is not proposed as a BetterCP/M interface. It is evidence
instrumentation and is confined to this investigation directory.

Running
-------
./run-all-phys015.sh restores a fresh base for N and A-L under
/private/tmp/inv015-runs. A-F and K/L send deterministic x to exercise the
ignore path. G/H send control-C to exercise abort/warm boot. I/J are ordinary
logical failure controls. No manually typed input is required.

The base image must contain ATTR.DAT, CLOSEME.DAT, DSKFILE.DAT, and PHYS015.COM.
E expects NEW015.DAT not to exist. The accepted base hash is:

  a23a5be8c2850429cae801bbadb940abc5e22540d02f772334d92158bc0aa6d5

Interpretation warning
----------------------
The injector fails before transfer, so unchanged images establish BDOS state
and presentation for that controlled failure point. They do not establish
atomicity for a real controller that reports an error after a partial write.
