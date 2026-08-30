Investigation 003 probe artifacts
=================================

OUT003.ASM exercises BDOS function 2 (Console Output) and function 9
(Print String) without interleaving diagnostic output with measured cases.
It tests:

  * function 2 treating '$' as ordinary output;
  * tab expansion at a known logical column;
  * function 9 using the first '$' as a non-emitted terminator;
  * an empty function-9 string;
  * CR/LF inside a function-9 string; and
  * function 9 sharing function-2 tab processing.

Build:

  z80asm -fb -oOUT003.COM OUT003.ASM

The exact reference environment, expected/observed stream, interpretation,
and limitations are recorded in the report and observed-output.txt.

printer-echo.txt is the raw z80pack logical-printer capture from the separate
control-P printer-echo experiment. z80pack's printer backend omits carriage
returns from this file; the report treats that as an emulator artifact.
