# Investigation 022 - CP/M 2.2 CCP Transient Program Lookup, Loading, and Execution Semantics

Date: 15 August 2026  
Status: Complete with explicit limitations in section 20  
Ledger baseline: `02 Compatibility Ledger - Investigation 021.txt`, SHA-256 `26ad23c1ee9cd85a0a1325090b7e27cf875b109b4a75ae8c0cc1dc1e96440402`

## 1. Objective and scope

This investigation fills the boundary between I021's transient candidate and I001's established entry at 0100h: COM-name construction, one-drive/one-user lookup, sequential record loading, resident-memory protection, entry preparation, and immediate return/error recovery. General BDOS Open/Read semantics and resident commands are not reinvestigated.

## 2. Method and evidence classification

- **A:** DRI Features and Facilities, Interface Guide, and Alteration Guide.
- **B:** February 1980 `OS2CCP.ASM` and relevant `OS3BDOS.ASM` behavior.
- **I:** patterned, minimal, boundary, drive/user marker, and three return-path experiments.
- **D:** exact loader presentation, final-record residual bytes, and implementation freedoms.

## 3. Relationship to I001 and I021 boundaries

I021 established an uppercase primary-name candidate and optional resolved command drive. It established that an explicit type is normally rejected and built-ins have already been removed. I001 establishes 0100h entry, page-zero gateways, default FCBs/tail, default DMA, stack return word, and termination forms. I022 neither duplicates nor changes those results; it traces and tests the path between them.

## 4. Documentation findings

Features and Facilities sections 6/6.3 state that CCP looks for `x.COM` after built-in recognition, loads it into the TPA, and executes it by primary name. A prefixed drive temporarily supplies the transient. Interface/Alteration documentation establishes the TPA at 0100h, resident boundary discoverability, default FCB/tail/DMA environment, and termination gateways.

Documentation treats files as 128-byte records and supplies no byte count within a final record. Exact loader loop, private CCP address, and configuration-specific maximum size are not public constants.

## 5. DRI CCP loader source findings

`userfunc` rejects a nonblank type, writes `COM` into the internal command FCB, selects an explicit drive temporarily, and invokes BDOS Function 15. There is one Open attempt: no path, system-drive, alternate-drive, or user-0 fallback.

On success CCP sets the destination/DMA to 0100h and repeatedly calls Function 20. A=00h advances the destination by 0080h. A=01h is successful EOF. Other nonzero results reach `BAD LOAD`. The executable is not Close'd: it is read-only and no directory metadata needs persistence.

After every successful record, CCP compares the next destination with its resident lower boundary and rejects equality or overflow. On accepted EOF it restores the original drive, constructs the two default FCBs and command tail, resets record state, sets DMA to 0080h, saves user/drive, and `CALL`s 0100h.

After RET, CCP resets its private stack, restores page-zero packed user/drive through BDOS selection, and re-enters the prompt loop. Function 0 dispatches to WBOOT; JMP 0000h reaches the same BIOS gateway.

## 6. Executable-name and FCB construction

The loader receives the internal 8.3 FCB-like command representation from I021. It requires the type field to be blank, supplies `COM`, preserves/resolves the drive byte, clears the sequential record field, and calls Function 15. Short names are space-padded; eight characters are accepted; excess characters have already been handled by I021's parser. An explicit `.COM` is not a general executable syntax.

Exact internal FCB address and DRI field-writing instructions are not required. The observable contract is selection of the correct unambiguous `NAME.COM` in the resolved drive/user context.

## 7. Drive and user lookup semantics

Unprefixed lookup uses only the current drive and current user. There is no automatic drive search and no user-0 fallback. Explicit `B:NAME` uses B with the same current user, then restores the persistent drive after ordinary execution/failure. The transient sees the packed command environment reflecting lookup/current state: I021/I001 define FCB-drive and 0004h details.

The marker matrix proved A/user0, A/user1, B/user0, and B/user1 identities independently. ONLY0 was absent from user1 even though present in user0.

## 8. Open and loader initialization

