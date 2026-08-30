# Investigation 063 - CP/M 2.2 Processor and Instruction Profile

## 1. Objective and scope

This investigation determines which processor-level behaviors belong to generic CP/M 2.2 binary compatibility and which require a named processor or machine profile. It examines the Intel 8080-compatible baseline, documented and undocumented Z80 extensions, instruction-visible registers and flags, timing, interrupts, and representative software impact. It does not design or implement BetterCP/M.

The principal result is layered. A generic CP/M 2.2 binary personality must execute the documented Intel 8080 instruction environment used by the operating system and portable transient programs. A Z80 profile adds documented Z80 instructions and CPU state. Undocumented opcodes, precise timing, and machine interrupt topology are not generic CP/M promises.

## 2. Compatibility standard

Evidence classes are **A** (documented behavior), **B** (Digital Research implementation/source behavior), **I** (controlled observation), and **D** (unresolved policy). Findings use **REQUIRED**, **POLICY PENDING**, **NOT REQUIRED**, and **NOT GUARANTEED**.

CP/M interface semantics and processor instruction semantics are related but distinct. CP/M defines callable services, entry objects, and application-visible memory conventions. The selected processor profile defines how program instruction bytes execute. A conforming binary environment cannot offer CP/M services while misexecuting the baseline instruction set, but generic CP/M does not thereby acquire every feature of every processor that historically ran it.

Any future ledger evidence from this report must use exactly `I063 PROCESSOR INSTRUCTION PROFILE subsystem IG AG`.

## 3. Relationship to previous investigations

I041 established public page-zero/BIOS discovery and rejected private implementation targets. I051 separated portable CP/M from direct ports, MMIO, controller state, clock loops, and interrupt assumptions. I055 defined practical compatibility as documented interfaces plus consequential ecosystem dependencies, not a clone of every reference artifact. I061 and I062 validated implementation-independent service semantics across DRI CP/M and CDOS.

Existing ledger entries 0032, 0033, 0049, and 0051 already say that initial or BDOS-residual IX/IY, alternate registers, I/R, flags, and interrupt state are not generic call-contract guarantees. I063 preserves those distinctions while addressing instruction execution itself: flags produced by an advertised CPU instruction are part of that CPU profile even though flags left by an unrelated BDOS return are not.

## 4. Processor evidence corpus

| Corpus item | Processor evidence | Evidence/class |
|---|---|---|
| CP/M 2.0 Interface Guide and CP/M 2.2 Alteration Guide | Intel MDS-800 reference, Intel IOBYTE, 8080 registers/opcodes, JMP/CALL and restart objects; configurable processor/disk speed | `documentation-extracts.txt` (**A**) |
| DRI reconstructed CP/M 2.2 source | CCP, BDOS, BIOS and DRI tools are expressed in 8080 mnemonic vocabulary; bounded Z80-mnemonic scan was empty | `source-analysis.txt` (**B**) |
| DRI CP/M 2.2 image and STAT.COM | Same system and utility execute in Intel 8080 and Z80 modes | T01 (**I**) |
| CPU8080 | Deterministic 8080 data, arithmetic, flag, stack and call control | T02-T03 (**I**) |
| CPUZ80 | Documented IX/IY, alternate-bank, relative branch, bit and block instructions | T04-T05 (**I**) |
| UNDOC63 | Isolated undocumented SLL opcode | T06-T07 (**I**) |
| TIMING63 | Same counted computation at two configured clocks | T08 (**I**) |
| I048/I051 ecosystem corpus | Z80-named tools exist; QTERM/PROMMER encode speed assumptions; no universal Z80 dependency was established | prior reports (**I/B/D**) |

Exact locations, limitations, and provenance are in `probes/corpus-inventory.txt`. The corpus supports a baseline/profile boundary; it is not a census of all CP/M software.

## 5. Instruction-set analysis

The documentation and DRI source support an Intel 8080-compatible binary baseline (**A/B**). T01-T03 independently show the reference CP/M image, DRI STAT, and a representative 8080 instruction/flag probe operating under both tested CPU modes (**I**). The required baseline includes the documented behavior of the 8080 opcodes a binary may execute, not the source-language spelling used to assemble them.

