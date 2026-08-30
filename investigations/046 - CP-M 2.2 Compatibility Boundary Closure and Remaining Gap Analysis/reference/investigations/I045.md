# Investigation 045 - CP/M 2.2 Cross-Layer Compatibility Boundary Review

Evidence classes are **A** documented CP/M behavior, **B** behavior of the examined Digital Research implementation/software, **I** controlled experimental observation, and **D** unresolved BetterCP/M policy.

## 1. Objective and scope

This investigation reviews all completed work through I044 to determine whether the major CP/M 2.2 compatibility boundaries have been captured where observable behavior crosses CCP, transient execution, BDOS, BIOS, storage, memory, lifecycle, and failure handling.

It adds a deterministic combined-operation and recovery probe. It does not design BetterCP/M architecture, introduce new subsystem behavior, or treat private DRI implementation structure as an interface.

## 2. Compatibility standard

Cross-layer behavior is **REQUIRED** when documentation or materially representative software depends on the combined public result. **NOT GUARANTEED** marks observable but nonportable state. **NOT REQUIRED** excludes private mechanisms whose externally visible result may be implemented differently. **POLICY PENDING** identifies unresolved BetterCP/M choices.

The test is the software-visible composition, not whether each layer separately resembles DRI source. Documentation (A), source/ecosystem (B), experiment (I), and policy (D) remain distinct.

## 3. Relationship to previous investigations

I021 establishes CCP command acquisition/dispatch; I024 lifecycle and BDOS return state; I033 physical-error propagation/recovery; I034 memory and resident boundaries; I036 BIOS runtime abstraction; I040 storage geometry/direct structures; I041 public versus private direct access; I042 standard-software assumptions; I043 memory/execution edge cases; and I044 consolidated failure boundaries.

The complete ledger through I044 supplies the function- and subsystem-level propositions. I045 reviews their seams and avoids restating them as broader duplicates.

## 4. Cross-layer compatibility findings

The major compatibility chains are:

| Chain | Observable composition | Coverage |
|---|---|---|
| Command to execution | CCP parse -> BDOS lookup/read -> DMA load -> page-zero entry -> CALL 0100h | I021-I024, I028, I034 |
| Application file I/O | FCB/current drive/user -> BDOS directory/allocation -> BIOS logical transfer -> configured storage | I008-I019, I025-I031, I036-I040 |
| Direct system access | Page-zero discovery -> BDOS gateway or BIOS vector -> implementation-independent public result | I020, I034, I036, I041 |
| Lifecycle | RET or reset request -> CCP/WBOOT reconstruction -> next command environment | I001, I024, I033-I035, I043-I044 |
| Failure | BIOS status -> BDOS presentation -> ignore or abort -> CCP/runtime recovery | I015, I025, I033, I044 |
| Standard software | documented ABI plus writable TPA/page-zero hooks/submission stream | I041-I043 |

No missing major baseline seam was found. Remaining issues are policy choices, additional implementation/profile validation, or corpus breadth rather than unidentified CP/M 2.2 subsystem contracts.

## 5. CCP/BDOS/BIOS interaction

**A/B.** CCP depends on BDOS for command-file lookup and record loading, prepares page-zero objects, and transfers to the transient. A transient uses CALL 0005h for BDOS or documented BIOS vectors discovered through WBOOT. Ordinary RET returns to CCP; Function 0/JMP 0000h use restart behavior.

**I.** CROSS45 entered through CCP, captured WBOOT FA03h and BDOS EC06h, obtained version 0022h, used BDOS storage/state functions, directly invoked configured BIOS CONST, restored DMA, and returned to a working prompt. Those numeric addresses are NOT GUARANTEED; the public gateway chain is REQUIRED.

Private CCP/BDOS targets, stacks, loaders, and BIOS routines remain NOT REQUIRED. Transients may observe public drive/user/DMA/page-zero state but not arbitrary CCP or BIOS internals.

## 6. Storage/runtime interaction

File visibility is the composition of FCB drive, current drive, current user, directory records, allocation state, selected DMA, and configured BIOS/storage profile (**A/B**). BDOS automatic explicit-drive operations temporarily reselect a drive while preserving the persistent current-drive state.

**I.** With alternate DMA, Search First returned slot 01 and placed user-0 `ATTR    DAT` in that DMA record. After selecting B/user 1, explicit A: search returned FF; after switching to user 0 it returned 01, while Function 25 still reported B. Function 13 then returned current drive to A. The slot and raw placement are reference values; drive/user filtering, DMA transfer, and persistent-state semantics are REQUIRED.

