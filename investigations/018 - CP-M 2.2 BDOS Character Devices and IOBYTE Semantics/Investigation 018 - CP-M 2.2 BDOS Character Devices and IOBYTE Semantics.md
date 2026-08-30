# Investigation 018 - CP/M 2.2 BDOS Character Devices and IOBYTE Semantics

Status: Complete evidence report; ledger not modified  
Date: 2026-08-15

## 1. Objective and method

This investigation establishes the application-visible contract for BDOS
Functions 3 (Reader Input), 4 (Punch Output), 5 (List Output), 7 (Get I/O
Byte), and 8 (Set I/O Byte). Evidence is separated as **A** (documented DRI
interface), **B** (DRI source behavior), **I** (tested z80pack/fixture behavior),
and **D** (unresolved BetterCP/M policy).

The stock z80pack BIOS does not provide independently observable physical
reader, punch, and list devices. CHAR018 therefore preserves and temporarily
replaces the six relevant BIOS character jump entries with capture routines,
then restores them before reporting. This is minimal deterministic test-fixture
instrumentation; BDOS, CCP, disk code, and images are unmodified.

## 2. Documentation findings

### Function 3 - Reader Input

**A:** C=03h; A receives the next ASCII character from the logical READER.
The BIOS contract supplies ASCII with bit 7 clear and uses Ctrl-Z (1Ah) for
input-device EOF. Function 3 has no character-ready/status parameter: it calls
the logical reader and completes when that BIOS operation completes. A physical
reader may block, while an unimplemented optional reader may immediately return
Ctrl-Z or diagnose absence. Universal blocking is therefore **NOT GUARANTEED**.

No echo, console editing, Ctrl-C/Ctrl-S/Ctrl-P interpretation, or relationship
to the console pending-character state is documented.

### Function 4 - Punch Output

**A:** C=04h and E contains the ASCII character sent to the logical PUNCH.
The character-device contract has bit 7 clear. No result, formatting, TAB
expansion, flow control, echo, or printer-toggle semantics are specified.

### Function 5 - List Output

**A:** C=05h and E contains the ASCII character sent to the logical LIST device.
It is direct logical-device output, distinct from Function 2's formatted console
path. Ctrl-P printer echo may cause formatted console output to additionally
call LIST, but Function 5 itself is neither formatted console output nor an
echo-toggle interface. No function-specific result is specified.

### Functions 7 and 8 - IOBYTE

**A:** Function 7 uses C=07h and returns the current IOBYTE in A. Function 8
uses C=08h and E as the new value. The system IOBYTE is page-zero byte 0003h;
Get reflects it and Set replaces it. Neither operation initializes a device.

The optional Intel-standard encoding divides the byte into two-bit fields:

| Bits | Logical device | Values 0, 1, 2, 3 |
|---|---|---|
| 0-1 | CON | TTY, CRT, BAT, UC1 |
| 2-3 | RDR | TTY, RDR, UR1, UR2 |
| 4-5 | PUN | TTY, PUN, UP1, UP2 |
| 6-7 | LST | TTY, CRT, LPT, UL1 |

The IOBYTE mechanism is explicitly optional. When implemented, BIOS logical
character routines interpret the mapping. BDOS Functions 3/4/5 still call the
logical READER/PUNCH/LIST BIOS entries; BDOS does not select physical hardware.
On a BIOS without meaningful switching, Functions 7/8 can still round-trip byte
0003h without changing device behavior. This refines, but does not contradict,
ledger entry 0006.

## 3. DRI source findings

OS3BDOS dispatches Function 3 directly to BIOS READER and then places A in the
ordinary BDOS result. Functions 4 and 5 dispatch directly to BIOS PUNCH and
LIST; the common dispatcher has already copied E to C, the BIOS character-input
register. They bypass DRI formatted-console routines, column state, console
break polling, pending console input, and `listcp` toggling.

Function 7 loads byte 0003h and returns it. Function 8 stores the dispatcher's
character byte directly at 0003h and returns. No device initialization or
IOBYTE field decoding occurs in BDOS. Sample BIOS code either implements the
mapping or supplies device-specific/null/EOF stubs; exact devices are BIOS
configuration, not BDOS behavior.

## 4. Experimental design and results

The accepted reference was z80pack cpmsim 1.39, commit
`91fd28eb04e675c2127df88ed3f40675e15282e2`, running DRI CP/M 2.2 with Z80
CBIOS 1.2. The raw transcript and fixture source are under `probes/`.

### 4.1 Reader versus console state

