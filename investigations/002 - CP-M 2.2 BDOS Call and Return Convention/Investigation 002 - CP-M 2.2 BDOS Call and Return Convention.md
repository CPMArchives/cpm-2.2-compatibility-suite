# Investigation 002 - CP/M 2.2 BDOS Call and Return Convention

Date: 13 August 2026  
Status: evidence report only; no BetterCP/M policy decision or implementation

## 1. Investigation question and scope

This investigation asks what common application-facing convention applies when a CP/M 2.2 transient calls BDOS through 0005h:

1. Where are the function number and argument placed?
2. Where are byte and word results returned?
3. What happens when the function number is outside CP/M 2.2's defined range?
4. What stack conditions are required, and is SP balanced across a returning call?
5. Which registers are documented as outputs or preserved, and which DRI register effects are merely implementation behavior?

The semantics of individual functions are out of scope except where a safe representative is needed to exercise the common ABI. Error policy, reentrancy, console semantics, and file-system behavior remain separate subjects.

Evidence classes follow the Compatibility Policy: **A** documented CP/M 2.2 requirement; **B** DRI implementation behavior; **C** possible de facto dependency; **I** incidental/residual behavior; **D** unresolved.

## 2. Why this matters to BetterCP/M

Every application-visible BDOS function crosses this boundary. Establishing it before investigating individual services prevents each later report and conformance test from making different assumptions about arguments, results, stacks, or clobbers. The BetterCP/M System Services architecture explicitly requires CP/M-compatible function identifiers, registers, return values, and side effects while leaving the internal implementation free.

## 3. Sources examined

### Primary documentation

1. Digital Research, **_CP/M 2.0 Interface Guide_**, copyright 1979, `<reference-archive>/CPM_2_0_Interface_Guide.pdf`, SHA-256 `e10f525f...a279`, 56 scanned PDF pages. Visually verified passages:
   - Section 2, “Operating System Call Conventions,” printed p. 3 / PDF p. 9: C, DE, A, HL, A=L/B=H, and out-of-range behavior.
   - printed p. 4 / PDF p. 10: function list 0-36, CCP's eight-level entry stack, BDOS local-stack switch, `CALL 0005H`, and `RET` example.
   - function 12, printed p. 13 / PDF p. 19; function 24, printed p. 20 / PDF p. 26; function 31, printed p. 24 / PDF p. 30.
2. Digital Research, **_CP/M 2.2 Alteration Guide_**, copyright 1979, `<reference-archive>/CPM_2.2_Alteration_Guide_1979.pdf`, SHA-256 `98a176be...6891`. Section 9, printed p. 23, defines 0005h as the primary BDOS entry and expressly refers the reader to the “CP/M Interface Guide.”

The interface manual says 2.0, not 2.2. It is used here because the 2.2 Alteration Guide expressly incorporates the Interface Guide for the BDOS entry, and the February 1980 2.2 source implements the stated convention including 2.2's larger function table. No claim is inferred from CP/M 3, MP/M, or a later derivative.

### Original DRI implementation

3. `<reference-archive>/cpm2-plm/OS3BDOS.ASM`, “Bdos Interface, Bdos, Version 2.2 Feb, 1980,” SHA-256 `a22b7dd0...44d8`. Relevant locations: entry and dispatch 73-119; result state 88-103 and 479-510; version constant 521; individual handlers 1917-2087; common return 2090-2104.
4. `OS3BDOS1.ASM`, the archive's Caldera variant. Its only diff is damaged/changed console line-editing code around the control-X path; the ABI and return sequence are identical. It does not affect this investigation.
5. DRI program call sites in `OS2CCP.ASM`, `AS1IO.ASM`, `DUMP.ASM`, `SYSGEN.ASM`, and `XSUB0/1.ASM`, used as corroboration that DRI programs call 0005h with C and DE and consume A where applicable.

### Reference environment

The experiment used the same identified reference as Investigation 001:

- z80pack commit `91fd28eb04e675c2127df88ed3f40675e15282e2`;
- `cpmsim` Release 1.39 in Z80 mode, executable SHA-256 `30374c2d...708d`;
- disposable copy of `cpm22-1.dsk`, pre-modification SHA-256 `bb065345...3443`;
- boot banner `64K CP/M Vers. 2.2 (Z80 CBIOS V1.2 for Z80SIM...)`;
- DRI CCP+BDOS sectors already matched byte-for-byte in Investigation 001 to z80pack's `srccpm2/cpm.bin`.

