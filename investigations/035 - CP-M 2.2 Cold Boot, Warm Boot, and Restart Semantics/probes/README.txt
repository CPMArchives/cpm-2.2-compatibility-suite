INVESTIGATION 035 PROBES

Purpose
-------
These deterministic CP/M 2.2 probes distinguish cold BOOT, WBOOT,
ordinary RET termination, BDOS Function 0, BDOS Function 13, and the
Control-C recovery path after a physical disk error.

Requirements
------------
  z80asm
  cpmsim
  POSIX sh, Tcl/Expect, cpmtools, and sha256sum or shasum

Build
-----
Run:

  ./build.sh

The script assembles all nine programs. The five required programs are
BOOT35.COM, WARM35.COM, COLD35.COM, STATE35.COM, and RECOVER35.COM.
RET35, FZERO35, RESET35, and PEND35 are supporting fixtures. The source
name RECOVER35 is shortened to RCVR35.COM only when placed on a CP/M
disk, because CP/M filenames have an eight-character basename limit.

The fault-injection emulator is rebuilt with:

  ./build-emulator.sh

Run
---
The preserved images-before/ images contain the probes and controlled
ATTR.DAT fixture. Run the complete matrix with:

  ./run-all035.sh

Each case receives fresh copies of both images. run-case035.exp supplies
all console input; no manually typed input is required. The runner's
temporary output is /private/tmp/i035-runs. The preserved transcripts and
post-run images in this directory were copied from a completed run.

Probe descriptions
------------------

BOOT35
  Purpose: exercise the configured BIOS cold BOOT entry directly.
  Procedure: alter drive, user, DMA, IOBYTE, page-zero bytes, and memory
  markers, then jump to the BIOS BOOT entry derived from the jump table.
  Observation: the BIOS sign-on and CCP prompt reappeared; drive/user,
  IOBYTE, page-zero gateways, and default DMA returned to startup values,
  while markers at 0050h and D000h survived.
  Conclusion: BOOT establishes the public startup environment, but the
  reference implementation does not blanket-clear memory.

WARM35
  Purpose: exercise the documented warm-start vector.
  Procedure: alter the same state and jump to 0000h.
  Observation: CCP resumed on drive B/user 7, page-zero gateways and the
  default DMA were reconstructed, and ordinary memory markers survived.
  Conclusion: WBOOT reconstructs the command environment; arbitrary
  residual memory and all private state are not a portable contract.

COLD35
  Purpose: snapshot application-visible boot state.
  Procedure: query drive, user, login/read-only vectors, pointers and
  console state; inspect page zero and memory; prove the active DMA by a
  directory search.
  Observation: see transcripts/cold.txt.
  Conclusion: the configured cold boot produced a usable CCP/BDOS/BIOS
  environment with drive A, user 0, valid gateways, and DMA 0080h.

STATE35
  Purpose: make identical observations after each transition.
  Procedure: run from user 7 on A while allowing the selected drive to
  remain B; query and inspect the same state as COLD35.
  Observation: see ret.txt, fzero.txt, warm.txt, and error.txt.
  Conclusion: RET is observably different from WBOOT; Function 0, JMP
  0000h, and error-abort recovery converge on the tested WBOOT result.

RECOVER35
  Purpose: observe restart after a real BIOS read failure.
  Procedure: open the fixture, select B/user 7, mutate state, arm one
  injected physical read fault, then answer the DRI error prompt with
  Control-C.
  Observation: DRI printed "Bdos Err On B: Bad Sector", did not return to
  the probe, and resumed at the CCP with WBOOT-reconstructed gateways.
  Conclusion: the tested DRI abort branch joins warm restart; retry and
  BIOS-dependent alternatives are outside this single result.

Supporting fixtures
-------------------
RET35 returns normally after mutation. FZERO35 invokes BDOS Function 0.
RESET35 isolates BDOS Function 13. PEND35 detects an offered character
without consuming it and then warm-boots. COMMON35.INC, OBS35.INC,
MUTATE35.INC, and PHYS035.INC contain shared routines/data.

Evidence limits
---------------
The direct BOOT call is an entry-point test, not a power-cycle or ROM
loader test. Login-vector observations after a CCP command include drives
used to locate that command. Console pending-input behavior is one BIOS
and emulator observation. Disk-error results apply to the injected read
failure and Control-C choice only.