The Z80 is upward-compatible for the tested subset. CPUZ80's IX/IY addressing, EXX, JR, DJNZ, BIT, and LDIR passed in Z80 mode but did not produce a result or normal return in 8080 mode (**I**). Therefore documented Z80 extensions are **REQUIRED** for a configuration that claims a Z80 binary profile, but **NOT REQUIRED** for generic CP/M 2.2 compatibility.

The undocumented CB 30h operation was deliberately variable: it produced the expected SLL result with one emulator option and trapped with another (**I**). No consequential corpus dependency was demonstrated. Its semantics are **NOT GUARANTEED** by generic CP/M and remain a profile decision.

## 6. Register and flag analysis

Programs necessarily depend on ordinary registers, stack behavior, program counter flow, and condition flags as defined by the selected processor instruction set. CPU8080 checked register-pair movement, PUSH/POP, CALL/RET, DAA, carry, zero, and parity outcomes in both modes; CPUZ80 checked IX/IY, the alternate BC bank, BIT status, and block transfer in Z80 mode (**I**).

This requirement ends at the instruction boundary. CP/M transient entry and BDOS call/return contracts expose only the register values documented or independently promoted by earlier investigations. Initial IX/IY, alternate registers, I/R, generic entry flags, interrupt enable, and incidental flags after BDOS remain **NOT GUARANTEED** or **NOT REQUIRED** under entries 0032, 0033, 0049, and 0051.

Undocumented flag bits, refresh-register details, prefix edge cases, and state from unadvertised instructions lack validated software evidence here and are **NOT GUARANTEED**.

## 7. Timing and hardware analysis

TIMING63 produced identical application-visible completion text at configured 2 MHz and 4 MHz, while measured elapsed time differed (**I**). The Alteration Guide permits disk skew changes for faster processors and subsystems (**A**); it does not establish a universal CPU frequency or cycle timing.

Exact clock rate, host throughput, instruction-cycle duration, wait states, refresh effects, and delay-loop calibration are **NOT REQUIRED** by generic CP/M. If a named machine profile advertises a clock or cycle-sensitive peripheral, that profile must state and test its tolerance; otherwise the outcome is **NOT GUARANTEED**.

Likewise, CP/M reserves or uses certain restart/page-zero locations and exposes BIOS behavior, but it does not prescribe a universal interrupt controller, Z80 interrupt mode, daisy chain, vector source, or interrupt cadence. Those are machine-profile behaviors. Existing CP/M semantics for restart and warm boot remain required independently.

## 8. Software impact analysis

The strongest available evidence favors an 8080 baseline: the DRI source corpus contains no matched Z80-only mnemonic in the bounded scan, and DRI CP/M plus STAT ran in 8080 mode. This is consequential because standard CP/M binaries must be executable without a Z80 extension assumption.

Z80-targeted software is historically real. I048 preserves Microsoft and SLR tool binaries, including Z80-named tools, and the broader archive contains software built for Z80 systems. T04-T05 demonstrate the technical consequence: the same Z80 extension bytes work in a Z80 profile and fail in an 8080-only profile. That makes processor-profile declaration important, not Z80 universal.

I051 found CPU-speed and counted-delay assumptions in QTERM and PROMMER. Such dependencies affect matching-machine compatibility, but exact values are not widespread portable CP/M interfaces. This investigation found no validated common-software dependency on undocumented Z80 opcodes, undocumented flag bits, refresh behavior, or exact clock cycles.

## 9. Compatibility classification

**REQUIRED**

- A generic CP/M 2.2 binary personality must provide correct documented Intel 8080 instruction semantics sufficient to execute the operating environment and 8080 transient programs.
- A declared processor profile must correctly implement its advertised documented instructions, registers, condition flags, stack/control flow, and binary encoding.
- A Z80 profile must retain the 8080-compatible subset and provide the documented Z80 extensions that the profile claims.

**POLICY PENDING**

- Whether BetterCP/M's first conformance claim will be generic 8080, Z80, or both.
- Whether any named profile will intentionally support specified undocumented Z80 opcodes or cycle tolerances.
- Which preserved Z80-only applications should become acceptance fixtures for a Z80 profile.

**NOT REQUIRED**

