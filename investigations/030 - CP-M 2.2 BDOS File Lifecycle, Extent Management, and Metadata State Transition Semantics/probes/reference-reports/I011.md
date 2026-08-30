# Investigation 011 - CP/M 2.2 BDOS Sequential Write and File Creation Semantics

Date: 14 August 2026  
Status: evidence report only; no Compatibility Ledger, prior investigation, architecture, roadmap, or BetterCP/M implementation modified

## 1. Scope and evidence classes

This investigation defines Function 22 (Make File), Function 21 (Write Sequential), and Function 16 only where Close makes written metadata persistent. It covers creation, 128-byte DMA writes, FCB mutation, allocation, extent creation, result codes, explicit drives, incomplete application records, and failure boundaries.

Random writes, deletion, rename, user namespaces, read-only-vector policy, and general BIOS behavior are out of scope. Evidence classes are **A** documented requirement, **B** DRI implementation behavior, **C** possible de facto dependency, **I** incidental, and **D** unresolved.

## 2. Relationship to existing findings

The current ledger incorporates Investigations 001-010 and ends at entry 247. Investigation 008 already establishes FCB layout, Function-15 activation, Function-16 convention/results, the requirement to close after writes, and disk-format-dependent allocation maps. Investigation 009 establishes directory-search/DMA observations; Investigation 010 establishes the corresponding sequential-read position and DMA rules.

This report does not duplicate those propositions. Its proposed additions begin at 248 and specialize creation and sequential writing.

## 3. Sources examined

### 3.1 Digital Research documentation

1. Digital Research, *CP/M 2.0 Interface Guide*, copyright 1979, `<reference-archive>/CPM_2_0_Interface_Guide.pdf`, SHA-256 `e10f525fcf399897fa86703eb930e21ba59fa54c0708c1cf5909e92beaf7a279`: Function 16 at printed p. 16 / PDF p. 22 and Functions 21-22 at printed p. 19 / PDF p. 25.
2. Digital Research, *CP/M 2.2 Alteration Guide*, copyright 1979, `<reference-archive>/CPM_2.2_Alteration_Guide_1979.pdf`, SHA-256 `98a176be191c68207b5859371cf3d95eb90f517a72bdeb3b3699833e7c368891`: incorporated interface, disk parameter structures, and BIOS separation.

The relevant pages were rendered and visually inspected. The 2.0 interface is applicable to the identified 2.2 source/reference system for the same bounded reason established in Investigations 002-010.

### 3.2 DRI source and callers

3. `<reference-archive>/cpm2-plm/OS3BDOS.ASM`, “Bdos Interface, Bdos, Version 2.2 Feb, 1980,” SHA-256 `a22b7dd0f8adaa8dd9affe2cbb0f5749ddf278bf36ca9f94e38f9acf335a44d8`: `make`, `seqdiskwrite`, `diskwrite`, `open$reel`, `close`, allocation, FCB update, and dispatch.
4. `OS3BDOS1.ASM` corresponding paths; no material contract difference found.
5. DRI CCP and utility callers were inspected for create/write/close lifecycle and nonzero write handling.

### 3.3 Reference system

- z80pack commit `91fd28eb04e675c2127df88ed3f40675e15282e2`;
- `cpmsim` Release 1.39, Z80 mode, executable SHA-256 `30374c2df2f44118d2b36a8bfef651a9f2d0ee9b9ddd0039c044b9f06df4708d`;
- DRI CP/M 2.2 CCP+BDOS and z80pack Z80 CBIOS V1.2;
- four preserved pre-run images with controlled directory/allocation states;
- cpmtools only for image construction and post-run inspection.

## 4. Documented contract

### 4.1 Make File (22)

**A:** C=16h and DE=FCB address select Make. The FCB must name a file that does not already exist on the FCB-selected or default drive. The caller is responsible for preventing duplicate names; a preceding Delete is suggested where duplication is possible.

**A:** Make creates an empty file, initializes the disk directory and memory FCB, and activates that FCB so a subsequent Open is unnecessary. Success returns a directory code 0-3; FFh means no directory space.

This contract does not define duplicate-name or ambiguous/wildcard creation. It also distinguishes directory space from data storage: an empty file can exist without any record allocation.

### 4.2 Write Sequential (21)

**A:** C=15h and DE=an FCB activated by Open or Make select Write Sequential. It writes the 128-byte record at current DMA into the record designated by the FCB's CR and advances CR.

**A:** Existing records may be overwritten. When CR overflows, the next logical extent is automatically opened and CR is reset in preparation for the next write.

