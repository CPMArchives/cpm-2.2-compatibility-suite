Investigation 070A cross-layer validation probes
================================================

CROSS70A is the accepted I045 cross-layer matrix relabelled for a fresh I070A
run. It is rebuilt from preserved source and exercises CCP loading/return,
page-zero gateways, BDOS version/state calls, alternate DMA directory transfer,
current versus explicit drive, user visibility, direct configured BIOS CONST,
disk reset, DMA restoration, and RET to CCP.

FAULT066 is the accepted I066 physical/logical failure probe, rebuilt from its
preserved source. Modes I and J are ordinary logical EOF/missing-data controls.
Modes A and G arm an isolated emulator's next physical read failure; the harness
selects ignore or Control-C abort, then runs CROSS70A to test recovered service.
The otherwise-unused experimental output port 18 is test equipment, not a CP/M
or BetterCP/M interface.

Build:

  ./build.sh

Harnesses:

  ./run-normal070A.exp DISKDIR LOGFILE
  ./run-logical070A.exp DISKDIR LOGFILE
  ./run-physical070A.exp ignore|abort DISKDIR LOGFILE EMULATOR

Every accepted run starts from a separately preserved before-image. Inputs are
fully scripted. SHA256SUMS.txt is the final artifact manifest.
