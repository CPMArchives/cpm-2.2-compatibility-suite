Investigation 022 transient lookup/load fixture
===============================================

LOAD22.COM is three records and verifies placement at 0100h, 0180h, 0200h.
MINRET22.COM is a one-byte RET transient. PART22.COM is shorter than one CP/M
record and reports the byte loaded at 017Fh. STATE22 records page-zero drive,
BDOS user, entry SP/return word, and command-tail count.

RET22, F0TERM22, and J0TERM22 terminate by RET, BDOS Function 0, and JMP 0000h.
MARK22 builds four distinct drive/user lookup markers.

BOUND22 plus make-fixtures.sh generate MAXOK.COM (453 records, 57,984 bytes)
and BOUND.COM (454 records, 58,112 bytes). These sizes are specific to the
accepted 62K reference configuration whose resident CCP begins at E400h.

Build sources with `z80asm -fb`. Run make-fixtures.sh
from this directory. The preserved rebuild directory proves byte identity.

run-lookup-load.exp automates patterned/minimal/boundary/user/drive/missing
tests. run-return-path.exp is invoked separately with RET22, F0TERM22, and
J0TERM22. No manually timed input is used.

All disk images are disposable copies. `console-preliminary.txt` preserves
the exploratory boundary run whose files were below the real E400h CCP base;
it is not accepted boundary evidence. `console-boundary-pre-part22.txt` is the
accepted 453/454 boundary run before PART22 was added. `console-main.txt` is
the final accepted matrix.

Every digest in rebuild.sha256 is identical for both the named top-level COM
and its corresponding preserved rebuild/<name>. The byte comparison is part
of the completion audit.