Raw geometry, physical slot/block choice, private directory DMA, and host-image layout are NOT GUARANTEED. Direct BIOS callers remain responsible for configured DPH/DPB/translation and for coordinating with BDOS state.

## 7. Memory/system-state interaction

Page zero connects transient execution to CCP, BDOS, BIOS, command tail, default FCBs, DMA defaults, and restart (**A**). The TPA is flat writable/executable storage, while resident memory must remain usable for services the program continues to invoke (I034/I043).

CROSS45 used application storage for an alternate DMA and observed BDOS-written directory content, then restored DMA 0080h before RET (**I**). It derived BIOS CONST from the configured WBOOT target rather than a fixed address. This composition is REQUIRED; exact targets, entry stack, unloaded bytes, private serialization, and memory residue are NOT GUARANTEED.

The remaining policy question is whether optional protected/cleared modes can coexist with a strict profile. They cannot replace the evidenced writable flat-memory behavior in strict compatibility.

## 8. Error/recovery interaction

A final BIOS disk error crosses into BDOS operator presentation. Ignore resumes without certifying transfer; Control-C abandons the transient and crosses WBOOT/BIOS, resident-system reconstruction, page-zero restoration, and CCP command acquisition (**A/B**).

**I.** In the failure run, the first injected read error was ignored and returned 00 with invalid sentinel DMA. The second was aborted. CROSS45 then produced byte-for-byte identical semantic output to the normal run across page-zero, BDOS, BIOS, directory/DMA, drive/user, reset, and RET.

Thus usable public recovery is REQUIRED across layers. Exact stack/register residue, caches, reload sectors, retry internals, interrupted state, and transaction rollback are NOT REQUIRED or NOT GUARANTEED. Natural partial-transfer behavior remains profile-specific and cannot be generalized from a pre-transfer injector.

## 9. Software ecosystem findings

Standard DRI software exercises the seams rather than isolated APIs: CCP loads transients through BDOS; SUBMIT/XSUB span file records, CCP command acquisition, page-zero interception, Function 10, and lifecycle; DDT patches executable memory and restart vectors; SYSGEN uses configured BIOS/storage structures; STAT consumes BDOS/DPB state (**B/I042-I043**).

These programs support REQUIRED combined outcomes already in ledger 0617, 0620-0622 and related entries. They do not justify fixed DRI addresses, exact internal layouts, undocumented register residue, or one disk geometry. No newly reviewed representative program exposed an unrecorded major seam.

## 10. Documentation findings

The Interface Guide explicitly describes CP/M as CCP, BDOS, BIOS, and TPA components whose public organization is combined: CCP supplies the human-facing file/command interface, FDOS combines BDOS and BIOS, transients call the system, and WBOOT returns control to CCP (**A**). Exact configured addresses vary.

The Alteration Guide defines page-zero gateways, configurable resident layout, BIOS jump-table contracts, logical disk/DMA state, READ/WRITE results, and recovery presentation (**A**). Documentation therefore supports subsystem separation internally while defining observable handoffs among them. It does not standardize private call graphs, memory addresses, controller geometry, caches, or reconstruction algorithms.

## 11. Source findings

`OS2CCP.ASM` crosses CCP to BDOS for lookup/load, prepares transient state, and resumes after CALL/RET (**B**). `OS3BDOS.ASM` crosses application FCB/DMA/state into directory/allocation logic and BIOS I/O, restores temporary drive reselection, and diverts physical failures to presentation (**B**). `CBIOS.ASM` maps logical system operations to configured hardware and implements restart (**B**).

These sources reveal deliberate handoffs but do not by themselves make private layouts mandatory. Each promoted conclusion also has documentation, experimental, or standard-software evidence.

## 12. Experimental results

The accepted environment was z80pack cpmsim 1.39, DRI CP/M 2.2, and Z80 CBIOS 1.2 with fully scripted input.

| Case | Result |
|---|---|
| CCP/transient entry | CROSS45 loaded, ran at the command prompt, and RET reprompted |
| Page-zero/BDOS | configured gateways observed; Function 12 returned 0022h |
| DMA/storage | alternate DMA received the returned directory entry |
| Drive/user boundary | explicit A: search failed in user 1 and succeeded in user 0 |
| Temporary/persistent drive | explicit A: operation left current drive B |
| Direct BIOS | configured CONST returned 00 with no input |
| Reset/lifecycle | Function 13 restored drive A; user remained zero; DMA restored; RET worked |
| Failure composition | ignore returned without valid data; abort rebuilt an environment in which the entire matrix repeated identically |

