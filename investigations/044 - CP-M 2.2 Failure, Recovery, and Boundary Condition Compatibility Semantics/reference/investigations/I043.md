# Investigation 043 - CP/M 2.2 Memory and Execution Edge Case Compatibility Semantics

Evidence classes are **A** documented CP/M behavior, **B** behavior of the examined Digital Research implementation or distributed software, **I** controlled experimental observation, and **D** unresolved BetterCP/M policy. Numeric addresses reported by the probes describe the reference 62K system only.

## 1. Objective and scope

This investigation determines which unusual memory and execution behaviors belong to the CP/M 2.2 compatibility surface. It covers the TPA boundary, near-limit COM loading, entry and private stacks, page-zero-mediated recovery, self-modifying execution, controlled system overlap, and representative DRI software dependencies. It does not design BetterCP/M memory architecture, introduce a modern process model, or implement changes.

The central question is not whether an 8080/Z80 can perform a memory operation, but whether documentation, the DRI implementation, experiment, or historically important software gives that operation compatibility weight.

## 2. Compatibility standard

A behavior is **REQUIRED** when CP/M documentation defines it or conforming execution of standard or materially representative CP/M software depends on it. **NOT GUARANTEED** marks observable state on which portable software cannot rely. **NOT REQUIRED** excludes DRI-private mechanics when the public result can be reproduced another way. **POLICY PENDING** records an unresolved BetterCP/M choice outside the strict baseline.

Evidence is kept separate: manuals establish A claims; DRI source and distributed utilities establish B claims; scripted z80pack runs establish I claims; design choices remain D. No conclusion rests solely on source reconstruction.

## 3. Relationship to previous investigations

I001 and I023 define transient entry, page zero, command tail, and default FCBs. I024 defines RET, Function 0, and JMP 0000h lifecycle paths. I034 defines the memory map, configured TPA ceiling, CCP overlay distinction, stack ownership, and absence of memory protection. I041 separates public gateways from private system targets. I042 establishes compatibility with standard ecosystem behaviors including XSUB.

I043 therefore does not re-propose those contracts. It repeats their most relevant boundary cases to check composition and adds one missing proposition: writable code and coherent execution of a modified instruction in the transient area.

## 4. Transient memory boundary

**A.** The transient begins at 0100h. The word at 0006h supplies the configured BDOS-entry/upper-memory convention; the exact address varies with system size. A specialized transient may use overlay memory below that ceiling when it preserves the facilities it still needs.

**I.** EDGE43 read EC06h at 0006h, wrote A5h to EC05h, read A5h back, restored the original 00h, and subsequently called BDOS successfully. EC05h and 00h are reference-instance values.

**Conclusion.** The discoverable boundary and flat writable TPA behavior are REQUIRED. A particular ceiling, initial last-byte content, or availability of active CCP/stack bytes to a program intending ordinary RET is NOT GUARANTEED. This corroborates ledger 0004 and 0589–0592.

## 5. Program loading assumptions

**A/B.** COM records load contiguously from 0100h. `OS2CCP.ASM` advances a 128-byte DMA destination and rejects a next record that would collide with `tranm`, because the DRI CCP remains present to CALL the program and receive ordinary RET.

**I.** MAXOK43.COM (453 records, 57,984 bytes) executed. MAXBAD43.COM (454 records, 58,112 bytes), with the same executable prefix, produced `BAD LOAD` and did not execute its marker.

**Conclusion.** Contiguous loading and enforcement of the configured loader ceiling are REQUIRED. The observed 453-record maximum, comparison instruction sequence, diagnostic bytes, and equality between any one CCP's ceiling and another implementation's ceiling are NOT REQUIRED. Programs may size themselves from documented/configured information; they may not assume a universal maximum or defined unloaded-memory contents.

## 6. Stack and execution assumptions

**A/I.** A transient has a valid entry return word, but exact SP, return address, surrounding contents, and capacity are not specified. EDGE43 observed SP EBA9h and return word EB5Fh. After changing to an application-owned stack it observed SP 02F5h both before and after returning Function 12, whose result was 0022h.

ZRET43 put 0000h on its own stack and executed RET; command processing resumed through the page-zero WBOOT gateway. FN043 adopted its own stack and invoked Function 0; it did not reach the following failure marker, and command processing resumed. These are compositions of previously established interfaces, not new guarantees about the entry word's numeric value.

**Conclusion.** A usable entry RET, caller-managed stacks, balanced returning BDOS calls, nonreturning Function 0, and WBOOT recovery are REQUIRED. Exact stack placement and a supplied zero return word are NOT GUARANTEED. DRI private-stack locations are NOT REQUIRED.

## 7. Page-zero interaction

