# Investigation 053 - CP/M 2.2 Software Corpus Validation

## 1. Objective and scope

This investigation validates the CP/M 2.2 compatibility contract accumulated through Investigation 052 against a representative software corpus. It repeats controlled workflows from Investigations 047-051 in isolated restored environments, preserves new transcripts and disk images, maps each observation to ledger areas and I052 tests, and asks whether any result exposes a missing compatibility boundary.

It is an evidence report only. It neither changes the Compatibility Ledger nor proposes BetterCP/M implementation or architecture.

## 2. Compatibility standard

The standard is ecosystem compatibility: documented CP/M 2.2 behavior (**A**), externally relevant DRI implementation behavior (**B**), controlled experimental observation (**I**), and unresolved policy (**D**). Software success is compositional evidence that the established contract is sufficient for that workflow; software failure becomes a compatibility issue only after separating operating-system behavior from application diagnostics, fixture defects, absent peripherals, and machine-specific assumptions.

Findings use **REQUIRED**, **POLICY PENDING**, **NOT REQUIRED**, and **NOT GUARANTEED**. Any future ledger reference to this investigation must use exactly `I053 VALIDATION SOFTWARE COMPATIBILITY subsystem IG AG`.

## 3. Relationship to previous investigations

I047 supplied standard utility workflows; I048 supplied development toolchain workflows; I049 supplied WordStar, BASIC/Wumpus, and Adventure application cases; I050 supplied generic Kermit cases; I051 supplied the public-interface control and hardware-dependent boundaries. I052 defined stable regression identifiers and mapped the 652-entry ledger to proposed tests.

I053 does not reinterpret their source-only or historical findings. It reruns representative cases across those categories as one validation campaign. Narrow earlier probes remain authoritative for exact register, byte, FCB, DMA, BIOS, and error semantics; this investigation tests whether those requirements compose adequately for software.

## 4. Software corpus

| Record | Software | Version/release | Category | Platform assumption | Preserved evidence |
|---|---|---|---|---|---|
| V053-01/02 | ASM, LOAD, PIP, STAT, ED, DDT, SUBMIT, XSUB, DUMP | DRI CP/M 2.2 distributions | Standard | 64K CP/M 2.2 Z80 CBIOS | Scripted transcript, generated files, images |
| V053-03/04 | ASM, MAC, RMAC, LOAD, LINK, DDT, SID, SUBMIT | DRI releases; LINK 1.3 where shown | Development | CP/M 2.2 | Two-run evidence, binaries, images |
| V053-05 | WordStar | 3.00 | Word processor | Mostek 56K CP/M, configured Adds terminal | Raw transcript, before/after image |
| V053-06 | Microsoft BASIC-80/Wumpus | 5.2 | Interpreter/game | Mostek 56K CP/M | Raw transcript, unchanged image pair |
| V053-07 | Adventure | A02 | Native multi-file application/game | Mostek 56K CP/M | Raw transcript, unchanged image pair |
| V053-08-10 | Kermit-80 Generic CP/M | 4.11 | Communications | CP/M logical devices; no peer | Three raw transcripts, unchanged image pair |
| V053-11 | BASE051 | I051 probe | Portable control | Public BDOS interface | Raw transcript, unchanged image pair |
| V053-12 | QTERM IMSAI patch | 4.3e | Hardware-dependent communications | Requires IMSAI port interface | Precise unused-port trap transcript |
| V053-13 | KSCOPE | Cromemco Dazzler release | Hardware-dependent display | Requires Dazzler port interface | Precise unused-port trap transcript |

The source/archive locations and fixture provenance remain those recorded by I047-I051. I053 used isolated copies of their preserved binaries, scripts, configurations, and images; `probes/README.txt` and `probes/SHA256SUMS` identify the new archive evidence.

## 5. Corpus coverage analysis

The corpus covers every required major category and includes normal, boundary, and failure operation. Standard and development cases exercise resident/transient command composition, FCB/DMA storage, buffered input, program generation, debugging, and recovery. Applications exercise full-screen terminal use, file persistence, an interpreter, a large multi-file transient, interruption, and return to the CCP. Kermit exercises logical devices, command processing, an absent peer, an absent file, and a build capability boundary. QTERM and KSCOPE isolate two direct-hardware dependencies after a portable control succeeds.

