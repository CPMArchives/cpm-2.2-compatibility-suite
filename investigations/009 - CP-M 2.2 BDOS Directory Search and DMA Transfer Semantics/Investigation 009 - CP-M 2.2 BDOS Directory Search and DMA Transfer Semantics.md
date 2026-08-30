# Investigation 009 - CP/M 2.2 BDOS Directory Search and DMA Transfer Semantics

Date: 14 August 2026  
Status: evidence report only; no Compatibility Ledger, prior investigation, architecture, roadmap, or BetterCP/M implementation modified

## 1. Investigation question and scope

This investigation defines BDOS functions 17 (Search First), 18 (Search Next), and function 26 only as it controls directory-search DMA transfer:

1. What are their exact call and result conventions?
2. What does a successful or failed search place at DMA?
3. How does A locate a matching 32-byte entry in the 128-byte record?
4. How are exact, wildcard, explicit-drive, current-drive, and all-user searches interpreted?
5. What state does Search Next continue, and what disrupts it?
6. What directory order is observable and portable?
7. Does changing DMA redirect transfer without restarting enumeration?

Open/close findings from Investigation 008 are used but not repeated. Make, delete, rename, sequential/random I/O, allocation policy, media errors, and general BIOS disk protocol are out of scope.

Evidence classes are **A** documented CP/M 2.2 requirement, **B** DRI implementation behavior, **C** possible de facto dependency, **I** incidental behavior, and **D** unresolved.

## 2. Why this matters to BetterCP/M

Directory search is both CP/M's enumeration interface and an unusual DMA producer: it returns a code in A while transferring an entire record containing four directory entries. Correct enumeration therefore depends on result code, buffer address, record layout, wildcard identity, current user/drive, and retained continuation state.

Establishing this boundary is prerequisite to compatible DIR-like utilities, delete/rename, file discovery, and later DMA/file-record work.

## 3. Relationship to existing ledger entries

The authoritative Investigation 008 ledger ends at entry 187. This investigation depends on entries 23-24 (default DMA/command tail), 35-51 (BDOS ABI), 132-155 (drive state), and 156-187 (FCB layout and identity). In particular, entries 144-146 define default/explicit FCB drives, and entries 158-167 define FCB fields.

No accepted entry defines functions 17, 18, or the general function-26 persistence contract. Investigation 007 established function 13's reset to DMA 0080h; this report does not duplicate that reset rule.

## 4. Sources examined

### 4.1 Digital Research documentation

1. Digital Research, *CP/M 2.0 Interface Guide*, copyright 1979, `<reference-archive>/CPM_2_0_Interface_Guide.pdf`, SHA-256 `e10f525fcf399897fa86703eb930e21ba59fa54c0708c1cf5909e92beaf7a279`:
   - FCB form, printed pp. 5-7 / PDF pp. 11-13;
   - functions 17-18, printed p. 17 / PDF p. 23;
   - function 26, printed p. 21 / PDF p. 27.
2. Digital Research, *CP/M 2.2 Alteration Guide*, copyright 1979, `<reference-archive>/CPM_2.2_Alteration_Guide_1979.pdf`, SHA-256 `98a176be191c68207b5859371cf3d95eb90f517a72bdeb3b3699833e7c368891`, including the incorporated interface, directory/DPB structures, and BIOS separation.

The relevant scans were rendered and visually inspected. The 2.0 Interface Guide applies for the bounded reason used in Investigations 002-008: the 2.2 environment incorporates that interface, and identified February 1980 2.2 source implements it.

### 4.2 Original DRI source and callers

3. `<reference-archive>/cpm2-plm/OS3BDOS.ASM`, “Bdos Interface, Bdos, Version 2.2 Feb, 1980,” SHA-256 `a22b7dd0f8adaa8dd9affe2cbb0f5749ddf278bf36ca9f94e38f9acf335a44d8`: directory reading, comparator, `dir$to$user`, functions 17/18/26, automatic reselection, and common return.
4. `OS3BDOS1.ASM` relevant regions; no material contract difference found.
5. DRI CCP and utilities using Search First/Next, including DIR-like and wildcard callers, were inspected for ordinary continuation patterns.

### 4.3 Reference environment

- z80pack commit `91fd28eb04e675c2127df88ed3f40675e15282e2`;
- `cpmsim` Release 1.39 in Z80 mode, executable SHA-256 `30374c2df2f44118d2b36a8bfef651a9f2d0ee9b9ddd0039c044b9f06df4708d`;
- disposable DRI CP/M 2.2 A/B images with controlled entries and unchanged before/after hashes;
- byte-identified DRI CP/M 2.2 CCP+BDOS and z80pack Z80 CBIOS V1.2;
- cpmtools only for deterministic image preparation/inspection.