**A:** A=00h reports success. A nonzero result reports an unsuccessful write due to a full disk. The manual does not assign a portable public meaning to every distinct nonzero byte.

### 4.3 Close File (16)

**A:** After writes, Close permanently records new FCB information in the directory. A read-only lifecycle does not require Close. Investigation 008 already records Function 16's C=10h/DE convention and 0-3/FFh results.

## 5. DRI implementation analysis

`make` finds an E5h directory slot, zeroes FCB fields after the identity, creates a zero-record directory entry, and sets a private high-S2 “not yet written” flag. It does not search for a duplicate and does not interpret `?` as a Make wildcard. Those outcomes are consequences of violating the documented precondition.

`seqdiskwrite` reads CR/RC from the caller FCB. If the target allocation entry is zero, it allocates a disk block, records it in the working FCB, writes the complete DMA record, extends RC where needed, clears the private no-write flag, and advances CR. DRI returns 2 when no block can be allocated.

After successfully writing record 128, DRI first updates the FCB, closes that full extent to the directory, and tries to create/open the next extent. If successful, the returned FCB is already EX=next and CR=0. If the directory lacks a slot, record 128 still returns success; the following write at the unresolved overflow position returns 1.

Ordinary writes change only the working FCB until Close merges allocation/RC into the matching directory entry. Make's initial empty entry is therefore searchable immediately, while its persistent length can lag. Private S2 flag values, block search order, zero-fill policy for newly allocated blocks, buffer addresses, and close merge mechanics are **I**.

Physical BIOS errors and write protection take DRI error-handler paths. They are not a documented extended Function-21 result taxonomy.

## 6. Deterministic experiment

`probes/WRITE011.ASM` is noninteractive. It reports operation results, current default drive, all 33 sequential FCB bytes, and selected DMA bytes. Search checks report the matching 32-byte directory entry. Reopen/read checks and host extraction verify persistence.

The preserved images establish:

- A: normal space, the probe, no test files;
- B: 63 of 64 directory entries occupied, data space free;
- C: all 64 entries occupied, data space free;
- D: directory slots free, all 241K data allocation consumed.

The probe covers new, duplicate, literal-question-mark, single/multiple/129-record, no-close, alternate-DMA, explicit-drive, unopened-FCB, directory-full, disk-full, and next-extent-directory-full cases. `observed-output.txt` contains decoded results and before/after hashes; `observed-raw.txt` is the terminal evidence.

## 7. Principal experimental findings

### 7.1 Make and initial visibility

New Make succeeded with directory code 01 and produced EX=0, RC=0, CR=0, and an empty public allocation map. Search First immediately found the empty entry before Close. No data block was reserved.

On allocation-full D, Make still succeeded and created empty NOSPACE.DAT; its first Write returned 02. Directory-full C returned FFh and the image remained byte-identical.

Calling Make for an existing name produced a second NEW.DAT entry. A name containing `?` produced a literal W?LD.DAT entry. These results confirm that DRI does not enforce the caller's uniqueness/nonambiguity obligation; they do not widen the interface contract.

### 7.2 Ordinary writes and DMA

Every successful write returned 00, consumed exactly 128 bytes from current DMA, increased CR, increased RC when writing beyond the prior length, and allocated a block when required. Three marker records persisted as M/N/O. Alternate DMA persisted D plus 127 zeros, confirming that application-level “partial final record” means the application must pad/control all 128 bytes; BDOS has no shorter sequential-write length.

Writing from an FCB never activated by Open/Make happened to return 00 and allocate/write a block in DRI memory, but no directory entry named it. This dangerous, orphan-producing behavior is outside contract.

### 7.3 Directory persistence and Close

After writing NEW.DAT's first record, the caller FCB showed RC=1 and an allocation, but Search First still returned the zero-record directory entry created by Make. Successful Close updated that entry; reopening and reading returned A.

NOCLOSE.DAT repeated the first half and deliberately omitted Close. It remained visible as a zero-record file after warm restart; the written sector was not reachable as file data. Thus a successful Write is not a substitute for Close.

### 7.4 Extents and failures

On normal A, the 128th BIG write returned 00 and returned an already prepared extent-1 FCB with CR=0. The 129th returned 00, left CR=1/RC=1, and final Close produced a 16,512-byte file with correct boundary markers.

On B, Make consumed the last directory slot. All 128 records wrote successfully and the full extent became persistent. Automatic creation of extent 1 then lacked a directory slot; the 128th call still returned 00, while the following call returned 01 without adding record 129.