The BIOS is a z80pack Z80 CBIOS, so BIOS-mediated clobbers are observations of that configured system, not universal DRI BIOS behavior.

## 4. Documented CP/M 2.2 requirements (A)

### 4.1 Entry and parameters

The primary entry is the jump at 0005h. A returning application call normally uses `CALL 0005H`.

- **C** contains the 8-bit function number.
- **DE** contains the 16-bit information address in the general convention.
- Function-specific definitions can use E as a single-byte argument; DE remains the carrier pair, not a second general argument.

The function-specific description determines whether the DE/E value is an address, character, drive, user number, or unused. Therefore “DE is always a pointer” would be incorrect.

### 4.2 Results and compatibility aliases

- A single-byte result is returned in **A**.
- A double-byte result is returned in **HL**.
- On every returning call, **A equals L** and **B equals H**.

The last rule supplies compatibility aliases: byte results appear as `HL=00xx` and `BA=00xx` in the DRI 2.2 implementation because the common result word begins at zero; word results appear in both HL and the nonstandard pair BA, with A duplicating L and B duplicating H. Applications are entitled to the documented A=L and B=H relationships, not merely the primary A or HL result.

The Interface Guide separately emphasizes the low-byte alias for function 24: A and L contain the same value for compatibility with earlier releases.

### 4.3 Out-of-range function numbers

An out-of-range function number returns a zero value. In DRI CP/M 2.2 the valid table is **0 through 40 inclusive**, established by the 41-entry source table. Hence 41-255 are out of range for this version and must return `HL=0000`, with A=L=00 and B=H=00.

“Out of range” is version-relative. Later systems can assign those numbers; BetterCP/M extensions must not accidentally alter baseline CP/M 2.2 behavior without an explicit compatibility decision.

### 4.4 Stack convention

The Interface Guide documents that DRI's CCP enters a transient with its return address on an eight-level stack, leaving seven levels, and states that this is sufficient for CP/M system calls because FDOS switches to a local stack at system entry. Its example calls BDOS and finally uses `RET` to return to CCP.

For the BDOS ABI itself, a caller must provide enough valid stack for the call/return transfer. A normally returning call restores caller SP. The manual does not grant an application use of BDOS's private local stack or establish reentrant/nested BDOS calls.

### 4.5 Register preservation

No examined DRI document promises preservation of AF, BC, DE, HL, flags, alternate registers, IX, IY, I, or R across BDOS. A, B, H, and L are explicitly outputs on all returns. C and DE are inputs but are not documented as preserved. Portable software must treat all undocumented register state as clobbered.

## 5. Relevant DRI implementation behavior (B/I)

The common source path makes the documented result convention mechanically explicit:

1. Entry saves DE as `info`, initializes the two-byte `aret` to 0000h, saves caller SP, and changes to `lstack` (`OS3BDOS.ASM` 88-97).
2. It compares C with `nfuncs=41`. An invalid selector returns immediately to the common epilogue with zero still in `aret` (98-119).
3. For valid functions it copies input E to C, dispatches through the table, and handlers place byte or word results in `aret` (99-103, 479-510, 2042-2047).
4. The epilogue restores caller SP, loads HL from `aret`, copies L to A and H to B, then returns (2090-2104).

Consequences:

- **B, compatibility-supporting:** SP is restored exactly for an ordinary returning call; A=L and B=H arise on one common path.
- **B/I:** C becomes the input E value for every valid call before dispatch. Invalid calls skip that assignment and retain selector C until the epilogue replaces only B. This is undocumented dispatch residue.
- **I:** flags are whatever the epilogue instructions leave; no stable flag result is defined.
- **I:** DE and other main registers vary with the handler and BIOS calls.
- **B/I:** the 8080-targeted BDOS does not use Z80 IX/IY or alternate registers, but a Z80 BIOS can, and documentation promises no preservation. Their survival is not a portable requirement.
- **B:** function 12 has `dvers equ 22h`, returns byte 22h through `aret`, and therefore yields HL=0022h, A=22h, B=00h.

The source uses one global saved caller-SP word (`entsp`) and a single local stack. This suggests non-reentrancy, but interrupt-time/nested BDOS calls were not tested and are not classified as a compatibility promise.

## 6. Experimental method and results

### 6.1 Probe

