Investigation 004 probe artifacts
=================================

DIO004.ASM tests BDOS function 6 (Direct Console I/O) and function 11
(Get Console Status).  DIO004.COM has SHA-256:

  375e2e7196808c7f9b9ee29fb8086ce6bf94d565a531aa6fb7bb9b3e3ecb7c4f

Build:

  z80asm -fb -oDIO004.COM DIO004.ASM

Install DIO004.COM on a disposable copy of z80pack's cpm22-1.dsk and run
cpmsim in Z80 mode.  Probe modes are:

  DIO004 E   Empty external input: functions 11, 6/FF, and 6/FE.
  DIO004 6   One scripted BIOS character consumed by function 6/FF.
  DIO004 S   Function 11 pending-buffer interaction with function 6/FF.
  DIO004 F   Undocumented DRI function-6 E=FE status branch.
  DIO004 O   Framed direct-output bytes: A, TAB, $, Ctrl-P, B.

Deterministic input harness
---------------------------

Manual or PTY-timed keystrokes are not evidence for ready-input behavior.
Modes 6, S, and F therefore derive the BIOS base from the page-zero WBOOT jump,
save the three-byte BIOS CONST and CONIN vectors, and temporarily redirect only
those two vectors to probe-local scripted routines.  CONST reports FFh until
CONIN supplies one Z byte, then reports 00h.  The original six vector bytes are
restored before diagnostic output.

This harness does not establish BIOS or emulator behavior.  It supplies a
controlled BIOS contract input to the identified DRI BDOS so the BDOS path can
be measured without timing ambiguity.  Function-6 direct output still passes
through the reference z80pack BIOS CONOUT and host terminal.

Printer echo
------------

For the separate echo test, Ctrl-P was entered at the CCP prompt before
DIO004 O.  printer-echo.txt preserves the logical LIST sink as readable text.
The raw sink omitted CR by z80pack design.  The significant observation is that
the formatted frame reached LIST while the direct-output bytes inside it did
not.

See observed-output.txt and the investigation report for questions, expected
results, interpretations, limitations, and evidence classifications.
