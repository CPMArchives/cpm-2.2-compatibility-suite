# Investigation 046 - CP/M 2.2 Compatibility Boundary Closure and Remaining Gap Analysis

Evidence classes are **A** documented CP/M behavior, **B** behavior of the examined Digital Research implementation/software, **I** controlled experimental observation, and **D** unresolved BetterCP/M policy.

## 1. Objective and scope

This investigation determines whether the evidence series through I045 covers the observable boundaries needed for a high-compatibility CP/M 2.2 environment, whether the ledger itself contains gaps or conflicts, and what focused work remains.

It is a closure review, not a BetterCP/M design or implementation exercise. It validates selected unresolved boundaries but does not promote undocumented DRI behavior without software or documentary evidence.

## 2. Compatibility standard

**REQUIRED** behaviors are documented or evidenced practical software dependencies. **NOT GUARANTEED** behaviors remain unsafe portable assumptions. **NOT REQUIRED** behaviors are private mechanisms whose public results may be implemented differently. **POLICY PENDING** marks deliberate compatibility-profile decisions still requiring ecosystem evidence or project choice.

Closure means that major observable boundaries are identified and classified; it does not mean every policy choice has been decided or every historical hardware profile tested.

## 3. Relationship to previous investigations

I001-I040 establish entry, CCP, BDOS functions, BIOS, character/disk devices, FCB/filesystem, storage geometry, lifecycle, error handling, and memory. I041 distinguishes public from private direct-system access. I042 tests standard ecosystem assumptions. I043 covers execution edges and self-modification. I044 consolidates failures. I045 verifies cross-layer composition.

I046 uses the authoritative ledger through I045, reviews its complete 0001-0622 number range, and targets remaining CCP entry-state and undocumented-selector policies experimentally.

## 4. Coverage review

All major observable interface families have direct investigation coverage:

| Area | Covered boundary |
|---|---|
| CCP | command acquisition, parsing, resident commands, transient lookup/load/dispatch, SUBMIT |
| Entry/lifecycle | page zero, FCBs/tail, registers/stack, RET, Function 0, WBOOT, recovery |
| BDOS | selectors 0-40, conventions, console/system/file/directory/random operations, errors |
| BIOS | jump table, boot, character and disk ABI, IOBYTE routing, logical sectors |
| Storage | DPH/DPB/ALV, extents, directory/allocation, geometry/translation, direct access |
| Memory | configured TPA, loader ceiling, resident ownership, overlays, self-modification |
| Ecosystem | CCP, SUBMIT/XSUB, DDT, SYSGEN, STAT, representative utility assumptions |
| Failures | logical results, exhaustion, read-only, physical errors, ignore/abort/recovery |
| Cross-layer | CCP-BDOS-BIOS-storage-memory-state and healthy post-recovery composition |

**Conclusion:** no major CP/M 2.2 observable subsystem boundary lacks an investigation. Coverage is sufficient to begin compatibility decisions and implementation planning, subject to the named policy/profile choices below.

## 5. Ledger analysis

The mechanical audit found 652 entry lines, 622 unique entry numbers, no missing number from 0001 through 0622, and 445 REQUIRED, 109 NOT GUARANTEED, 48 NOT REQUIRED, and 50 POLICY PENDING entry lines.

It also found a concrete editorial defect: entries 0248-0277 and their Investigation 011 heading appear twice consecutively. The two blocks carry the same propositions, dispositions, evidence, and conformance requirements. Entry 0276 therefore also duplicates one POLICY PENDING line. Entries 0435 and 0523 separately state the same unresolved Function-37 question with agreeing dispositions. Entries 0012/0506 overlap on the second default FCB but differ in proposition scope.

No duplicated proposition has conflicting classification. The correction is to remove the second 0248-0277 block and consolidate/cross-reference Function 37 in a future authorized ledger-maintenance operation. This report does not edit the ledger.

## 6. Software ecosystem review