- Z80-only instructions, registers, interrupt modes, or refresh behavior in a generic CP/M 2.2 claim that does not advertise Z80 compatibility.
- A universal processor clock, cycle count, wait-state pattern, or machine interrupt topology.

**NOT GUARANTEED**

- Undocumented opcode and undocumented flag behavior without a declared profile promise.
- Results of executing instructions outside the selected processor profile.
- Timing-sensitive behavior outside stated machine/profile tolerances.

## 10. Experimental results

| ID | Behavior/software/environment | Procedure and observation | Conclusion |
|---|---|---|---|
| T01 | DRI CP/M 2.2 and STAT; 8080 mode | Fresh image booted; STAT returned normally | Valid 8080-compatible CP/M baseline |
| T02 | CPU8080; 8080 mode | Deterministic self-check printed `CPU8080 PASS` | Baseline instruction semantics observed |
| T03 | CPU8080; Z80 mode | Same executable printed `CPU8080 PASS` | Tested Z80 upward compatibility |
| T04 | CPUZ80; Z80 mode | IX/IY, EXX, JR, DJNZ, BIT, LDIR; `CPUZ80 PASS` | Documented Z80 profile behavior observed |
| T05 | CPUZ80; 8080 mode | Same bytes produced no PASS/return; emulator stopped on an interpreted HALT path | Z80 binary is outside 8080 profile; exact failure not guaranteed |
| T06 | UNDOC63; Z80 undocumented enabled | CB 30h produced checked result; `UNDOC63 OBSERVED` | Implementation observation only |
| T07 | UNDOC63; Z80 undocumented trapped | Same CB 30h trapped at 0105h | Undocumented behavior is optional/profile-specific |
| T08 | TIMING63; Z80 at 2/4 MHz | `TIMING63 DONE` in both; elapsed/rate differed | Semantics portable; exact time not generic |

The complete mandatory record fields—behavior, software, processor environment, procedure, observation, and conclusion—are preserved in `probes/processor-profile-records.tsv`. Runs were scripted and used recreated disks. The first incorrectly formatted staging attempt was discarded before acceptance; retained transcripts are the clean-image reruns.

## 11. Compatibility conclusions

1. CP/M 2.2's generic binary compatibility floor is Intel 8080-compatible execution, supported independently by documentation, DRI source, and controlled runs (**REQUIRED**).
2. CP/M services are not a substitute for CPU correctness: applications may rely on the selected processor's documented instruction-produced registers and flags (**REQUIRED within the selected profile**).
3. Z80 documented extensions form a useful and historically important processor profile, not an unconditional generic CP/M requirement (**NOT REQUIRED generically; REQUIRED when advertised**).
4. Initial/residual Z80 state and BDOS flags remain outside the general CP/M call contract (**NOT GUARANTEED/NOT REQUIRED**), consistent with the ledger.
5. Undocumented opcodes and flags lack evidence for generic promotion and may vary or trap (**NOT GUARANTEED**).
6. Exact clock, cycle timing, wait states, and interrupt topology belong to named machine profiles (**NOT REQUIRED generically**).

## 12. Proposed ledger additions

These are proposals only; no ledger was modified.

### 0766. Intel 8080-compatible binary execution baseline

A generic CP/M 2.2 binary personality shall execute documented Intel 8080 instructions with their documented register, flag, stack, control-flow, and encoding semantics sufficiently to run the CP/M environment and 8080 transient programs.

Disposition: **REQUIRED**  
Evidence: `I063 PROCESSOR INSTRUCTION PROFILE subsystem IG AG`; sections 4-6 and T01-T03.  
Conformance: Run an 8080-only instruction/flag probe and representative DRI CP/M software on the claimed execution environment.

### 0767. Declared processor-profile instruction semantics

A configuration that advertises a processor profile shall implement the documented instructions and CPU-visible state of that profile; a Z80 claim includes its documented extensions and the 8080-compatible subset.

Disposition: **REQUIRED**  
Evidence: `I063 PROCESSOR INSTRUCTION PROFILE subsystem IG AG`; T03-T05.  
Conformance: Test profile-specific instruction families separately from CP/M service tests.

### 0768. Z80 extensions outside a generic CP/M claim

