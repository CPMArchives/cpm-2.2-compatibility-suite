# Investigation 041 - CP/M 2.2 Direct System Access and Undocumented Application Interface Compatibility Semantics

## 1. Objective and scope

This investigation defines the CP/M 2.2 compatibility boundary for software that touches system interfaces directly. It covers the public BDOS gateway, documented direct BIOS vector, page-zero data and vectors, fixed-address assumptions, and historically important interposition practices. It does not specify BetterCP/M internals, CP/M 3 or MP/M extensions, or invisible algorithms.

The principal result is a layered contract. `CALL 0005h`, the documented page-zero objects, and BIOS vectors discovered through the WBOOT gateway are compatibility interfaces. The numeric implementation targets behind those gateways, private resident structures, and unspecified bytes are not. A strict compatibility profile must expose the documented flat-memory surface used by historical software, while a program that bypasses a gateway assumes responsibility for the lower-level semantics it reaches.

## 2. Compatibility standard

Evidence is labelled as follows:

- **A**: documented CP/M behavior in the CP/M 2.0 Interface Guide (IG) or CP/M 2.2 Alteration Guide (AG).
- **B**: Digital Research implementation or distributed-program behavior.
- **I**: controlled observation in the z80pack CP/M 2.2 reference environment.
- **D**: unresolved BetterCP/M policy.

An undocumented behavior is not required merely because it occurred once. Historically significant DRI program dependencies can establish that a compatibility mode must accommodate a *class* of access, but do not freeze incidental addresses or private code. Findings are classified REQUIRED, NOT GUARANTEED, NOT REQUIRED, or POLICY PENDING.

## 3. Relationship to previous investigations

I002 and I027 established the public BDOS register and return convention. I020 established the 17-entry BIOS vector, direct character calls, boot behavior, and page-zero reconstruction. I034 established the application-visible memory map and ownership boundary. I036 established BIOS as the configured hardware-abstraction boundary. I037 consolidated BDOS Functions 0-40. I040 established that direct disk callers must use configured BIOS geometry and do not inherit BDOS file-system protection.

I041 does not repeat those propositions. It tests their direct-access implications, adds ecosystem evidence, tests reversible gateway interposition and private-target bypass, and identifies one missing negative guarantee.

## 4. Direct BDOS access

**Documented boundary (A).** The Interface Guide locates the principal FDOS/BDOS entry at BOOT+0005h, normally 0005h, and describes calls as a function number plus information address. The Alteration Guide identifies 0005h-0007h as a JMP to BDOS and describes it as the primary entry. I002/I027 supply the exact CP/M 2.2 convention: C is the selector; DE or E is function-specific input; documented results are returned in A or HL with the established aliases; returning calls balance caller SP.

**Implementation and ecosystem (B).** DUMP and SYSGEN invoke BDOS at 0005h. AS0COM and CPMOVE inspect the operand at 0006h to learn configured high memory. XSUB saves that operand, redirects the gateway to a trap, chains the saved target, and restores it. These programs distinguish the stable gateway and configured operand from a universal numeric resident address.

**Observation (I).** BDOS41 called representative selectors through 0005h. Function 12 returned 0022h, Function 7 returned the fixture IOBYTE A5h, Function 24 returned a login vector, Function 26 returned normally, and out-of-range selector 41 returned zero. Returning calls balanced SP. MOD41 temporarily replaced the gateway target, observed exactly one wrapper call returning 0022h, and restored the bytes. DIRECT41 bypassed the gateway and the current private target happened to return 0022h.

**Conclusion.** `CALL 0005h` and the documented calling convention are **REQUIRED**. The configured operand is readable for its documented memory-ceiling role. Calling the current target directly, depending on bytes immediately before/after it, or assuming the target never changes is **NOT GUARANTEED**. DRI's private BDOS entry layout is **NOT REQUIRED**.

## 5. Direct BIOS access

**Documented boundary (A).** The Alteration Guide defines 17 consecutive three-byte JMP entries from BOOT through SECTRAN and defines each register-level service. Because 0000h jumps to the WBOOT entry, software can derive the vector base as the word at 0001h minus three. Exact placement varies with configuration.

**Implementation and ecosystem (B).** SYSGEN reads WBOOT's operand and computes SELDSK, SETTRK, SETSEC, SETDMA, READ, and WRITE by documented offsets. OS3BDOS likewise names every BIOS offset. CBIOS places implementation handlers behind the public table.