CCP uses Function 15 with a zeroed current-record state and the synthesized COM FCB. A failed Open proceeds directly to generic `comerr`; no secondary search occurs. Successful Open supplies sequential state consumed only by Function 20. CCP does not depend on a Close result or use random/file-size calls.

## 9. DMA and sequential-load mechanics

CCP chooses DMA=0100h for record zero and advances exactly 128 bytes after each successful Function 20. LOAD22 observed record markers at 0100h, 0180h, and 0200h. Before transfer, CCP resets DMA=0080h, then creates/preserves the command tail there. This gives the I001 default-DMA result despite using the entire TPA as load DMA beforehand.

Layering is explicit: CCP selects FCB/destination and advances; BDOS Open interprets the FCB; BDOS Read transfers one record and reports status; CCP interprets EOF/error and restores entry state.

## 10. EOF and final-record semantics

The first Function-20 code 01 terminates a successful load; N successful reads mean N records loaded. A one-byte host fixture occupied a CP/M record, began with RET, and executed. CCP receives no sub-record length and loads the entire final record. PART22 observed 00 at the last byte of its fixture record, but that padding belongs to the disk-creation tool/file contents. No exact padding byte is portable.

An ordinary zero-record CP/M executable was not constructed: CP/M directory representation/cpmtools does not provide a useful executable Open/EOF case distinct from a missing file. No behavior is invented.

## 11. TPA boundary and oversize-program handling

The portable rule is that the loader must not overwrite the resident command/system environment and checks at record granularity. In the accepted 62K reference, CCP begins at E400h. A 453-record file ended with next destination E380h and executed; a 454-record file reached E400h, printed `BAD LOAD`, and did not execute its marker.

The numeric 57,984-byte maximum is not portable. The significant comparison is strict: next destination must remain below the configured resident CCP boundary. This DRI mechanism preserves CCP for ordinary CALL/RET return. BetterCP/M may protect resident state differently.

The boundary record was read into memory below E400h and then rejected; resident memory remained usable and CCP reprompted. No excessive record overwrote resident CCP.

## 12. Successful execution-transfer preparation

After EOF CCP restores the command drive, parses default FCB 1 and 2, copies 33-byte FCB state to 005Ch, constructs the counted uppercase tail at 0080h, sets default DMA 0080h, saves packed user/drive in 0004h, and executes `CALL 0100h`. The CALL creates the valid return word established in I001/I002. Exact SP and return address remain nonportable.

No source or experiment establishes a portable residual-register or interrupt-state promise beyond existing entries.

## 13. RET, Function 0, and JMP 0000h return paths

RET returns to the instruction after CCP's CALL, resets CCP SP, restores saved user/drive, selects the drive, and prompts without WBOOT. Function 0 dispatches through BIOS WBOOT. JMP 0000h uses the page-zero WBOOT gateway. WBOOT-based paths may reload CCP; the requirement is restored command environment, not floppy-sector mechanics.

All three controlled paths, launched from B user1, returned to B>. A follow-up STATE22 saw 0004h=11h and current user 01h. Thus these termination forms converge on the same observable drive/user command environment in the accepted case while remaining internally distinct.

## 14. Loader failure and recovery behavior

Missing Open uses I021's `token?` generic path. Oversize/non-EOF sequential failures use `BAD LOAD`, restore temporary drive and DMA through `retcom`, and reprompt without executing partial bytes. Exact punctuation remains policy-sensitive.

Physical read failure is not re-forced: I015 established BDOS interception/fatal presentation, and source-only repetition would add no safe evidence. CCP distinguishes ordinary EOF code 01 from other returned codes, but a DRI physical error may not return to CCP.

## 15. Experimental design

Artifacts include:

- LOAD22 patterned three-record executable;
- one-byte MINRET22 and short PART22 final-record fixture;
- generated 453/454-record boundary executables;
- four drive/user MARK22 variants;
- STATE22 and RET/F0/J0 terminators;
- deterministic main and return-path Expect harnesses;
- preserved base/fixture/after/return images, transcripts, listings, and hashes.

The preliminary boundary transcript is retained and explicitly non-authoritative: its initial 437/438-record files were below the actual E400h CCP base. The corrected experiment is the accepted evidence.

## 16. Experimental results

