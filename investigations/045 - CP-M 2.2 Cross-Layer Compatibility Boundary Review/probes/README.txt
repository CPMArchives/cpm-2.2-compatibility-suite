Investigation 045 probes
========================

CROSS45.ASM/COM is the cross-layer state and transition probe. It captures the
page-zero WBOOT and BDOS targets, calls BDOS, changes DMA, searches a directory,
crosses current-drive and user-area state, uses an explicit-drive FCB, invokes
BIOS CONST through the configured jump table, resets disk state, restores DMA,
and returns to CCP.

PHYS015.ASM/COM and the preserved instrumented cpmsim/simio.c come from the
accepted Investigation 044 physical-error instrumentation. The unused output
port 18 injects one pre-transfer physical failure. It is test equipment, not a
CP/M interface.

build.sh rebuilds CROSS45. run-normal045.exp runs the normal/boundary matrix.
run-failure045.exp injects one ignored physical read failure, a second failure
aborted with Control-C, and then runs CROSS45 in the recovered environment.
All input is scripted. The terminal warning after the final harness interrupt
is a host emulator shutdown artifact.

Before-images are ready-to-run images after probe installation. After-images,
full transcripts, directory listings, and hashes are preserved. The physical
fault injector fails before transfer and cannot establish general partial-write
atomicity.