The investigated corpus covers the most compatibility-revealing categories available locally: DRI CCP and utilities, submission/input interception, debugger breakpoints/self-modification, direct BIOS system-generation tools, DPB-consuming utilities, assemblers/linkers, editors, and conventional BDOS applications (**B/I**).

This evidence establishes practical dependencies on documented gateways, FCB/DMA semantics, writable/executable TPA, page-zero hooks used by standard XSUB/DDT, configured BIOS structures used by SYSGEN, and coherent lifecycle/recovery. It does not establish dependencies on every exact prompt, control-character rendering, incidental register, or private handler.

The current corpus is sufficient for the major compatibility contract. A larger quantitative application corpus is still useful for resolving POLICY PENDING presentation and undocumented-convention choices; that is targeted validation, not discovery of a missing subsystem.

## 7. Remaining compatibility gaps

The unresolved items fall into bounded groups:

1. **CCP/entry presentation:** exact second-FCB obligation, unopened control-field values, leading blank/case/NUL tail representation, input/tail capacity, exact prompts/errors, TAB handling, and post-termination drive/user details.
2. **Console edge behavior:** logical-column rules, retained pending keys, pause/Ctrl-C/Ctrl-P interactions, seven-bit masking, correction-display bytes, and exact status value.
3. **Undocumented/reserved calls:** Function 37 strict-profile status, Functions 38/39 private zero behavior, LISTST and active IOBYTE policy.
4. **File/error edge presentation:** exact EOF/write codes where manuals/evidence differ, wildcard Rename, physical Delete/Rename cases, unavailable-drive and Bad Sector text/ignore policy.
5. **Profiles/extensions:** structured headless errors, optional protection/clearing, extension selectors, named raw storage profiles, and natural partial-transfer fault behavior.

These gaps are already visible and classified. Most are **D POLICY PENDING** or intentionally **NOT GUARANTEED/NOT REQUIRED**. None blocks defining the baseline documented ABI; some must be decided before claiming a particular strict-compatibility profile.

## 8. Experimental validation

GAP46 was invoked as `GAP46 FIRST.TXT SECOND.BIN` under z80pack CP/M 2.2 with scripted input (**I**). It observed:

- default FCB prefixes for FIRST.TXT at 005Ch and SECOND.BIN at 006Ch;
- first-FCB byte 15 equal to residual 06h, while the second prefix's corresponding byte was zero;
- command-tail count 15h (21 decimal) and text ` FIRST.TXT SECOND.BIN`, including the leading blank;
- login/read-only vectors 0003h/0002h after selecting and protecting B, becoming 0001h/0000h after Function 37 DE=0002h;
- Function 37 result 0000h and current drive still B;
- Functions 38, 39, and selector 41 each returning 0000h.

These results strengthen DRI-behavior evidence but do not resolve policy without broader dependency evidence. Selector 41 zero remains REQUIRED; Functions 38/39 are not promoted. CROSS45 then completed its full cross-layer matrix, proving GAP46 restored a coherent environment. Ready A/B disks were byte-identical after the run.

## 9. Proposed future investigations

No additional broad CP/M 2.2 boundary-discovery investigation is required. Future work should be explicitly focused:

1. **Application-corpus dependency study:** execute/search a larger preserved corpus for reliance on second FCB, exact tail/prompt/control behavior, Function 37, LISTST, or IOBYTE routing. Purpose: resolve specific POLICY PENDING items.
2. **Cross-implementation/profile validation:** repeat the conformance matrix on non-DRI CCP/BDOS and materially different BIOS/storage profiles. Purpose: distinguish DRI behavior from portable de facto behavior.
3. **Natural/late physical-fault study:** use hardware or an injector capable of failure after partial transfer. Purpose: characterize declared profile behavior without inventing universal atomicity.
4. **Ledger normalization review:** remove the duplicated Investigation 011 block and consolidate semantic duplicates under explicit authorization. Purpose: improve the normative artifact, not discover runtime semantics.