1. Contiguous record placement: 0100h/0180h/0200h markers 11h/B2h/C3h.
2. Minimal one-record RET executable loaded/executed.
3. Final record was loaded completely; padding byte was fixture-defined.
4. 453 records executed; 454 records produced BAD LOAD without marker execution.
5. Lookup selected exactly current drive/current user or explicit drive/current user.
6. No user0, other-drive, or system-drive fallback.
7. RET, Function0, and JMP0 restored B/user1 command state.
8. Missing and oversize failures reprompted without disk modification.

## 17. Compatibility conclusions

Required behavior is selection of resolved NAME.COM, current-user isolation, one-drive lookup, contiguous 128-byte loading at 0100h, successful EOF handling, resident-memory protection, reconstruction of I001 entry state, CALL-compatible RET, and recovery from failures/termination.

Not required are DRI's private FCB address, exact CCP base/comparison code, exact maximum bytes, BDOS call count, absence/presence of an internal Close, exact physical WBOOT reload, residual registers, and final-record padding byte.

## 18. Proposed Compatibility Ledger additions (not applied)

### 0492. CCP executable identity

For a transient candidate with primary name NAME, CCP selects the unambiguous executable identity NAME.COM; an explicit type is not required or generally accepted.

Disposition: REQUIRED  
Evidence: I022; Features and Facilities sections 6/6.3; CCP; lookup experiments.  
Conformance: Compare controlled NAME.COM with typed NAME and typed explicit types.

### 0493. Single-drive transient lookup

Unprefixed transient lookup searches the current drive only; CP/M 2.2 provides no automatic alternate/system-drive path search.

Disposition: REQUIRED  
Evidence: I022; CCP; drive marker/missing-file experiments.  
Conformance: Place the same/missing command on controlled drives and vary current drive.

### 0494. Current-user transient lookup

Transient lookup uses only the current user area, with no automatic user-0 fallback.

Disposition: REQUIRED  
Evidence: I022; CCP; user-area marker/ONLY0 experiments.  
Conformance: Place distinct/single COM files in user0/user1 and compare execution.

### 0495. Explicit-drive lookup context

`X:NAME` searches NAME.COM on X in the current user, temporarily selects X, and restores the prior persistent drive after ordinary completion/failure.

Disposition: REQUIRED  
Evidence: I022; Features and Facilities section 6; CCP; B marker experiments.  
Conformance: Record marker, entry state, and following prompt across users.

### 0496. CCP sequential COM loading

CCP loads successful Function-20 records contiguously beginning at 0100h, advancing the destination by exactly 128 bytes per record.

Disposition: REQUIRED  
Evidence: I022; CCP; LOAD22 patterned records; I010.  
Conformance: Verify distinct markers at 0100h+n*0080h.

### 0497. CCP load completion

Function-20 EOF code 01 after N successful reads completes loading successfully; other returned nonzero codes are loader failures rather than executable EOF.

Disposition: REQUIRED  
Evidence: I022; CCP; minimal/pattern/boundary experiments; I010/I015.  
Conformance: Compare ordinary EOF, controlled non-EOF return, and physical-error paths.

### 0498. Final COM record granularity

CCP loads the entire final 128-byte CP/M record and has no portable byte-count information within it; unused/residual final-record bytes are not guaranteed.

Disposition: NOT GUARANTEED  
Evidence: I022; CP/M record model; CCP; MINRET22/PART22.  
Conformance: Vary controlled padding and require only complete record transfer.

### 0499. Resident-system load protection

The transient loader must suppress execution when loading would reach/overwrite configured resident command/system memory; the boundary is enforced at record granularity.

Disposition: REQUIRED  
Evidence: I022; CCP; 453/454-record boundary experiment; I001.  
Conformance: Test largest accepted and first rejected record counts per configuration.

### 0500. Transient maximum is configuration-dependent

Exact maximum COM byte/record count and exact CCP boundary address are configuration-dependent and are not portable constants.

Disposition: NOT GUARANTEED  
Evidence: I022; relocation model; configured boundary experiment.  
Conformance: Repeat boundary tests on differently sized CP/M systems.