Artifacts are in `probes/ABI002.ASM`, `ABI002.COM`, `observed-output.txt`, and `README.txt`. Binary SHA-256 is `d98f2e35...f8899`.

Build and run:

```text
z80asm -fb -oABI002.COM ABI002.ASM
cpmcp -f ibm-3740 drivea.dsk ABI002.COM 0:ABI002.COM
cpmsim -z -d <disposable-disk-directory>
A>ABI002
```

For each case the probe seeds distinguishable main, alternate, IX/IY, and flag values; records SP immediately before `CALL 0005H`; captures SP and all those registers immediately on return using flag-neutral direct stores; and only later prints the records. It temporarily sets IOBYTE to A5h so function 7 has a nonzero byte result, then restores the original value.

### 6.2 Questions, expectations, observations, interpretation

| Case | Specific question and expected documented result | Observed result | Interpretation |
|---|---|---|---|
| 12 (0Ch), Return Version | Word/result convention; expect CP/M 2.2 value 0022h and A=L/B=H | HL=0022, A=22, B=00; SP EBA7 before/after | Confirms A and B aliases and balanced return. |
| 7, Get I/O Byte | Nonzero byte result; expect A=A5 and aliases | A=A5, HL=00A5, B=00; SP balanced | Confirms byte result also emerges through common result word. |
| 24 (18h), Login Vector | Nonzero word result and aliases | HL=0001, A=01, B=00; SP balanced | Confirms word result and low alias. Value 1 reflects drive A logged in. |
| 26 (1Ah), Set DMA | No defined result; common convention should return zero | HL/A/B=0; SP balanced | Confirms zero-default DRI behavior for this void call; DE was clobbered to F902 by the implementation/BIOS path. |
| 41 (29h), out of range | Documented zero result | HL/A/B=0; SP balanced | Confirms first selector beyond DRI 2.2's table returns zero. |

Across valid calls, observed C became input E (`B2`, `34`, `78`, `80`); for invalid 41 it remained `29`. Flags returned as 44h in all tested cases rather than the seeded 55h. IX=E5F6, IY=1357, AF'=8EAA, BC'=48AD, DE'=5ABE, and HL'=6CCF survived every tested call.

Those latter values are **B/I**, not requirements. The experiment positively demonstrates clobbering of C and flags and handler-dependent DE. It cannot prove preservation across untested functions, different BIOS paths, asynchronous interrupts, or other CP/M 2.2 configurations.

### 6.3 Limitations

- Only safe, noninteractive functions were tested.
- The Z80 CBIOS is not a DRI distribution BIOS.
- The probe cannot capture every register atomically, although stores before later BDOS output preserve the returned flags until AF is saved.
- Successful survival of a register in five calls is not evidence of a portable preservation guarantee.
- Out-of-range 41 was tested; source inspection, not 215 experiments, establishes that the same unsigned comparison covers 41-255.

## 7. Compatibility analysis

### Required baseline

BetterCP/M should eventually mark as REQUIRED: entry through 0005h; selector in C; function-specific DE/E input; byte results in A; word results in HL; A=L and B=H on every normal return; zero result for selectors outside the baseline 0-40 range; and balanced caller SP for returning functions.

### Not a preservation contract

The input convention must not be misread as callee-save semantics. Existing DRI programs commonly reload C and DE before calls and immediately consume A. Both source and experiment show that C, DE, HL, BC, A, and flags may change. BetterCP/M is free to clobber undocumented registers, including Z80-only registers, unless later software-dependency evidence establishes a de facto rule.

### Extension collision

The documented zero for out-of-range functions makes selectors 41-255 observably reserved in baseline CP/M 2.2. Assigning a BetterCP/M extension directly to one of them would be an intentional change to this behavior. Extension design is out of scope, but the conflict must be recorded for later engineering.

### Correction to Investigation 001

Investigation 001 classified immediate `RET` and the valid entry return word as C/policy-pending and listed explicit documentation as unresolved. The CP/M 2.0 Interface Guide, printed p. 4, explicitly documents the CCP return address, stack depth, example `CALL 0005H`, and final `RET`. The 2.2 Alteration Guide refers to that Interface Guide, and the February 1980 2.2 CCP source implements `CALL 0100H`.

Recommended correction: reclassify ordinary `RET` termination and a valid CCP return address at entry as **documented CP/M 2.x behavior applicable to 2.2 (A), corroborated by 2.2 source and experiment**, while keeping the exact SP value and exact return address incidental. The existing ledger is empty, so no ledger entry is contradicted; the correction applies to Investigation 001's candidate classification.

