# Investigation 044 - CP/M 2.2 Failure, Recovery, and Boundary Condition Compatibility Semantics

Evidence classes are **A** documented CP/M behavior, **B** behavior of the examined Digital Research implementation, **I** controlled experimental observation, and **D** unresolved BetterCP/M policy.

## 1. Objective and scope

This investigation defines the application-visible boundary among normal results, logical failures, resource exhaustion, BIOS/device failures, invalid requests, abnormal termination, and recovery in CP/M 2.2. It consolidates earlier function-specific investigations and adds a deterministic composition matrix for normal, boundary, failure, recovery, and repeated-failure states.

It does not design BetterCP/M's internal error architecture, promise modern exception or transaction semantics, or treat unsafe malformed pointers as a supported interface.

## 2. Compatibility standard

**REQUIRED** behavior is documented or is needed to preserve established CP/M software interaction. **NOT GUARANTEED** state is observable but unsuitable as a portable dependency. **NOT REQUIRED** excludes private DRI mechanisms when public behavior can be reproduced differently. **POLICY PENDING** identifies a BetterCP/M choice not settled by CP/M 2.2.

Manual claims (A), DRI source behavior (B), experiment (I), and policy (D) remain distinct. Source guided the tests but did not substitute for them.

## 3. Relationship to previous investigations

I015 established the physical READ/WRITE error and operator-presentation boundary. I025 consolidated application-visible file-operation failures and resource exhaustion. I033 established propagation, ignore/abort, and post-abort recovery. I037 completed selector/function coverage. I040 addressed damaged structures and direct-disk responsibility. I043 defined memory/loading boundaries.

I044 tests these layers together. It does not duplicate ledger propositions 390-413, 513-517, 529-532, 581-588, or 0618.

## 4. Failure visibility

CP/M 2.2 has no universal exception or error-number channel (**A/B**). A logical failure normally returns through the invoked function's result family. A final physical disk failure diverts BDOS into operator presentation and suspends the caller. Read-only/select failures may be nonreturning in DRI CP/M. CCP-level failures such as missing commands or oversized COM files are presented and recovered by CCP rather than returned to a transient.

FAIL44 observed FF for missing Open, 01 twice at EOF, 06 for random R2 overflow, and zero for unsupported selector 41 (**I**). The physical probe instead blocked at `Bad Sector`. Applications must interpret both the operation and whether control returned.

## 5. Resource exhaustion

Directory entries and allocation blocks are separate resources (**A/B**). On the 64-entry directory-full image with 178K data free, Make returned FF and Write was not called; the image remained identical. On the allocation-full image with a free directory slot, Make returned 01 and changed the directory, then sequential Write returned 02 without allocating a block or advancing CR (**I**).

This is a REQUIRED distinction. A later failure does not imply rollback of an earlier successful Make. Exact chosen slot, block-search order, FCB residue, or an atomic multi-call transaction is NOT GUARANTEED. Insufficient transient memory remains the configuration-dependent CCP loader boundary established by I043, not a BDOS allocation code.

## 6. Disk and file errors

**A.** File calls define per-function logical results: directory-code/FF families, sequential EOF/full results, and random I/O codes. BIOS READ/WRITE define zero success and nonzero permanent failure after recovery attempts. These namespaces are not interchangeable.

**I.** An injected physical read failure entered `Bad Sector`. After ignore, the sequential call returned 00 and advanced CR although DMA retained EE. A repeated failure answered with Control-C did not return to the probe. A following healthy read returned 00 with data byte 41. The fault was pre-transfer; no claim of general write atomicity follows.

Partial operation, affected FCB/DMA/search/allocation state, and persistence after ignored failure are NOT GUARANTEED. Applications must independently validate durable results when that matters.

## 7. Device failures

The CBIOS disk interface has an explicit result boundary, but the CP/M 2.2 character-device calls do not provide a parallel general physical-error result (**A/B**). CONST/status reports ready versus not-ready; CONIN/READER may wait; CONOUT/LIST/PUNCH provide no documented success/failure result to BDOS. Therefore unavailable input can be observed as not-ready or blocking according to the selected call, while output-device failure has no portable application return code.

FAIL44 observed Function 11 return 00 with no supplied character (**I**); this is a status result, not proof of device failure. Opening unavailable drive C produced DRI `Bad Sector`, did not return to OPEN25, and recovered after Control-C (**I**). Exact unavailable-drive classification and character-device fault presentation are BIOS/device dependent and NOT GUARANTEED beyond their documented interfaces.

