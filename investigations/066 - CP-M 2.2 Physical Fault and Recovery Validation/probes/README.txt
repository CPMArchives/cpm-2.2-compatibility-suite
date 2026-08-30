Investigation 066 deterministic physical-fault validation
=========================================================

FAULT066.COM runs under the preserved z80pack cpmsim 1.39 / Z80 CBIOS
1.2 environment.  base066.dsk is a restored IBM-3740 CP/M 2.2 image.
Every case starts from a fresh copy.

Build the probe:

  z80asm -fb -oFAULT066.COM FAULT066.ASM

Build the isolated emulator:

  cd emulator-src/cpmsim
  make clean
  make

Run the matrix (requires expect, cpmtools, and the built emulator):

  ./run-all066.sh

Instrumentation uses otherwise-unused emulated port 18:

  OUT 1  fail the next physical read before transfer
  OUT 2  fail the next physical write before transfer
  OUT 3  perform the next physical write, then report status 6

These values are experimental controls, not CP/M or BetterCP/M APIs.
Port 3 proves only a completed physical write followed by an error report;
it does not model a torn sector.

Case map:

  T01 normal read
  T02 pre-transfer read failure, ignore
  T03 pre-transfer write failure, ignore
  T04 repeated failures followed by normal I/O
  T05 ignore recovery
  T06 control-C abort recovery
  T07 unavailable explicit drive B
  T08 write-then-error, ignore
  T09 write-then-error, control-C abort

T07 captured two repeated prompts, then the harness timed out.  It does not
claim a completed abort/recovery path; T06 independently validates abort.

Artifacts:

  fault-validation-records.tsv  complete required validation records
  observed-output.txt           concise observed results
  cases/Tnn/console.txt         raw console transcript
  cases/Tnn/drivea.dsk          post-run image
  cases/Tnn/{before,after}.sha256
  cases/Tnn/directory.txt       post-run CP/M directory
  cases/Tnn/*.dat,*.sha256      extracted test files and hashes
  artifact-sha256.txt           final artifact manifest
  rebuild-*.sha256, rebuild.diff byte-identical rebuild audit
  protected-*.sha256/diff       no-prior-file-change audit
