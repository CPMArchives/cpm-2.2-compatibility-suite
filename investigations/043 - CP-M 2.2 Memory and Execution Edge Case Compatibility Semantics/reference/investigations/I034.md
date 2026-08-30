# Investigation 034 - CP/M 2.2 Memory Layout, System Area, and Transient Program Boundary Semantics

Evidence classes are **A** documented CP/M behavior, **B** behavior of the examined DRI implementation, **I** controlled experimental observation, and **D** unresolved BetterCP/M policy. These are report-local labels. Proposed ledger entries use the requested project evidence abbreviations.

## 1. Objective and scope

This investigation defines the CP/M 2.2 application-visible memory contract: page zero, system vectors, BDOS and BIOS access, CCP placement, the transient program area (TPA), COM loading, initial stack, and ownership boundaries.

It distinguishes three concepts that must not be collapsed: the documented TPA ceiling advertised through page zero, the lower ceiling enforced by the DRI CCP when loading a COM while retaining itself for ordinary RET, and the resident BDOS/BIOS area that a conforming application must preserve while using system services. Numeric addresses from the reference 62K configuration are observations, not portable constants.

## 2. Relationship to previous investigations

I001 established the original transient entry map. I002 and I027 established CALL 0005h and balanced BDOS return. I023 established the command-tail/default-FCB entry objects. I024 established RET, Function 0, and JMP 0000h lifecycle paths. I028 established complete CCP handoff, undefined unloaded memory, and loader boundary behavior. I033 confirms that WBOOT recovery is a public result rather than an exact reload implementation.

I034 does not duplicate those function-level propositions. It tests their simultaneous placement, derives the configured system boundaries, and resolves the relationship between ordinary COM loading, CCP overlay, direct system access, and stack ownership.

## 3. Documentation findings

**A.** The Alteration Guide reserves page zero as follows: 0000h-0002h WBOOT jump; 0003h optional IOBYTE; 0004h default drive; 0005h-0007h primary BDOS jump and memory-ceiling convention; documented restart/interrupt regions through 003Fh; 0040h-004Fh CBIOS scratch; reserved 0050h-005Bh; default FCB area beginning 005Ch; optional random-record bytes 007Dh-007Fh; and default 128-byte disk buffer/command tail at 0080h-00FFh.

**A.** All transient programs begin at 0100h. The operand at 0006h is both the target of the BDOS gateway and the documented upper-memory convention when the CCP is overlaid. The exact operand varies with configured memory size and debugging arrangements.

**A.** The guide explicitly permits a transient that no longer needs BDOS to overwrite normally prepared page-zero information and even relocate a memory image to address zero. If the BIOS or the WBOOT gateway at zero is destroyed, cold start rather than ordinary warm recovery is required. Permission to perform such specialized takeover is not a guarantee that system services continue after their code/data is overwritten.

**A.** COM images load at 0100h in 128-byte records. Documentation defines neither initial contents above the loaded records nor a numeric universal maximum COM size. It defines public gateways and results, not fixed CCP/BDOS/BIOS addresses.

## 4. Source findings

**B.** `OS2CCP.ASM` is relocatable. Its `tranm`/`ccploc` is the CCP lower address; its BDOS interface serialization location is CCP+0800h. The loader reads records at 0100h and upward and rejects when the next DMA destination reaches or exceeds `tranm`. It calls the transient at 0100h, so retaining CCP code and its private stack is necessary for ordinary RET.

**B.** `OS3BDOS.ASM` begins with six serialization bytes, places the callable entry jump six bytes later, and switches returning calls to a private BDOS stack. Exact source origins, six-byte values, private stack size/address, and routine layout are implementation details.

**B.** Distributed BIOS sources relocate CCP, BDOS, and BIOS together, install page-zero JMP operands, and implement WBOOT by reloading the configured resident components below BIOS. The actual system may use an equivalent mechanism.

In the reference configuration, source and observation agree on CCP E400h, DRI serialization/interface base EC00h, BDOS entry EC06h, and BIOS base FA00h. These numbers are not compatibility requirements.

## 5. Zero page semantics