### 0501. CCP load-failure nonexecution

Missing, oversize, or non-EOF loader failure suppresses transfer to 0100h and returns/restarts the command environment according to the applicable error layer.

Disposition: REQUIRED  
Evidence: I022; CCP; missing/BOUND marker experiments; I015.  
Conformance: Embed an execution marker in each failed fixture and verify absence.

### 0502. Pre-execution DMA restoration

After using TPA destinations as load DMA, CCP restores default DMA=0080h before transfer and preserves the counted command tail in that buffer.

Disposition: REQUIRED  
Evidence: I022; CCP; STATE/entry observations; I001 entries 0023-0024.  
Conformance: Execute a probe that immediately tests tail and first disk transfer DMA.

### 0503. CCP CALL/RET cleanup path

DRI CCP transfers with CALL 0100h; ordinary RET returns through CCP cleanup, restoring saved user/drive and reprompting without requiring WBOOT.

Disposition: REQUIRED  
Evidence: I022; CCP; RET22/STATE22; I001/I002.  
Conformance: Terminate by RET from controlled drive/user and verify restored state without boot evidence.

### 0504. Termination-state convergence

RET, BDOS Function 0, and JMP 0000h shall all recover a usable command environment preserving the saved command drive/user state, although WBOOT participation and physical reload mechanics differ.

Disposition: REQUIRED  
Evidence: I022; RET/F0/J0/STATE22; CCP; I001/I007/I020.  
Conformance: Compare all three paths from identical controlled state.

### 0505. CCP loader implementation freedom

Exact internal FCB/DMA addresses, register allocation, load-loop instruction sequence, numeric return address/SP, and WBOOT reload sectors are not required when public results conform.

Disposition: NOT REQUIRED  
Evidence: I022; CCP source analysis; configuration variability.  
Conformance: Test observable identity, memory, entry, failure, and return results only.

## 19. Proposed corrections/evidence/disposition updates to existing entries

No disposition correction is required. Add I022 as stronger loader-side evidence to:

- 0001-0004: load origin, entry, and configured bounds;
- 0023-0024: restored default DMA and command-tail overlap;
- 0027-0030: CALL-produced RET word and nonportable exact SP/address;
- 0025-0026: WBOOT termination paths;
- 0486-0489: explicit-drive dispatch, primary-name syntax, preparation boundary, and failure recovery.

No duplicate entries are proposed for page-zero gateways, default FCB layout, command-tail bytes, general Open/Read results, or BIOS WBOOT.

## 20. Incomplete and unresolved cases

1. Zero-record executable behavior was not claimed because a useful Openable zero-record fixture was not established.
2. Physical read failure was not re-injected; I015 controls that layer.
3. Exact final-record padding is intentionally NOT GUARANTEED.
4. Exact `BAD LOAD`/generic punctuation remains governed by I021 presentation policy.
5. Falling through executable bytes was omitted as erroneous application behavior with no compatibility evidence.
6. No later path-search or user0 fallback behavior was considered.

## 21. Artifact and preservation audit

- Required report, sources, COMs, listings, generators, harnesses, transcripts, base/fixture/after/return images, and hashes exist.
- All deterministic COMs, including generated boundary and marker variants, rebuild byte-identically.
- Accepted commands did not modify disks after fixture installation; return-path images remain identical across the three paths.
- Ledger 021 remained `26ad23c1ee9cd85a0a1325090b7e27cf875b109b4a75ae8c0cc1dc1e96440402`.
- No previous investigation, ledger, architecture, roadmap, source, or other BetterCP/M file was modified. No ZIP was created.

## 22. Sources

- Digital Research, *An Introduction to CP/M Features and Facilities*, sections 6 and 6.3.
- Digital Research, *CP/M 2.0 Interface Guide*, transient program and FCB/DMA interface.
- Digital Research, *CP/M 2.2 Alteration Guide*, TPA/page-zero/boot environment.
- DRI `OS2CCP.ASM` (February 1980) and `OS3BDOS.ASM`.
- BetterCP/M I001, I007-I010, I013, I015, I019-I021 and Ledger 021.
- Preserved Investigation 022 experimental artifacts.