DRI documentation/source establish CP/M and implementation behavior. BIOS provides directory sectors through configured disk parameters. cpmsim executes the system. Host directory insertion is test preparation, not a CP/M ordering guarantee.

## 5. Documented requirements

### 5.1 Function 17 - Search First

**A:** C=11h and DE=FCB address select Search First. It starts scanning the referenced directory for the supplied FCB identity.

**A:** FFh in A means no file found. A successful result is 0, 1, 2, or 3.

**A:** On success the current 128-byte directory record is placed at the current DMA address. The matching 32-byte directory entry starts at `DMA + A*32`.

**A:** A directory entry has the CP/M FCB/directory form: user number in byte 0, name/type and attributes, extent/system fields, record count, and allocation map. The other three entries in the transferred record are also observable; the manual notes that programs can extract directory information even though ordinary applications need not.

**A:** `?` in any position from `f1` through `ex` matches the corresponding field of any directory entry on the selected drive. Attribute/high extent bits are not separate literal filename characters.

**A:** With ordinary `dr`, code 0 uses the current default and codes 1-16 select A-P according to the FCB rules. If `dr` is not `?`, S2 is automatically zeroed.

**A:** If `dr='?'`, automatic drive selection is disabled, the current default drive is searched, and returned matches may belong to any user number. This broad scan is documented as unusual for applications but available for complete directory scanning.

### 5.2 Function 18 - Search Next

**A:** C=12h selects Search Next. It takes no new DE parameter in the documented entry convention; it continues the directory scan from the last matched entry established by Search First.

**A:** Successful Search Next has the same 0-3 result and DMA-record relationship as Search First. FFh means no more matching entries.

The documented continuation presumes the search context remains applicable. It does not promise meaningful continuation after changing drives, changing/removing media, starting another search, or invoking an operation that reuses directory-search state.

### 5.3 Function 26 - Set DMA Address

**A:** C=1Ah and DE=the new DMA address select Set DMA Address.

**A:** The selected address is the location of the 128-byte data record before writes and after reads. It remains current until another function 26, cold start, warm start, or disk-system reset changes it.

For directory search, the successful 128-byte directory record is transferred to whichever DMA address is current for that individual function-17/18 call.

## 6. DRI implementation behavior

DRI reads directory sectors into a private directory buffer, scans 32-byte entries in ascending directory position, computes A as the low directory-entry index masked to 0-3, then copies the entire private 128-byte record to the caller's `dmaad`. Its private buffer address, counters, checksum state, and copy routine are **I**.

Search First initializes the scan from the directory beginning and records the FCB address/search length in global BDOS state. Search Next reuses that saved FCB address and directory position. A new search replaces the single continuation context. This organization explains the contract but need not be reproduced internally.

Normal search temporarily selects an explicit FCB drive and restores the prior default on return. Search Next again consults the saved FCB, so an explicit-drive sequence remains on that explicit drive. With FCB drive zero, Search Next uses whatever drive is current at that later call.

DRI unconditionally calls `dir$to$user` after its search routine, including FFh. Consequently failed/exhausted searches copy the last private directory record to DMA. Documentation defines DMA contents only when a file is found; failure contents are **B/I, NOT GUARANTEED**.

DRI's `dr='?'` path sets match length zero, skips automatic selection, and thereby accepts every nonempty entry in current-directory order, including other user numbers. This matches the manual's special complete-directory scan.

## 7. Experimental method and results

### 7.1 Probe

Artifacts are `probes/DSRCH009.ASM`, `DSRCH009.COM`, `observed-output.txt`, `observed-raw.txt`, `capture.exp`, and `README.txt`. The final binary SHA-256 is `ea1c35a31340d516161daa8eed74b9391a6f5e2c7fe651644feb4d47c874b074`.

Controlled A/B directories were populated in known physical order, including four matching A user-0 TXT files, two B matches, a nonmatching type, and one A user-1 file. Each call records A, function-25 current disk, byte 0080h, and all 128 current-DMA bytes. The automated capture uses no timed input.

### 7.2 Results

| Case | Results | Interpretation |
|---|---|---|
| Exact BETA | 1, then FFh | BETA at DMA+32; exact continuation exhausted. |
| Missing | FFh | No match; DRI overwrote DMA with invalid failure residue. |
| A `????????.TXT` | 0,1,3,0,FFh | ALPHA, BETA, DELTA, EPSILON in directory order. |
| Repeat | 0,1 with identical record | Search First restarted; unchanged order repeated. |
| DMA changed between calls | 0 at BUF1, 1 at BUF2 | Continuation survived function 26; next record used new DMA. |
| Alternate DMA exact DELTA | 3 | Full record at BUF2; 0080h sentinel unchanged. |
| Explicit B wildcard | 0,1,FFh | BRAVO then BETA; current A restored after each call. |
| Default A then select B | 0 on A, then 0 on B | DRI position continued against new drive; sequence invalidated semantically. |
| `dr='?'` | 0,1,2,3,0,1,2,FFh | Every nonempty A entry, including user-1 UONE. |

