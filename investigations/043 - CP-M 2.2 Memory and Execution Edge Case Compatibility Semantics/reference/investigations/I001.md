# Investigation 001 - CP/M 2.2 Transient Program Entry Environment

Date: 13 August 2026  
Status: evidence report only; no BetterCP/M policy decision or implementation

## 1. Scope and methodology

This investigation establishes what a transient `.COM` program can observe when Digital Research CP/M 2.2 gives it control. Findings are classified as:

- **A - documented contract:** explicit or clearly required by DRI CP/M 2.2 documentation.
- **B - observed DRI implementation:** established by the supplied DRI 2.2 source or by experiment, but not promised.
- **C - possible de facto behavior:** undocumented behavior that software could plausibly use; not automatically a BetterCP/M requirement.
- **D - unknown:** insufficient or conflicting evidence.

The BetterCP/M architecture, especially `architecture/09 Program Execution Model.txt`, was read as the statement of present goals. It intentionally leaves the detailed entry contract to compatibility investigation. No file under `<project-root>` was modified.

Method: identify versioned primary material; trace the CCP load-to-entry path and the BDOS entry path; run a minimally perturbing Z80 probe against an identifiable CP/M 2.2 system; compare documentation, source, and observation. The experiment is corroborative: the z80pack BIOS is not DRI's distribution BIOS.

## 2. Primary sources used

1. **Digital Research, _CP/M 2.2 Alteration Guide_, copyright 1979**, `<reference-archive>/CPM_2.2_Alteration_Guide_1979.pdf`, 78 PDF image pages. The cover explicitly says CP/M 2.2. Principal evidence: Section 9, “Reserved Locations in Page Zero,” printed pp. 23-24 (PDF pp. 27-28); Section 6, BIOS entry points; Appendix C sample CBIOS. This is the principal documentary source.
2. **Digital Research CCP assembly**, `<reference-archive>/cpm2-plm/OS2CCP.ASM`, SHA-256 `9d13a24553e16accbb8e2e345a1d3736d4ee4b7d2d80b452818218935cab1188`. Header: “console command processor (CCP), ver 2.0”; explicit source version “2.2 February, 1980,” lines 1-7. Principal evidence: equates at 23 and 61-64; parser at 320-388; command loop at 425-465; transient load/entry at 744-787.
3. **Digital Research BDOS assembly**, `<reference-archive>/cpm2-plm/OS3BDOS.ASM`, SHA-256 `a22b7dd0f8adaa8dd9affe2cbb0f5749ddf278bf36ca9f94e38f9acf335a44d8`. The archive contains a second one-sequence variant, `OS3BDOS1.ASM`; `README.TXT` explains its provenance. This report relies on `OS3BDOS.ASM`, and no relevant conclusion depends on the differing sequence. Principal evidence: BDOS entry at lines 73-115 and return machinery at 88-103 and 475-500.
4. **Digital Research, _CP/M 2.0 Interface Guide_**, `<reference-archive>/CPM_2_0_Interface_Guide.pdf`, 56 scanned pages. This is explicitly version 2.0, not 2.2. It is background for the stable CP/M 2 interface, not the sole basis for a 2.2-specific finding; the supplied scan has no usable text layer.
5. **Digital Research, _CP/M Operating System Manual_, Third Edition, September 1983**, local HTML index under `<reference-archive>/Digital Research CP:M Operating System Manual/`. The index identifies Chapter 5 as “CP/M 2 System Interface,” but chapter files have been replaced by a web anti-bot page. The 1983 edition also postdates 2.2. It was therefore not used as substantive evidence.

Files explicitly not treated as 2.2 authority include the CP/M 2.0 System Alteration Guide, the 2.0 guide for 1.4 users, and any CP/M 1.x, CP/M 3, MP/M, simulator BDOS, or third-party utility material.

## 3. Reference CP/M 2.2 environment

- Emulator: `cpmsim`, z80pack repository commit `91fd28eb04e675c2127df88ed3f40675e15282e2`; executable SHA-256 `30374c2df2f44118d2b36a8bfef651a9f2d0ee9b9ddd0039c044b9f06df4708d`. Banner reports Release 1.39.
- CPU mode: `-z`, Zilog Z80 emulation.
- Boot disk: disposable copy of `cpmsim/disks/library/cpm22-1.dsk`, SHA-256 `bb06534599e7167547563096217d775bcd073464408dbae0927a010604d03443` before probe insertion.
- Boot banner: `64K CP/M Vers. 2.2 (Z80 CBIOS V1.2 for Z80SIM, Copyright 1988-2007 by Udo Munk)`.
- System identity: disk sectors 1 through 44 (the CCP+BDOS region after the boot sector) have SHA-256 `37466378...25c`, exactly matching 44 sectors from offset 17 in `cpmsim/srccpm2/cpm.bin`, as prescribed by `srccpm2/putsys.c` lines 64-93. Thus this is DRI CCP/BDOS with a third-party Z80SIM CBIOS, not z80pack's optional emulated BDOS.