Page zero is shared interface memory, not ordinary anonymous transient storage. Its defined fields retain their documented meanings at transient entry. Reserved, interrupt, scratch, and unused bytes do not acquire fixed-content guarantees merely because they are readable.

ZERO34 captured every byte from 0000h through 00FFh before and after a returning Function 12 call. Each within-call pair was identical in this reference run. Gateways were `C3 03 FA` at 0000h and `C3 06 EC` at 0005h. Other regions contained a mixture of BIOS code/scratch, FCB state, command buffer, and residual bytes rather than zeros (**I**).

At the later CCP entry following the overlay/WBOOT test, required gateway meanings were restored, but unused bytes in 0080h-00FFh differed from the earlier command entry. Only the counted command-tail portion and other documented fields are contracts; bytes beyond them are not (**I**, consistent with I023/I028).

Programs may read or modify documented application-facing objects for their stated purposes. Programs must not assign incompatible meanings to reserved/CBIOS areas or assume modifications survive BDOS, CCP, or WBOOT transitions. Deliberately overwriting gateways or system scratch changes which services remain callable.

## 6. BDOS entry semantics

The compatible application entry is CALL 0005h. C supplies the selector and DE/E supplies function-specific input; returning services restore caller SP and use their documented result convention (I002/I027).

The JMP operand at 0006h is configuration-visible, but callers must use the gateway rather than a private address behind it. In the reference, it was EC06h and Function 12 returned 0022h before and after the boundary tests (**I**).

The DRI image has six serialization bytes immediately below EC06h. The manual nevertheless advertises the 0006h operand as the overlay ceiling convention. This means an application using the extreme upper bytes must treat itself as an overlaying transient and cannot assume the DRI CCP serialization/ordinary-return path remains intact. Exact pre-entry header layout is not a portable API.

## 7. BIOS entry semantics

The BIOS is exposed as the documented 17-entry JMP table. With a valid page-zero WBOOT jump, the BIOS base is the operand at 0001h minus three; entries follow at three-byte intervals (I020).

VECTOR34 derived FA00h from WBOOT FA03h and invoked CONST through the vector at FA06h. With no pending input it returned 00h. The same probe invoked BDOS through 0005h and received version 0022h (**I**).

Direct calls through documented BIOS vector entries are compatibility-relevant and intentionally bypass BDOS transformations. Hard-coded FA00h, private targets behind JMP entries, table mutation, or undocumented register preservation are not guaranteed.

## 8. CCP memory placement

CCP location is relocatable and not directly fixed by the application ABI. The reference CCP began at E400h. Its first byte was C3h both before and after WBOOT recovery (**B/I**).

The DRI CCP loader protects itself: a 453-record COM ending with next destination E380h executed, while a 454-record image whose next destination reached E400h produced `BAD LOAD` and did not execute (**I022/I028/I034**).

CCP memory is nevertheless overlayable runtime workspace under the documented TPA convention. OVR34 adopted a private stack, changed E400h from C3h to A5h, continued to use resident BDOS for output, and exited through JMP 0000h. WBOOT restored CCP and the next commands ran (**I**). A program that overwrites CCP must not use ordinary RET into the destroyed command processor.

## 9. Transient program area

The TPA begins at 0100h. Its configured overlay ceiling is discovered through the 0005h jump operand; bytes below that operand may be used by a deliberate overlaying transient subject to preserving any services and recovery route it still needs (**A**).

In this reference the operand was EC06h, so the advertised last byte was EC05h. MEM34 wrote A5h there, read it back, restored the original byte, and then successfully called BDOS. OVR34 later wrote 5Ah there without restoration and used WBOOT, which restored the resident environment (**I**).

This does not make every byte initially free. CCP and its entry stack occupy part of the advertised overlay area during ordinary execution, and DRI serialization bytes occupy EC00h-EC05h. Applications choosing ordinary RET must avoid destroying the active CCP path and stack. Applications choosing a private stack and WBOOT may use more space, while resident BDOS/BIOS must remain intact if called.

The TPA is one flat, contiguous address space in baseline CP/M 2.2. No bank isolation, process protection, allocation API, or automatic bounds enforcement is promised.

## 10. COM program loading

