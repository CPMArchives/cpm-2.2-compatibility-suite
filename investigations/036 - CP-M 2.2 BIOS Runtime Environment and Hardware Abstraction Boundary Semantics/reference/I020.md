# Investigation 020 - CP/M 2.2 BIOS Jump Table, Boot, and Character-I/O Semantics

Date: 15 August 2026  
Status: Complete, with the explicit cold-BOOT and LISTST limitations in section 16  
Ledger baseline: `02 Compatibility Ledger - Investigation 019.txt`, SHA-256 `666a537e444aca74d99f801c5c87f9f7027a5a9a1ba18105c1dd7ed34c7b13f8`

## 1. Objective and scope

This investigation establishes the CP/M 2.2 BIOS jump-table, BOOT/WBOOT, page-zero, and character-I/O boundary. It covers BOOT, WBOOT, CONST, CONIN, CONOUT, LIST, PUNCH, READER, and LISTST. Disk entries are considered only as members of the fixed vector.

It does not redesign BetterCP/M, treat z80pack addresses as portable, or modify the Compatibility Ledger. Existing Investigations 001-019 remain controlling for transient entry, BDOS character processing, IOBYTE, physical errors, and disk calls.

## 2. Method and evidence classification

Evidence classes used here are:

- **A - documented interface:** DRI CP/M 2.2 Alteration Guide (AG), especially printed sections 6 and 9; CP/M 2.0 Interface Guide (IG) for the application/BDOS boundary.
- **B - DRI implementation:** original `OS3BDOS.ASM`, `OS2CCP.ASM`, `BIOS.ASM`, and `CBIOS.ASM`.
- **I - observation:** deterministic BIOS020/WBOOT20/PZERO20 probes in z80pack CP/M 2.2.
- **D - policy:** compatibility choices not settled by the primary interface.

Documentation defines the contract; source identifies control paths and tests; experiments establish behavior only in the reference environment. No conclusion rests on source alone.

## 3. Documented BIOS jump-table contract

AG section 6 defines a vector of **17 consecutive jump instructions**, each three bytes, in this order:

| Index | Offset | Entry |
|---:|---:|---|
| 0 | 00h | BOOT |
| 1 | 03h | WBOOT |
| 2 | 06h | CONST |
| 3 | 09h | CONIN |
| 4 | 0Ch | CONOUT |
| 5 | 0Fh | LIST |
| 6 | 12h | PUNCH |
| 7 | 15h | READER |
| 8 | 18h | HOME |
| 9 | 1Bh | SELDSK |
| 10 | 1Eh | SETTRK |
| 11 | 21h | SETSEC |
| 12 | 24h | SETDMA |
| 13 | 27h | READ |
| 14 | 2Ah | WRITE |
| 15 | 2Dh | LISTST |
| 16 | 30h | SECTRAN |

Entries must exist even where a configured optional routine is a null return. The vector is the stable interface; implementation routines may reside elsewhere. The guide's sample 4A00h plus relocation bias and the observed FA00h are configurations, not universal addresses.

## 4. BIOS-base discovery and direct-call interface

Locations 0000h-0002h are documented as `JMP WBOOT`. WBOOT is vector index 1, so a caller can derive the vector base as:

```
base = word_at_0001h - 3
entry(n) = base + 3*n
```

BIOS020 used exactly this method and derived FA00h; all 17 computed entries contained C3h followed by a target. No fixed numeric address was assumed.

The Alteration Guide publishes the vector as the route into BIOS and gives register contracts. Direct calls therefore intentionally bypass BDOS transformations: no BDOS echo, tab expansion, Ctrl-P state, pending-character cache, or DMA semantics should be inferred. Hardware and logical-to-physical routing remain BIOS/configuration dependent.

The manuals examined do not expressly promise that arbitrary applications may replace vector bytes. BIOS020's temporary patch is test instrumentation, not a proposed application right. Direct invocation through the documented entries is compatibility-relevant; mutation of them is not established.

## 5. BOOT findings

### Documented contract (A)

BOOT receives control from the cold-start loader, performs basic initialization, initializes IOBYTE if implemented, initializes the system parameters also required by WBOOT, sets C=0 to select drive A, and transfers control to the CCP. A signon is permitted but explicitly omissible.

