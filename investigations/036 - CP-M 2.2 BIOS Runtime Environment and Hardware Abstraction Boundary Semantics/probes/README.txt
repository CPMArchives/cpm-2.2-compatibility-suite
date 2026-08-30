INVESTIGATION 036 PROBES

The five named probes are rebuildable, deterministic fixtures derived from the
accepted Investigation 019, 020, and 033 fixtures so that this investigation
can test their combined runtime boundary without altering earlier artifacts.

BIOS36.ASM/COM
  Purpose: enumerate all 17 jump-table entries and test parameter/result
  transport through direct calls.
  Procedure: derive the BIOS base from 0001h, print each JMP entry, temporarily
  interpose deterministic character handlers, call them, then restore vectors.
  Observation: a contiguous FA00h vector of 17 JMP instructions; C reached
  output handlers and A returned status/input bytes.
  Conclusion: the vector is a callable runtime ABI, not merely BDOS internals.

CON36.ASM/COM
  Purpose: isolate console/list/reader/punch direct-call conventions.
  Procedure: run the same controlled vector interposition with known bytes.
  Observation: CONST 00/FF, CONIN 41, READER 52, and C values 09/10/1A reached
  CONOUT/LIST/PUNCH respectively; LISTST bytes crossed unchanged.
  Conclusion: documented register transport is required; device policy and
  undocumented residual registers are not.

DISK36.ASM/COM
  Purpose: observe the BIOS disk boundary and direct SECTRAN/read access.
  Procedure: interpose SELDSK through SECTRAN while BDOS performs controlled
  file operations, then directly select drive/track/sector/DMA and read two
  translated sectors.
  Observation: persistent S/T/C/M setup preceded R/W; write types 0/1/2 were
  visible; direct SECTRAN results fed SETSEC; DMA received 128-byte sectors.
  Conclusion: direct users must follow the stateful documented call sequence.

VECTOR36.ASM/COM
  Purpose: verify public discovery cells independently.
  Procedure: print bytes 0000h-0007h.
  Observation: C3 03 FA at 0000h and C3 06 EC at 0005h.
  Conclusion: the WBOOT operand locates the configured BIOS vector; its absolute
  address and the BDOS target remain configuration-specific.

ERROR36.ASM/COM
  Purpose: distinguish raw BIOS failure from BDOS error presentation.
  Procedure: arm a one-shot emulator physical-read failure and perform the
  controlled read through BDOS; answer the DRI diagnostic with carriage return.
  Observation: the BIOS nonzero result caused the DRI fatal prompt; ignore
  returned to the caller with affected FCB state and unchanged DMA sentinel.
  Conclusion: raw direct callers receive BIOS success/nonzero failure only;
  DRI text, retry/abort/ignore, and warm recovery belong above that boundary.

Build: ./build.sh
Run:   ./run-all036.sh

All input is supplied by run036.exp. Each case starts from fresh image copies.
The custom emulator is preserved in emulator-src/. Full output is in
transcripts/. The normal disk case intentionally changes its A image through
controlled file creation/writes; the injected pre-transfer error case leaves
both images byte-identical.

Evidence limits: the character fixture validates vector dispatch and register
transport, not a physical reader/punch/printer. LISTST encoding and unavailable
optional-device behavior remain unresolved. The local source corpus proves DRI
SYSGEN/XSUB direct-system practice, but does not justify frequency claims for
every third-party software category.