Both ready disk-image pairs were byte-identical before/after. Full transcripts and hashes are preserved. The experiments establish public composition on the reference system, not numeric targets, directory slot, or private recovery sequence.

## 13. Compatibility conclusions

**REQUIRED:** public cross-layer chains for command loading/execution; page-zero gateways; BDOS-to-BIOS/storage composition; drive/user/DMA-dependent file visibility; temporary explicit-drive reselection; configured direct BIOS vectors; lifecycle convergence; and usable post-abort reconstruction.

**NOT GUARANTEED:** numeric addresses, raw directory order, internal DMA/caches, entry stack, register residue, storage geometry, rollback, partial-write state, corrupted-media recovery, or interrupted-transient preservation.

**NOT REQUIRED:** DRI private call graphs, routine names, stack layout, loader comparison, retry placement, CCP reconstruction, controller implementation, and host image representation.

**POLICY PENDING:** optional protection/clearing, strict diagnostic presentation, structured headless errors, extension selectors, Function 37, named storage profiles, and exact second-default-FCB/tail-capacity choices already identified in prior reports.

## 14. Proposed ledger additions

None. The authoritative ledger ends at 0622. Its existing independently testable entries already cover every cross-layer result established here. A new generic “cross-layer compatibility” proposition would duplicate those entries and be less independently testable.

When adding corroboration to existing entries, use the exact evidence string `I045 CROSS-LAYER SYSTEM COMPATIBILITY subsystem IG AG`. The ledger itself was not modified.

## 15. Existing-entry updates

- **0001-0034, 0461-0474:** add CROSS45 gateway/vector/state evidence without promoting numeric addresses.
- **0105-0130 and 0542-0570:** add alternate-DMA, explicit-drive, user-filtering, and temporary-reselection composition evidence; preserve directory-order/slot exclusions.
- **0411-0459 and 0598-0618:** add direct BIOS/storage-chain corroboration; do not broaden one configured profile into a universal geometry.
- **0492-0505, 0509-0517, 0571-0580:** add the full CCP-to-transient-to-RET and reset-state sequence; no wording correction.
- **0581-0588:** add the failure-abort-CROSS45 recovery sequence as stronger public-reconstruction evidence.
- **0619:** CROSS45 confirms public gateway/vector discovery while avoiding private BDOS targets.
- **0620-0622:** ecosystem review adds no wording change; retain their precise standard-software/self-modification tests rather than generalizing them.

All proposed evidence updates use `I045 CROSS-LAYER SYSTEM COMPATIBILITY subsystem IG AG`.

## 16. Open questions

1. Cross-implementation repetition on non-DRI CCP/BDOS and materially different BIOS/storage profiles would measure portability breadth, not define a new baseline seam.
2. Natural errors after partial media transfer remain profile-specific evidence worth collecting for declared disk profiles.
3. A larger preserved application corpus may resolve existing policy questions about exact CCP text, second default FCB, command-tail capacity, Function 37, or incidental conventions.
4. BetterCP/M must decide which optional strict-versus-extended modes expose memory protection, validation, selectors, or structured errors without changing strict results.
5. No additional focused investigation is required merely to identify another major CP/M 2.2 subsystem boundary; future work should target these named policy/profile/corpus questions.

## 17. Conformance implications

Conformance must include end-to-end scenarios in addition to unit tests: CCP lookup/load/entry/RET; alternate-DMA directory and data transfer; current versus explicit drive and user visibility; configured direct BIOS calls; reset and page-zero restoration; physical failure ignore/abort; and a complete healthy operation after recovery.

The suite should vary addresses, memory size, disk profile, directory slot, drive/user state, DMA placement, and internal implementation. It must validate public results while rejecting dependencies on DRI private targets, raw geometry, cache residue, exact stacks, or reconstruction sequences. Policy and extension profiles must be tested separately from the strict baseline.

Completion audit: all 17 required sections and all named artifacts exist. CROSS45 and preserved PHYS015 rebuild byte-identically. Both accepted ready-image pairs are unchanged. All protected pre-existing BetterCP/M files verify. The authoritative ledger retained SHA-256 `55c1e86da06e6bc7d4f43106fe8ec0eb6a32b1df067c71f88855250453d615bf`; no ledger, previous investigation, or implementation file was modified; no ZIP archive was created.