BOOT is a transfer-of-control entry, not a returning subroutine contract. The exact loader, physical sectors, signon text, stack, interrupt state, hardware initialization, and implementation addresses are configuration details.

### DRI source (B)

Distributed `BIOS.ASM` prints a signon, sets the saved disk to A, and enters common `gocpm`. `CBIOS.ASM` describes the simplest parameter initialization. These are examples, not a universal boot algorithm.

### Observation (I)

The accepted transcript records z80pack's deterministic cold startup, CP/M 2.2 signon, and CCP `A>` prompt. BOOT was not patched or invoked from a transient. This confirms only that the reference configuration reaches CCP after cold start; internal BOOT sequencing remains documentary/source evidence.

## 6. WBOOT findings

### Documented contract (A)

AG section 6 says WBOOT receives programmed restart, reloads CP/M from drive A up to but not including the BIOS in the distribution layout, reconstructs system parameters, and transfers to CCP with C identifying the drive to select. It explicitly requires JMP WBOOT at 0000h and JMP BDOS at 0005h.

The externally important result is a functioning reinitialized resident system and command environment. Exact sector loop, retry count, whether an equivalent implementation physically reloads identical regions, CCP load address, and retained private state are not portable. The distributed design reloads CCP and BDOS while retaining the installed BIOS; BetterCP/M need not reproduce that physical mechanism if the public post-WBOOT state conforms.

BDOS Function 0 dispatches directly to the BIOS WBOOT vector in `OS3BDOS.ASM`. JMP 0000h uses the page-zero gateway. RET termination is distinct: it returns through the CCP-provided stack word and need not invoke WBOOT (Investigations 001-002).

### Observation (I)

WBOOT20 changed the opcodes at 0000h and 0005h from C3h to 00h while preserving their operands, then transferred to the saved WBOOT target. CCP returned. PZERO20 then observed both opcodes restored to C3h and the original operands restored/retained. This is direct evidence for page-zero gateway reconstruction in the reference environment.

## 7. Page-zero reconstruction findings

The documented meanings relevant here are:

- 0000h-0002h: `JMP WBOOT`;
- 0003h: optional IOBYTE;
- 0004h: default/current command drive byte;
- 0005h-0007h: `JMP BDOS`.

WBOOT must establish valid gateways before giving control to CCP. The exact WBOOT/BDOS operands are configured addresses. AG tells BOOT to initialize WBOOT parameters; the sample BIOS common `gocpm` installs 0000h and 0005h, selects default DMA 0080h, and transfers to CCP.

IOBYTE initialization is optional on cold BOOT. The distributed WBOOT source deliberately leaves IOBYTE set. No general requirement was found that warm start reset 0003h. Location 0004h carries the drive passed to CCP; exact preservation after arbitrary corruption is not a supported test. WBOOT20 therefore damaged only the two documented gateway opcodes.

## 8. Character-device BIOS findings

### CONST

CONST is nonblocking and returns A=FFh when a console character is ready or A=00h when none is ready. It samples status and must not consume the pending character. DRI BDOS masks bit 0 when polling, but that implementation detail does not relax the documented 00h/FFh BIOS result.

### CONIN

CONIN waits if necessary, returns the next console character in A, and clears the parity/high bit. BIOS does not echo or interpret it; BDOS performs echo, editing, Ctrl-C/Ctrl-S, and pending-character behavior above this boundary.

### CONOUT

CONOUT accepts the ASCII character in C with zero parity. BIOS/device-specific filtering or terminal timing is allowed, but BDOS formatting must not be attributed to this call.

### LIST and PUNCH

LIST and PUNCH accept one zero-parity ASCII character in C for their respective logical output device. Optional unassigned devices may use null routines. Their exact physical target is not fixed.

### READER

READER returns one zero-parity ASCII byte in A. Ctrl-Z (1Ah) reports end-of-file. An absent device may immediately return Ctrl-Z or diagnose rather than hang.

### LISTST

