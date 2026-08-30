Investigation 006 probe artifacts
=================================

BUF006.ASM exercises BDOS function 10 Buffered Console Input with deterministic
scripted input. BUF006.COM has SHA-256:

  566cc4dfda0483c60c4c747ad7084de2da4ef8dfd0666d5db0441b41ab846cf8

Build:

  z80asm -fb -oBUF006.COM BUF006.ASM

Install on a disposable copy of z80pack's cpm22-1.dsk and run:

  cpmsim -z -d <disposable-disk-directory>
  A>BUF006

Harness
-------

The probe derives the BIOS base from the page-zero WBOOT jump, saves the BIOS
CONST, CONIN, CONOUT, and LIST vectors, and temporarily redirects them to local
routines. CONIN returns bytes from a case-specific script. CONST returns zero,
modeling a console where the next byte becomes available only when blocking
CONIN requests it. CONOUT bytes are captured exactly; LIST and CONIN calls are
counted. Original vectors are restored before reporting.

This arrangement answers line-editor questions without manually timed keyboard
input. It tests DRI BDOS given a valid controlled BIOS behavior; it does not
classify the harness as DRI BIOS, z80pack, or general CP/M behavior.

Cases
-----

  ABC CR             ordinary input and CR termination
  AB LF              LF termination
  CR                 empty line
  ABC, maximum 3     capacity termination
  AB BS C CR         backspace editing
  AB DEL C CR        rubout editing
  A Ctrl-E B CR      physical end of line
  AB Ctrl-U C CR     delete line after new line
  AB Ctrl-X C CR     erase to beginning of line
  AB Ctrl-R C CR     redisplay current line
  A Ctrl-P B CR      printer-echo toggle and buffer exclusion

Ctrl-C warm restart was not invoked by the probe because it does not return to
the case recorder. Its documented beginning-of-line condition and DRI source
path are analyzed in the report. Exact expected and observed results and the
rejected development run are recorded in observed-output.txt.