On allocation-full D, Make returned success because an empty file needs no data block, but its first Write returned 02 and left RC/CR/allocation zero. This experimentally distinguishes directory exhaustion, next-extent directory failure, and data-block exhaustion in DRI.

### 7.5 Explicit drive

The B-drive FCB retained drive byte 2 throughout Make and Write, while Function 25 continued to report default A. Explicit-drive creation/writing therefore uses temporary automatic selection and does not change the default drive.

## 8. Answers to required questions

1. **Make convention:** C=16h, DE=FCB; success A=0-3, directory-full A=FFh.
2. **New/existing/wildcard/explicit:** new and explicit-drive names create empty activated files; existing and ambiguous names violate the precondition and have no portable outcome (DRI created duplicates/literal `?`).
3. **Successful FCB:** identity preserved; extent/record/allocation/current-record state initialized for an empty activated file. DRI's exact S2 flag is private.
4. **Immediate reservation:** a directory entry, but no data record/block, is required for the empty file.
5. **Visibility:** the new zero-record entry is searchable before Close.
6. **Failures:** no directory slot returns FFh; no data storage does not prevent empty Make but prevents the first required allocation; existing-name “failure” is caller-managed, not promised by Function 22.
7. **Write convention:** C=15h, DE=activated FCB.
8. **Size:** exactly one 128-byte record on success.
9. **DMA:** the current Function-26 DMA address is the source.
10. **FCB:** successful writes advance CR, extend RC as needed, and update allocation; extent transition changes EX and system fields. S1/S2 literal contents are not application-owned.
11. **Allocation:** on demand in disk-format-dependent units; exact block choice is not portable.
12. **Shapes:** first/multiple/full-extent writes succeed; the next extent is prepared automatically; cross-extent writing requires no new application Open.
13. **Application partial record:** BDOS still writes 128 bytes; the application supplies padding/content.
14. **Results:** zero success; nonzero failure. DRI used 02 for no data block and 01 when no next extent directory slot was available.
15. **Unactivated FCB:** outside contract; DRI may corrupt allocation state rather than reject it.
16. **Close persistence:** updated RC/allocation/extent directory metadata is committed by Close; full extents may be committed during automatic transition.
17. **No Close:** persistence of the final working extent is not guaranteed; observed one-record data was lost from the file while the empty Make entry remained.
18. **Exact timing:** applications must Close after writes. Internal update timing/merge order beyond required observable lifecycle is not required.

## 9. Proposed Compatibility Ledger additions

These are proposals only; the ledger was not modified.

248. **REQUIRED - Function 22 convention.** Make File shall be selected by C=16h with DE addressing its FCB. Source: Interface Guide; Investigation 011. Conformance: create a controlled new name.

249. **REQUIRED - Make uniqueness precondition.** The Function-22 FCB shall name a file that does not already exist; the caller is responsible for preventing duplicates. Source: Interface Guide; Investigation 011. Conformance: baseline tests use an absent exact name.

250. **REQUIRED - New empty file.** Successful Make shall create a zero-record file under the supplied valid FCB identity. Source: Interface Guide; Investigation 011. Conformance: search the name and inspect RC=0.

251. **REQUIRED - Make activates FCB.** Successful Make shall initialize and activate the caller FCB for subsequent I/O without Function 15. Source: Interface Guide; Investigation 011. Conformance: call Function 21 immediately.

252. **REQUIRED - Make success result.** Successful Make shall return a directory code 0-3 in A. Source: Interface Guide; Investigation 011. Conformance: accept each slot code as success.

253. **REQUIRED - Make directory-full result.** Function 22 shall return FFh when no directory entry is available. Source: Interface Guide; Investigation 011. Conformance: use a 64-entry-full test directory.

254. **REQUIRED - Immediate empty-file visibility.** A successfully made file shall be visible as a zero-record entry to subsequent directory search before Close. Source: DRI source implementing Make; Investigation 011. Conformance: Search First immediately after Make.

255. **REQUIRED - Data-full empty Make.** Exhaustion of data blocks alone shall not prevent creation of an empty file when a directory slot remains. Source: empty-file contract; DRI source; Investigation 011. Conformance: Make on allocation-full media with a free directory slot.

256. **NOT GUARANTEED - Make on existing name.** Function 22 has no portable duplicate-detection/failure behavior when its uniqueness precondition is violated. Source: Interface Guide; DRI duplicate experiment; Investigation 011. Conformance: compatible programs shall check/delete as appropriate before Make.

