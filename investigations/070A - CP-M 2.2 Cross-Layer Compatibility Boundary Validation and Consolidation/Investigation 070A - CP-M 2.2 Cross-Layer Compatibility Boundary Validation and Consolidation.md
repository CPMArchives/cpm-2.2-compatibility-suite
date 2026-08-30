# Investigation 070A - CP/M 2.2 Cross-Layer Compatibility Boundary Validation and Consolidation

Evidence classes are **A** documented CP/M behavior, **B** behavior of the examined DRI implementation and standard utilities, **I** controlled experimental observation, and **D** unresolved BetterCP/M policy.

## 1. Objective and answer

This investigation validates the canonical Investigation 069 ledger as a complete externally visible contract across CCP, transient, BDOS, BIOS, storage, state, lifecycle, and recovery seams. It does not reopen settled subsystem semantics or prescribe BetterCP/M architecture.

**Answer:** yes. The accumulated 627 propositions form a coherent cross-layer CP/M 2.2 compatibility boundary. The normal, logical-failure, physical-ignore, and physical-abort workflows all composed successfully. No proposition conflict, missing public handoff, exact duplicate proposition, or classification contradiction was found. BetterCP/M can implement this boundary without copying private DRI addresses, call graphs, allocation choices, stacks, retry placement, or recovery algorithms.

## 2. Baseline and method

The authoritative input was `compatibility/02 Compatibility Ledger - Investigation 069.txt`, SHA-256 `40d5e514a698bbabdfe8c7d926cea39b9962e17d83b25f2a2915ea4882014097`. It was hashed before testing and treated as read-only.

The review used I045 as the prior seam analysis, I046 as the gap assessment, I047 for standard-utility interaction, I069 for canonicalization decisions, and earlier reports named by individual ledger propositions. The CP/M 2.0 Interface Guide and CP/M 2.2 Alteration Guide were reviewed directly. DRI source conclusions were accepted only as implementation evidence, not as public requirements by themselves.

Experiments used z80pack cpmsim 1.39 with DRI 64K CP/M 2.2, Z80 CBIOS 1.2, and IBM-3740 images. `CROSS70A` is a fresh rebuild of the accepted cross-layer probe. `FAULT066` is a byte-identical rebuild of the accepted logical/physical-failure probe. The physical runs used the preserved isolated emulator instrumentation that fails exactly one BIOS read before transfer. Every input was scripted and every accepted path began from a preserved ready image.

## 3. Documented boundary

**A.** The manuals define a composed system rather than a requirement to reproduce DRI internals. Applications enter through the TPA/page-zero conventions, call BDOS through the public gateway, and may discover the configured BIOS jump table through the public warm-boot vector. BIOS disk service is stateful: select drive, track, sector, and DMA, then READ or WRITE. The Alteration Guide defines zero/nonzero BIOS transfer results and describes BDOS physical-error presentation with operator ignore or Control-C abort. It also shows warm-start reconstruction of page-zero gateways, default DMA 0080h, current drive handoff, and return to CCP.

These are observable handoffs. The example addresses, skeletal CBIOS code, retry count, private dispatcher structure, and physical-controller technique are implementation material unless another public proposition independently requires the result.

## 4. Validation workflows

### 4.1 Normal application workflow

**I.** Cold boot reached `A>`. CCP acquired `CROSS70A`, found and loaded the COM file at the transient entry point, and transferred control. The probe used CALL 0005h for BDOS version, drive, user, DMA, search, selection, and reset operations; derived BIOS CONST from the configured WBOOT vector; restored DMA; and returned by RET to a usable CCP prompt.

The same run exercised a complete public file lifecycle through the standard resident `SAVE` and `ERA` commands. `SAVE 1 COPY70.DAT` made, wrote, and closed a record; directory lookup found the file; `ERA` removed it; a final lookup reported `NO FILE`; and the directory returned to its original free-space count. The normal drive-A image changed, as expected, because create/delete updates physical directory state even though the final namespace and free allocation matched the start. Drive B was unchanged.

