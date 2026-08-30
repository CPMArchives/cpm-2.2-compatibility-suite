INVESTIGATION 065 PROBE README

Purpose
  Validate a named CP/M communications profile with machine-matched QTERM,
  a controlled serial peer, successful XMODEM, retry, disconnect, unavailable
  endpoint, and two configured baud settings.

Environment
  probes/imsaisim is an isolated arm64 build of z80pack IMSAI simulator 1.19
  using Z80 core release 1.39. The system is DRI CP/M 2.2 B03. QTERM 4.3e
  is the IMSAI/VT100 patch from the z80pack communications disk. SIO2A is
  attached to /tmp/.z80pack/imsaisim.sio2.

Reproduction
  1. Copy images-before/system.dsk and images-before/communications.dsk to a
     work/disks directory as drivea.dsk and driveb.dsk; copy disk.map there.
  2. Supply the preserved IMSAI ROM directory (not duplicated here; its input
     hash and provenance are recorded) or point -r at z80pack/imsaisim/roms.
  3. Run the corresponding .exp script with the arguments printed by running
     it without arguments. Local Unix-socket creation may require permission.
  4. Compare the transcript, peer log, received bytes, disk images, and hashes.

Tests
  run-terminal065.exp    T01/T06 normal byte exchange at 9600 or 1200
  run-xmodem065.exp      T02/T03 normal transfer or injected NAK
  run-xmodem-interrupt065.exp T07 peer loss during an unacknowledged transfer
  run-disconnect065.exp  T04 forced peer loss
  run-unavailable065.exp T05 no connected peer

Interpretation cautions
  T04 and T05 are bounded and harness-terminated. T01/T06 are also stopped
  after the measured exchange; they do not claim application return. T07 is
  stopped after 15 seconds without completion. T02/T03
  alone establish completed protocol transfer and CCP return. Configured baud
  labels are not proof of physical timing. QTERM's ports are IMSAI-profile
  behavior, not generic CP/M.
