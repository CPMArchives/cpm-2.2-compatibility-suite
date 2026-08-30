# Investigation 007 - CP/M 2.2 BDOS Disk Reset, Selection, and Drive-State Query Semantics

Date: 14 August 2026  
Status: evidence report only; no Compatibility Ledger, prior investigation, or BetterCP/M implementation modified

## 1. Investigation question and scope

This investigation defines the externally visible contract of BDOS functions 13, 14, 24, and 25:

1. Which disk, login, read-only, and DMA state does Reset Disk System establish?
2. How does Select Disk identify and establish the default disk?
3. What does the login vector mean, and when are its bits added or cleared?
4. What does Get Current Disk return?
5. Does page-zero byte 0004h track live BDOS selection during a transient?
6. What is guaranteed for invalid drive numbers?

Function 28 and function 29 are used only to make reset of read-only state observable. Function 17 is used only to trigger documented explicit-FCB drive selection and a directory DMA transfer. Their broader semantics are out of scope.

Evidence classes are **A** documented CP/M 2.2 requirement, **B** DRI implementation behavior, **C** possible de facto dependency, **I** incidental behavior, and **D** unresolved.

## 2. Why this matters to BetterCP/M

Default drive, logged-in drive, read-only drive, and DMA address are distinct state. File operations cannot be specified safely if these are collapsed. This investigation establishes their transitions before later work defines FCB directory and record operations.

It also corrects a misleading live-state reading of ledger entry 7. In DRI CP/M, byte 0004h is command-environment/warm-start state supplied to a transient; function 25 is the live BDOS current-disk query.

## 3. Relationship to the Compatibility Ledger

This investigation depends on entry 7 (page-zero default-drive byte), entries 23-24 (default DMA address and initial command tail), entries 35-43 (BDOS ABI), and entries 45-51 (non-preservation and incidental return state). It adds no alternate ABI rule.

The authoritative ledger ends at entry 131. No existing entry defines functions 13, 14, 24, or 25. Entry 7 requires correction as described in section 12; retaining its current statement would contradict identified DRI behavior.

## 4. Sources examined

### 4.1 Digital Research documentation

1. Digital Research, *CP/M 2.0 Interface Guide*, copyright 1979, `<reference-archive>/CPM_2_0_Interface_Guide.pdf`, SHA-256 `e10f525fcf399897fa86703eb930e21ba59fa54c0708c1cf5909e92beaf7a279`:
   - function 13 and 14, printed p. 14 / PDF p. 20;
   - function 24, printed p. 20 / PDF p. 26;
   - function 25, printed p. 21 / PDF p. 27.
2. Digital Research, *CP/M 2.2 Alteration Guide*, copyright 1979, `<reference-archive>/CPM_2.2_Alteration_Guide_1979.pdf`, SHA-256 `98a176be191c68207b5859371cf3d95eb90f517a72bdeb3b3699833e7c368891`. Section 9 defines page zero and incorporates the interface environment.

The scanned Interface Guide pages were rendered and visually inspected. Its version-2.0 interface is applied for the bounded reason used in Investigations 002-006: the CP/M 2.2 Alteration Guide incorporates that interface, and the identified February 1980 2.2 source implements it.

### 4.2 Original DRI source

3. `<reference-archive>/cpm2-plm/OS3BDOS.ASM`, “Bdos Interface, Bdos, Version 2.2 Feb, 1980,” SHA-256 `a22b7dd0f8adaa8dd9affe2cbb0f5749ddf278bf36ca9f94e38f9acf335a44d8`:
   - private `curdsk`, `dlog`, `rodsk`, and `dmaad` state;
   - selection and automatic reselection paths;
   - functions 13, 14, 24, 25, 28, and 29;
   - common return/reselection path.
4. `<reference-archive>/cpm2-plm/OS2CCP.ASM`, especially `saveuser`, `setdiska`, transient dispatch, and return. It shows that the CCP writes byte 0004h and separately invokes BDOS selection.
5. DRI distribution BIOS source, including SELDSK behavior and its zero return for an unavailable drive.

### 4.3 Reference environment

- z80pack commit `91fd28eb04e675c2127df88ed3f40675e15282e2`;
- `cpmsim` Release 1.39 in Z80 mode, executable SHA-256 `30374c2df2f44118d2b36a8bfef651a9f2d0ee9b9ddd0039c044b9f06df4708d`;
- disposable copies of `cpm22-1.dsk`, SHA-256 `bb06534599e7167547563096217d775bcd073464408dbae0927a010604d03443`, and `cpm22-2.dsk`, SHA-256 `30d3f145e86179801a72963f7ddd59ef83a1c045d3d19901d0a4a697b26a8a7a`;
- byte-identified DRI CP/M 2.2 CCP+BDOS with z80pack Z80 CBIOS V1.2.

