INVESTIGATION 039 PROBES

IOBYTE39
  Purpose: observe byte storage, Functions 7/8, and direct location 0003h.
  Procedure: begin with STAT-selected CRT (01), set A5, query it, let a BIOS-facing
  handler inspect it, and restore 01.
  Observation: Function 7 and 0003h agreed; the handler saw A5 immediately.
  Conclusion: IOBYTE is coherent application-visible runtime state.

DEVICE39
  Purpose: test four logical device paths while assignment changes are live.
  Procedure: run controlled console/reader/punch/list handlers with IOBYTE 01/A5.
  Observation: the selected byte reached BIOS-facing logic; device streams remained
  separate and BDOS did not decode the fields itself.
  Conclusion: BIOS/profile performs physical routing for each logical field.

STAT39
  Purpose: pair raw byte observations with DRI STAT DEV presentation.
  Procedure: the harness runs STAT DEV:, valid CON:=CRT:/TTY:, and invalid BAD:;
  STAT39 supplies a raw state cross-check.
  Observation: STAT decoded 00 as four TTY mappings, 01 as CON=CRT only, rejected
  BAD, and changed only the console field.
  Conclusion: semantic display/assignment is historically visible; exact wording
  and the DRI name table are implementation conventions.

SWITCH39
  Purpose: test reassignment through a transient and warm restart.
  Procedure: set IOBYTE 01 with Function 8, print a marker, invoke Function 0;
  harness then runs STAT DEV:.
  Observation: the tested CBIOS warm path retained CON=CRT.
  Conclusion: runtime changes are immediate, but WBOOT persistence follows the
  configured BIOS initialization policy and is not universally fixed.

BDOS39
  Purpose: test BDOS character functions under changed mappings.
  Procedure: call Functions 3-5 and console paths while BIOS handlers capture the
  live IOBYTE and device bytes.
  Observation: BDOS passed logical calls to BIOS and left mapping interpretation
  there; character functions did not overwrite IOBYTE.
  Conclusion: BDOS follows current BIOS routing rather than caching a private map.

BIOS39
  Purpose: test direct BIOS access with a nondefault assignment.
  Procedure: inspect page zero/IOBYTE and call deterministic direct vector entries.
  Observation: 0003h remained 01 and direct calls worked through the configured
  vector independently of BDOS formatting.
  Conclusion: direct callers may inspect IOBYTE, but whether a BIOS routine consults
  it is part of that BIOS/profile contract.

Build: ./build.sh
Run:   ./run-all039.sh

All console input is scripted. The probes restore temporary vector changes and the
harness restores TTY before exit. Both after-images are byte-identical to their
prepared before-images.

