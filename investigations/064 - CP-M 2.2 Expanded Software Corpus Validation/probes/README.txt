Investigation 064 reproduction

Requirements: z80pack cpmsim 1.39, expect, cpmtools with ibm-3740 format.

The pinned historical binaries are under ../downloads. Run ./run-tests.sh to
create five fresh image pairs and execute the normal, failure, and processor-
boundary cases. No manual input is required. The script extracts the generated
FORTRAN HELLO.COM for hashing.

Raw console transcripts include ANSI terminal control sequences and emulator
shutdown diagnostics. A scripted Control-\ stops each case after the relevant
observation; it is not CP/M behavior. T03 and T05 are deliberately bounded
after the product did not return to CCP.

The test does not claim successful spreadsheet, database, business, BBS,
printer, paired-communications, or matching-hardware behavior.

Public-distribution note
------------------------
Microsoft FORTRAN-80 and FORLIB, Borland Turbo Pascal, generated output that
may incorporate their runtimes, and all disk images containing those products
are retained in the private research archive but omitted from the public
repository. The source fixtures, scripts, transcripts, listings, hashes, and
analysis remain available. Reproduction requires lawfully obtained copies of
the historical compilers.
