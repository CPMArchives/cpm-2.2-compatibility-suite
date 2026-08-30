# Investigation 026 - CP/M 2.2 BDOS System State Functions and Application-Visible Environment Semantics

Status: Complete evidence report; Compatibility Ledger not modified  
Date: 2026-08-16

## 1. Objective and scope

This investigation defines the application-visible CP/M 2.2 system-state
contract for BDOS Functions 14, 25-27, 31, 32, and 37, and resolves the scope's
Function 39-41 naming against the actual CP/M 2.2 interface. Function 28 is
tested because it is CP/M 2.2's write-protect operation. Evidence classes are
**A** (documented interface), **B** (DRI implementation), **I** (controlled
observation), and **D** (unresolved policy). Exact DRI addresses and private
variables are never promoted merely because they were observable.

## 2. Relationship to previous investigations

I007 already established drive/user state and Functions 13, 14, 24, 25, 28,
29, 32, and 37. I017 established ALV/DPB representation. I018 separated
IOBYTE/BIOS character routing. I019 and I020 established the BIOS selection,
boot, and page-zero boundaries. I024 established termination behavior; I025
established failure semantics. This report cross-checks those findings as one
environment contract and adds no duplicate allocation mapping or BIOS-private
requirements.

## 3. Documentation findings

**A:** Function 14 takes E=0-15 for A-P and selects the default disk. Function
25 (C=19h) returns that current disk in A. Function 26 (C=1Ah, DE=address)
sets the address used for subsequent 128-byte disk transfers until another Set
DMA, disk-system reset, warm start, or cold start; those reset it to 0080h.

**A:** Function 27 returns in HL the current drive's allocation-vector address.
The information can be invalid for a disk marked read-only. Function 31 returns
in HL the BIOS-resident current-drive DPB; the documented 15-byte data may be
read and, when disk conditions require, dynamically changed by a transient.
Neither manual promises numeric pointer values or stale-pointer lifetime.

