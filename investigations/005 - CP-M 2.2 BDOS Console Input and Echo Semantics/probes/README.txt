Investigation 005 probe artifacts
=================================

IN005.ASM tests BDOS function 1 Console Input without manually timed keyboard
input. IN005.COM has SHA-256:

  08044cb19feaa9cabd7904130968b680109c899ff3592712b227cae85966a0e5

Build:

  z80asm -fb -oIN005.COM IN005.ASM

Install IN005.COM on a disposable copy of z80pack's cpm22-1.dsk and run:

  cpmsim -z -d <disposable-disk-directory>
  A>IN005

Deterministic BIOS harness
--------------------------

The probe derives the BIOS base from the page-zero WBOOT jump, saves the
12 bytes comprising BIOS CONST, CONIN, CONOUT, and LIST jump vectors, and
temporarily redirects those vectors to probe-local routines.

The harness:

  * supplies exactly one scripted input byte through CONIN;
  * reports readiness through CONST until that byte is consumed;
  * captures exact characters sent to CONOUT;
  * counts characters sent to LIST; and
  * counts BIOS CONIN calls.

The original vectors are restored before results are printed. This harness
presents deterministic BIOS behavior to the identified DRI BDOS; it does not
claim that probe-local behavior is CP/M, DRI BIOS, or z80pack behavior.

Cases
-----

The probe tests graphic A, TAB at known logical column zero, CR, LF, backspace,
Ctrl-A, Ctrl-P followed by formatted Q, and a Z first retained by function 11
then read by function 1.

Run once with printer echo inactive. For the separate active-echo case, enter
Ctrl-P at the CCP prompt before IN005. Investigation 003 already established
that DRI buffered console input controls this state; the active case here asks
only whether function-1 echo participates in the existing state.

Record layout and both valid raw result sets are in observed-output.txt.
Development runs with identified instrumentation defects are explicitly
rejected there and are not evidence.