The experiment distinguishes these layers: documented propositions are class A; handler/state paths in DRI source are class B; SELDSK availability is BIOS configuration; the simulator merely executes the identified stack.

## 5. Documented CP/M 2.2 requirements

### 5.1 Function 13 - Reset Disk System

**A:** C=0Dh selects Reset Disk System.

**A:** Reset restores disk-system state so all disks are read/write, disk A is the selected default, and the default DMA address is BOOT+0080h (0080h in the standard page-zero arrangement).

**A:** The operation supports changing disks without a system reboot. Media-change safety after a disk is online remains governed by the documented read-only behavior; reset is the interface for reinitializing that state.

The documentation does not promise a function-specific return value.

### 5.2 Function 14 - Select Disk

**A:** C=0Eh selects the function and E supplies a drive number: 0=A through 15=P.

**A:** The selected drive becomes the default for subsequent file operations.

**A:** Selection places that disk online and activates its directory until the next cold start, warm start, or Reset Disk System.

**A:** In the standard environment, changing media while a drive remains online makes it read-only when the change is detected.

**A:** An FCB drive code of zero uses the current default drive. FCB codes 1 through 16 select A through P explicitly and ignore the current default for that operation.

The documented domain is 0-15. It gives no portable normal-return contract for E outside that domain.

### 5.3 Function 24 - Return Login Vector

**A:** C=18h returns a 16-bit login vector in HL. Bit 0 is A and bit 15 is P. Zero means offline; one means actively online because of explicit selection or an implicit nonzero FCB drive reference.

The Interface Guide also describes A=L for earlier compatibility. Ledger entry 39 already requires A=L on every normal BDOS return, so no duplicate finding is proposed here.

### 5.4 Function 25 - Return Current Disk

**A:** C=19h returns the current default disk in A, with 0=A through 15=P.

## 6. Relevant DRI implementation behavior

DRI maintains `curdsk`, `dlog`, `rodsk`, and `dmaad` separately. Function 13 zeros `rodsk` and `dlog`, stores zero in `curdsk`, stores 0080h in `dmaad`, calls BIOS SETDMA, and then follows the ordinary select path. Successful selection therefore leaves A's login bit set, not a zero login vector.

Function 14 aliases `curselect`. A changed valid drive is stored in `curdsk`; BIOS SELDSK is called; its bit is added to `dlog`; and directory state is initialized if this is the first login. Selecting an already-current disk returns without repeating selection.

An explicit nonzero FCB drive temporarily selects that disk. DRI records the former current disk and restores it on the common return path, while the newly logged disk remains in `dlog`. The private temporary fields and call graph are **I**, not requirements.

Neither function 13 nor function 14 writes address 0004h. DRI CCP writes 0004h before dispatching a transient, packing the user number in the high nibble and the CCP's command default disk in the low nibble, and restores its value around command processing. Thus byte 0004h and live `curdsk` can intentionally differ inside a transient. The packing mechanism is **B/I**; the compatibility consequence is that software must use function 25 for live post-selection state.

For a drive rejected by BIOS SELDSK, DRI invokes its select-error path. The displayed error, retry/input behavior, and available drive count depend on BDOS error handling and BIOS configuration. No exact invalid-drive behavior is promoted to baseline contract.

## 7. Experimental method and results

### 7.1 Probe

Artifacts are `probes/DSK007.ASM`, `DSK007.COM`, `observed-output.txt`, and `README.txt`. The final binary SHA-256 is `9a7fbfe8c00f285cacf0568bc9d33f50d0f1287c8849eae9c0b332a199c0e5e9`.

The probe records function 25, function 24, byte 0004h, and function 29 at entry and after controlled transitions. It selects an alternate DMA, resets, explicitly selects B and A, marks A read-only and resets, then performs a wildcard function-17 operation whose FCB explicitly names B. The search result is not evidence about search semantics.

The probe was run once from A and once from B. No BDOS, BIOS, or emulator code was patched. The disks were disposable copies.

### 7.2 Results

