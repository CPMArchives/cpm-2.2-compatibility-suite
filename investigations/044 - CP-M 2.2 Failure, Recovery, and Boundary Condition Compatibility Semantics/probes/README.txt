Investigation 044 probes
========================

FAIL44.ASM/COM is the new returning-failure and boundary probe. It checks a
normal call, missing Open, repeated EOF, random-address overflow, unsupported
selector 41, and console status with no input. build.sh rebuilds it.

WRITE25 and OPEN25 are preserved reference probes from Investigation 025.
WRITE25 distinguishes a full directory from exhausted allocation blocks.
OPEN25 C selects an unavailable drive and enters the DRI operator-error path.

PHYS015 is the extended Investigation 033 physical-error probe. The preserved
instrumented cpmsim and simio.c implement a one-shot pre-transfer read/write
fault using otherwise unused output port 18. This instrumentation is not a
CP/M interface. run-physical044.exp performs an ignored read failure, a second
read failure aborted with Control-C, and then a healthy read in one session.

All harness input is scripted. The emulator terminal warning after the final
Control-\ character is a host shutdown artifact, not CP/M behavior.

Build
-----

  ./build.sh

Run
---

The preserved scripts accept explicit disposable disk directories. The
accepted runs are in transcripts/, with ready before-images and after-images
preserved separately. The full and directory-full cases intentionally use
their corresponding controlled images.

Interpretation
--------------

The fault injector fails before transfer. It proves presentation, caller
suspension, ignore/abort routing, and observed state at that controlled point.
It does not prove atomicity for hardware that reports an error after a partial
write.