In every success, the selected entry was exactly `DMA + A*32` inside the captured 128-byte record. Image hashes remained unchanged across both accepted runs.

### 7.3 Repeatability and rejected run

The final interactive and automated-capture runs produced the same decoded results and unchanged disk hashes. A development run with DE incorrectly left at FCB+16 is rejected and not evidence; it led directly to correcting the probe helper before the accepted runs.

### 7.4 Limitations

The BIOS was not instrumented because BIOS physical-read counts are not required to establish the caller-visible record transfer. Results use one disk format and controlled drives/users. Ordering under directory mutation, erased-entry reuse, media changes, alternative DPBs, and I/O error paths remains untested.

## 8. Compatibility analysis

The valid search result is a tuple: result code A, current DMA address, 128-byte record, and the 32-byte entry at A*32. Returning only a copied FCB, only the matching 32 bytes, or an arbitrary list index would be incompatible.

Search order is physical/logical directory scan order, not alphabetic order. BetterCP/M must continue forward through its compatibility directory ordering, but applications have no guarantee that independently created disks yield the same filename sequence.

Function 26 changes the destination, not the search cursor. Search continuation is a single stateful operation and should be treated as interrupted by a new Search First or state-changing directory/drive operations unless a later investigation establishes stronger interleaving guarantees.

Explicit-drive FCBs bind each continuation call to that drive. Default-drive FCBs do not freeze a drive identity in DRI; changing default drive between calls destroys portable sequence meaning.

## 9. Unresolved questions

1. Which intervening BDOS directory operations besides a new Search First overwrite or invalidate Search Next state in externally significant ways?
2. Do important programs depend on DRI copying a directory record on FFh despite documentary silence?
3. What continuation/error behavior is required if media changes, a directory mutates, or BIOS I/O fails mid-search?
4. Must BetterCP/M duplicate DRI's exact empty/deleted neighboring entry bytes in a successful 128-byte record, or only the disk's actual directory contents?
5. How should extensions with more than four entries per internal unit still present the mandatory CP/M 128-byte/four-entry DMA interface?
6. Are malformed high-bit filename bytes matched consistently enough across DRI systems to matter?

## 10. Proposed conformance tests

Mandatory tests:

1. Exact and missing Search First calls with controlled directories.
2. Verify A=0-3 and matching entry address `DMA+A*32` independently for all four positions.
3. Verify all 128 successful DMA bytes, including neighboring entries.
4. Enumerate multiple wildcard matches through FFh.
5. Verify Search First restarts from the directory beginning and Search Next continues after the last match.
6. Repeat on unchanged media and require the same physical directory sequence.
7. Verify exact sequence is not assumed alphabetic or creation-independent.
8. Test filename, type, and extent `?` positions separately.
9. Test default, explicit A/B, and `dr='?'` all-user searches.
10. Change DMA between First and Next and verify continuation plus new destination.
11. Preserve a sentinel at 0080h during alternate-DMA search.
12. Verify explicit-drive search restores prior current drive.

Diagnostic/policy tests:

13. Inspect but do not require DMA after FFh.
14. Change default drive between default-drive First/Next and diagnose invalidation.
15. Interleave another Search First and directory operations to map continuation replacement.
16. Exercise media mutation and controlled BIOS read failures.

Must-not-require observations:

17. Do not require DRI private buffer addresses, search counters, checksum arrays, or unconditional-copy implementation.
18. Do not require alphabetic enumeration or the same physical order across independently constructed directories.

## 11. Proposed ledger findings

One row is one independently testable proposition. The authoritative ledger was not modified.

