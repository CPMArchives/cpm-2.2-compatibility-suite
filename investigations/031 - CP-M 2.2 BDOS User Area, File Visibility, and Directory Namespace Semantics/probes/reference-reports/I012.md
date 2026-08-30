# Investigation 012 - CP/M 2.2 BDOS File Deletion and Rename Semantics

Date: 14 August 2026  
Status: evidence report only; no Compatibility Ledger or pre-existing BetterCP/M file modified

## 1. Scope

This investigation defines Function 19 (Delete File) and Function 23 (Rename File): conventions, FCB identity, wildcard/multiple matches, directory/allocation effects, current/explicit drives, current user, open-FCB interactions, collision behavior, and observable results.

Passwords, CP/M Plus attributes, directory compaction, host filesystem behavior, and write-protection policy remain out of scope. Evidence classes are **A** documented requirement, **B** DRI implementation behavior, **C** possible de facto dependency, **I** incidental, and **D** unresolved.

## 2. Relationship to prior work

The authoritative ledger incorporates Investigations 001-011 and ends at entry 284. Investigation 008 supplies FCB identity/drive/user-independent layout and Open/Close lifecycle; Investigation 009 supplies search/DMA semantics; Investigations 010-011 supply allocation-bearing read/write lifecycles. Proposed additions here begin at 285 and do not repeat those entries.

## 3. Evidence sources

### 3.1 DRI documentation

1. Digital Research, *CP/M 2.0 Interface Guide*, `<reference-archive>/CPM_2_0_Interface_Guide.pdf`, SHA-256 `e10f525fcf399897fa86703eb930e21ba59fa54c0708c1cf5909e92beaf7a279`: Function 19 at printed p. 18 / PDF p. 24 and Function 23 at printed p. 20 / PDF p. 26.
2. Digital Research, *CP/M 2.2 Alteration Guide*, `<reference-archive>/CPM_2.2_Alteration_Guide_1979.pdf`, SHA-256 `98a176be191c68207b5859371cf3d95eb90f517a72bdeb3b3699833e7c368891`: directory/allocation and BIOS context.

Relevant pages were rendered and visually inspected.

### 3.2 DRI source and reference system

3. `<reference-archive>/cpm2-plm/OS3BDOS.ASM`, February 1980 BDOS 2.2, SHA-256 `a22b7dd0f8adaa8dd9affe2cbb0f5749ddf278bf36ca9f94e38f9acf335a44d8`: `delete`, `rename`, search comparator, allocation-vector scanning, reselection, user selection, and dispatch.
4. `OS3BDOS1.ASM`; no material difference found.
5. z80pack commit `91fd28eb04e675c2127df88ed3f40675e15282e2`, cpmsim 1.39, DRI CP/M 2.2 and Z80 CBIOS 1.2, using two preserved disposable images.

## 4. Documented contracts

### 4.1 Delete File

**A:** C=13h, DE=FCB select Function 19. The FCB name/type may contain `?`; drive selection may not be ambiguous. All matching files in the current user on the selected drive are removed.

**A:** FFh means no referenced file was found; otherwise A is 0-3. This code is not a count of deleted files.

### 4.2 Rename File

**A:** C=17h, DE=rename FCB select Function 23. Bytes 0-15 identify the old file; bytes 16-31 carry the new identity. Byte 0 selects the drive. Destination byte 16 is assumed zero, so old and new are on the same drive. The extent/reel part of each half is ignored for naming.

**A:** Rename changes all occurrences/extents of the old identity. A=0-3 means success; FFh means the old name was not found.

**A:** The user number remains identical. CP/M 2.2 has no baseline timestamp preservation requirement.

The interface does not define destination collision behavior, wildcard substitution in Rename, or operations through FCBs opened before a delete/rename.

## 5. DRI implementation analysis

`delete` searches through source name/type, loops over every match, checks write permission, sets directory byte 0 to E5h, clears each nonzero allocation entry from the in-memory allocation vector, writes that directory record immediately, and continues searching. Directory order is not compacted.

`rename` searches through source name/type, then overwrites bytes 0-11 of every matching directory entry from the destination half (after copying source drive into destination-drive position). Extent, RC, allocation, attributes encoded outside the copied name/type bytes, and directory slot remain unchanged. It does not search for an existing destination.