LISTST is vector index 15 and returns listing-device readiness/status. AG names the entry and says it was then used by DESPOOL, but the prose contract examined does **not** specify an exact result encoding. The distributed sources are inconsistent even in comments: `CBIOS.ASM` says 0 if not ready/1 if ready, while the skeleton returns 0 with a comment that 0 is acceptable. BIOS020 proves the entry is callable and its A result crosses the boundary, but its scripted 00h then FFh does not establish the historical encoding. Exact encoding therefore remains POLICY PENDING, not invented from the fixture.

## 9. DRI CCP/BDOS/source findings

`OS3BDOS.ASM` defines every BIOS address as `bios+3*n`, confirming fixed table arithmetic. Function 0 maps to WBOOT; Functions 3, 4, and 5 map to READER, PUNCH, and LIST. Console paths call CONST, CONIN, and CONOUT. Printer echo calls LIST conditionally. The examined BDOS has a LISTST equate but no call to it.

DRI BDOS caches a pending console character, interprets console controls, expands output behavior, and routes logical calls. Those mechanisms sit above BIOS and are already treated in Investigations 003-006, 016, and 018. CCP reaches those services through 0005h and maintains 0004h for command-entry drive state.

The distributed BIOS sources implement one global device/system context and document no reentrancy or register-preservation discipline beyond each entry's stated inputs and outputs.

## 10. Experimental design

The accepted run used fresh copies of preserved IBM 3740 images. Three byte-identically rebuildable COM probes were installed:

1. **BIOS020** dumped page zero, derived the vector base, dumped 17 entries, patched seven character vectors in RAM, called each directly, captured raw C/A values, and restored all bytes.
2. **WBOOT20** recorded page zero, saved the WBOOT target, changed only two gateway opcodes, and invoked the saved target.
3. **PZERO20** ran after the returned CCP prompt and dumped the reconstructed bytes.

Expect queued all commands. There was no manually timed input. Original disk images, accepted before/after images, raw console output, normalized observations, listings, source, binaries, and hashes are preserved.

## 11. Experimental results

### Jump table

The page-zero operand was FA03h and yielded base FA00h. All 17 entries at FA00h through FA30h contained C3h. Their targets differed and lay outside the vector, demonstrating the interface/implementation-address distinction.

### Direct character calls

The deterministic results were:

| Call | Observation |
|---|---|
| CONST, empty | A=00h |
| CONST, ready | A=FFh |
| CONIN | A=41h; ready flag consumed only here |
| CONOUT | captured C=09h |
| LIST | captured C=10h |
| PUNCH | captured C=1Ah |
| READER | A=52h |
| LISTST | scripted A=00h then FFh |

The fixture distinguishes raw BIOS bytes from BDOS-transformed output. The scripted values validate register transport and dispatch, not physical device behavior or LISTST's historical encoding.

### Warm restart

Before damage: `C3 03 FA 00 00 C3 06 EC`. After WBOOT and CCP return: the same eight bytes. Thus both deliberately erased gateway opcodes were reconstructed. The disk hashes changed only because the three probe files were installed; the probe generated no CP/M file writes.

## 12. Logical-versus-physical character-device conclusions

The BIOS entries are logical CONSOLE, LIST, PUNCH, and READER services. If IOBYTE routing is implemented, BIOS maps them to physical devices; it is optional under AG. Direct calls do not make UART ports, host files, emulator mappings, readiness timing, or terminal quirks portable.

BDOS intentionally adds semantics above BIOS. A compatible implementation must preserve that layering even if BetterCP/M's internal architecture does not resemble DRI's.

## 13. Compatibility conclusions

Required surface:

- the 17-entry, three-byte JMP vector and order;
- derivability of WBOOT/vector base through the valid page-zero gateway;
- nonreturning BOOT/WBOOT control transfers with documented initialization results;
- reconstruction of valid 0000h and 0005h gateways before CCP resumes;
- documented register contracts for CONST/CONIN/CONOUT/LIST/PUNCH/READER;
- direct-call behavior at the vector boundary, without BDOS transformations.

Not guaranteed or not required:

- exact base and routine addresses;
- exact cold/warm loader, sectors, signon, reload mechanics, call counts, interrupt/stack state, or residual registers;
- vector patchability by applications;
- exact physical devices, ports, terminal filtering, and timing;
- reentrancy or preservation of unspecified registers.