The fixture first caused Function 11 to retain console Z. Function 3 then
called READER exactly once and returned the deliberately diagnostic byte C1h
unchanged, with no console echo. Function 1 subsequently returned the retained
Z (5Ah). Thus Function 3 neither consumes DRI's console pending byte nor uses
console echo/control handling. C1h also locates high-bit clearing at the BIOS/
device contract boundary: DRI BDOS does not transform the BIOS result. A
conforming reader must normally deliver documented 7-bit ASCII.

### 4.2 Punch and List raw paths

Functions 4 and 5 each passed 41h, TAB 09h, Ctrl-P 10h, and diagnostic 80h
unchanged to their respective fixture entry. A further TAB was also direct.
After formatted console A, Function 2 TAB still expanded to seven spaces;
Function 4/5 TAB had not changed formatted-console column state.

Function 5 delivered Ctrl-P as an ordinary LIST byte. A following Function 2
X was absent from LIST capture, proving Function 5 did not enable printer echo.
The same BIOS LIST entry is used when DRI formatted console output copies bytes
under an already-enabled Ctrl-P echo state, but the initiating semantics differ.

### 4.3 IOBYTE and DMA

Function 7 returned the initial 00h. Function 8 with E=A5h immediately made
location 0003h A5h; Function 7 then returned A5h. Function 8 restored 00h.
During A5h state, PUNCH saw the live A5h value, demonstrating that BIOS code can
route using it; the fixed BDOS dispatch did not decode it.

Full-value preservation includes fields irrelevant or unsupported on a given
BIOS. No initialization call was observed. DMA sentinels at 0080h and a selected
alternate address remained A5h and 5Ah. Both disk images were byte-identical
before/after.

The fixture's diagnostic 80h/C1h bytes establish absence of a DRI BDOS mask,
not permission for portable applications to violate the documented 7-bit ASCII
device contract.

## 5. Compatibility conclusions

### REQUIRED

- Implement the documented selector, E input, and A result conventions.
- Route Functions 3/4/5 to logical RDR/PUN/LST services, with documented 7-bit
  ASCII and Ctrl-Z reader EOF behavior supplied at the device/BIOS boundary.
- Keep these direct logical-device paths separate from formatted console echo,
  editing, flow control, column calculation, and Ctrl-P toggling.
- Functions 7/8 must read/write the system IOBYTE value at page-zero 0003h.
- Where IOBYTE routing is implemented, use the documented two-bit fields and
  delegate physical-device selection to BIOS logical-device services.
- These calls must not alter DMA or unrelated disk state.

### NOT GUARANTEED

- Function 3 universally blocks: unimplemented readers may immediately return
  Ctrl-Z or diagnose absence, and physical readiness is BIOS/device-dependent.
- A meaningful result from Functions 4, 5, or 8; residual registers beyond the
  general Investigation 002 ABI.
- IOBYTE Set causes any physical rerouting on a BIOS that omits the optional
  facility; exact physical devices, timing, buffering, and error presentation.

### NOT REQUIRED

- DRI private labels/dispatch layout; the diagnostic high-bit behavior of the
  fixture; z80pack's particular device assignments; automatic device
  initialization by Functions 7/8.

### POLICY PENDING

- Whether BetterCP/M strict mode should always implement active Intel-standard
  IOBYTE routing or permit an inert-but-round-trippable IOBYTE as CP/M permits.
- Behavior for absent logical devices: null output/reader Ctrl-Z, diagnostic,
  or host-configured failure are all permitted by the examined BIOS guidance.

## 6. Proposed Compatibility Ledger additions (not applied)

Investigation 017 proposals 0424-0435 remain unapplied. These proposals begin
at 0436 and do not duplicate entry 0006 or the established console entries.

### 0436. Function 3 Reader convention

Function 3 uses C=03h and returns in A the next character supplied by the
logical READER BIOS service.

Disposition: **REQUIRED**  
Evidence: Interface Guide; Alteration Guide BIOS contract; DRI source; CHAR018.  
Conformance test: Supply a controlled READER byte and verify A and one call.

### 0437. Reader completion and optional-device behavior

Function 3 completes when the logical READER operation completes; universal
blocking is not promised because an absent reader may return Ctrl-Z immediately
or use a BIOS-defined diagnostic.

Disposition: **NOT GUARANTEED**  
Evidence: Alteration Guide optional-device guidance; DRI direct dispatch.  
Conformance test: Accept blocking physical input or documented absent-device EOF.

### 0438. Reader separation from console

Function 3 does not echo, interpret console controls, or consume BDOS console
pending-character state.

Disposition: **REQUIRED**  
Evidence: separate documented logical device; DRI source; CHAR018.  
Conformance test: Retain console input, call Reader, then recover console input.

### 0439. Function 4 Punch convention

Function 4 uses C=04h and sends the ASCII byte in E to logical PUNCH without
formatted-console processing.