The first three are valuable before a final “maximum compatibility” profile freeze but are not prerequisites for beginning BetterCP/M implementation against the current REQUIRED ledger.

## 10. Compatibility conclusions

**REQUIRED:** implement the existing documented and evidenced propositions, including public CCP/BDOS/BIOS/storage/memory/lifecycle/error compositions and standard-software dependencies.

**NOT GUARANTEED:** incidental contents/state, malformed-input behavior, exact private placement/residue, arbitrary rollback, raw geometry, corrupt-media recovery, and undocumented preservation.

**NOT REQUIRED:** DRI private call graphs, stacks, caches, algorithms, addresses, controller mechanics, reserved 38/39 semantics, and modern abstraction equivalents.

**POLICY PENDING:** the bounded presentation, console, Function-37/device-routing, profile, and extension questions listed in section 7. Their existence does not indicate an unidentified subsystem boundary.

Overall status: **compatibility-boundary closure achieved for the CP/M 2.2 baseline**, with explicit policy/profile validation remaining.

## 11. Proposed ledger additions

None. Runtime propositions established by GAP46 are already present as REQUIRED, POLICY PENDING, or NOT REQUIRED/NOT GUARANTEED entries. Adding a generic closure proposition would not be independently testable.

The ledger does require future editorial correction, not new semantic entries: delete the second exact copy of 0248-0277 and consolidate/cross-reference 0435/0523. When evidence is added, use `I046 CLOSURE COMPATIBILITY SYSTEM subsystem IG AG`. The ledger itself was not modified.

## 12. Existing-entry updates

- **0012, 0016, 0019-0021, 0506, 0508:** add GAP46 DRI evidence for two FCB prefixes, loader residue, and leading-blank counted tail; retain POLICY PENDING.
- **0248-0277:** preserve the first block and propose removal of the second byte-for-byte semantic duplicate; do not renumber later entries.
- **0435/0523:** combine into one Function-37 policy proposition or make one an explicit cross-reference; add GAP46 vector/result/current-drive evidence.
- **0524 and 0529:** add GAP46 confirmation that 39/private and 41/unsupported returned zero; retain their distinct classifications.
- **0619-0622 and cross-layer entries identified by I045:** add only closure-review corroboration where useful; do not create umbrella duplicates.

Every evidence update uses `I046 CLOSURE COMPATIBILITY SYSTEM subsystem IG AG`.

## 13. Open questions

1. Which POLICY PENDING behaviors are required by real preserved applications rather than only repeated by DRI?
2. What exact scope will BetterCP/M label “strict CP/M 2.2,” and which behaviors belong only to optional compatibility extensions?
3. Which BIOS/storage profiles will receive byte-level media compatibility guarantees?
4. What minimum cross-implementation and application corpus is sufficient before freezing the strict profile?
5. Should ledger normalization be performed as a dedicated audited maintenance task before implementation begins?

## 14. Conformance implications

The current ledger can drive a layered conformance suite now. It should test every REQUIRED proposition independently, then add end-to-end CCP/load/entry/BDOS/BIOS/storage/lifecycle/recovery scenarios. NOT GUARANTEED state must be varied deliberately; NOT REQUIRED mechanics must not appear in acceptance criteria; POLICY PENDING tests must remain diagnostic until decided.

Before treating the ledger as a machine-countable normative list, remove the duplicate 0248-0277 block and resolve the Function-37 overlap. Conformance identifiers should remain the stable first occurrence and later entries must not be renumbered merely to repair duplication.

Completion audit: all 14 required sections and all named artifacts exist. GAP46 and CROSS45 rebuild byte-identically. The accepted ready images are unchanged. All protected pre-existing BetterCP/M files verify. The authoritative ledger retained SHA-256 `119aa2ee89d33973c2bc55267a99c55240887371fe210af455b01614426c5975`; no ledger, previous investigation, or implementation file was modified; no ZIP archive was created.