## 8. Invalid input and parameters

Function contracts define valid selectors, FCB preparation, drive encodings, addresses, and other preconditions (**A**). They do not define one safe bad-parameter result. Selector 41, outside the strict 0-40 table, returned A/HL zero as already required by ledger 529 (**B/I**). Random Read with nonzero R2 returned 06 as documented. Missing Open returned FF.

Malformed or unactivated FCBs, invalid drive fields, and arbitrary pointers remain NOT GUARANTEED (ledger 517/532). No invalid-pointer dereference was performed: such a test could corrupt system state and would not establish a portable contract. Implementations may validate more aggressively outside strict mode, but strict compatibility must not replace defined function-specific results with one universal exception.

## 9. Recovery behavior

Returning logical failures leave the transient in control, subject to function-specific FCB/DMA mutation. Ignore at physical-error presentation resumes the interrupted DRI path without certifying that I/O occurred. Control-C aborts the caller and establishes a usable warm-started command environment (**A/B/I**).

In one session, the first injected read failure was ignored, the second was aborted, and an independent healthy read then succeeded. In a separate unavailable-drive case, FAIL44 ran completely after Control-C. Required recovery is public usability; exact caches, registers, stack, logged-drive details, reload sequence, and interrupted application state are NOT REQUIRED or NOT GUARANTEED as already classified.

## 10. Software ecosystem findings

Utilities and file managers branch on the result family of the operation they invoked, not on one global error. Development tools and compilers depend on a usable CCP after ordinary command/load errors. Communications software must distinguish nonblocking status from blocking character input and cannot assume a general character-output fault code. Disk utilities using direct BIOS calls own their retry/error policy at that boundary.

The DRI CCP itself demonstrates contextual handling: `NO FILE`, `BAD LOAD`, save/full failures, syntax errors, and BDOS fatal presentation are different paths (**B**). Historical compatibility therefore requires layered behavior, not a modern synthesized exception abstraction.

## 11. Documentation findings

The CP/M 2.0 Interface Guide documents function-specific return values for Close, Delete, sequential/random I/O, Make, Rename, and related file calls (**A**). It does not define a universal error value, transaction rollback, safe malformed-pointer behavior, character-device physical-error reporting, or preserved state after abnormal termination.

The CP/M 2.2 Alteration Guide documents BIOS READ/WRITE zero/nonzero results, at least ten recovery attempts before permanent error, `BDOS ERR ON x: BAD SECTOR`, carriage-return ignore, and Control-C abort (**A**). It assigns physical recovery responsibility at the BIOS/BDOS boundary without standardizing private controller statuses or internal handler layout.

## 12. Source findings

`OS3BDOS.ASM` initializes a result, dispatches valid selectors, constructs logical statuses in function-specific paths, and sends nonzero BIOS READ/WRITE results through `diocomp` to permanent-error presentation (**B**). `persub` reboots on Control-C and otherwise resumes; select/read-only handlers wait and reboot. These routine names, vectors, flags, and stacks are private.

`OS2CCP.ASM` handles command, load, and save failures contextually and returns to command acquisition (**B**). `CBIOS.ASM` supplies disk status/retry behavior, whereas its character-device entries expose ready/data operations without a common physical-error result (**B**).

## 13. Experimental results

The accepted tests ran under z80pack cpmsim 1.39, DRI CP/M 2.2, and Z80 CBIOS 1.2. All input was scripted. Full transcripts, before/after images, hashes, listings, source, binaries, and harnesses are preserved.

| Matrix state | Probe | Result |
|---|---|---|
| Normal | FAIL44 Function 12 | A=22, HL=0022 |
| Boundary | EOF twice | 01, then 01 |
| Boundary | R2 overflow / selector 41 | 06 / zero |
| Device status | no console input | 00 not-ready |
| File failure | missing Open | FF |
| Directory full | WRITE25 | Make FF; no Write; image unchanged |
| Allocation full | WRITE25 | Make 01; Write 02; created empty entry persisted |
| Unavailable drive | OPEN25 C | Bad Sector; caller abandoned on Control-C |
| Physical ignore | PHYS015 | returned 00; DMA EE; CR advanced |
| Repeated physical abort | PHYS015 | second caller abandoned; healthy follow-up read succeeded |