**A:** Function 32 uses E=FFh to return the current user in A and otherwise
sets the user to E modulo 32. Function 28, not Function 40, temporarily marks
the current disk read-only until a cold or warm start. The examined Interface
Guide documents functions only through 36. It does not document Function 37,
a Function 39 `Get BIOS', or Function 41 file attributes.

**A:** The CP/M 2.2 alteration defines Function 40 as Random Write with Zero
Fill. Function 41 is not a CP/M 2.2 application function. Consequently later
system function names cannot be imported into the 2.2 contract.

## 4. BDOS source findings

**B:** DRI stores `curdsk', `usrcode', `dmaad', login (`dlog'), and read-only
(`rodsk') state in BDOS. Selection calls BIOS SELDSK and adopts the returned
DPH-derived ALV/DPB objects; BIOS owns the DPH/DPB and device operation while
BDOS owns the current/logged/read-only/user/DMA policy state.

**B:** Function 26 records DE in `dmaad' and immediately calls BIOS SETDMA.
BDOS temporarily selects its private directory DMA when needed and restores
the recorded application DMA before returning. Function 27 returns the current
DPH's ALV pointer; Function 31 returns its DPB pointer.

**B:** Function 37 computes both `dlog &= ~DE' and `rodsk &= ~DE'. It does not
change `curdsk', the recorded DMA address, or user code. Functions 38 and 39
dispatch to the ordinary zero-result handler. Function 40 is random write with
zero fill. Selectors above 40 take the previously established out-of-range
zero-return path. Exact symbol placement and work-area layout are **NOT
REQUIRED**.

## 5. Function-by-function analysis

| Function | CP/M 2.2 application-visible meaning | Classification |
|---|---|---|
| 14 | Select E-numbered default disk; successful selection logs it | REQUIRED |
| 25 | Return live default disk in A | REQUIRED |
| 26 | Set persistent current DMA pointer from DE | REQUIRED |
| 27 | Return current-drive ALV pointer in HL | REQUIRED subject to I017 lifetime limits |
| 31 | Return current-drive BIOS DPB pointer in HL | REQUIRED subject to I017 lifetime limits |
| 32 | E=FF query; otherwise set E modulo 32 | REQUIRED |
| 37 | DRI clears selected login/read-only vector bits | POLICY PENDING as undocumented service |
| 28 | Temporarily write-protect current disk | REQUIRED |
| 39 | No `Get BIOS' contract; DRI returns zero | NOT REQUIRED |
| 40 | Random Write with Zero Fill, not Write Protect | REQUIRED under I013, outside this state probe |
| 41 | Outside CP/M 2.2's 0-40 selector range | NOT REQUIRED |

Function 14's invalid/unavailable-drive presentation remains governed by I007,
I015, and I025. It is not converted into a portable normal return here.

## 6. Experimental methodology

Six deterministic Z80 probes were assembled and run on z80pack cpmsim 1.39
with DRI CP/M 2.2 and Z80 CBIOS 1.2. STATE26 covered drive/user/DMA and version;
DPB26 covered cross-drive ALV/DPB pointers and selectors 39/41; RESET26 covered
Function 37; PROTECT26 separated Functions 28 and 40; TERMSTATE26 plus CHECK26
compared RET, Function 0, and JMP 0000h. Expect harnesses supplied every command
and termination character. Fresh per-case disk-image copies were preserved.

STATE26 set DMA to its A5-filled alternate buffer, then made several unrelated
state/pointer calls before Search First. The successful directory transfer
changed that alternate buffer while byte 0080h remained unchanged, showing the
recorded DMA survived intervening calls. The exact returned directory slot and
bytes are directory-layout observations, not new requirements.

## 7. Results

Initial state was current A, user 0, login 0001h, read-only 0000h. After
Function 14 selected B and Function 32 set 7, the query results were B/user 7
and login 0003h. Version Function 12 returned 0022h. The alternate-DMA search
returned slot 01h, changed alternate DMA byte 0 from A5h to 01h, and left 0080h
byte 0 at 00h.

A and B returned distinct ALV pointers FCB0h/FCCFh but shared DPB pointer FA8Dh
and identical 15 bytes in this BIOS. Those addresses and sharing are **I**, not
portable. The bytes decode to the same geometry already recorded by I017.

Function 37 with DE=0002h changed login/read-only 0003h/0002h to 0001h/0000h.
With DE=0001h it then cleared A's login bit while Function 25 still returned A;
the current ALV/DPB pointers remained the observed A pointers. This confirms
that DRI's current-drive number, login vector, and pointer work state are not a
single variable. Use of a current drive after clearing its login bit causes a
later operation to relog/initialize it; stale-pointer behavior is not promised.

Function 28 changed read-only vector 0000h to 0001h. Calling Function 40 with
an unsuitable FCB returned 0006h and left read-only 0001h: it executed the
random-write family, not write protection. Function 37 then cleared the bit.
Function 39 returned 0000h and Function 41 returned 0000h in DRI, but neither
result defines the requested later-system service.

After TERMSTATE26 set B/user 7/DMA 0300h, RET returned to CCP; the subsequent
observer saw current A, user 7, login 0003h. Function 0 and JMP 0000h both led
the observer to current A, user 0, login 0003h. These are DRI CCP/warm-start
observations and agree with I024. The documentation independently requires DMA
reset to 0080h on warm start; command acquisition also uses 0080h. Exact CCP
restoration of user/drive after each termination path remains bounded by I024,
not a general promise that arbitrary global mutations survive program exit.

All accepted disk cases differed from their before images only by deliberate
probe installation; the experiments themselves performed no intended file
mutation.

## 8. Compatibility conclusions

**REQUIRED:** BDOS owns a live current-drive number, user code, application DMA
pointer, login vector, and read-only vector. BIOS supplies selected-drive
DPH/DPB/ALV resources and performs SETDMA/SELDSK operations. Functions 14, 25,
26, 27, 28, 31, and 32 must expose the documented contract. Function 40 must
retain its CP/M 2.2 random-write-with-zero-fill identity.

**NOT GUARANTEED:** current drive or user remains constant after the application
changes it; DMA remains unchanged after Set DMA, disk-system reset, or any
warm/cold start; ALV/DPB pointers remain valid after drive/reset/boot changes;
ALV remains useful after write protection; exact pointer values; or exact
residual registers.

**NOT REQUIRED:** DRI variable addresses/names, shared DPB identity, Function
39 as Get BIOS, Function 40 as Write Protect, Function 41 attributes, or exact
zero values for unsupported selectors.

**POLICY PENDING:** whether undocumented DRI Function 37 is mandatory and, if
so, whether its exact simultaneous login/read-only bit clearing is required;
and the broader I024 policy for which CCP environment changes BetterCP/M should
preserve after each termination path.

## 9. Proposed Compatibility Ledger additions

The ledger is not modified. Proposals begin at 0518.

### 0518. BDOS-owned application system state

    BDOS maintains the live current drive, user code, DMA address, login
    vector, and read-only vector exposed by their documented functions.

    Disposition: REQUIRED

    Evidence: I026; BDOS; IG; I007; I014; I017.

    Conformance: Change and query each state component independently.

### 0519. BIOS-owned selected-drive resources

    BIOS selection supplies drive-specific DPH/DPB/ALV resources while BDOS
    owns application-visible selection, login, protection, and DMA policy.

    Disposition: REQUIRED

    Evidence: I026; BDOS; AG; I017; I019.

    Conformance: Select drives and verify BDOS exposes the corresponding BIOS
    resources without requiring a particular address.

### 0520. Function 26 persistence boundary

    A Function-26 DMA address remains selected for subsequent disk transfers
    until another Function 26, disk-system reset, warm start, or cold start.

    Disposition: REQUIRED

    Evidence: I026; IG; BDOS; I009; I024.

    Conformance: Interpose nonresetting BDOS calls before a transfer, then test
    each documented reset boundary.

### 0521. System-state independence

    Current drive, login membership, read-only membership, user code, and DMA
    address are distinct state; changing one does not imply undocumented
    synchronization of all others.

    Disposition: REQUIRED

    Evidence: I026; BDOS; I007; I017.

    Conformance: Alter each component and query the others.

### 0522. ALV and DPB pointer lifetime

    Exact Function-27/31 pointer values and continued validity after disk
    selection, reset, relogin, or boot transitions are not portable.

    Disposition: NOT GUARANTEED

    Evidence: I026; IG; AG; I017; I019.

    Conformance: Applications re-query after state transitions; conformance
    does not compare DRI numeric addresses.

### 0523. Function 37 compatibility status

    DRI CP/M 2.2 Function 37 clears DE-selected bits from both login and
    read-only vectors without changing the current-drive number, but the
    examined application manuals do not document the service.

    Disposition: POLICY PENDING

    Evidence: I026; BDOS; I007; I017; IG/AG silence.

    Conformance: If adopted, test inactive, current, multiple, and read-only
    drive bits independently.

### 0524. CP/M 2.2 Function 39 has no Get-BIOS contract

    CP/M 2.2 does not define Function 39 as Get BIOS; DRI's observed zero is
    an implementation result and does not expose a BIOS address.

    Disposition: NOT REQUIRED

    Evidence: I026; BDOS; IG; AG.

    Conformance: Do not require a Get-BIOS pointer from selector 39.

### 0525. CP/M 2.2 selectors 40 and 41

    Function 40 is Random Write with Zero Fill. Function 41 file attributes
    are outside CP/M 2.2, whose implemented selector range ends at 40.

    Disposition: REQUIRED

    Evidence: I026; AG; BDOS; I002; I013.

    Conformance: Test Function 40 as random write; require no Function-41
    extension for CP/M 2.2 conformance.

## 10. Existing-entry updates

- Entries 0001-0034: add I026 evidence to default DMA entries 0023-0024; no
  disposition change.
- Entries 0132-0155 within the requested 0190-0247 review context: add I026 to
  Functions 14/25, disk reset, login, user-preservation, and invalid-drive
  boundaries. Entry 0155 remains POLICY PENDING.
- Entries 0190-0247 otherwise concern FCB/search/read behavior; no change.
- Entries 0424-0435: add I026 cross-drive pointer and reset evidence. Preserve
  I017 dispositions; do not duplicate ALV/DPB mapping propositions.
- Entries 0509-0512: add I026 lifecycle observation without strengthening DRI
  post-termination drive/user values into universal requirements.
- Entries 0513-0517: no correction or disposition change.

## 11. Open questions

1. Locate an authoritative DRI CP/M 2.2 application-interface publication for
   Function 37, if one exists.
2. Decide whether BetterCP/M offers later-version Functions 39/41 only as an
   explicitly identified extension, never as baseline CP/M 2.2.
3. Resolve the existing I024 policy for CCP restoration of user/drive state;
   the DRI observations here are evidence, not the decision.
4. DPB edits are documented, but their validation and lifetime across selection
   remain deliberately NOT GUARANTEED as in I017.

## 12. Artifact preservation audit

The new Investigation 026 directory contains sources, six binaries, listings,
harnesses, four transcripts, before/case images, directory listings, emulator
version, build instructions, and SHA-256 manifests. Rebuilt binaries are
byte-identical. The authoritative Investigation-025 ledger SHA-256 before and
after is `fa009b428b776c1d5142ba1d9429a8c3a39de4fac61b258d1737989e381196ef`.
Prior investigations and other protected BetterCP/M files were not modified.

## 13. Sources

- Digital Research, *CP/M 2.0 Interface Guide*, Functions 14, 25-32.
- Digital Research, *CP/M 2.2 Alteration Guide*, BDOS/BIOS changes and Function
  40 Random Write with Zero Fill.
- Digital Research CP/M 2.2 `OS3BDOS.ASM` and `OS2CCP.ASM`.
- Investigations 007, 014, 017-020, 024, and 025.
- z80pack cpmsim 1.39 reference environment and preserved transcripts.

