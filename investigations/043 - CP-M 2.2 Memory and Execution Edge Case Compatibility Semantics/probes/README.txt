Investigation 043 probes
========================

EDGE43 captures the entry stack/return word, switches to an application-owned
stack, verifies BDOS stack balance, self-modifies and executes an instruction,
and writes/reads/restores the advertised last TPA byte.

ZERORET43.ASM builds ZRET43.COM, which uses an application-owned stack whose
return word is 0000h and RETs.
FN043 invokes BDOS Function 0 after adopting a private stack.
OVER43 deliberately derives the DRI CCP base, overwrites its first byte and the
original entry return word, then uses the preserved WBOOT gateway. Its numeric
derivation is a reference-implementation experiment, not a portable interface.
MAXOK43 and MAXBAD43 repeat the accepted/first-rejected loader boundary with
otherwise identical executable prefixes.

Run build.sh, then run043.sh. The latter restores fresh z80pack disks, installs
the probes, preserves before/after images, runs all input deterministically, and
captures the transcript. No manually typed input is required.

The terminal I/O warning after the final harness interrupt is an emulator
shutdown artifact, not CP/M behavior.