Documented Z80-only instructions and registers are not required by a generic CP/M 2.2 claim that does not advertise a Z80 processor profile.

Disposition: **NOT REQUIRED**  
Evidence: `I063 PROCESSOR INSTRUCTION PROFILE subsystem IG AG`; DRI source screen and T01-T05.  
Conformance: Do not fail a generic 8080-profile implementation merely because a Z80-only transient cannot execute.

### 0769. Undocumented processor behavior

Undocumented opcodes, undocumented flag bits, and results of instructions outside the selected processor profile are not guaranteed by generic CP/M 2.2.

Disposition: **NOT GUARANTEED**  
Evidence: `I063 PROCESSOR INSTRUCTION PROFILE subsystem IG AG`; T06-T07.  
Conformance: A generic suite may verify permitted variation or trapping; any stronger promise requires a named profile.

### 0770. Processor timing and interrupt topology

CP/M 2.2 does not require a universal CPU clock, exact instruction timing, wait-state pattern, refresh behavior, or machine interrupt topology.

Disposition: **NOT REQUIRED**  
Evidence: `I063 PROCESSOR INSTRUCTION PROFILE subsystem IG AG`; section 7, T08, and I051.  
Conformance: Test such properties only under a profile that explicitly advertises them.

## 13. Existing-entry updates

No compatibility ledger was modified. At the next authorized integration:

- Add `I063 PROCESSOR INSTRUCTION PROFILE subsystem IG AG` as strengthening evidence to 0032, 0033, 0049, and 0051 without changing their dispositions; I063 confirms the difference between CPU-instruction results and CP/M entry/return residue.
- Cross-reference the existing hardware-profile, direct-I/O, timing, interrupt, and optional-device entries strengthened by I051 rather than duplicating their machine-specific propositions.
- Check proposed 0766-0770 against any entries added concurrently after Investigation 062 and renumber as necessary.

No correction to an existing proposition was identified.

## 14. Open questions

1. Will BetterCP/M claim an 8080 profile, a Z80 profile, or both in its first release? (**D**)
2. Which Z80-only programs are consequential enough to form the profile acceptance corpus? (**D**)
3. Should any profile deliberately promise a named set of undocumented Z80 opcodes, and if so against which physical processor revision or validated emulator set? (**D**)
4. Are 8085-specific instructions or flag differences important to a future named profile? They were not tested here. (**D**)
5. What timing tolerance, if any, should a named historical machine profile promise for delay-loop software and peripherals? (**D**)
6. Which interrupt modes and external interrupt sources belong in each future machine profile? (**D**)

## 15. Conformance implications

Conformance should be layered. The generic binary tier runs 8080-only instruction and representative CP/M software controls. A Z80 tier adds documented prefix, index, alternate-register, relative-branch, bit, and block-operation tests. Undocumented-opcode tests are informational unless a named profile promotes them. Timing and interrupt tests belong to machine profiles with explicit tolerances and fixtures.

Service-interface tests must not accidentally require BDOS residual flags or Z80 entry state. Conversely, CPU-profile tests must check instruction-produced flags and registers directly, without treating their correctness as optional CP/M residue. Failure outside a profile should be reported as profile mismatch; the generic standard does not prescribe whether an unsupported opcode traps, hangs, or executes differently.

### Completion audit

- The Investigation 063 staging directory contains this report, four source probes, four COM files, listings, deterministic build/run scripts, six accepted transcripts, experimental records, documentation/source/corpus analyses, observed output, and hashes.
- All four COM files rebuild byte-identically; `probes/rebuild-verification.txt` records the comparison.
- Accepted runs use newly recreated CP/M disk images and scripted input. Before/after image hashes are recorded; the programs made no disk changes after staging.
- SHA-256 values are recorded in `hashes/SHA256SUMS` and source inputs in `hashes/source-inputs.sha256`.
- The authoritative Compatibility Ledger remained SHA-256 `991df2326bb693c9b600f19fede9d1cafa7e50c2b4dd409c8ed1508ff45fcdd3`.
- The protected-tree comparison records only the new Investigation 063 directory after installation; no existing BetterCP/M file was modified.
- No BetterCP/M implementation or architecture file was changed.