### 4.2 Drive, user, DMA, FCB, directory, and allocation state

**I.** Alternate-DMA Search First returned slot 01 and placed the user-0 `ATTR.DAT` directory entry in that DMA record. After selecting current drive B and user 1, explicit A: lookup returned FF. Repeating under user 0 returned 01 while Function 25 still reported B. Function 13 restored current drive A, and the probe restored DMA 0080h before RET.

`FAULT066` opened the known FCB and advanced sequential/random read state. `SAVE` and `ERA` established creation, record transfer, close visibility, deletion, and public allocation release. These results compose without requiring a raw directory slot, allocation block number, private checksum vector, or host-image layout.

### 4.3 Logical failure and continued execution

**I.** Sequential and random missing-data controls returned 01 normally, left the EE DMA sentinel as non-result data, and did not enter the physical-error console path. The same session then loaded and completed `CROSS70A` and returned to CCP. This validates the ledger's separation between documented BDOS logical result codes and BIOS/media failure handling.

### 4.4 Physical failure, ignore, and abort

**I.** A controlled pre-transfer BIOS read failure entered DRI's `Bdos Err On A: Bad Sector` path. On ignore, the interrupted read returned 00 but the DMA sentinel remained invalid new data. This is coherent with the ledger: an ignored physical error can resume, while the apparent return does not certify transfer success or DMA validity.

In a separate restored run, Control-C at the same presentation abandoned the transient, performed warm recovery, and reached `A>`. Both recovered sessions then loaded and completed `CROSS70A`, performed directory lookup, and returned to a usable prompt. All logical and physical read-only ready images were byte-identical after testing.

The injector fails before transfer. These runs do not establish rollback or atomicity for partial writes, damaged media, or controller-specific recovery.

## 5. Chain integrity findings

| Chain | Public composition validated | Internal behavior excluded |
|---|---|---|
| CCP -> transient | command acquisition, lookup/load, 0100h execution, page zero, RET/reprompt | private loader comparisons, exact CCP address, stack |
| Transient -> BDOS | CALL 0005h selectors/arguments/results combined with stateful file operations | incidental registers and private BDOS entry targets |
| BDOS -> BIOS | configured vector use, logical operations, final physical status presentation | dispatcher layout, cache and retry placement |
| BIOS -> storage | selected logical drive/track/sector/DMA and declared disk profile | controller geometry outside the profile and host-image layout |
| Lifecycle | normal RET, logical-return continuation, ignore return, Control-C warm recovery | exact reconstruction sequence and interrupted register residue |
| State | current/explicit drive, user, DMA, FCB, directory, allocation, page zero | raw slot/block choices and stale internal buffers |

No layer required an undocumented promise from the next layer to obtain the tested public result. Where DRI exposes incidental values, the ledger consistently marks them NOT GUARANTEED or NOT REQUIRED rather than allowing a REQUIRED higher-layer result to depend on them.

## 6. Ledger quality and classification review

The machine audit found 627 unique entries in contiguous range 0001-0627, no gaps, no missing dispositions, and no normalized exact duplicate propositions. Counts are 424 REQUIRED, 105 NOT GUARANTEED, 49 NOT REQUIRED, and 49 POLICY PENDING.

The review specifically checked apparent tension at the seams:

- REQUIRED gateway use is compatible with NOT GUARANTEED exact addresses.
- REQUIRED RET termination and valid entry return word are compatible with NOT REQUIRED exact SP and return address.
- REQUIRED logical error codes are compatible with the distinct physical-error presentation and recovery contract.
- REQUIRED post-recovery usable service does not imply transaction rollback, cache preservation, or interrupted-transient continuation.
- REQUIRED DMA transfer rules are compatible with invalid/unspecified DMA content after failed or ignored reads.
- REQUIRED drive/user namespace behavior is compatible with NOT GUARANTEED directory order, slot, and allocation-block choice.
- REQUIRED generic processor behavior plus declared profile behavior is compatible with NOT REQUIRED Z80 extensions in a generic claim.