CCP loads successful Function-20 records contiguously at 0100h and executes only an accepted image. LOAD34 was 017Ah bytes on the host and occupied three CP/M records. It saw its own loaded bytes at 0100h, 0180h, and 0200h, while sampled upper memory contained residual values (**I**).

LARGEOK (453 records, 57,984 bytes) executed its marker. TOOLARGE (454 records, 58,112 bytes) produced `BAD LOAD` without its marker. Both began with the same executable header; only record count differed (**I**).

The important distinction is that maximum loadable COM size is set by CCP's need to remain available for the CALL/RET path and is not necessarily the full documented overlay TPA. Programs can acquire additional runtime workspace only after entry and only with an appropriate private stack/recovery strategy. Exact maximum sizes, final-record padding, and unloaded bytes are not portable.

## 11. Stack semantics

CCP's CALL 0100h supplies a valid return word. It does not supply a separately cleared or numerically specified application stack. STACK34 observed entry SP EBA9h and return word EB5Fh, copied eight bytes, moved to a private stack for diagnostics, restored the entry SP, and RET returned to CCP (**I**).

Those addresses lie in the reference CCP/upper overlay region and are configuration-specific. A program that wants to use that region must establish its own stack before overwriting it and must not rely on the original RET path afterward. Stack growth direction is the processor's downward Z80/8080 behavior, but available depth and surrounding bytes are not promised by CP/M.

Returning BDOS calls preserve caller stack balance, yet BDOS may use its own private stack internally. Applications own and must size any stack they establish.

## 12. Memory ownership

| Region | Compatibility ownership during ordinary transient execution |
|---|---|
| 0000h-00FFh | Shared system/application interface page; defined objects have defined roles; reserved/scratch bytes are not ordinary guaranteed storage |
| 0100h through loaded image | Transient code/data owned by the application |
| Unloaded TPA below CCP | Available application workspace with undefined initial contents |
| Active CCP and entry stack | System-owned for ordinary RET, but deliberately overlayable if the program adopts another termination/recovery path |
| BDOS interface/resident code and data | System-owned while BDOS services or warm recovery depend on it |
| BIOS vector/code/data | System-owned; documented vectors callable, implementation storage not application workspace |

CP/M provides no hardware protection among these regions. “System-owned” is a compatibility obligation on software, not a memory-access barrier. A write may physically succeed while invalidating later behavior.

During returning BDOS calls, application TPA and caller stack are expected to remain usable according to the call contract, but arbitrary registers and undocumented system scratch are not preserved. Ordinary RET allows CCP to reconstruct the next command environment; WBOOT may reload resident regions. Arbitrary TPA residue is not preserved state.

## 13. Direct system access

**REQUIRED:** CALL 0005h; JMP 0000h; documented page-zero fields; derivation and invocation of documented BIOS vector entries; the 0006h memory-ceiling convention.

**NOT GUARANTEED:** direct calls into private BDOS/CCP routines, hard-coded system addresses, exact bytes in reserved page zero, DRI serialization layout, private stacks, or direct mutation of vector targets.

Direct BIOS calls bypass BDOS and use BIOS-specific documented inputs/outputs. Direct BDOS calls use the function ABI. Access to DPH/DPB and other documented returned tables remains governed by their own investigations; visibility of an address does not turn all adjacent system memory into an API.

## 14. Experimental results

The accepted run used z80pack cpmsim 1.39, DRI CP/M 2.2, Z80 CBIOS 1.2, a fresh tailored image, and scripted input only. Before/after disk images were byte-identical.