The returning/fatal ready images changed because FAIL44 intentionally created and deleted an empty file; physical directory-sector residue is not logical file persistence. The physical-error image was byte-identical. The harness terminal warning after its final interrupt is host shutdown noise.

## 14. Compatibility conclusions

**REQUIRED:** function-specific logical results; directory/allocation exhaustion distinction; BIOS disk zero/nonzero and retry boundary; suspension at permanent physical error; documented ignore and Control-C abort choices; strict unsupported-selector zero; and recovery to a usable command environment after abort.

**NOT GUARANTEED:** universal error codes; rollback; valid DMA or coherent FCB/search/allocation state after failure; persistence after ignored physical writes; safe malformed pointers/FCBs; output-device fault returns; exact unavailable-device classification; interrupted transient preservation; or corrupt-media repair.

**NOT REQUIRED:** DRI handler names, vectors, stacks, flags, exact retry loop placement, CCP reconstruction, z80pack statuses/fault port, directory residue, and private controller mechanics.

**POLICY PENDING:** exact diagnostic text; DRI's acceptance of every non-Control-C ignore character versus documented carriage return; optional structured/headless error extensions; strict-mode character-device timeout/fault presentation; and optional validation diagnostics for malformed calls.

## 15. Proposed ledger additions

None. The authoritative ledger ends at 0622, and every independently testable proposition supported here is already represented by entries 390-413, 513-517, 529-532, 579, 581-588, 0618, or their function-specific predecessors. Adding a generic “failure model” entry would be less testable and would wrongly flatten the function-specific distinctions.

Investigation 044 evidence should be cited as `I044 ERROR RECOVERY BDOS BIOS subsystem IG AG` when applied to existing entries. The ledger was not modified.

## 16. Existing-entry updates

- **390-396, 398-403:** add the repeated physical ignore/abort/healthy sequence as corroboration; retain all dispositions.
- **397:** its current REQUIRED disposition reflects later I035 resolution; add I044 recovery evidence without restoring the earlier policy-pending status.
- **404-408 and 513-517:** add FAIL44 plus directory/allocation-full reruns; preserve function-specific wording and no-rollback limitations.
- **411-413:** retain POLICY PENDING; I044 adds no evidence resolving text, accepted ignore characters, or structured extensions.
- **529-532:** add selector-41, R2-overflow, missing-FCB, and invalid-pointer discipline; do not generalize invalid requests.
- **579 and 581-588:** add unavailable-drive recovery and repeated physical failure; public recovery wording remains sufficient.
- **0618:** no change. Damaged-directory recovery was reviewed but not experimentally repeated because I044's controlled corruption question is already settled as NOT GUARANTEED.

Each evidence update uses `I044 ERROR RECOVERY BDOS BIOS subsystem IG AG`.

## 17. Open questions

1. Must strict mode reproduce DRI diagnostic text byte-for-byte or only semantic drive/error/choice presentation?
2. Must strict mode accept any non-Control-C ignore character, or only documented carriage return?
3. What optional structured interface can support headless operation without changing strict BDOS result families?
4. How should an optional profile expose character-output failure when CP/M 2.2 supplies no application result channel?
5. Which historical applications depend on exact post-ignore FCB/DMA residue despite its current NOT GUARANTEED classification?
6. Natural post-partial-transfer controller failures remain necessary to characterize particular media profiles, but cannot establish universal atomicity.

## 18. Conformance implications

A conformance suite must use a matrix rather than one generic failure test: success; each documented logical failure; directory full; allocation full; address overflow; unsupported selector; unavailable drive; final physical read/write failure; ignore; abort; repeated failure; and healthy post-recovery operation. It must observe whether the call returned, not merely A.

Tests must poison DMA/FCB state and independently inspect media after ignored or failed operations. They must not require rollback, atomicity, a safe arbitrary-pointer result, exact DRI private handlers, or output-device error codes. Fault injection must identify its transfer point so pre-transfer evidence is not misreported as partial-write evidence.

Completion audit: the report has all 18 required sections. Probe source/binaries, build instructions, deterministic harnesses, transcripts, ready before-images, after-images, hashes, manual renders, prior reports, and source excerpts exist. FAIL44 rebuilds byte-identically; preserved reference probes match their sources. The authoritative ledger retained SHA-256 `879e592198a07a73f7ec57dd6643392655fc2f8a296020e2aa7a99541ee40e79`. All protected pre-existing BetterCP/M files verify; no ledger, prior investigation, or implementation file was modified; no ZIP archive was created.