## 8. Unresolved questions

1. Is any register preservation convention documented in another DRI CP/M 2.2 printing or relied upon by a meaningful software corpus?
2. May BDOS be called from an interrupt handler, and if not, was non-reentrancy documented? Source strongly suggests it is unsafe, but that is not yet a compatibility conclusion.
3. Do real applications rely on zero results from particular defined “void” functions, as distinct from truly out-of-range selectors?
4. Should BetterCP/M reserve 41-255 exactly, or provide extensions through a negotiated mechanism? This is later policy/engineering, not settled here.
5. Are functions 37-40 fully and consistently documented in a CP/M 2.2 Interface Guide revision absent from the current source set? The available 2.0 guide lists only 0-36, while 2.2 source implements 37-40.

## 9. Proposed conformance tests

1. Call each returning baseline function with the documented C and DE/E inputs; verify its primary A or HL result.
2. For every returning function, independently assert A=L and B=H, including error returns.
3. Call selectors 41, 42, 7Fh, 80h, and FFh; require HL=0000, A=00, B=00 in strict CP/M 2.2 mode.
4. Place sentinels around a shallow caller stack; verify each nonterminating BDOS call restores SP and does not modify caller-owned stack outside the call return word.
5. Diagnostic-only clobber probe: seed every Z80 register and flags around each function; report changes but do not fail on undocumented registers.
6. Verify function 12 returns HL=0022h with A=22h and B=00h.
7. Verify byte-return function 7 with a known IOBYTE and word-return function 24 with a known login vector to exercise nonzero high/low aliases. A high-byte-nonzero word case should be added once disk state can be controlled safely.
8. Execute a minimal transient containing only `RET`; verify return to CCP as the documented transient-entry convention, separately from BDOS ABI tests.

## 10. Proposed Compatibility Ledger findings

No project file was modified. Proposed entries:

| Finding | Evidence | Proposed disposition |
|---|---|---|
| BDOS gateway is the jump at 0005h; normal returning invocation is `CALL 0005H` | Interface Guide p. 3; Alteration Guide p. 23; 2.2 source | REQUIRED |
| Function selector in C; function-specific information in DE/E | Interface Guide p. 3 and per-function tables; 2.2 source 75-103 | REQUIRED |
| Byte return in A; word return in HL | Interface Guide p. 3 | REQUIRED |
| A=L and B=H on every normal BDOS return | Interface Guide p. 3; source 2101-2104; probe | REQUIRED |
| Out-of-range selector returns zero; CP/M 2.2 range is 0-40 | Interface Guide p. 3 plus 2.2 source table 106-119; probe 41 | REQUIRED for strict 2.2 baseline |
| Returning calls restore caller SP; BDOS uses a private local stack | Interface Guide p. 4; source 92-97, 2101-2104; probe | REQUIRED externally; internal mechanism NOT REQUIRED |
| No general register/flag preservation beyond defined results | Documentation silence plus source/probe clobbers | NOT GUARANTEED |
| Valid-call C=input E, tested IX/IY/alternate survival, returned flags=44h | Source/probe residue | NOT REQUIRED / diagnostic only |
| Immediate transient `RET` and valid CCP return word | Interface Guide p. 4; 2.2 CCP source; Investigation 001 probe | REQUIRED; revise Investigation 001 classification |

## 11. Implications for later BetterCP/M engineering

The future System Services specification needs one common public return epilogue, semantically if not structurally, that produces the documented A/L and B/H aliases and restores the application stack. Tests must validate the aliases for every function, because an implementation that returns only A or only HL is observably incompatible.

The internal dispatcher need not copy DRI's `aret`, local stack, table, or register residues. It must, however, keep baseline handling of unassigned selectors explicit so later extensions do not silently change CP/M 2.2 behavior.

Recommended later numbered investigations:

1. **BDOS console input, output, status, and control-character semantics** (functions 1, 2, 6, 9, 10, 11), divided further if interactive editing proves too broad.
2. **BDOS disk/user state primitives** (functions 12-14, 24-32, 37) before file operations, because they define persistent state used by the filesystem.
3. **BDOS error and warm-boot behavior**, including console aborts and disk errors.
4. **BDOS reentrancy and interrupt-call restrictions** only if the intended interrupt architecture or software evidence makes it compatibility-significant.