| Matrix requirement | Evidence | Result |
|---|---|---|
| Standard zero page | ZERO34 initial capture | Required gateways and entry objects present; other bytes varied |
| State across BDOS call | ZERO34 Function 12 | All 256 captured bytes unchanged in this call pair |
| CCP return/restart state | final MEM34/ZERO34 after OVR34 | Gateways/CCP restored; later command ran; unused buffer residue differed |
| Small COM | LOAD34 | 378-byte image executed at 0100h; three records visible |
| Large COM | LARGEOK | 453 records executed |
| First rejected COM | TOOLARGE | 454 records: `BAD LOAD`, no marker |
| Program termination | STACK34/OVR34 | RET worked with saved stack; overlay recovered through JMP 0000h |
| TPA beginning | all probes | entry and first loaded byte at 0100h |
| Advertised TPA end | MEM34/OVR34 | 0006h=EC06; EC05 writable; exact value configuration-specific |
| System boundaries | MEM34/VECTOR34 | CCP E400, DRI header EC00, BDOS entry EC06, BIOS FA00 in reference |
| BDOS vector access | VECTOR34 | Function 12 through 0005h returned 0022h |
| BIOS vector access | VECTOR34 | derived CONST entry returned 00h |
| Direct zero-page access | ZERO34 | complete 256-byte snapshots preserved |
| Transient/BDOS/CCP transitions | full scripted sequence | ordinary calls returned; RET reprompted; WBOOT restored overlaid CCP |

The probes do not establish a cross-implementation numeric CCP/BDOS/BIOS layout, precise free-stack depth, guaranteed residue, memory protection, or behavior after overwriting BIOS/WBOOT. The guide states cold start is required when those recovery facilities are destroyed; no destructive BIOS overwrite was performed.

## 15. Compatibility conclusions

**REQUIRED**

- Page-zero documented locations and semantic gateways; transient origin/entry at 0100h; contiguous TPA convention and configured upper-bound discovery.
- CALL 0005h BDOS access and documented direct BIOS vector access.
- Contiguous 128-byte COM loading, protection of the active resident/CCP load boundary, valid entry RET word, and usable warm recovery.
- An implementation must permit the documented flat-memory model even if its internal architecture differs.

**NOT GUARANTEED**

- Numeric CCP, BDOS, BIOS, stack, or maximum-COM addresses; unloaded memory; unused page-zero bytes; exact entry SP/return address/depth; arbitrary memory persistence after termination.
- Successful continued use of a system component after its memory has been overwritten.
- That the normal CCP COM-loader maximum equals all memory available to a deliberate overlaying program.

**NOT REQUIRED**

- DRI's CCP/BDOS sizes, six-byte serialization layout, exact loader comparison, private stacks, WBOOT reload sectors, internal relocation method, or clearing unused memory.

**POLICY PENDING**

- Whether BetterCP/M offers optional memory protection or cleared TPA modes while retaining a strict flat-memory compatibility mode.
- Whether diagnostics should warn when software overwrites advertised system regions; CP/M itself supplies no protected-process model.

## 16. Proposed Compatibility Ledger additions

The authoritative ledger ends at 0588. The following proposals begin at 0589 and avoid duplicating the established page-zero, loader, BIOS-vector, and stack entries.

### 0589. Loader ceiling and overlay TPA are distinct

    The largest COM image accepted by the active CCP loader may be smaller than
    the configured TPA advertised through the 0005h jump operand, because the
    loader may retain CCP and its return environment while an executing transient
    may deliberately overlay them.

    Disposition: REQUIRED
    Evidence: I034; MEMORY; CCP; AG; I028
    Conformance: Compare the first rejected COM record with runtime writes below
    the advertised 0006h ceiling using a safe private stack and recovery path.

### 0590. CCP overlay invalidates ordinary RET assumptions

    A transient that overwrites active CCP code, data, or its supplied return
    environment cannot rely on ordinary RET into that environment; it must retain
    a valid recovery route such as programmed warm restart.

    Disposition: REQUIRED
    Evidence: I034; MEMORY; CCP; BIOS; AG
    Conformance: Overwrite controlled CCP bytes after adopting a private stack,
    avoid RET, invoke WBOOT, and verify a usable command environment is restored.

### 0591. System ownership is an application obligation

    CP/M 2.2 provides no memory-protection barrier between transient and system
    regions. A physically successful write to page zero, CCP, BDOS, or BIOS does
    not guarantee that the overwritten service, return path, or restart remains
    valid.

    Disposition: NOT GUARANTEED
    Evidence: I034; MEMORY; BDOS; BIOS; AG
    Conformance: Test documented accesses normally and treat destructive writes
    only as isolated takeover cases with an independently retained recovery path.

