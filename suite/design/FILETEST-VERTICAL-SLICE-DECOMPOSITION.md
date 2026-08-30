# FILETEST First-Slice Proposition Decomposition

This specification decomposes four candidate source seeds into exact frozen proposition scenarios. It contains 43 mapped cases; 38 are selected for the first read-oriented slice and 5 are explicitly deferred.

## Source conclusion

`FCB008` and `READ010` contain the strongest directly adaptable scenario logic. `OPEN30.ASM` merely includes the full `WRITE011.INC` program; its reopen observations require prior mutation and are deferred from the read-only slice. `OPEN31.ASM` merely includes `DELREN012.INC`; despite its purpose comment, the included program does not isolate the two ordinary cross-user Open scenarios required by ledger 0561 and 0562. Those scenarios are classified `MISSING_NEW_SCENARIO`, not credited to the old binary.

Support totals are {'DIRECT_ADAPTABLE': 31, 'COMPOSED_ADAPTABLE': 1, 'FRAMEWORK_ANTI_ASSERTION': 2, 'ADAPTATION_ADDS_GUARDS': 1, 'FRAMEWORK_VARIATION_RULE': 3, 'DEFER_UNDEFINED_INPUT': 2, 'DEFER_HARNESS_PROFILE': 1, 'MISSING_NEW_SCENARIO': 2}.

## Selected scope

- `OPEN`: existing default/explicit drive, missing, wildcard-first activation, lifecycle prerequisite, diagnostic reserved-byte handling.
- `CLOSE`: activated unchanged Close, dirty missing-name failure, and permitted variation for unchanged read-only-use state.
- `SEQREAD`: activated-FCB use, success and 128-byte guarded DMA, alternate DMA, record/CR progression, extent transition, EOF families, explicit drive and read-only file.

Physical fault presentation, unopened/invalid FCB diagnostics, and the missing cross-user Open scenarios are deferred. Deferment is `NOT_RUN`, not `PASS`, `NOT_APPLICABLE`, or `BLOCKED`.

## Selector and dependency rules

Every TSV row has `/NNNN`, frozen `/CASE:...`, and `/GROUP:...` selectors. `/NNNN` is the canonical hobbyist/debugging shorthand. Selection expands before execution. Shared setup may be reused, but every selected ledger case receives its own evaluator and record. The exact BDOS function list is a minimum operational dependency; RC1 parent dependencies remain separately recorded and must be refined to runnable prerequisite case IDs during implementation.

## Fixture contract

The first slice consumes a pristine, host-built fixture and does not require BDOS Make, Write, Delete or Rename. Reserved fixture names are suite-specific and recorded in a manifest with image and per-record hashes. The executable uses guarded FCB and DMA work areas, saves the default drive/user/DMA environment where the available public calls permit it, restores changed state on every returning path, and reports restoration failure as `ERROR`.

## Implementation order

1. Selector expansion and `/LIST` from the TSV-derived compact table.
2. Report writer capable of preserving a record before the next scenario.
3. Guarded FCB and DMA helpers plus fixture-manifest verification.
4. `OPEN`, then `SEQREAD`, then `CLOSE` evaluators.
5. Host parser and exact coverage audit for all selected rows.
6. DRI CP/M 2.2 reference run, independent implementation run, and induced framework/candidate failures.

No source probe or binary is approved unchanged. The scenario table is the implementation contract for the vertical slice; the frozen RC1 oracle remains normative.