Disposition: **REQUIRED**  
Evidence: Interface Guide; DRI source; CHAR018.  
Conformance test: Capture graphic and control bytes at BIOS PUNCH.

### 0440. Function 5 List convention

Function 5 uses C=05h and sends the ASCII byte in E directly to logical LIST;
it neither toggles printer echo nor performs formatted-console processing.

Disposition: **REQUIRED**  
Evidence: Interface Guide; DRI source; CHAR018.  
Conformance test: Capture TAB/Ctrl-P and verify later Function 2 state.

### 0441. Character-output result values

Functions 4 and 5 specify no application-visible result.

Disposition: **NOT GUARANTEED**  
Evidence: Interface Guide; general BDOS ABI.  
Conformance test: Do not require A/HL beyond general normal-return aliases.

### 0442. Function 7 IOBYTE query

Function 7 uses C=07h and returns in A the current byte at location 0003h.

Disposition: **REQUIRED**  
Evidence: Interface Guide; DRI source; CHAR018.  
Conformance test: Compare Function 7 with direct 0003h reads.

### 0443. Function 8 IOBYTE set

Function 8 uses C=08h and E as the new IOBYTE, stores the complete byte at
0003h, and a following Function 7 reproduces it.

Disposition: **REQUIRED**  
Evidence: Interface Guide; DRI source; CHAR018.  
Conformance test: Round-trip several full-byte patterns including A5h.

### 0444. IOBYTE field encoding

Where optional IOBYTE routing is implemented, bits 0-1/2-3/4-5/6-7 select the
documented CON/RDR/PUN/LST assignments respectively.

Disposition: **REQUIRED**  
Evidence: Alteration Guide Intel-standard table; existing entry 0006.  
Conformance test: Exercise all implemented logical-to-physical assignments.

### 0445. IOBYTE routing boundary

BDOS Functions 3/4/5 invoke logical BIOS entries; BIOS, not BDOS, interprets
IOBYTE physical routing, and active routing remains optional.

Disposition: **REQUIRED**  
Evidence: Alteration Guide; DRI source; instrumented BIOS fixture.  
Conformance test: Observe fixed logical dispatch under multiple IOBYTE values.

### 0446. Active IOBYTE routing policy

CP/M permits a BIOS to omit active IOBYTE physical-device reassignment even
though Functions 7/8 expose the byte; whether BetterCP/M always implements
active routing is a compatibility-profile choice.

Disposition: **POLICY PENDING**  
Evidence: Alteration Guide explicitly makes IOBYTE implementation optional.  
Conformance test: Define and test strict and/or inert configured behavior.

### 0447. IOBYTE set has no initialization contract

Function 8 changes selection state only; it does not guarantee physical-device
initialization or a meaningful function-specific result.

Disposition: **NOT GUARANTEED**  
Evidence: Interface Guide silence; DRI source; CHAR018.  
Conformance test: Do not require device-open/reset side effects or result A.

### 0448. Character-device DMA independence

Functions 3, 4, 5, 7, and 8 neither use nor overwrite DMA and do not change the
selected DMA address.

Disposition: **REQUIRED**  
Evidence: interface inputs contain no DMA operand; DRI source; CHAR018 sentinels.  
Conformance test: Preserve default/alternate DMA sentinels across all calls.

## 7. Incomplete and unresolved cases

No required experiment was blocked. Not tested as universal behavior: real
paper-tape/printer timing, distinct stock-z80pack peripherals, all 256 IOBYTE
values, warm-start IOBYTE lifetime, or hardware error presentation. Active
physical rerouting remains configuration/policy dependent; no conclusion is
manufactured from z80pack's absent distinct devices.

## 8. Artifact and preservation audit

- Report, source, COM, deterministic harness, raw output, preserved images,
  instructions, and SHA-256 records: present.
- CHAR018 rebuilt byte-identically with z80asm 2.1.
- Both accepted disk images: byte-identical before/after.
- Authoritative `02 Compatibility Ledger - Investigation 016.txt` before/after
  SHA-256: recorded unchanged.
- No ledger, prior investigation, architecture, roadmap, or other pre-existing
  BetterCP/M file was modified. Only the new Investigation 018 directory is
  installed. No ZIP was created.

## 9. Sources

1. Digital Research, *CP/M 2.0 Interface Guide*, Functions 3-5 and 7-8.
2. Digital Research, *CP/M 2.2 Alteration Guide*, BIOS character I/O and IOBYTE.
3. Digital Research CP/M 2.2 `OS3BDOS.ASM`, February 1980.
4. Digital Research sample `BIOS.ASM` and `CBIOS.ASM`.
5. BetterCP/M Compatibility Ledger and Investigations 002-007, 014, 016, 017.
6. z80pack reference environment identified above.