| State | Current | Login | 0004h from A/B launch | Read-only | Meaning |
|---|---:|---:|---:|---:|---|
| Entry | A / B | A / A+B | A / B | none | CCP launch state and BDOS state initially agree. |
| Reset | A | A | unchanged A / B | none | Reset establishes BDOS A without rewriting 0004h. |
| Select B | B | A+B | unchanged | none | Explicit selection changes current and adds login. |
| Select A | A | A+B | unchanged | none | Earlier B login remains active. |
| Mark A read-only | A | A+B | unchanged | A | Function 29 makes reset clearing observable. |
| Reset again | A | A | unchanged | none | Login and read-only state reinitialized. |
| Explicit-FCB B operation | A | A+B | unchanged | none | B logs in, then DRI restores current A. |

For the DMA diagnostic, 0080h was prefilled E1h and the alternate DMA E2h. After reset and the B directory operation, 0080h was 00h and the alternate remained E2h in both runs. This is consistent with the documented reset to 0080h and the inspected DRI path.

### 7.3 Limitations

The experiment used configured drives A and B only. It did not invoke an invalid drive because the DRI select-error path is interactive and BIOS-dependent; documentary silence and source analysis are sufficient to reject an exact portable result.

The directory operation is only a trigger. Its 00h result, matching order, directory bytes, and DMA contents are not classified.

The media-change/read-only rule was not induced by swapping disk images during execution. It remains class A from the manual; the probe only validates reset of an explicitly established read-only bit.

## 8. Compatibility analysis

BetterCP/M needs separate current-disk, login-vector, read-only-vector, and DMA state. Reset is a compound transition across all four. A login vector is cumulative online state, not a one-hot copy of current disk.

Explicit FCB drive selection must not permanently replace the current default merely because it logs another drive. Conversely, function 14 does change the current default.

Address 0004h must not be used as the live implementation backing for function 25 without an explicit policy change. DRI proves they can diverge during a transient. Existing entry 7 should describe the page-zero command-entry/warm-start role, not promise synchronization after every BDOS selection.

## 9. Unresolved questions

1. Should BetterCP/M deliberately synchronize 0004h after function 14 as an extension, while preserving strict-mode DRI behavior?
2. What exact policy should BetterCP/M use for drive numbers outside 0-15 or valid CP/M numbers absent from the configured BIOS?
3. Which media-change detection strategies are required across different physical and virtual BIOS designs?
4. Is DRI's preservation of user number across function 13 a de facto dependency? The source states it, but the examined function-13 documentation does not make it explicit.

## 10. Proposed conformance tests

Mandatory tests:

1. Reset from non-A current state and verify function 25 returns A.
2. Establish multiple login bits, reset, and verify only A remains logged.
3. Establish read-only bits, reset, and verify they clear.
4. Select a nondefault DMA, reset, and verify the next disk transfer uses 0080h.
5. Select each configured valid drive with function 14 and verify function 25.
6. Verify explicit selection adds a login bit without clearing earlier bits.
7. Use an explicit-drive FCB and verify login while the prior default is restored.
8. Validate function-24 bit mapping at both low and high byte boundaries on a suitable BIOS.
9. Validate function-25 result range and A=L/B=H aliases independently.
10. Launch from a non-A command drive, reset/select inside the transient, and diagnose 0004h separately from function 25.

Diagnostic/policy tests:

11. Exercise E=16 and unavailable in-range drives under controlled error handling.
12. Compare media-change/read-only behavior on removable, image-backed, and immutable storage.
13. Diagnose whether function 13 preserves user number.

Must-not-require observations:

14. Do not require DRI private state addresses, field names, initialization call graph, or exact select-error text.
15. Do not require a function-specific result from functions 13 or 14.

## 11. Proposed Compatibility Ledger findings

One row is one independently testable proposition. The authoritative ledger was not modified.