The relevant public objects are the WBOOT jump at 0000h, BDOS jump at 0005h, its operand/memory convention at 0006h, and the other documented entry objects established by prior investigations (**A**). ZRET43 and OVER43 used 0000h; EDGE43 used 0005h and 0006h (**I**).

DDT and XSUB demonstrate historically significant rewriting of page-zero restart or gateway fields (**B**), but their precise patches do not redefine all of page zero as application-owned storage. Documented gateway semantics are REQUIRED. Incidental bytes, private targets, universal preservation of application patches, and arbitrary use of reserved/scratch locations are NOT GUARANTEED.

## 8. Memory overlap behavior

**B.** DDT implements software breakpoints by replacing a target byte with an RST instruction and later restoring the original byte. CPMOVE copies and patches executable image bytes. Both require coherent writable/executable memory.

**I.** EDGE43 changed the immediate operand of a local instruction to 5Ah, invoked that instruction, and received 5Ah. It restored the byte afterward. OVER43, using a DRI-specific address derivation, overwrote the first CCP byte and the original entry return word after adopting a private stack; resident BDOS still printed its marker, and JMP 0000h restored a usable command environment.

**Conclusion.** Self-modification within application-owned TPA memory, including executing the modified instruction, is REQUIRED. There is no guarantee that services or return paths survive when their storage is overwritten. DRI CCP location/derivation and the exact reload mechanism are NOT REQUIRED.

## 9. System memory interaction

CP/M's flat address space has no process-protection barrier (**A/B/I034**). Public BDOS/BIOS gateways and documented returned structures are callable; their implementations remain system-owned while in use. An overlaying application may consume CCP space only after arranging a compatible stack and recovery route.

OVER43 confirms that a physical write may succeed without converting private CCP layout into an interface (**I**). Direct private-target calls, hard-coded resident addresses, and continued operation after overwriting BDOS, BIOS, or required recovery code are NOT GUARANTEED. This investigation adds no requirement beyond ledger 0590, 0591, and 0619.

## 10. Software ecosystem findings

Assemblers and compilers emit COM images and commonly use free TPA for code, data, heap, and application stacks. Editors and large applications may size workspace against the configured ceiling. Debuggers such as DDT patch executable bytes for breakpoints. Relocation utilities such as CPMOVE rewrite executable images. XSUB hooks page-zero gateways and maintains a private stack (**B**).

The strongest cross-category compatibility requirement is a coherent flat writable/executable TPA. Evidence does not justify fixed residue, a fixed top address, DRI-private internal entry points, or unlimited stack room. Games or other applications may self-modify like any transient, but no separate game-specific contract was found.

## 11. Documentation findings

The CP/M 2.0 Interface Guide defines loading at 0100h, page-zero access, system calls, and transient termination (**A**). The CP/M 2.2 Alteration Guide documents the page-zero layout, configurable high-memory convention, relocation/configuration context, and the possibility of specialized transients occupying normally resident/entry preparation areas (**A**).

The manuals do not promise one CCP/BDOS/BIOS address, one maximum COM record count, zero-filled TPA, exact entry SP or return address, stack capacity, memory protection, instruction-cache behavior, or survival of overwritten system services. They also do not elevate every technically possible overwrite into a portable interface.

## 12. Source findings

`OS2CCP.ASM` loads upward from 0100h, checks the next destination against `tranm`, calls the accepted transient, and resets the CCP stack after return (**B**). `OS3BDOS.ASM` saves caller SP, dispatches on a private stack, and restores caller SP on normal return (**B**).

`DDT2MON.ASM` installs a restart vector and patches/restores breakpoint instruction bytes. `CPMOVE.ASM` rewrites copied executable bytes and address operands. `XSUB1.ASM` replaces and later restores page-zero gateway targets and uses its own stack (**B**). These sources guide and corroborate tests; the public conclusions also have documentation, experiment, or ecosystem execution evidence.

## 13. Experimental results

The accepted run used z80pack cpmsim 1.39 with DRI CP/M 2.2 and Z80 CBIOS 1.2. `run043.exp` supplied every command. Full output is preserved in `probes/transcripts/main.txt` and explained in `probes/observed-output.txt`.

| Controlled case | Observed result |
|---|---|
| Normal execution | EDGE43 completed and returned to CCP |
| Boundary memory | Last advertised TPA byte wrote/read/restored |
| Self-modifying execution | Patched instruction returned 5Ah |
| Private stack | BDOS Function 12 returned with identical SP |
| Synthetic RET-to-zero | WBOOT reprompted; next probe ran |
| Function 0 | Did not return; CCP reprompted; next probe ran |
| Controlled CCP overlap | WBOOT restored a working command environment |
| Maximum accepted file | 453-record MAXOK43 executed |
| First rejected file | 454-record MAXBAD43 produced `BAD LOAD` |