257. **NOT GUARANTEED - Ambiguous Make name.** Function 22 has no portable wildcard interpretation for `?` in a creation identity. Source: Interface Guide precondition; DRI literal-name experiment; Investigation 011. Conformance: creation names shall be exact and valid.

258. **NOT REQUIRED - Immediate data-block reservation.** BetterCP/M need not reserve a data block during Make; DRI reserves only an empty directory entry. Source: DRI source/experiment; Investigation 011. Conformance: test the zero-record public state, not an internal reservation policy.

259. **REQUIRED - Function 21 convention.** Write Sequential shall be selected by C=15h with DE addressing an activated FCB. Source: Interface Guide; Investigation 011. Conformance: invoke after successful Open or Make.

260. **REQUIRED - Write activation precondition.** Function 21 requires an FCB activated by successful Open or Make. Source: Interface Guide; Investigation 011. Conformance: ordinary tests never synthesize allocation fields.

261. **REQUIRED - Write source position.** Function 21 shall write the record designated by the caller FCB's current extent/current-record state. Source: Interface Guide; Investigation 011. Conformance: reopen and compare sequential markers.

262. **REQUIRED - Successful write result.** Function 21 shall return A=00h when the record is successfully written. Source: Interface Guide; Investigation 011. Conformance: write with available space.

263. **REQUIRED - Write transfer size.** Each successful Function 21 shall consume exactly one 128-byte logical record. Source: Interface Guide; Investigation 011. Conformance: verify all bytes, including record tail.

264. **REQUIRED - Current DMA source.** Function 21 shall take the record from the current DMA address, including an address selected by Function 26. Source: Interface Guide; Investigation 011. Conformance: alternate DMA and reopen/read.

265. **NOT GUARANTEED - Partial-record length.** Function 21 has no shorter application-level byte-count parameter or result; all 128 DMA bytes participate. Source: Interface Guide; Investigation 011. Conformance: applications pad their final logical record.

266. **REQUIRED - CR advance after write.** A successful sequential write shall advance the public FCB to the next record position. Source: Interface Guide; Investigation 011. Conformance: observe CR after consecutive writes.

267. **REQUIRED - RC extension.** A successful write beyond the previous extent length shall increase the working extent record count to include that record. Source: DRI implementation of file-length contract; Investigation 011. Conformance: observe RC=1 and RC=3.

268. **REQUIRED - Existing-record overwrite.** Function 21 shall permit a successful record to overlay an existing record in an activated file. Source: Interface Guide; Investigation 011. Conformance: open an existing file at a controlled CR and verify replacement.

269. **REQUIRED - On-demand allocation.** Function 21 shall obtain sufficient storage when writing an unallocated record and reflect usable allocation state in the FCB. Source: Interface Guide/FCB model; Investigation 011. Conformance: first write to a new file and continue reading it.

270. **NOT GUARANTEED - Exact allocation choice.** Allocation unit representation, selected block numbers, and search order are disk-format/implementation dependent. Source: Investigation 008; DRI source; Investigation 011. Conformance: validate reachability, not block identity.

271. **REQUIRED - Automatic write extent transition.** After filling an extent, sequential writing shall prepare/open the next logical extent automatically without another application Open. Source: Interface Guide; Investigation 011. Conformance: write records 128 and 129 consecutively.

272. **REQUIRED - Successful transition state.** When next-extent preparation succeeds after record 128, the returned working FCB shall permit the next Function 21 at that extent's record zero; DRI exposes EX advanced and CR=0. Source: Interface Guide; Investigation 011. Conformance: inspect state and successfully write record 129.

273. **REQUIRED - Full last record remains successful.** If record 128 itself is written but preparation of a following extent fails for lack of a directory slot, the completed record shall still report success and remain part of the file. Source: DRI source/experiment consistent with per-record success; Investigation 011. Conformance: use a one-slot-left directory.

274. **REQUIRED - Next-extent failure result.** A later Function 21 that cannot create the required next extent shall return nonzero and shall not claim a new record. Source: Interface Guide; DRI source/experiment; Investigation 011. Conformance: attempt record 129 with no directory slot.

275. **REQUIRED - Allocation-full failure.** Function 21 shall return nonzero when the requested record cannot be allocated because storage is full. Source: Interface Guide; Investigation 011. Conformance: first write to an empty made file on allocation-full media.