Consequently CCP/BDOS observations are strong corroboration of DRI behavior; BIOS-specific low-memory bytes and interrupt state remain platform observations.

## 4. Documented transient-program contract (A)

### Load, entry, and memory

The Alteration Guide, Section 9, printed p. 24, calls 0100h “the assumed beginning of all transient programs.” Together with the `.COM` convention and CCP source, the documented entry/load address is **0100h**. Page zero is 0000h-00FFh. The usable TPA begins at 0100h and extends up to, but not including, the lowest CP/M-resident address encoded by the operand of the jump at 0005h. Section 9 explicitly says `LHLD 0006H` obtains that lowest address assuming the CCP is overlaid. The exact top is configuration-dependent.

### Page zero

Section 9, printed pp. 23-24, documents:

| Address | Documented meaning |
|---|---|
| 0000h-0002h | `JMP` to BIOS warm-start entry; `JMP 0000H` is a programmed restart. |
| 0003h | Intel-standard IOBYTE, optional in the user's CBIOS. |
| 0004h | Current default drive, 0=A through 15=P. |
| 0005h-0007h | `JMP` to BDOS; `JMP 0005H` is the primary BDOS entry; the operand also exposes the low CP/M address. |
| 0008h-003Ah | restart/interrupt locations, mostly unused/reserved; 0038h may be used by DDT/SID breakpoints. |
| 0040h-004Fh | 16-byte CBIOS scratch area in the distribution arrangement. |
| 005Ch-007Ch | default FCB produced by the CCP for a transient program. |
| 007Dh-007Fh | optional default random-record position. |
| 0080h-00FFh | default 128-byte disk buffer; also receives the command line at transient load. |

The manual warns that page-zero information is set up for normal CP/M operation but can be overwritten if BDOS facilities are not required; destroying BIOS or the warm-start vector can require a cold start to recover.

### BDOS invocation

The documented service gateway is `CALL 0005H` (or otherwise transferring through the jump at 0005h), with function number in C and the information address/value convention in DE. The BDOS source header confirms C and DE at lines 73-77. A call is required when return to the transient is desired; a `JMP 0005H` can be used only when the selected service does not return or the caller has arranged a return address.

### Command tail and default FCB

At 0080h is a one-byte count; characters begin at 0081h. CCP source establishes that the tail begins at the first blank after the command name and includes that leading blank, is uppercased by the command reader, and is copied through a zero byte; the stored count excludes the terminating zero (`OS2CCP.ASM` 227-240, 768-778). The manual documents the buffer/command-line overlap but is not explicit in the cited section about every parsing detail. Therefore location and role are A; exact casing, leading-blank, and trailing-zero details are B unless corroborated by another edition.

The default FCB at 005Ch is produced from the first argument. Its standard fields are drive byte, blank-padded 8.3 name/type, extent bytes, allocation area, and current record. CCP's `fillfcb` parsing accepts drive prefixes, expands `*` to `?`, pads with spaces, and zeroes extent-related fields. Before entry it creates a second default FCB beginning at 006Ch from the second argument and copies 33 bytes from the CCP work FCB to 005Ch (`OS2CCP.ASM` 762-767). Because the second FCB overlays the first FCB's allocation area, programs use the default FCBs as unopened names, not simultaneously as two live sequential FCBs.

### Default DMA

The documented default DMA/buffer address is **0080h**. The command tail occupies the same memory at entry, so the initial DMA contents are command-tail data, not a freshly read disk record.

### Termination and aftermath

Documented conventional termination mechanisms are:

1. `JMP 0000H`, invoking BIOS warm boot.
2. BDOS function 0 (System Reset), which dispatches to BIOS warm boot (`OS3BDOS.ASM` function-table entry 0 at line 107).
3. A return from the program is supported by DRI's CCP invocation and is described here as observed implementation behavior, because the cited 2.2 manual section does not promise the entry stack.

A warm boot reloads/reenters the CCP, restores the page-zero vectors and default DMA as the BIOS implementation requires, preserves/selects the encoded user/drive state passed to CCP, and resumes the command loop. A direct return follows CCP's post-call path, reselects the saved disk/user context, and jumps back to the CCP (`OS2CCP.ASM` 784-787); it need not perform a BIOS warm boot.

## 5. DRI CP/M 2.2 implementation behavior (B)

The evidentiary chain for the main entry path is:

> 0100h convention (manual p. 24) -> `tran equ 100h` (CCP line 23) -> file records loaded at `tran` (750-760) -> default FCB/tail/DMA prepared (762-782) -> `call tran` (784) -> probe executes at 0100h.

Specific source-established behavior:

- Files are loaded in 128-byte sequential records beginning at 0100h. The CCP detects wrap into its own base and prints `BAD LOAD` (`OS2CCP.ASM` 750-760, 792-796).
- CCP memory is immediately above the maximum TPA: `tranm equ $` at the CCP origin (23-25). Thus the 0005h jump operand identifies the boundary when CCP is overlaid.
- FCB1 is built from argument 1 at 005Ch and FCB2 from argument 2 at 006Ch. Filename and type are uppercase, space padded; absent components are blank/zero initialized; wildcard rules are CCP parser behavior.
- Tail copying starts at the first blank after the command token and copies the terminating zero. Byte 0080h is the number of copied nonzero characters.
- CCP explicitly resets BDOS DMA to 0080h immediately before entry (781).
- CCP invokes a transient with **`CALL 0100H`**, not `JMP`; therefore entry SP points to a return address into CCP, and an immediate `RET` is a normal DRI implementation path. On return it resets SP to its private stack, restores saved selection, and reenters CCP (784-787).
- No instruction initializes general registers for a public entry convention. Entry values are residues of `setdmabuff`, `saveuser`, and BDOS/CCP helpers. Likewise IX, IY, alternate registers, I, R, flags, and interrupt enable are not established by CCP as a transient contract.
- BDOS saves the caller's SP and switches to its own stack for each service (`OS3BDOS.ASM` 88-103), so the transient need only supply a valid call stack for a returning BDOS call.

## 6. Experimental method and observations

Probe source and binary are in `outputs/probes/ENTRY001.ASM` and `ENTRY001.COM` (binary SHA-256 `b8d5f667d2114aa600c898820fdc6477efdb9fbcd635bc129bcd94c5e3a9c36e`). Build and run:

```text
z80asm -fb -oENTRY001.COM ENTRY001.ASM
cpmcp -f ibm-3740 drivea.dsk ENTRY001.COM 0:ENTRY001.COM
cpmsim -z -d <disposable-disk-directory>
A>ENTRY001 ALPHA.TXT B:FOO?.BAR
```

The first instruction is `LD (INIT_SP),SP`. It then uses Z80 direct pair stores to save BC, DE, HL, IX, and IY without changing them; saves AF only after those; exchanges and saves alternate pairs; samples I, R, and IFF2; snapshots page zero and 16 bytes at original SP; only then calls BDOS to print hex. Limitation: the Z80 has no nonperturbing instruction to capture all state atomically. R necessarily advances as instructions execute; the reported R is not the entry R. IFF2 is sampled later through P/V after `LD A,I`. The probe does not establish IFF1. This is documented in the source rather than concealed.

Observed register record (16-bit values decoded from little endian):

| Item | Value |
|---|---:|
| SP | EBA9h |
| AF | 006Ch |
| BC | 00FFh |
| DE | F9FFh |
| HL | EBEFh |
| IX | B145h |
| IY | 3C28h |
| AF' / BC' / DE' / HL' | FB14h / 1AE2h / F77Ch / 4A00h |
| I | 00h |
| R at sample | 4Ah |
| AF after `LD A,I` | 0068h (P/V=1, hence IFF2=1 at that sample) |

These register values are **one run's B/C evidence**, not an A contract. They demonstrate residue, not required constants.

Important page-zero observations:

- 0000h was `C3 03 FA` (`JP FA03h`, warm boot).
- 0003h was 00h; 0004h was 00h (IOBYTE 0, drive A).
- 0005h was `C3 06 EC` (`JP EC06h`, BDOS); EC06h was the low resident address.
- 005Ch decoded as drive 00, name `ALPHA   `, type `TXT`, EX/S1/S2/RC zero.
- 006Ch decoded as drive 02 (`B:`), name `FOO?    `, type `BAR`, EX/S1/S2/RC zero.
- 0080h was 15h (21); 0081h onward was ASCII ` ALPHA.TXT B:FOO?.BAR`, followed by 00h. The count includes the leading space and excludes the zero.
- Bytes beyond that zero in 0080h-00FFh were stale prior buffer memory, not cleared padding.
- Original stack bytes began `5F EB 00 00 ...`; `[SP]=EB5Fh` is the CCP return address. This matches `CALL tran`.

An immediate `RET` at the end returned to an `A>` prompt without printing the boot banner, confirming the non-warm-boot CCP return path in this environment.

## 7. Documented versus observed differences