Reselection combines the current BDOS user number with the selected FCB drive. Rename explicitly retains that user; cross-user/cross-drive rename is not represented by the API.

DRI's comparator accepts source `?`; the destination bytes are copied literally. This explains the observed duplicate literal `XREN?.DAT` entries but is not explicit in the interface manual.

## 6. Deterministic probe

`probes/DELREN012.ASM` performs exact and wildcard searches before/after operations, reports A/current drive/FCB bytes, switches user deterministically with Function 32, reopens or reads where relevant, and recreates a deleted file. The preserved A/B images contain controlled one-/multi-record files and a user-1 file.

The required artifact name exceeds CP/M's eight-character filename limit; the same `DELREN012.COM` bytes are stored on A as `DREN012.COM`. `observed-raw.txt` preserves the run; `observed-output.txt` records decoded directory/allocation results and image hashes.

## 7. Principal findings

### 7.1 Deletion

Exact deletion returned 00 and the next search returned FFh. Nonexistent deletion returned FFh. One wildcard call removed both WILD1 and WILD2 while KEEP remained; the success result was still a directory code, not two.

DRI immediately wrote E5h to each directory entry and made its allocation blocks available. A later recreated file acquired a freed block, although exact block selection is not portable.

Explicit B deletion left default A unchanged. User 0 could not delete user-1 U1FILE (FFh); after selecting user 1, deletion succeeded. Thus operations are confined to current user and selected drive.

An FCB opened before deletion could still read the old sector after deletion. Because allocation had already been released, this stale access can alias subsequently allocated data and is not safe or guaranteed.

### 7.2 Rename

OLDNAME -> NEWNAME preserved RC=3, allocation 0Ah, content/extents, and directory position; old search failed and new search succeeded. BOLD -> BNEW did the same on explicit B without changing default A.

Missing source returned FFh. Renaming SRCFILE to existing DEST returned success and created two DEST entries. Wildcard WREN? -> XREN? renamed both source entries to identical literal `XREN?` spellings, not character-substituted names.

An FCB opened under OPNREN could still read after another FCB renamed the directory identity to OPNNEW. Its allocation state remained usable, but its old name no longer identified a directory entry; continued access/close consequences are outside contract.

### 7.3 Directory order and timestamps

DRI rewrites matching entries in place and does not compact. Investigation 009 already establishes that exact physical directory order is not portable. CP/M 2.2's ordinary directory entry has no required timestamps, so timestamp preservation is not a compatibility proposition.

## 8. Required-question answers

1. Delete: C=13h, DE=FCB.
2. Existing and all wildcard matches are removed; nonexistent returns FFh.
3. Success 0-3, no match FFh; other physical/protection errors use separate DRI handling.
4. DRI immediately marks entries E5h and frees allocation-vector bits.
5. Searches stop finding deleted names; freed space is immediately reusable. Existing open FCB behavior is not guaranteed.
6. Explicit/current drive and current user scope the delete; other users are untouched.
7. Rename: C=17h, DE=32-byte two-name FCB.
8. Source is bytes 0-15; destination bytes 16-31, with destination drive byte zero and same user/drive.
9. Existing source succeeds; missing source FFh. Collision and wildcard rename are unspecified; DRI creates duplicate/literal names.
10. Rename preserves allocation, extent/RC/content and rewrites entries in place. No CP/M 2.2 timestamp requirement exists.
11. Explicit drive works without default-drive change; user is unchanged. Open-FCB continuation is unspecified.
12-14. Documented call/result/scope/data-preservation rules are REQUIRED; invalid/collision/open-FCB cases are NOT GUARANTEED; wildcard Rename exactness and physical-error presentation remain POLICY PENDING; private E5/allocation algorithms and in-place order are NOT REQUIRED.

## 9. Proposed Compatibility Ledger additions

Proposals only; the ledger was not modified.

285. **REQUIRED - Function 19 convention.** Delete File uses C=13h and DE=FCB. Source: Interface Guide; Investigation 012. Conformance: delete a controlled exact name.

286. **REQUIRED - Delete identity.** Function 19 matches filename/type in the supplied FCB on its current/explicit drive and current user. Source: Interface Guide; DRI source; Investigation 012. Conformance: isolate drive and user fixtures.