**Observation (I).** BIOS41 derived FA00h in this configuration and found 17 consecutive C3h entries. Under reversible deterministic fixtures, direct CONST returned 00h/FFh, CONIN 41h, READER 52h, LISTST 00h/FFh, and CONOUT/LIST/PUNCH received C=09h/10h/1Ah. DIRECT41 called SELDSK directly with invalid C=FFh and received HL=0000h; the harness then stopped without claiming a usable command state.

**Conclusion.** Discovery, order, and the documented service conventions are **REQUIRED**. FA00h and handler targets are **NOT GUARANTEED**. A direct caller receives raw BIOS behavior and bypasses BDOS validation, allocation, diagnostics, and recovery. Exact behavior after an invalid direct call is **NOT GUARANTEED** unless the declared machine profile specifies it.

## 6. Zero-page compatibility

AG section 9 assigns externally visible roles to 0000h-0002h (WBOOT JMP), optional 0003h (IOBYTE), 0004h (current drive), 0005h-0007h (BDOS JMP and high-memory convention), restart/reserved areas, 0040h-004Fh BIOS scratch, 005Ch onward default FCB state, and 0080h-00FFh default DMA/command tail (**A**).

ZERO41 observed `C3 03 FA 00 00 C3 06 EC` at 0000h-0007h and identical selected page-zero bytes before and after Function 12. The command-tail bytes varied appropriately between process invocations (**I**). The observed addresses and transient-supplied contents are instance data, not constants.

Defined locations and meanings are **REQUIRED**. Optional IOBYTE semantics remain conditional on the configured profile. Exact bytes in reserved, scratch, interrupt, unused, FCB-residual, or command-tail regions are **NOT GUARANTEED** beyond their separately documented lifecycle.

## 7. System vector compatibility

The JMP at 0000h, JMP at 0005h, and the configured BIOS jump table are compatibility-visible vectors (**A**, **B**, **I**). They must be valid at transient entry and re-established by WBOOT before CCP resumes, as already required by entries 0001, 0004, and 0461-0466.

The reference system stored them in ordinary writable memory. MOD41 and BIOS41 reversibly patched vectors, and XSUB demonstrates a shipped DRI interposition use (**B**, **I**). This strengthens the need for a strict flat-memory mode in which these bytes are visible and writable. It does not guarantee that arbitrary modifications survive BDOS, CCP transitions, WBOOT, or a service whose implementation was overwritten. Exact vector operands and targets remain configuration-dependent.

## 8. Fixed memory assumptions

The fixed application-visible anchors are page zero and the TPA origin 0100h (**A**). BOOT is normally 0000h and the public BDOS gateway normally 0005h in standard CP/M 2.2. Default FCBs and command/DMA storage have documented page-zero addresses. These are interface addresses, not frozen resident-layout addresses.

The CCP base, BDOS implementation base, BIOS base, private stacks, serialization bytes, maximum accepted COM size, and handler addresses move with memory size and configuration (**A**, **B**, I034). Hard-coded values such as E400h, EC06h, or FA00h observed here are **NOT GUARANTEED**. Software must follow public indirection and returned parameter structures.

## 9. Software ecosystem findings

The examined DRI programs represent system utilities, a disk/system-generation utility, an assembler component, and a command-submission tool:

| Program | Direct-access pattern | Compatibility significance |
|---|---|---|
| DUMP | CALL 0005h; JMP 0000h recovery | Public gateways are common application conventions. |
| AS0COM | Reads word at 0006h | Documented configured ceiling is used by development tools. |
| SYSGEN | Derives BIOS disk entries from WBOOT | Direct documented BIOS access is historically significant. |
| XSUB | Saves, redirects, chains, and restores 0005h/WBOOT operands | Reversible gateway interposition matters to strict DRI compatibility. |
| CPMOVE | Reads 0006h and manipulates a copied system image | Relocation tools use documented anchors plus private, tool-specific knowledge. |
| CBIOS/OS3BDOS | Establish vectors; use fixed offsets behind configured bases | Public vector shape is stable; internal handlers are not. |

No examined source supports a universal fixed numeric BDOS/BIOS implementation address. Debuggers may use the documented RST 7/DDT region when configured, but DDT-specific targets and breakpoint implementation are not a general CP/M application ABI. Disk utilities that call BIOS directly must follow the configured DPH/DPB/translation contract established by I040.

## 10. Documentation findings

The Interface Guide documents a relocatable system organization, BOOT=0000h and TBASE=0100h for standard systems, the FDOS gateway at BOOT+0005h, its operand as the configured FBASE/high-memory value, transient return through BOOT, and function-number/information-address service calls (**A**).