Policy pending:

- strict LISTST return encoding and absent-list-device behavior.

## 14. Proposed Compatibility Ledger additions (not applied)

### 0461. BIOS jump-vector structure

The CP/M 2.2 BIOS exposes 17 consecutive three-byte JMP entries in the documented BOOT-through-SECTRAN order.

Disposition: REQUIRED  
Evidence: I020; AG section 6; BDOS; distributed BIOS sources; BIOS020.  
Conformance: Locate the configured BIOS and verify opcodes, spacing, count, and order independently.

### 0462. BIOS vector address freedom

The exact BIOS base, JMP targets, and placement of implementation routines are configuration-dependent and are not portable constants.

Disposition: NOT GUARANTEED  
Evidence: I020; AG relocation model and sample BIOSes; BIOS020.  
Conformance: Run the same vector test at distinct configured memory sizes without fixed numeric addresses.

### 0463. BIOS-base discovery through WBOOT gateway

With 0000h containing the required JMP to the vector's WBOOT entry, the configured BIOS vector base is the 0001h operand minus three and entry n is base plus three times n.

Disposition: REQUIRED  
Evidence: I020; AG sections 6 and 9; BIOS020.  
Conformance: Derive the base only from page zero and successfully identify all entries.

### 0464. BOOT control contract

BOOT performs cold-start initialization, establishes WBOOT-required system parameters, initializes IOBYTE if that option is implemented, supplies drive A in C, and transfers control to CCP rather than returning to its caller.

Disposition: REQUIRED  
Evidence: I020; AG section 6; distributed BIOS sources; controlled reference cold-start transcript.  
Conformance: Cold-start a configured image and validate public state at CCP entry.

### 0465. WBOOT control contract

WBOOT reestablishes a usable resident CP/M command environment and transfers to CCP with C identifying the drive to select; it is not a returning application subroutine.

Disposition: REQUIRED  
Evidence: I020; AG section 6; BDOS Function-0 dispatch; distributed BIOS sources; WBOOT20.  
Conformance: Invoke programmed warm restart and verify CCP resumes with documented public state.

### 0466. Warm-start gateway reconstruction

Before CCP resumes, WBOOT establishes a valid JMP WBOOT at 0000h and JMP BDOS at 0005h using configured operands.

Disposition: REQUIRED  
Evidence: I020; AG sections 6 and 9; distributed BIOS sources; WBOOT20/PZERO20.  
Conformance: Damage only the two gateway opcodes, invoke saved WBOOT, and verify both valid gateways at the next transient entry.

### 0467. Boot implementation freedom

Exact boot sectors, loader/retry algorithm, signon, addresses, stack, interrupt state, call counts, and physical CCP/BDOS reload mechanism are not required where the public BOOT/WBOOT result conforms.

Disposition: NOT REQUIRED  
Evidence: I020; AG configuration/relocation model; differing distributed BIOS examples.  
Conformance: Accept distinct boot implementations that produce the same documented public state.

### 0468. BIOS console status contract

CONST is nonblocking, does not consume input, and returns A=00h for none or A=FFh for ready.

Disposition: REQUIRED  
Evidence: I020; AG section 6; BDOS; distributed BIOS sources; BIOS020 fixture.  
Conformance: Queue one character, poll before/after, and recover that same character through CONIN.

### 0469. BIOS console input contract

CONIN waits for and returns the next zero-parity console character in A; BIOS-level echo and BDOS console-control interpretation are not part of this entry.

Disposition: REQUIRED  
Evidence: I020; AG section 6; BDOS layering; BIOS020 fixture.  
Conformance: Supply controlled input and separately observe A and absence of BIOS-imposed BDOS transformations.

### 0470. BIOS character output contracts

CONOUT, LIST, and PUNCH each accept one zero-parity ASCII character in C for their respective logical output device without inheriting BDOS formatting semantics.

Disposition: REQUIRED  
Evidence: I020; AG section 6; BDOS; BIOS020 raw-byte capture.  
Conformance: Call each vector with graphic/control bytes and capture the C byte at the logical boundary.