| Proposed no. | Proposition | Evidence | Disposition |
|---:|---|---|---|
| 188 | Function 17 is selected by C=11h and takes an FCB address in DE. | A | REQUIRED |
| 189 | Search First starts scanning at the beginning of the referenced directory. | A + source + experiment | REQUIRED |
| 190 | Successful Search First returns directory code 0-3 in A. | A + experiment | REQUIRED |
| 191 | Search First returns FFh in A when no entry matches. | A + experiment | REQUIRED |
| 192 | On successful search, BDOS places the complete 128-byte directory record at current DMA. | A + source + experiment | REQUIRED |
| 193 | A successful result code selects the matching 32-byte entry at `DMA+A*32`. | A + experiment | REQUIRED |
| 194 | The transferred record consists of four compatibility-visible 32-byte directory entries. | A + experiment | REQUIRED |
| 195 | Directory entry byte 0 contains its user number. | A + experiment | REQUIRED |
| 196 | Directory entry bytes 1-31 use the documented FCB identity, extent, record-count, and allocation form. | A | REQUIRED |
| 197 | `?` in FCB positions f1 through ex wildcards the corresponding directory field. | A + source + experiment | REQUIRED |
| 198 | Search comparison does not treat documented type attribute bits as different base type characters. | A + source | REQUIRED |
| 199 | Ordinary FCB drive 0 searches the current default drive. | A + experiment | REQUIRED |
| 200 | Ordinary explicit FCB drive 1-16 searches A-P and restores the prior current default after return. | A + source + experiment | REQUIRED |
| 201 | For ordinary Search First, S2 is automatically zeroed when the documented special wildcard condition does not apply. | A + source | REQUIRED |
| 202 | FCB `dr='?'` disables auto-selection and searches the current default drive across all user numbers. | A + source + experiment | REQUIRED |
| 203 | Function 18 is selected by C=12h and takes no new documented DE argument. | A | REQUIRED |
| 204 | Search Next continues scanning after the last matched directory entry. | A + source + experiment | REQUIRED |
| 205 | Successful Search Next uses the same 0-3 result and 128-byte DMA relationship as Search First. | A + experiment | REQUIRED |
| 206 | Search Next returns FFh when no further entry matches. | A + experiment | REQUIRED |
| 207 | A new Search First restarts and replaces the prior continuation sequence. | A + source + experiment | REQUIRED |
| 208 | Function 26 is selected by C=1Ah and takes the new DMA address in DE. | A | REQUIRED |
| 209 | Function 26 makes its address current until another set/reset/start transition changes it. | A + source | REQUIRED |
| 210 | Changing DMA between Search First and Search Next does not restart the search; the next successful record uses the new DMA. | A + source + experiment | REQUIRED |
| 211 | Search enumeration proceeds in directory scan order. | A + source + experiment | REQUIRED |
| 212 | Repeating a search on unchanged directory state yields the same scan order. | A + experiment | REQUIRED |
| 213 | Enumeration is not guaranteed alphabetic or identical across independently laid-out directories. | A/source analysis | NOT GUARANTEED |
| 214 | Continuation after changing the default drive during a default-drive search is not guaranteed to remain on the original drive. | B + experiment | NOT GUARANTEED |
| 215 | Continuation after another search or a directory/media mutation is not generally guaranteed without specific evidence. | D/source state analysis | NOT GUARANTEED |
| 216 | DMA contents after FFh are not valid search-result data. | A silence + B experiment | NOT GUARANTEED |
| 217 | DRI's FFh-path copy of its last private directory record is not required. | B/I + experiment | NOT REQUIRED |
| 218 | DRI private directory buffer, counters, checksum state, and search implementation are not required. | I | NOT REQUIRED |

Proposed additions: **31 entries (188-218)**.

## 12. Proposed corrections/reclassifications

No existing ledger entry requires correction, splitting, merging, or reclassification.

Entries 174-175 remain open-specific wildcard/first-match findings. Entries 197 and 204-207 define enumeration behavior and therefore do not duplicate the open contract.

Entry 146's explicit-FCB temporary selection is confirmed for search; it remains unchanged.

## 13. Engineering implications

BetterCP/M must maintain a compatibility search cursor containing at least directory identity/position and enough FCB context to continue. Its internal representation may differ, but one active continuation sequence must behave like CP/M.

Directory search must materialize a genuine 128-byte CP/M directory record at current DMA and return the entry slot separately. A higher-level filename iterator is insufficient unless it reconstructs the exact compatibility record.

The current DMA belongs to BDOS state, not the search cursor. Disk-format and storage layers may use other internal block sizes, but the compatibility boundary remains four 32-byte entries per 128-byte transfer.

## 14. Recommended future investigations

1. **BDOS Sequential File Read Semantics** - function 20, 128-byte DMA records, CR/EX/RC transitions, EOF, and automatic extent continuation.
2. **BDOS Sequential File Write and Make Semantics** - functions 21-22, allocation, creation, dirty state, disk-full handling, and close.
3. **BDOS Delete and Rename Semantics** - functions 19 and 23 using established wildcard/search identity rules.
4. **BDOS Search-State Interleaving and Mutation** - only if software evidence requires stronger guarantees for intervening calls.
5. **BDOS Read-Only and Drive-Reset Vector Semantics** - functions 28-29 and 37.
6. **BDOS User Number and Namespace Semantics** - function 32 and directory user-byte behavior.

## Completion audit

- Investigation 009 directory exists directly under `investigations/`: **yes**.
- Required report and probe filenames present: **yes**.
- Final probe rebuilds byte-identically: **yes**.
- Existing BetterCP/M files outside new Investigation 009 modified: **no**.
- Ledger additions and unresolved policy questions included: **yes**.
- DRI/BIOS/emulator/host-preparation boundaries distinguished: **yes**.
- Successful and failed DMA semantics separated: **yes**.