276. **POLICY PENDING - Exact write failure codes.** DRI returns 01h for unavailable next-extent directory space and 02h for unavailable data blocks, while the manual promises only nonzero unsuccessful/full-disk status. Source: Interface Guide; DRI source/experiment; Investigation 011. Conformance: decide whether BetterCP/M guarantees these exact distinctions.

277. **NOT GUARANTEED - Unactivated write behavior.** Function 21 behavior on an FCB not activated by Open or Make is outside contract; DRI may write orphaned allocation rather than reject it. Source: Interface Guide precondition; Investigation 011. Conformance: compatible programs shall not make such calls.

278. **REQUIRED - Explicit-drive Make/Write.** Functions 22 and 21 shall honor a valid explicit FCB drive without changing the caller's default drive. Source: FCB automatic selection contract; Investigation 011. Conformance: create/write B while Function 25 remains A.

279. **REQUIRED - Close commits final written metadata.** Consistent with entry 178, Close after writes shall make the final extent's new length and allocation persist for later Open/Read. Source: Interface Guide; Investigation 011. Conformance: compare directory search before/after Close and reopen.

280. **NOT GUARANTEED - Unclosed final extent.** Successful Function-21 return alone does not guarantee that final working-extent metadata survives program termination or warm start; the writer must Close. Source: Interface Guide; Investigation 011. Conformance: omit Close only in a negative test.

281. **NOT GUARANTEED - Pre-Close directory metadata.** Before required Close, directory search need not expose the working FCB's latest RC or allocation map. Source: Interface Guide close contract; DRI experiment; Investigation 011. Conformance: applications shall use their activated FCB and Close, not directory search as a commit test.

282. **NOT REQUIRED - Exact close-time update sequence.** BetterCP/M need not reproduce DRI's directory-buffer merge order or exact moment of intermediate extent writes, provided successful lifecycle persistence conforms. Source: DRI source; Investigation 011. Conformance: test final reopened content and documented results.

283. **POLICY PENDING - Physical write-error presentation.** The portable interface does not establish additional Function-21 result codes for BIOS/media errors or write protection; DRI routes these through its error handling. Source: Interface Guide; DRI source; Investigation 011. Conformance: select a documented BetterCP/M policy while preserving ordinary zero/nonzero semantics.

284. **NOT REQUIRED - DRI private write machinery.** BetterCP/M need not reproduce DRI's S2 high-bit write flag, block-search order, buffer zero-fill loop, `open$reel`, or close merge routine. Source: DRI source/experiment; Investigation 011. Conformance: test public FCB, directory, DMA, result, and persistent data behavior.

## 10. Unresolved policy questions

1. Should BetterCP/M promise DRI's exact Function-21 code 01h for next-extent directory exhaustion and 02h for data-block exhaustion, beyond the manual's nonzero contract?
2. How should physical BIOS write errors and write-protected media be presented while preserving CP/M's error-handler behavior?
3. Should BetterCP/M offer a documented transactional extension stronger than CP/M's mandatory-Close lifecycle, without making it baseline compatibility?

## 11. Engineering and conformance implications

Make should atomically reserve a directory identity and return an activated zero-length public FCB without requiring data storage. Write should stage one complete DMA record, allocate as required, update working RC/CR/allocation coherently, and treat extent transition as part of sequential state management. Close is the application commit point for the final extent.

Conformance should separately exhaust directory entries and data blocks; use 127/128/129 boundaries; inspect directory entries before/after Close; verify all 128 DMA bytes; reopen and read persisted markers; and assert default-drive stability. Invalid/duplicate Make and unactivated Write belong in robustness tests whose DRI results are not baseline requirements.

## 12. Recommended future investigations

1. Random Read/Write and random-record FCB semantics, including zero-fill and Function 40.
2. Delete and Rename lifecycle, wildcard scope, allocation reclamation, and collision behavior.
3. Physical disk-error, write-protection, and read-only-vector handling across file writes.
4. File size computation and Function 35 interaction with extent/module boundaries.
5. User-number namespaces and file-operation isolation.

## 13. Completion audit

- The Investigation 011 directory contains the required report and probe files plus raw capture, image-reset/construction scripts, and preserved pre-run images.
- WRITE011.COM rebuilds byte-identically from WRITE011.ASM.
- The accepted pre/post hashes account for expected A/B/D mutation; directory-full C remained byte-identical.
- The Compatibility Ledger and all pre-existing BetterCP/M files were not modified.
- Principal findings, proposed entries 248-284, unresolved policies, and recommended future investigations are present.
- No ZIP archive was created; the investigation remains a direct loose directory.