Both preserved disk images were byte-identical before and after the complete run. Repeated EDGE43 output was identical. The harness's terminal warning after its final interrupt is an emulator shutdown artifact. No destructive BIOS overwrite was performed, and no claim is made about such an unperformed case.

## 14. Compatibility conclusions

**REQUIRED:** the documented flat TPA; entry at 0100h; configured boundary discovery; contiguous COM loading; usable public termination/restart paths; application-owned stack operation; and coherent write-then-execute self-modification within application-owned TPA memory.

**NOT GUARANTEED:** exact resident or stack addresses; exact entry SP/return word value; universal maximum COM size; unloaded/unused bytes; arbitrary page-zero contents; or continued operation of overwritten system code, data, gateways, stacks, or return paths.

**NOT REQUIRED:** DRI CCP/BDOS private layouts and stack sizes, six-byte serialization area, exact boundary comparison, precise `BAD LOAD` implementation, DRI-specific CCP derivation, WBOOT reload mechanics, or DDT's chosen RST number.

**POLICY PENDING:** whether non-strict BetterCP/M modes may offer write protection, W^X, patch mediation, cleared memory, or overlap diagnostics. A strict compatibility profile must still run the evidenced self-modifying software model.

## 15. Proposed ledger additions

The authoritative ledger ends at 0621. One independently testable addition is warranted; all other findings corroborate existing entries.

### 0622. Self-modifying transient execution

    In a strict CP/M 2.2 compatibility profile, application-owned transient
    program area storage is writable and executable: a transient may modify its
    own loaded code or data, and a later instruction fetch observes the modified
    bytes, subject to preserving system-owned regions it still requires.

    Disposition: REQUIRED
    Evidence:    I043 MEMORY EXECUTION SYSTEM subsystem IG AG; EDGE43; DDT;
                 CPMOVE
    Conformance: Load a transient containing a patchable instruction, change an
                 operand in place, execute it, and verify the changed result;
                 repeat at more than one valid TPA placement.

## 16. Existing-entry updates

- **0001–0004, 0031–0034:** add EDGE43/ZRET43 as entry, boundary, return-word, and stack corroboration; do not change wording or disposition.
- **0042–0044:** add EDGE43/FN043 as returning/nonreturning BDOS stack evidence; do not require DRI private-stack mechanics.
- **0496–0505:** add MAXOK43/MAXBAD43 as repeatability evidence; preserve the configured, non-universal loader-boundary distinction.
- **0534–0541:** add ZRET43/FN043/OVER43 for lifecycle and recovery composition; do not claim the synthetic zero word is supplied at entry.
- **0589–0592:** add EDGE43/OVER43 corroboration for overlay ceiling, CCP destruction, lack of protection, and private-stack necessity; no duplicate proposition.
- **0619–0621:** no wording change. Source observations of private entry targets and XSUB gateway patching corroborate but do not broaden these entries.

Every added evidence reference should use the investigation string `I043 MEMORY EXECUTION SYSTEM subsystem IG AG` exactly; the ledger itself was not modified.

## 17. Open questions

1. Which additional widely deployed applications self-modify outside debugger, relocation, and gateway-hooking categories?
2. Do representative non-DRI CP/M 2.2 systems require any instruction-fetch synchronization beyond an ordinary write before executing changed bytes?
3. Should BetterCP/M expose optional protection or diagnostics only outside its strict compatibility profile?
4. How should a future conformance corpus distinguish application-owned TPA patches from deliberate, system-specific resident patches?
5. Cross-memory-size and 8080-host repetitions would strengthen portability evidence without changing the present strict-profile requirement.

## 18. Conformance implications

A strict conformance suite must execute a self-patching COM and observe the new instruction behavior. It should also repeat the established entry, private-stack BDOS, RET, Function 0, WBOOT, last-TPA-byte, and accepted/rejected loader-boundary tests at multiple configured memory sizes. Tests must vary numeric resident addresses, entry SP, return address, unused memory, and loader ceiling.

The suite must not require EC05h/EC06h/EBA9h/EB5Fh/02F5h, a 453-record maximum, DRI private targets, a zero entry return word, or a particular reload algorithm. Protection or W^X implementations pass strict compatibility only if they transparently preserve evidenced transient self-modification and the documented flat-memory results.

Completion audit: all report, source, build, transcript, disk-image, and reference artifacts named here exist in the Investigation 043 directory. All COM artifacts rebuild byte-identically. Recorded SHA-256 manifests verify. The authoritative ledger retained SHA-256 `c2c3b7b9c48954eed4bebb7e594e9a054075ee2ca13764fa3feace28e9c4a8f5`; no ledger or earlier investigation file was modified. No ZIP archive was created.
