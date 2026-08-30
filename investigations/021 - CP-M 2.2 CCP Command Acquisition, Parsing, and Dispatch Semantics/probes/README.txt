Investigation 021 CCP parser and dispatch fixture
=================================================

PARSE21 prints the externally supplied command-entry drive byte, first and
second default FCB identity/control prefixes, and counted command tail. It is
used only to connect the common CCP parser to Investigation 001's established
transient-entry results.

MARK21 prints a unique harmless marker and returns. Identical bytes are
installed under DIR.COM, TYPE.COM, and SAVE.COM on disposable images, and as
DIR.COM in user 1 and on B:, to distinguish resident dispatch from transient
execution.

Build:

  z80asm -fb -oPARSE21.COM -lPARSE21.lst PARSE21.ASM
  z80asm -fb -oMARK21.COM -lMARK21.lst MARK21.ASM

Install on fresh IBM-3740 image copies with cpmcp. The accepted fixture has
PARSE21.COM and the three marker aliases on A:, and PARSE21.COM/DIR.COM on B:.

Run:

  ./run-ccp021.exp /path/to/disk-directory transcripts/console-main.txt
  ./run-invalid-drive.exp /path/to/fresh-copy transcripts/console-invalid-drive.txt

Both harnesses queue exact bytes without manual input. The invalid-drive
harness responds deterministically to DRI's fatal Select handler and verifies
the following warm-start prompt.

`command-corpus.txt` is the canonical input description. Raw terminal output
is preserved separately from `observed-output.txt` interpretation. The final
emulator control-\ shutdown diagnostic is not CP/M evidence.
