Investigation 029 probes

SEARCH29  foundational exact/wildcard/DMA/drive/all-user matrix
MATCH29   exact, filename/type wildcard, lowercase, multi-extent cases
DMA29     complete successful 128-byte DMA record dump
STATE29   continuation across queries/DMA and replacement by new First
USER29    ordinary user filtering and special dr='?' scan
ERROR29   no-match/exhaustion and invalid-drive fatal presentation

Build: run ./build.sh. It requires z80asm.
Fixtures: run ./make-fixtures.sh cases/recreated. It requires cpmtools.
Run: ./run-main029.exp cases/main transcripts/main.txt and
     ./run-error029.exp cases/error transcripts/error.txt.

The expect harnesses supply all commands and the Control-C used to leave the
deliberate invalid-drive DRI fatal handler. No timed keyboard input is used.
The accepted evidence is in transcripts/main.txt and transcripts/error.txt.
Development output preceding the corrected Function 18 selector is excluded.

CP/M numeric note: z80asm treats undecorated numbers as decimal. Function 18
therefore uses `LD C,18`; hexadecimal 12h is the same selector.