| Proposed no. | Proposition | Evidence class | Disposition |
|---:|---|---|---|
| 132 | Function 13 is selected by C=0Dh. | A | REQUIRED |
| 133 | Function 13 makes all disk drives read/write in BDOS state. | A + source + experiment | REQUIRED |
| 134 | Function 13 selects drive A as the current default disk. | A + source + experiment | REQUIRED |
| 135 | Function 13 resets the default DMA address to 0080h. | A + source + experiment | REQUIRED |
| 136 | After function 13 successfully selects A, the login vector contains A online and previously logged drives offline. | A + source + experiment | REQUIRED |
| 137 | Function 13 has no function-specific return value. | A | NOT GUARANTEED |
| 138 | Function 14 is selected by C=0Eh and takes a documented drive number in E. | A | REQUIRED |
| 139 | Function-14 drive numbers 0 through 15 denote A through P. | A | REQUIRED |
| 140 | A successful function 14 changes the current default for subsequent file operations. | A + source + experiment | REQUIRED |
| 141 | Successful function 14 places the selected drive online until cold start, warm start, or disk reset. | A + source + experiment | REQUIRED |
| 142 | Logging another drive does not clear earlier login-vector bits. | A + source + experiment | REQUIRED |
| 143 | Changing media while a drive remains online causes the standard environment to make it read-only when detected. | A | REQUIRED |
| 144 | FCB drive code zero uses the current default drive. | A + source | REQUIRED |
| 145 | FCB drive codes 1-16 explicitly select A-P for that operation, independently of the current default. | A + source | REQUIRED |
| 146 | An implicit explicit-FCB selection can log another drive without permanently changing the current default. | A + source + experiment | REQUIRED |
| 147 | Function 24 returns a 16-bit login vector in HL. | A + source + experiment | REQUIRED |
| 148 | Login-vector bits 0-15 correspond respectively to drives A-P. | A + source | REQUIRED |
| 149 | A zero login bit means offline and a one bit means online through explicit or implicit selection. | A + source + experiment | REQUIRED |
| 150 | Function 25 returns the current default disk in A as 0=A through 15=P. | A + source + experiment | REQUIRED |
| 151 | Function 14 does not guarantee a normal return or particular result for E outside 0-15. | A silence + BIOS-dependent B | NOT GUARANTEED |
| 152 | Functions 13 and 14 have no requirement to rewrite page-zero byte 0004h during a transient. | B + experiment; documentary role analysis | NOT REQUIRED |
| 153 | DRI private disk-state variables and selection/reselection mechanism need not be reproduced. | I | NOT REQUIRED |
| 154 | DRI's exact unavailable-drive error presentation and interaction are not a baseline requirement. | B/C, BIOS-dependent | POLICY PENDING |
| 155 | DRI function 13 preserves the current user number. | B/C | POLICY PENDING |

Proposed new entries: **24** (132-155).

## 12. Proposed corrections or reclassifications

**Correct entry 7.** Its current wording says address 0004h “contains the current default-drive code” and that the byte “reflects the current CP/M default drive.” That is too broad if “current” means live BDOS state after functions 13 or 14.

Proposed replacement proposition:

> **REQUIRED - Command-entry default-drive byte.** On transient entry, the low nibble of location 0004h identifies the CCP default drive associated with the command environment (0=A through 15=P) and is available to the warm-start/CCP convention. Portable software must use BDOS function 25 to query live current-disk state after BDOS drive-state changes. Functions 13 and 14 are not required to synchronize 0004h during the transient.

The high-nibble user-number packing seen in DRI CCP is not added to this correction; it is implementation behavior and was not part of entry 7.

No other entry should be split, merged, or reclassified.

## 13. Implications for later BetterCP/M engineering

The system-services layer should own explicit fields for current drive, online/login vector, read-only vector, current DMA, and user number. Storage backends and BIOS adapters may determine availability and media-change detection, but they must not blur the BDOS-visible state transitions.

Reset should be implemented transactionally enough that callers cannot observe a partially reset combination after normal return. Strict compatibility mode should preserve the DRI distinction between page-zero command state and live BDOS current state.

## 14. Recommended later investigations

1. **BDOS FCB Open, Close, and Directory Search Semantics** - functions 15-18, using the drive-state rules established here.
2. **BDOS DMA and Directory-Entry Transfer Semantics** - functions 26-27 and the externally visible directory buffer contract.
3. **BDOS Read-Only and Drive-Reset Vector Semantics** - functions 28-29 and 37, including media-change policy across BIOS types.
4. **BDOS User Number and Per-User Namespace Semantics** - function 32 and its interaction with reset, CCP, FCBs, and page zero.

## Completion audit

- Investigation directory is direct under `investigations/` and numbered 007: **yes**.
- Existing investigations and authoritative ledger modified: **no**.
- Narrow nonduplicate subject selected after state verification: **yes**.
- Documentary, source, caller, BIOS, and empirical evidence separated: **yes**.
- Probe is reproducible and preserved with source, binary, output, and instructions: **yes**.
- DRI, BIOS, and emulator observations distinguished: **yes**.
- One independently testable proposition per proposed ledger row: **yes**.
- Required, policy-pending, not-required, not-guaranteed, incidental, and unresolved distinctions preserved: **yes**.
- Corrections to existing ledger identified without editing it: **yes**.
- Remaining questions and later work recorded: **yes**.