### 0592. Entry-stack storage may occupy overlayable memory

    The valid transient entry return word and surrounding stack may reside in
    memory that an overlaying application otherwise intends to use; exact stack
    placement, capacity, and survival after overlay are not guaranteed.

    Disposition: NOT GUARANTEED
    Evidence: I034; MEMORY; CCP; I001; I028
    Conformance: Vary entry stack placement; require immediate RET, but require an
    overlaying program to establish its own stack before consuming that region.

## 17. Proposed existing-entry updates

- **0001-0003:** add I034 experimental corroboration; no wording or disposition change.
- **0004:** add I034 and clarify that the 0006h operand is both the BDOS entry target and documented overlay-ceiling convention. The normal CCP loader may impose a lower COM-file ceiling, and DRI-private bytes immediately below the entry are not a portable layout guarantee.
- **0005-0017, 0023-0024:** add ZERO34/VECTOR34 evidence only where it strengthens the existing page-zero map; do not duplicate default FCB, tail, or DMA propositions.
- **0031-0034:** add STACK34/MEM34 evidence for nonportable registers, flags, stack, and numeric vector targets; no disposition change.
- **0042-0044 and 0526-0533:** add I034 for gateway/stack layering; DRI private BDOS stack remains NOT REQUIRED.
- **0461-0474:** add VECTOR34 as direct-call and discovery corroboration; exact BIOS placement remains NOT GUARANTEED.
- **0496-0505:** add LOAD34/LARGEOK/TOOLARGE evidence. Preserve the configured loader-boundary and numeric-maximum dispositions.
- **0534-0541:** add I034 simultaneous handoff, unloaded-memory, stack, and post-recovery evidence; no duplicate entries.

## 18. Open questions

1. How widely did non-DRI CCPs retain themselves below the documented overlay ceiling versus intentionally allowing larger COM images?
2. Which historical applications use the 0006h operand as heap/stack ceiling, and do any consume the DRI serialization bytes immediately below the callable entry?
3. Should strict BetterCP/M reproduce writable flat memory exactly while an optional mode protects resident pages?
4. Should an optional cleared-memory mode be exposed only outside strict compatibility because unused TPA contents are currently NOT GUARANTEED?
5. Cross-memory-size repetitions would strengthen the separation between semantic discovery and the observed E400h/EC06h/FA00h constants.

## 19. Conformance implications

A conformance suite should run at multiple configured memory sizes. It must verify entry at 0100h, page-zero roles, CALL 0005h, BIOS discovery from WBOOT, the configured upper-bound convention, small/multirecord loading, largest accepted/first rejected COM images, valid immediate RET, and WBOOT recovery after a controlled CCP overlay.

Tests must vary unused TPA bytes, entry SP, return address, vector targets, and numeric resident placement. They must not require zero-filled memory, a fixed 62K map, the DRI six-byte serialization header, an exact CCP loader maximum, or use of DRI private addresses. A destructive-overlay test must first establish a private stack and preserve WBOOT/BIOS; otherwise it tests self-corruption rather than CP/M conformance.

## Preservation and completion audit

- The report and five required named ASM/COM probes exist; additional OVR34 and large-boundary fixtures are preserved.
- Each named probe has purpose, procedure, observation, and compatibility conclusion in `probes/observed-output.txt`.
- The scripted matrix contains no manually typed input.
- All recorded COM files rebuild byte-identically; `rebuild.diff` is empty.
- Before/after disk-image hashes are identical.
- Source documents, prior reports, transcripts, build instructions, listings, images, and hash manifests are preserved.
- No prior BetterCP/M file or Compatibility Ledger was modified. The ledger's pre-investigation hash is preserved.

## Sources

- Digital Research, *CP/M 2.0 Interface Guide*.
- Digital Research, *CP/M 2.2 Alteration Guide*, sections 6 and 9, especially printed pages 23-24.
- Digital Research, `OS2CCP.ASM`, `OS3BDOS.ASM`, `BIOS.ASM`, and `CBIOS.ASM`.
- BetterCP/M Investigations 001, 002, 020, 022-024, 027, 028, and 033.
- z80pack cpmsim 1.39 with DRI CP/M 2.2 and Z80 CBIOS 1.2.