The Alteration Guide documents the complete page-zero allocation, the dual role of the 0005h JMP, overwrite conditions for overlaying programs, the WBOOT/BDOS gateway setup, and the ordered BIOS table with register contracts (**A**). It explicitly permits page zero and system memory to be overwritten by a transient that no longer requires affected facilities, placing recovery responsibility on that program. Neither manual promises private entry labels, fixed resident addresses, arbitrary reserved bytes, or a general preservation contract for undocumented state.

## 11. Source findings

CBIOS installs the two page-zero JMPs and publishes the BIOS table. OS3BDOS dispatches user calls after entry through the configured BDOS gateway and calls BIOS by vector offsets. Its private dispatch tables, stacks, messages, and labels are implementation mechanisms (**B**).

DUMP uses the public gateway. AS0COM reads the documented gateway operand. SYSGEN discovers BIOS via WBOOT. XSUB deliberately interposes the BDOS gateway while preserving and chaining its target. CPMOVE combines documented anchors with release-specific relocation knowledge (**B**). The diversity shows why direct access must be assessed by interface object: documented vectors and structures are portable; source-local targets and algorithms are not.

Source review generated the MOD41 and DIRECT41 tests but did not substitute for their experimental evidence.

## 12. Experimental results

### Controlled matrix

| Access/state | Probe | Controlled operation | Observed result | Evidence |
|---|---|---|---|---|
| Documented, normal | BDOS41 | CALL 0005h representative functions | Documented values; balanced return | I |
| Documented, normal | VECTOR41/ZERO41 | Read public page-zero objects | Valid JMPs; visible transient state | I |
| Direct, normal | BIOS41 | Discover and invoke BIOS table | 17 JMPs; raw service conventions | I |
| Documented, boundary | BDOS41 | Selector 41 | Zero result | I027/I041 |
| Direct, boundary | BIOS41 | First/last vector and status endpoints | BOOT-SECTRAN shape; 00h/FFh statuses | I |
| Modified | MOD41 | Interpose 0005h and chain target | One call; 0022h; restored | I |
| Modified | BIOS41 | Reversible vector fixtures | Deterministic args/results; restored | I |
| Direct, failure | DIRECT41 | SELDSK C=FFh | HL=0000h; no recovery claim | I |
| Undocumented direct | DIRECT41 | Call word at 0006h as routine | 0022h in this build only | I |

Each probe's purpose, procedure, observed behavior, and compatibility conclusion appear in `probes/observed-output.txt`; complete transcripts and source are preserved. The terminal I/O warning occurs only after deliberate harness interruption and is not classified as CP/M behavior.

Fresh drive images were restored for the matrix. Before/after SHA-256 values matched for both drives, so the experiments made no persistent media change.

## 13. Compatibility conclusions

**REQUIRED**

- CALL 0005h with the established CP/M 2.2 BDOS convention and documented results.
- JMP 0000h programmed restart and valid WBOOT/BDOS gateways at transient entry.
- Documented page-zero roles, TPA origin 0100h, default FCBs, and command/DMA area.
- The 0006h operand's documented configured-ceiling meaning.
- Discovery and direct invocation of the documented 17-entry BIOS vector.
- Raw BIOS service semantics and direct-caller responsibility for bypassed BDOS policy.
- A strict compatibility profile in which documented page-zero/vector bytes are application-visible in the CP/M flat address space.

**NOT GUARANTEED**

- Fixed numeric CCP, BDOS, BIOS, stack, vector-target, or private-entry addresses.
- That calling the current target behind 0005h is equivalent to using the gateway.
- Contents of reserved/scratch/unused page-zero bytes or unspecified registers.
- Persistence or safety of arbitrary vector/system-memory modifications.
- BDOS diagnostics, validation, allocation protection, or recovery after direct BIOS calls.
- Exact outcomes after invalid direct calls beyond a declared platform profile.

**NOT REQUIRED**

- DRI dispatch tables, serialization layout, internal labels, handler code, private stacks, and exact CCP/BDOS/BIOS placement.
- DDT's exact private implementation or any emulator/host-device mechanism.
- Replication of incidental bytes and addresses observed in the 64K z80pack build.

**POLICY PENDING (D)**

- Whether non-strict BetterCP/M profiles offer protected vectors, warnings, or denied direct writes. Any such mode must be distinguished from the strict CP/M 2.2 compatibility profile.
- Whether to emulate particular third-party private-entry dependencies after concrete software is identified and tested; no generic promise is justified now.

## 14. Proposed ledger additions