287. **REQUIRED - Delete wildcards.** `?` in Delete filename/type fields shall match any corresponding character. Source: Interface Guide; Investigation 012. Conformance: delete two matching names while preserving a nonmatch.

288. **REQUIRED - Delete all matches.** One Function-19 call shall remove every matching file/extent in scope, not only the first. Source: Interface Guide; Investigation 012. Conformance: enumerate before and after wildcard deletion.

289. **REQUIRED - Delete success result.** Successful Function 19 returns a directory code 0-3. Source: Interface Guide; Investigation 012. Conformance: treat all four as success, not a deletion count.

290. **REQUIRED - Delete no-match result.** Function 19 returns FFh if no referenced file is found. Source: Interface Guide; Investigation 012. Conformance: delete a known absent identity.

291. **REQUIRED - Immediate search disappearance.** After successful Delete, subsequent search shall not return the deleted entries. Source: Delete contract; Investigation 012. Conformance: Search First immediately after Delete.

292. **REQUIRED - Allocation release.** Successful Delete shall release all allocation belonging exclusively to removed entries for subsequent allocation. Source: filesystem deletion contract; DRI source; Investigation 012. Conformance: delete then create/write on constrained media.

293. **NOT GUARANTEED - Exact freed-block reuse.** The identity/order of blocks selected after deletion is allocator-dependent. Source: Investigation 008/012. Conformance: test available capacity, not exact block numbers.

294. **REQUIRED - Explicit-drive Delete.** Function 19 honors a valid explicit drive without changing the default drive. Source: FCB reselection contract; Investigation 012. Conformance: delete B while Function 25 remains A.

295. **REQUIRED - Delete user isolation.** Function 19 affects only files in the current BDOS user number. Source: DRI user model; Investigation 012. Conformance: identical/target names in different users.

296. **NOT GUARANTEED - Open FCB after Delete.** Continued read/write/close behavior through an FCB opened before its directory entry was deleted is outside contract. Source: interface silence; DRI stale-read experiment; Investigation 012. Conformance: applications shall close files before deleting them.

297. **NOT REQUIRED - DRI E5 deletion mechanism.** BetterCP/M need not implement deletion internally by literal E5h marking or DRI's allocation-vector scan, provided observable compatibility holds. Source: DRI source; Investigation 012. Conformance: test absence and reusable capacity.

298. **REQUIRED - Function 23 convention.** Rename File uses C=17h and DE=rename FCB. Source: Interface Guide; Investigation 012. Conformance: rename a controlled file.

299. **REQUIRED - Rename FCB layout.** Source identity occupies bytes 0-15 and destination identity bytes 16-31. Source: Interface Guide; Investigation 012. Conformance: use distinct exact names.

300. **REQUIRED - Same-drive destination.** Source byte 0 selects the drive; destination byte 16 is zero and Rename remains on that drive. Source: Interface Guide; Investigation 012. Conformance: explicit B rename.

301. **REQUIRED - Rename all extents.** Function 23 shall change every directory occurrence/extent of the source file. Source: Interface Guide; Investigation 012. Conformance: rename a multi-extent file and reopen all data.

302. **REQUIRED - Rename success result.** Successful Function 23 returns directory code 0-3. Source: Interface Guide; Investigation 012. Conformance: accept any documented slot code.

303. **REQUIRED - Rename missing-source result.** Function 23 returns FFh when the source name cannot be found. Source: Interface Guide; Investigation 012. Conformance: rename a known absent source.

304. **REQUIRED - Rename identity transition.** After successful Rename, the old exact identity is absent and the new identity identifies the file. Source: Interface Guide; Investigation 012. Conformance: search/open both names.

305. **REQUIRED - Rename data preservation.** Rename shall preserve file contents, extent/record-count state, allocation, and attributes not represented by the changed name/type. Source: Interface Guide operation; DRI source/experiment; Investigation 012. Conformance: compare directory fields and read markers.

306. **REQUIRED - Rename user preservation.** Rename shall keep the file in the same current user; cross-user Rename is not represented. Source: Interface Guide/DRI source; Investigation 012. Conformance: search under current and other users.