It is representative rather than exhaustive. Material gaps are spreadsheet, database, packaged business, BBS, printer, and additional compiled-language samples; successful paired communications and receive/carrier-loss cases; and matching IMSAI, Dazzler, or other physical hardware profiles. These are corpus/profile gaps, not evidence of a missing baseline requirement. Details are in `probes/corpus-coverage.txt`.

## 6. Documentation findings

CP/M documentation (**A**) defines the public CCP, BDOS, BIOS, memory, FCB, DMA, console, logical-device, and lifecycle surfaces consumed by the portable cases. It does not promise that every third-party executable is portable across machine profiles, prescribe vendor UI or diagnostic wording, provide application protocols or peripherals, or make direct machine ports part of the generic CP/M contract.

The successful workflows are consistent with that documented division. The documentation does not justify turning ASM, LINK, WordStar, BASIC, Kermit, or emulator text into operating-system-required presentation. Nor does it justify treating successful communications without a peer or hardware-specific operation without its device as baseline requirements.

## 7. Source findings

DRI source (**B**) and earlier source analyses identify the public paths exercised by the DRI utilities and toolchain: CCP parsing/loading, BDOS dispatch, FCB/DMA file operations, console calls, termination, and restart. Third-party source/binary analysis in I049-I051 identifies terminal configuration, Kermit's logical-device/build assumptions, QTERM's IMSAI input port, and KSCOPE's Dazzler output port.

Source was used to select and interpret tests, not as a substitute for execution. I053 conclusions rely on newly preserved external results. Internal control flow, exact algorithms, private addresses, and vendor diagnostics are not promoted into requirements.

## 8. Validation results

All 13 deterministic records produced their specified acceptance observations:

- The standard utility suite assembled, loaded, copied, listed, edited, inspected, batch-fed, dumped, and reran controlled files. ASM and PIP also produced their expected missing-input outcomes.
- The development suite assembled/linked and executed small, macro, multi-module, and multi-record programs; DDT/SID and SUBMIT paths worked; independently generated DEV48 and BATCH48 were byte-identical. The negative link case reported an unresolved symbol and returned control.
- WordStar saved known text which DIR found and TYPE reproduced. BASIC/Wumpus and Adventure reached deterministic states and returned to CP/M.
- Generic Kermit started, reported configuration, exited, emitted send-init data without a peer, recovered on scripted abort, and handled unavailable speed support and a missing file.
- BASE051 returned CP/M version 22 through the public interface. QTERM and KSCOPE loaded far enough to print CP/M/application output, then trapped exactly at their unsupported direct ports.

Adventure, Wumpus, communications, and hardware/control before/after image pairs are byte-identical. WordStar and intentionally mutating utility/toolchain workflows changed their images as expected. Exact hashes and full per-record procedures are preserved in `probes/images-sha256.txt`, `probes/validation-records.txt`, and `probes/transcripts/`.

## 9. Failure analysis

ASM's `NO SOURCE FILE PRESENT`, PIP's `NO FILE`, and LINK's `UNDEFINED SYMBOLS` are expected program-level presentations of ordinary missing-input or unresolved-symbol conditions. The command environment remained available. Their exact wording is **NOT REQUIRED** CP/M behavior.

Kermit's unavailable speed feature is a generic-build capability boundary, not a BDOS defect. Its missing-file report consumes an existing file failure. The no-peer case demonstrates send-init output and application recovery only; successful transfer is untested and remains a communications-profile gap.

QTERM's `IN 23h` at PC 0112h and KSCOPE's `OUT 0Eh` at PC 0110h occur only after the public CP/M environment operates and loads the program. They are precise machine-profile mismatches, not missing generic CP/M requirements. Matching-profile behavior remains **POLICY PENDING** where the ledger already makes it so.

The copied I047/I048 harnesses close scripted console input after all final markers; cpmsim then reports that it cannot read console input and enters its monitor. This is harness shutdown, not software failure. No unexpected result in this campaign exposes a new CP/M boundary.

## 10. Compatibility requirement mapping

`probes/requirement-mapping.tsv` is the compact mapping. Principal relationships are:

- V053-01/02 -> ledger 0569-0579 and 0620-0621; I052 `UTIL-001`, `UTIL-004`, `CCP-008`, `ERROR-001`.
- V053-03/04 -> entry/lifecycle 0001-0014, loader/overlay 0589-0590, self-modification 0622; `UTIL-002` through `UTIL-004`.
- V053-05-07 -> file-operation region 0155-0388, memory/lifecycle and character/profile entries as applicable; `APP-001` through `APP-003`.
- V053-08-10 -> file region and character/logical-device 0606-0612; `COMM-001` and `COMM-003`.
- V053-11 -> public BDOS call/version and entry path; `BDOS-STATE-001`, `MEM-001`.
- V053-12/13 -> direct BIOS/profile 0600-0601 and raw character/device 0606-0612; `COMM-004`, `HW-001`, `BIOS-007`.

This is strengthening compositional **I** evidence. It does not replace the **A**, **B**, and narrow **I** evidence underlying the mapped propositions, and it does not turn broad numeric ranges into claims that every proposition was independently retested here.

## 11. Compatibility conclusions

**REQUIRED:** The established public entry, CCP, BDOS, FCB/DMA, memory, console/logical-device, termination, and selected profile contracts are sufficient for every successful normal workflow and expected ordinary failure observed here.

**POLICY PENDING:** Which terminal, communications-peer, serial, and named machine/hardware profiles BetterCP/M promises; whether the missing application categories become release gates; and when matching hardware evidence is sufficient.

**NOT GUARANTEED:** Application recovery internals, unspecified post-error state, exact vendor output, timing beyond the tested fixtures, and behavior when software directly addresses absent private hardware.

**NOT REQUIRED:** Reproducing vendor UI/diagnostic text, implementing unavailable Kermit commands in CP/M, making IMSAI/Dazzler software work on an unrelated baseline, or treating every application quirk as an operating-system rule.

The corpus therefore validates the current contract within the tested profiles. It reveals coverage gaps but no new baseline compatibility requirement or contradiction.

## 12. Proposed ledger additions

None. Every operating-system behavior exercised maps to existing entries. Adding a proposition that representative software must pass would be circular and less independently testable than the underlying requirements. Software-specific diagnostics and unsupported hardware accesses do not qualify as new CP/M requirements.

## 13. Existing-entry updates

No ledger file was modified. No disposition or wording correction is proposed.

At a future authorized evidence-integration step, the mapped entries may cite `I053 VALIDATION SOFTWARE COMPATIBILITY subsystem IG AG` as strengthening ecosystem-level experimental evidence. The citation should be limited to the exact workflow/profile tested and must not replace earlier narrow evidence. Entries 0600-0601 and 0606-0612 are especially strengthened as a boundary: portable public/logical-device paths work, while direct unmatched ports fail precisely as the existing profile distinction predicts.

## 14. Open questions

1. Which rights-cleared spreadsheet, database, business, BBS, printer, and additional language products should extend the corpus? (**D**)
2. Which Kermit peer and transport fixture will support successful send/receive, binary/text, carrier-loss, retry, and receive-failure testing? (**D**)
3. Which terminal and communications profiles become mandatory release gates rather than optional profiles? (**D**)
4. Which IMSAI, Dazzler, raw-controller, front-panel, and other named environments can be validated on sufficiently faithful matching hardware/emulation? (**D**)
5. Should repeated timing-sensitive runs be required, and what repeat count establishes adequate evidence? (**D**)
6. Should future corpus validation run against both original CP/M and BetterCP/M, and what differential-result policy will separate permitted variation from defects? (**D**)

## 15. Conformance implications

A BetterCP/M baseline conformance claim can use these workflows as cross-layer acceptance tests only after naming the enabled machine, terminal, and communications profiles. It should require the operating-system observations, disk relations, and clean control transfers recorded here, while permitting vendor-specific presentation differences and rejecting attempts to make absent private hardware a generic requirement.

The 13 records are reproducible acceptance specifications, not a complete product certification corpus. Future execution against BetterCP/M should restore each before image, use the same deterministic input, pin software and fixture hashes, preserve raw output and disk state, and reduce any unexpected workflow failure with the narrower I052 tests before proposing a compatibility change.

Completion audit: the report, validation records, mappings, transcripts, before/after images, and hashes are present; all performed experiments are documented; incomplete paired-transfer and matching-hardware cases are explicitly identified; no unsupported success is claimed; no BetterCP/M implementation was made; the authoritative ledger remained unchanged; prior investigation artifacts remained unchanged; and no ZIP archive was created.