- Documentation defines 0000h as warm restart and 0005h as BDOS; exact jump targets FA03h and EC06h are configuration-specific observations.
- Documentation identifies 005Ch and 0080h; source/experiment add exact second-FCB placement, wildcard/casing details, leading blank, zero terminator, and uncleared bytes after it.
- Documentation does not define a general-register or alternate-register entry state. DRI leaves residues.
- Documentation in the cited evidence does not define SP. DRI CCP supplies a valid return stack solely as a consequence of `CALL 0100H`.
- Warm-boot termination and direct `RET` both regain CCP, but only the former passes through BIOS WBOOT and reload/reinitialization behavior.

## 8. Candidate de facto compatibility behaviors (C)

These deserve testing against software corpora, not automatic adoption:

1. Immediate `RET` termination, including a valid word at entry SP.
2. A zero byte immediately after the counted command tail.
3. Tail includes one leading blank and is uppercase.
4. Bytes after the tail terminator remain uncleared/stale.
5. Second default FCB at 006Ch, including its overlap with FCB1.
6. CCP wildcard expansion (`*` to remaining `?`) and exact blank/zero fill.
7. Programs using `LHLD 0006H` to size the TPA.
8. Programs inspecting BIOS/BDOS jump opcodes and targets, not merely calling them.

Initial values of AF/BC/DE/HL, alternate registers, IX/IY, I/R, flags, or exact SP should **not** be promoted even to C without evidence of real software dependency.

## 9. Unknown or unresolved (D)

- Whether DRI ever explicitly documented `RET` as a portable CP/M 2.2 termination method in another 2.2 Interface Guide printing.
- Whether all DRI-distributed 2.2 CCP binaries use byte-identical parsing and entry sequences; this source is explicitly February 1980, but provenance of every binary distribution was not established.
- Required contents, if any, of absent FCB arguments beyond the fields copied/initialized by this CCP.
- Whether interrupt enable at entry was consistent across DRI-supported BIOSes. The experiment saw IFF2=1 later in the probe; this is BIOS/platform-sensitive.
- Whether real programs depend on stale tail/DMA bytes, precise register residue, or the CCP return address.
- Precise behavior after warm boot (drive preservation, disk reset, SUBMIT continuation) across conforming BIOS implementations.
- Whether a `.COM` whose final record crosses the CCP boundary leaves partial data visible after `BAD LOAD`; not probed.

## 10. Candidate BetterCP/M conformance tests

Tests should carry expected classification, so an implementation accident does not become policy implicitly.

1. **A:** load a signature `.COM`; verify first opcode executes at 0100h and records occupy successive addresses.
2. **A:** verify 0000h and 0005h are callable jump gateways with warm-boot and BDOS semantics.
3. **A:** verify `LHLD 0006H` reports the configured low resident boundary and the advertised TPA is writable up to that boundary.
4. **A:** verify default DMA is 0080h before the first application BDOS disk operation.
5. **A/B:** table-test no arguments, one argument, two arguments, drive prefixes, 8.3 truncation, `*`, `?`, and extra tokens against expected FCB/tail bytes.
6. **A/B:** verify byte 0080h count, tail bytes from 0081h, and the observed zero terminator separately.
7. **A:** terminate via `JMP 0000H` and BDOS 0; verify the command environment returns and required persistent drive/user state is correct.
8. **C, policy pending:** immediate `RET` returns safely to the command environment without requiring WBOOT.
9. **B/C, diagnostic only:** snapshot registers, SP, stack, IFF, and unused page-zero bytes; report differences without initially treating them as failures.
10. **A:** boundary-sized `.COM` acceptance/rejection tests, including the largest legal image and first overflowing image.

## 11. Findings for eventual Compatibility Ledger consideration

No ledger was edited. Candidate entries for later review:

- **Strong A:** `.COM` origin/entry 0100h; page-zero warm-boot and BDOS vectors; default FCB at 005Ch; default DMA/command buffer at 0080h; TPA upper-bound discovery through the 0005h jump operand; BDOS C/DE calling convention; WBOOT and BDOS 0 termination.
- **A/B detail needing exact wording:** command-tail count/characters; default-FCB parsing and initialization; second FCB at 006Ch.
- **C requiring policy:** immediate `RET`; NUL after tail; uppercase/leading-space representation if not located in explicit 2.2 documentation; stale bytes after tail.
- **Reject as a guarantee absent new evidence:** exact entry registers, flags, interrupt state, exact SP/address of CCP return word, or BIOS-specific vector targets.

The central conclusion is deliberately narrow: CP/M 2.2 has a well-defined memory-and-service entry environment, but DRI's particular CCP also leaks substantial incidental processor and buffer state. BetterCP/M will need policy decisions only after separating those two categories, not by equating observation with obligation.