307. **REQUIRED - Explicit-drive Rename.** Function 23 honors a valid explicit source drive without changing the default drive. Source: Interface Guide; Investigation 012. Conformance: rename B while A remains default.

308. **NOT GUARANTEED - Destination collision.** CP/M 2.2 does not specify collision rejection or replacement when destination already exists; DRI creates duplicate directory identities. Source: interface silence; DRI source/experiment; Investigation 012. Conformance: compatible applications ensure destination absence.

309. **POLICY PENDING - Wildcard Rename.** DRI matches `?` in the source and copies destination `?` literally to every match, but the interface does not explicitly define wildcard Rename semantics. Source: DRI source/experiment; Investigation 012. Conformance: decide whether BetterCP/M promises this de facto behavior.

310. **NOT GUARANTEED - Open FCB after Rename.** Continued operations through an FCB opened under the old name after Rename are outside the documented contract. Source: interface silence; DRI stale-FCB experiment; Investigation 012. Conformance: applications close before rename and reopen afterward.

311. **NOT GUARANTEED - Physical directory order.** Rename does not create a portable promise about exact directory-slot/order changes. Source: Investigation 009; DRI in-place behavior; Investigation 012. Conformance: programs use search, not slot identity.

312. **NOT REQUIRED - Timestamp preservation.** CP/M 2.2 ordinary directory semantics require no timestamps for Delete/Rename to preserve. Source: CP/M 2.2 directory format; Investigation 012. Conformance: do not impose CP/M Plus fields.

313. **NOT REQUIRED - DRI in-place rename algorithm.** BetterCP/M need not copy exactly 12 bytes in place or reproduce DRI search-loop internals, provided public identity/data results conform. Source: DRI source; Investigation 012. Conformance: inspect public directory/data only.

314. **POLICY PENDING - Delete/Rename physical errors.** Application-visible behavior for BIOS errors and protection failures is governed by broader CP/M error handling, not an additional documented 19/23 code taxonomy. Source: Interface Guide; DRI source; Investigation 012. Conformance: resolve in a dedicated error/protection investigation.

315. **NOT GUARANTEED - Invalid drive ambiguity.** Delete requires an unambiguous valid drive and Rename requires destination drive zero; behavior for ambiguous/invalid drive encodings is outside contract. Source: Interface Guide; Investigation 012. Conformance: compatible callers use documented encodings.

316. **NOT REQUIRED - Directory compaction.** Delete/Rename need not compact or reorder the directory. DRI marks/decorates entries in place; exact physical organization remains internal. Source: scope and DRI behavior; Investigation 012. Conformance: validate enumeration and capacity, not compaction.

## 10. Unresolved policy questions

1. Should BetterCP/M guarantee DRI's wildcard-Rename behavior, including literal destination question marks?
2. Should BetterCP/M deliberately diagnose destination collisions as an extension, while retaining a strict compatibility mode for DRI behavior?
3. How should read-only files/disks and physical directory-write failures interact with Functions 19/23?
4. Should an optional safety mode detect operations on still-open files, without changing baseline CP/M semantics?

## 11. Engineering implications

Delete should identify the complete match set, remove entries, and release allocation coherently before returning success. Rename should alter identity across all extents without reallocating or copying data. Both must combine FCB drive selection with current user and restore the default drive after explicit operations.

Conformance should compare full directory entries and capacity, exercise multiple extents/matches, distinguish result codes from counts, and treat collision/stale-FCB cases as robustness tests rather than baseline promises.

## 12. Recommended future investigations

1. Read-only file/disk vectors and BDOS disk-error handling for destructive operations.
2. Random I/O and Function 35 file-size semantics.
3. User-number namespace lifecycle across all file operations.
4. Allocation reclamation under corrupted/duplicate directory entries.
5. CCP ERA/REN command preprocessing versus raw BDOS semantics.

## 13. Completion audit

- Required report, source, binary, decoded output, README, raw capture, reset script, and preserved pre-run images exist.
- DELREN012.COM rebuilds byte-identically.
- Controlled A/B image changes match the intended Delete/Rename operations; preserved pre-run images are unchanged.
- The authoritative ledger hash is unchanged and no pre-existing BetterCP/M file was modified.
- Proposed entries 285-316, policy questions, and recommended future investigations are present.
- No ZIP archive was created.