The authoritative ledger ends at 0618. Only one new independently testable proposition is justified; the remaining findings strengthen existing entries.

### 0619. Private BDOS target is not an application gateway

    The address stored in the 0005h JMP operand identifies the configured BDOS
    entry and memory ceiling, but an application is not guaranteed that calling
    that target directly is equivalent to CALL 0005h or remains valid across
    conforming implementations and configurations.

    Disposition: NOT GUARANTEED
    Evidence: I041 SYSTEM BDOS BIOS MEMORY subsystem IG AG; DIRECT41; XSUB;
              AS0COM
    Conformance: relocate or wrap the BDOS implementation while preserving CALL
                 0005h and verify conforming applications continue to operate;
                 do not accept a private-target caller as a general conformance
                 requirement.

This proposal has not been applied.

## 15. Existing-entry updates

- **0001 and 0004:** add I041 VECTOR41/ZERO41/MOD41 and XSUB/CBIOS as evidence that the gateways are visible, configured indirections; retain REQUIRED.
- **0005-0017 and 0023-0024:** add ZERO41 only as corroboration of defined page-zero roles; do not guarantee incidental bytes or duplicate I023/I034.
- **0042-0044 and I027 call-interface entries:** add BDOS41 and DIRECT41 to sharpen the public-gateway/private-target boundary; no register-preservation expansion.
- **0461-0474:** add BIOS41 and DIRECT41 as direct discovery/invocation evidence; retain NOT GUARANTEED for exact base, handler targets, and invalid lower-level behavior.
- **0589-0592:** add MOD41 and the XSUB ecosystem example. Entry 0591 already supplies the necessary flat-memory ownership warning; do not add a duplicate vector-write entry.
- **0598-0600 and 0617:** add DIRECT41 as corroboration that direct BIOS callers receive raw results and bypass BDOS/CCP policy; retain their existing dispositions.

No correction to an existing disposition was found, and the ledger was not modified.

## 16. Open questions

1. Which third-party CP/M 2.2 programs call private BDOS targets rather than using 0005h, and are any important enough for an opt-in quirk profile?
2. Which debuggers depend on particular RST vectors or DDT-private layouts beyond the documented page-zero reservation?
3. Should BetterCP/M's non-strict profiles diagnose writes to gateways or resident system memory, while the strict profile preserves flat-memory behavior? (**D**)
4. Should a conformance declaration enumerate optional support for reversible gateway interposition separately from ordinary application compatibility? (**D**)

These questions do not block the CP/M 2.2 baseline contract.

## 17. Conformance implications

A conformance suite should run at multiple configured memory sizes. It should verify CALL 0005h without assuming its target, inspect the documented page-zero roles, derive BIOS from WBOOT, exercise all 17 JMP slots, test raw character vectors, and confirm configured disk access through BIOS parameters. It should vary implementation targets while keeping public gateways stable.

A strict profile should also run a reversible 0005h interposition test and restore all bytes. Destructive or invalid direct calls must be isolated and must not be used to demand unspecified post-failure state. Tests must reject hard-coded z80pack addresses and private DRI structures as universal requirements.

### Completion audit

- Investigation directory and all referenced report, source, executable, transcript, image, and hash artifacts: verified.
- Six COM probes rebuilt byte-identically: verified; see `probes/rebuild-verification.txt`.
- Fresh controlled images unchanged except as expected: verified; both were unchanged.
- Existing BetterCP/M substantive files outside Investigation 041: verified unchanged against the preserved pre-investigation manifest. Two Finder-managed `.DS_Store` files changed independently during the work; their before/after hashes are explicitly disclosed in `probes/protected-files-audit.txt`. Investigation 041 did not write or reconstruct them.
- Compatibility Ledger: not modified; preserved SHA-256 recorded in `probes/ledger-sha256-before.txt` and `probes/ledger-sha256-after.txt`.
- Proposed ledger addition and unresolved policy questions: present above.
- Artifact SHA-256 manifest: `SHA256SUMS.txt`.

### Evidence sources

- Digital Research, *CP/M 2.0 Interface Guide*, system organization and FDOS entry.
- Digital Research, *CP/M 2.2 Alteration Guide*, sections 6 and 9 and distributed source listings.
- DRI sources preserved under `reference/`: AS0COM, CBIOS, CPMOVE, DUMP, OS3BDOS, SYSGEN, XSUB1.
- Investigations 002, 020, 027, 034, 036, 037, and 040.
- z80pack CP/M 2.2 controlled observations preserved under `probes/`.
