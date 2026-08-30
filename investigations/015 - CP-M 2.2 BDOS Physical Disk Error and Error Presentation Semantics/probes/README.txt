Investigation 015 probes
========================

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
  PHYS015.ASM  5d21b7fe1144a29789893d39fd1f56a55b04caaf174dff7ad23d723972bb3e5c
  PHYS015.COM  fd4f4d92f42dbed18f9e8ecaa6680f6661ee9ba03f4f1f45bad596073daa099a

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
./run-all-phys015.sh restores a fresh base for N and A-J under
/private/tmp/inv015-runs. A-F send deterministic x to exercise the documented
ignore path. G/H send control-C to exercise abort/warm boot. I/J are ordinary
logical failure controls. No manually typed input is required.

The base image must contain ATTR.DAT, CLOSEME.DAT, DSKFILE.DAT, and PHYS015.COM.
E expects NEW015.DAT not to exist. The accepted base hash is:

  9d07cd7d4954cdfff268ce7698b3faf393c25a1b4785de81ffdfbcf5f8fc5d77

Interpretation warning
----------------------
The injector fails before transfer, so unchanged images establish BDOS state
and presentation for that controlled failure point. They do not establish
atomicity for a real controller that reports an error after a partial write.