### 0471. BIOS reader contract

READER returns a zero-parity ASCII character in A and reports end-of-file with Ctrl-Z; an unassigned reader may immediately report that EOF rather than block.

Disposition: REQUIRED  
Evidence: I020; AG section 6; distributed BIOS sources; BIOS020.  
Conformance: Test normal input and configured absent-device EOF independently.

### 0472. LISTST result policy

LISTST is a callable vector entry returning listing-device status in A, but the examined primary prose does not settle an exact ready/not-ready encoding or optional-device behavior.

Disposition: POLICY PENDING  
Evidence: I020; AG section 6/table and DESPOOL note; conflicting distributed BIOS comments; BIOS020 dispatch test.  
Conformance: Defer exact value tests until documentary/software-dependency evidence sets policy.

### 0473. Direct BIOS call layering

Calls through documented BIOS vector entries use the BIOS register contracts and intentionally bypass BDOS formatting, echo, control-character, pending-input, and DMA semantics.

Disposition: REQUIRED  
Evidence: I020; AG section 6; BDOS source layering; BIOS020; I018.  
Conformance: Compare direct and BDOS-mediated controlled character operations.

### 0474. BIOS residual registers and reentrancy

No general preservation of registers other than stated outputs, nor reentrant/interleavable BIOS character or boot service state, is guaranteed.

Disposition: NOT GUARANTEED  
Evidence: I020; AG entry-specific contracts; distributed single-context BIOSes.  
Conformance: Applications rely only on documented inputs/outputs and make no nested-context assumption.

## 15. Proposed corrections/evidence updates to existing entries

No correction is proposed.

Evidence updates, if the ledger maintainer wants them later:

- Entry 0005: add I020 WBOOT20/PZERO20 as direct gateway-restoration evidence.
- Entry 0008: add I020 WBOOT20/PZERO20 as direct BDOS-gateway-restoration evidence.
- Entries 0436-0448: add I020 only for the lower BIOS dispatch/layering boundary; their existing BDOS propositions remain unchanged.

## 16. Incomplete and unresolved cases

1. BOOT internals were not instrumented. Cold-start completion was observed, while sequencing is supported by AG and source. No claim is made that z80pack's sequence is universal.
2. Exact LISTST encoding remains unresolved because the examined AG prose omits it and distributed comments are inconsistent. The fixture cannot manufacture documentary evidence.
3. Physical IOBYTE routing was not re-run; Investigation 018 already established the optional routing boundary.
4. Exact CCP/BDOS memory reload was not destructively marked. The documented WBOOT result was tested through gateway reconstruction and CCP return; reload mechanism is explicitly classified as implementation freedom.
5. Interrupt state, exact stack, timing, and residual registers were not measured and are not promoted.

## 17. Artifact and preservation audit

- New Investigation 020 directory and `probes/` exist.
- BIOS020.ASM/COM/listing, WBOOT20.ASM/COM/listing, PZERO20.ASM/COM/listing, harness, README, raw transcript, normalized output, before/after images, and hashes are present.
- All three COM files rebuilt byte-identically; `rebuild.sha256` records both accepted and rebuilt digests.
- Source PDFs, DRI sources, z80pack commit, ledger baseline, and artifact hashes are recorded.
- Accepted images were fresh preserved copies. Only A: differs because the three probe COM files were installed; B: remained byte-identical.
- No existing Compatibility Ledger, earlier investigation, architecture, roadmap, or BetterCP/M file was modified.

## 18. Sources

- Digital Research, *CP/M 2.2 Alteration Guide* (1979), printed sections 6, 9, and distributed BIOS appendices.
- Digital Research, *CP/M 2.0 Interface Guide*, application/BDOS interface context.
- DRI `OS3BDOS.ASM`, `OS2CCP.ASM`, `BIOS.ASM`, and `CBIOS.ASM` (hashes in `source-hashes.sha256`).
- BetterCP/M Investigations 001-019 and Compatibility Ledger through 019.
- z80pack cpmsim Release 1.39, commit `91fd28eb04e675c2127df88ed3f40675e15282e2`.
- Investigation 020 preserved raw artifacts.
