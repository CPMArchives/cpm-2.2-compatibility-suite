INVESTIGATION 038 PROBES

The probes reuse accepted deterministic fixtures from Investigations 004, 018,
and 020 under Investigation 038 names. They temporarily interpose only documented
BIOS vector slots, restore every byte before returning, and require no manual input.

CHAR38.ASM/COM
  Purpose: compare BDOS console, reader, punch and list runtime paths.
  Procedure: supply controlled BIOS bytes, retain a pending console Z, emit raw
  control characters, change IOBYTE, and guard both DMA areas.
  Observation: reader input did not consume/echo console Z; punch/list passed raw
  bytes; console output expanded TAB; IOBYTE changed live; DMA was untouched.
  Conclusion: devices are distinct raw paths; formatted console policy is not
  inherited by reader/punch/list.

STATUS38.ASM/COM
  Purpose: verify BIOS status and direct-call transport.
  Procedure: enumerate the vector and script CONST/LISTST empty/ready values.
  Observation: CONST 00/FF and LISTST 00/FF crossed the vector unchanged.
  Conclusion: callable status is required, but exact LISTST encoding remains a
  profile/policy question rather than evidence manufactured by the fixture.

IOBYTE38.ASM/COM
  Purpose: isolate live device-assignment visibility.
  Procedure: set IOBYTE A5 through BDOS, call a BIOS-facing punch handler, query,
  then restore zero.
  Observation: the handler observed A5 and Function 7 returned A5.
  Conclusion: IOBYTE changes are immediately application/BIOS visible; decoding
  and supported physical assignments belong to the configured BIOS.

BLOCK38.ASM/COM
  Purpose: test readiness, polling and direct-console buffering.
  Procedure: run empty, Function 6 input, Function 11 polling, undocumented FE,
  and raw output modes with deterministic BIOS handlers.
  Observation: empty calls returned zero; 6/FF consumed Z; repeated Function 11
  retained ready state in BDOS; 6/FF did not consume that BDOS pending byte; raw
  output emitted TAB, dollar and Ctrl-P unchanged.
  Conclusion: readiness is a snapshot/polling interface; pending-buffer details
  are DRI behavior, and raw Function 6 output bypasses formatting.

ERROR38.ASM/COM
  Purpose: exercise optional-device boundary values and unavailable-device model.
  Procedure: provide a deliberately out-of-contract reader C1 and capture raw
  punch/list output and results.
  Observation: BDOS passed C1 through rather than masking parity and supplied no
  separate punch/list error result.
  Conclusion: BIOS/profile must supply seven-bit reader/EOF behavior; unavailable
  optional-device failure has no universal richer CP/M error protocol.

Build: ./build.sh
Run:   ./run-all038.sh

The final pending Z displayed at the CCP prompt is intentional evidence that the
DRI Function 11 buffer survived the probe return. The harness then terminates the
emulator without submitting it as a command. Before/after disk images are
byte-identical.

