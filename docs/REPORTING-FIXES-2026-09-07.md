# Development reporting and batch cleanup repairs — 2026-09-07

These are uncommitted development fixes following a BetterCP/M compatibility run, not a new suite release. Test classifications and success criteria have not been relaxed.

- Failure-list routines in BDOSTEST, CCPTEST, CONSTEST, DIRTEST, DISKTEST, ENTRYTST, FILETEST and RANDTEST now fetch their loop count after printing the heading. BDOS console calls may destroy BC.
- FILETEST and RANDTEST also preserve the failure-list pointer around separator output. Otherwise a second failure number could come from unrelated memory.
- BDOSTEST, CCPTEST, ENTRYTST and DIRTEST no longer include observations in their required-pass totals.
- DIRTEST 0294 and 0307 restore the incoming default drive. Previously they selected B on exit, causing later fixture searches to run on the wrong disk. The five affected later rows (0545, 0546, 0559, 0561, 0566) passed alone and now also pass in the batch.

All thirteen COM programs were rebuilt using ZSM4 and DRI LINK under z80pack; each assembly reported zero errors. `suite/build/SHA256SUMS.txt` identifies the edited sources and matching COM files. Preserved release archives were not replaced.

Emulator evidence is retained in the companion BetterCPM repository under `build/compatibility/run-20260907-*`. BDOSTEST now reports 56 required passes and 14 observations, rather than 70 passes. ENTRYTST's formerly corrupt failure list was checked on a failing intermediate core and printed only the correct selector, 0603. FILETEST likewise printed only 0253 on an intentionally unsuitable fixture, then passed with a directory-full D disk. This separates reporting repairs from changes to the system under test.


## Follow-up campaign, 7-8 September

CCPTEST now accepts the documented second operand for `/0013` so that
`CCPTEST /0013 B:ALPHA.TXT` can actually exercise the default-FCB oracle.
Other selectors retain strict trailing-operand rejection.

ERRTEST 0408 incorrectly demanded Close return zero. The ledger explicitly
permits directory slots 0..3 (and FILETEST tests those slots). Added probe
files moved the temporary file off slot zero, exposing this fixture-dependent
false failure and its dependent 0582 result. The check now accepts only 0..3.
No conformance proposition was relaxed.