Entries 0435 and 0523 are not duplicate requirements after I069. Entry 0435 owns Function 37's compatibility status; 0523 conditionally defines the state-effect profile if that policy is adopted. Their shared POLICY PENDING disposition is coherent.

No overly broad proposition was found that needs narrowing to preserve a private DRI mechanism. The detailed chain mapping is preserved in `probes/ledger-semantic-review.tsv`.

## 7. Proposed ledger updates

**No new proposition, deletion, merger, disposition change, or wording correction is proposed.** A generic cross-layer proposition would duplicate the independently testable entries and weaken the ledger's granularity.

If evidence citations are updated in a later authorized ledger-maintenance investigation, I070A may be added as corroboration to these existing ranges without changing their meaning:

- 0001-0034 and 0475-0512: CCP loading, page-zero entry, termination, and reprompt;
- 0131-0158, 0185-0217, and 0382-0384: drive/user/DMA/search state;
- 0159-0184 and 0218-0370: FCB/file lifecycle and allocation-visible results;
- 0392-0459: configured BIOS boundary and physical-error propagation;
- 0492-0505 and 0571-0580: lifecycle and recovery convergence;
- 0598-0618: logical-storage/profile composition.

Suggested evidence label: `I070A CROSS-LAYER CONTRACT VALIDATION subsystem IG AG`.

## 8. POLICY PENDING review

All 49 POLICY PENDING entries remain unresolved. This investigation tested whether they conflict with the adopted baseline; it was not authorized to decide product policy, and the workflows supplied no new discriminating evidence for those choices.

The seam-relevant pending groups remain: exact CCP/default-FCB/command-tail choices; detailed console presentation and retained-input behavior; unavailable-drive and physical-error presentation; exact EOF/write/allocation codes where prior evidence remains incomplete; Function 37 adoption and its conditional state profile; active IOBYTE routing and LISTST result policy; post-termination drive/user choice; and optional exact prompt/diagnostic text. The full 49-entry list is preserved in `probes/ledger-structural-review.txt`.

## 9. Application-visible versus implementation behavior

The required boundary is the result observed by a conforming program or operator: executable loading and entry; public gateways; selector/argument/result conventions; stateful FCB/DMA/drive/user behavior; directory and allocation-visible effects; configured BIOS services; and usable lifecycle/recovery convergence.

BetterCP/M need not reproduce DRI's numeric addresses, private stacks, CCP/BDOS call graph, exact directory scan implementation, allocation choice, retry location, cache organization, warm-loader sequence, or host disk-image representation. Optional extended/protected modes may add behavior only if the strict CP/M personality continues to satisfy the ledger's adopted propositions.

## 10. Limitations

This is validation, not new subsystem discovery. It uses one accepted DRI CP/M 2.2/Z80 CBIOS/IBM-3740 reference profile and accepted pre-transfer fault instrumentation. Prior cross-implementation and hardware-profile investigations supply breadth beyond this run. No claim is made about untested torn writes, corrupted media, every utility, or every POLICY PENDING choice.

## 11. Completion audit

The new Investigation 070A directory contains this report, source, COM files, assembler listings, deterministic harnesses, raw transcripts, before/after disk images, directory listings, isolated emulator source/binary, build instructions, structural and semantic ledger reviews, protected-tree manifests, and SHA-256 manifests.

`CROSS70A.COM` rebuilt deterministically. `FAULT066.COM` rebuilt byte-identically at SHA-256 `2365c3bac5b06f36e584610a0da5d6b1d3d19e2f0496f70a8e4b18e23307f4ec`. The authoritative ledger hash was `40d5e514a698bbabdfe8c7d926cea39b9962e17d83b25f2a2915ea4882014097` before and after. The protected-tree before/after manifests are identical; no ledger, earlier investigation, architecture, roadmap, specification, or implementation file was modified. No ZIP archive was created.

The final artifact manifest is `SHA256SUMS.txt`.
