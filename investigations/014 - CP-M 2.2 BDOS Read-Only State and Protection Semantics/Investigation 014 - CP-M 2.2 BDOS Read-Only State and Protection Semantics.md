# Investigation 014 - CP/M 2.2 BDOS Read-Only State and Protection Semantics

Date: 14 August 2026  
Status: evidence report only; no Compatibility Ledger or pre-existing BetterCP/M file modified

## 1. Scope and prior findings

This investigation defines Function 30 (Set File Attributes), Function 28 (Write Protect Disk), Function 29 (Get Read-Only Vector), and the observable behavior of protected sequential/random writes, delete, rename, Make, and Close. Investigations 008-013 supply FCB, directory, sequential/random I/O, creation, and destructive-operation contracts. The current ledger ends at 355; proposals here begin at 356.

Each potentially fatal operation was run alone after a fresh boot from a newly restored image. No conclusion labelled experimental below is inferred only from source.

## 2. Sources

1. DRI, *CP/M 2.0 Interface Guide*, `<reference-archive>/CPM_2_0_Interface_Guide.pdf`, SHA-256 `e10f525fcf399897fa86703eb930e21ba59fa54c0708c1cf5909e92beaf7a279`: Functions 28-30, printed pp. 22-23 / PDF pp. 28-29. Relevant pages were rendered and visually inspected.
2. DRI, *CP/M 2.2 Alteration Guide*, `<reference-archive>/CPM_2.2_Alteration_Guide_1979.pdf`, SHA-256 `98a176be191c68207b5859371cf3d95eb90f517a72bdeb3b3699833e7c368891`.
3. `<reference-archive>/cpm2-plm/OS3BDOS.ASM`, February 1980 BDOS 2.2, SHA-256 `a22b7dd0f8adaa8dd9affe2cbb0f5749ddf278bf36ca9f94e38f9acf335a44d8`: `indicators`, `set$ro`, `check$rofile`, `check$write`, `rofsub`, `rodsub`, `close`, reset, and dispatch.
4. Existing BetterCP/M Investigations 008-013.
5. z80pack commit `91fd28eb04e675c2127df88ed3f40675e15282e2`, cpmsim 1.39, DRI CP/M 2.2, Z80 CBIOS 1.2, and preserved disposable IBM-3740 images.

Evidence classes are **A** documented, **B** DRI source/behavior, **I** incidental, and **D** unresolved.

## 3. Documented attribute model

In an FCB/directory entry, bit 7 of the first type byte (byte 9, t1') is the read-only indicator. Bit 7 of byte 10 (t2') is the system/invisible-directory indicator. Bit 7 of byte 11 (t3') is reserved in CP/M 2.2. The low seven bits remain the three file-type characters. Name/type comparisons ignore the high indicator bits where the documented operation requires it.

Function 30 uses C=1Eh and DE=an FCB containing an unambiguous filename. The FCB's t1'/t2' values are copied to every matching directory extent. It returns the ordinary directory code 00-03 on a match and FF on no match. It can set or clear either indicator. Exact directory slots, write order, and search internals are not part of the interface.

Function 28 uses C=1Ch and no function-specific input. It temporarily protects the currently selected drive. Function 29 uses C=1Dh and returns a 16-bit vector in HL: A through P map to bits 0 through 15. Function 13 clears the software read-only vector as part of disk-system reset.

The manual also permits BDOS to mark a disk read-only after detecting a media change. That automatic detection path was not forced in this investigation; only Function 28 and Function 13 were experimentally isolated.

## 4. DRI implementation findings

DRI stores t1'/t2' in directory bytes 9/10. `indicators` searches all filename/type matches and rewrites each matching extent. Open copies the complete directory FCB, including indicators. Make copies the FCB identity and indicators into the new entry.

Protected file mutation reaches `check$rofile`; disk mutation reaches `check$write`. DRI then prints a distinct file- or disk-read-only diagnostic, performs blocking console input, and warm-boots. There is no normal BDOS return from these handlers. These routine names and internal dispatch are not compatibility requirements; whether BetterCP/M must reproduce the exact diagnostic/input/warm-boot presentation is a policy question separate from preventing mutation.

DRI Close has different behavior. A software-protected disk makes Close return early without updating it. File read-only is not rechecked by Close itself. This matters only for an unusual stale/dirty-FCB sequence; ordinary writes to an already read-only file are rejected earlier.

## 5. Deterministic experiment

`probes/PROT014.ASM` reports the BDOS result when one exists, current drive, all 36 FCB bytes, and DMA marker. `run-all-prot014.sh` copied one preserved base image for each mode N and A-K. `run-prot014-case.exp` supplied command input and a deterministic `x` response to each error handler, observed the returning `A>` prompt, and terminated the emulator. Console streams, directory listings, hashes, and all post-run images are preserved.

The base image SHA-256 was `84103fcdc4e2f202194c966120589a824671d03b07305b11bc05dc632cce3acc` for every case.

## 6. Principal experimental findings

### 6.1 Normal attribute and vector behavior

- Function 29 returned `0000`; Function 28 changed it to `0001`; Function 13 restored `0000`. Current drive remained A.
- Function 30 set ATTR.DAT read-only+system with result 00 and cleared both with result 00.
- Function 30 set read-only across 130-record BIG.DAT; the post-run logical multi-extent file was read-only.
- Function 30 on missing NOATTR.DAT returned FF.
- Function 22 created empty MADEATTR.DAT with read-only+system bits from its FCB and returned its directory slot, 03.
- The N image changed only as expected for attributes/new entry; its post-run SHA-256 was `f55cb1dd452581ad5550ef3f8dabebae5dbc099ea7b2dbbaf2349d96c96fccb1`.

### 6.2 File read-only cases A-D

Sequential write (21), random write (34), delete (19), and rename (23) each printed `Bdos Err On A: File R/O`, waited for one scripted character, and warm-booted. None returned to the probe. All four images were byte-identical to their before images; directory and allocation state were unchanged.

Open in A/B copied the read-only bit into the activated FCB. Delete/rename templates in C/D did not need the bit set: BDOS found it in the directory entry and rejected the operation.

### 6.3 Close case E

The probe legally wrote one record to CLOSEME.DAT, saved its dirty activated FCB, used a second FCB and Function 30 to mark the directory entry read-only, restored the dirty FCB, then called Close. Close returned 00. The file remained read-only and one record long; SHA-256 changed to `e2043a728930d49a13680f0237f750d3acd579c81b8d31f2de07c92055627380`.

This is not a protected write returning successfully: the write preceded protection. It shows only that DRI Close does not independently recheck the current directory read-only bit when committing an already dirty FCB. Applications must not treat a late attribute change as a transaction barrier for an outstanding activated FCB.

### 6.4 Disk-protected cases F-J

After Function 28, Make, sequential write, random write, delete, and rename each printed `Bdos Err On A: R/O`, waited for the scripted character, and warm-booted. None returned. Every post-run image was byte-identical to its before image; no directory or allocation mutation preceded the fatal handler.

### 6.5 Vector/reset case K

Function 29 reported `0000`, then `0001` after Function 28, then `0000` after Function 13. The image remained byte-identical, confirming this tested protection state is transient BDOS state rather than an on-disk attribute.

## 7. Answers to required questions

1. Function 30 is C=1Eh, DE=unambiguous FCB; t1'/t2' are byte-9/10 high bits. It sets/clears all matching extents and returns directory code 00-03 or FF.
2. Open preserves directory attributes; Make accepts attribute bits in its FCB; Function 30 changes existing entries. Rename ordinarily preserves attributes under Investigation 012, while protected-file rename/delete are prevented. The exact Close race is described in 6.3.
3. File read-only prevented sequential/random writes, deletion, and rename before any disk-image mutation. DRI entered a fatal handler, required input, then warm-booted; there was no normal result.
4. Function 28 protects the current drive until disk-system reset/warm/cold initialization. In the isolated A-drive test, Function 29 bit 0 tracked it and Function 13 cleared it.
5. Function 29 is C=1Dh and returns HL, A=bit 0 through P=bit 15. The observed A-drive vector was 0001.
6. Disk protection prevented Make, sequential/random writes, delete, and rename before any image mutation. DRI's observed fatal presentation matched 3 with the disk-specific message.
7. The required compatibility core is the FCB bit layout, Function 28-30 ABI/results/state, all-extent attribute change, correct vector/reset behavior, and prevention of protected mutations. Exact DRI routine structure is not required. Exact fatal UI remains policy pending.

## 8. Proposed Compatibility Ledger additions

Proposals only; the ledger was not modified.

356. **REQUIRED - Read-only attribute location.** FCB/directory byte 9 bit 7 (t1') is the file read-only indicator. Source: Interface Guide; Investigation 014.

357. **REQUIRED - System attribute location.** FCB/directory byte 10 bit 7 (t2') is the system/directory-invisibility indicator. Source: Interface Guide; Investigation 014.

358. **REQUIRED - Attribute/type coexistence.** Attribute high bits do not replace the low-seven-bit file-type characters. Source: Interface Guide; Investigation 014.

359. **NOT GUARANTEED - Reserved t3'.** FCB/directory byte 11 bit 7 is reserved and has no application-defined CP/M 2.2 meaning. Source: Interface Guide; Investigation 014.

360. **REQUIRED - Function 30 convention.** Set File Attributes uses C=1Eh and DE=an FCB containing an unambiguous filename. Source: Interface Guide; Investigation 014.

361. **REQUIRED - Function 30 set/clear.** Function 30 sets or clears t1'/t2' according to the supplied FCB. Source: Interface Guide/experiment; Investigation 014.

362. **REQUIRED - Function 30 all extents.** Function 30 applies the requested indicators to every directory extent matching the file identity. Source: Interface Guide/experiment; Investigation 014.

363. **REQUIRED - Function 30 success result.** A successful Function 30 returns directory code 00-03. Source: Interface Guide/experiment; Investigation 014.

364. **REQUIRED - Function 30 no-match result.** Function 30 returns FF when the unambiguous file does not exist. Source: Interface Guide/experiment; Investigation 014.

365. **NOT GUARANTEED - Function 30 exact success slot.** The particular 00-03 directory slot returned for a successful attribute change is not stable across directory layouts. Source: directory model; Investigation 014.

366. **REQUIRED - Open preserves indicators.** Successful Open copies existing file indicator bits into the activated FCB. Source: DRI source/experiment; Investigations 008/014.

367. **REQUIRED - Make accepts indicators.** Successful Make copies supplied t1'/t2' into the new directory entry. Source: DRI source/experiment; Investigations 011/014.

368. **REQUIRED - File read-only sequential protection.** Sequential write to a read-only file is prevented. Source: DRI behavior/experiment; Investigation 014.

369. **REQUIRED - File read-only random protection.** Random write to a read-only file is prevented. Source: DRI behavior/experiment; Investigation 014.

370. **REQUIRED - File read-only delete protection.** Delete of a read-only file is prevented. Source: DRI behavior/experiment; Investigation 014.

371. **REQUIRED - File read-only rename protection.** Rename of a read-only file is prevented. Source: DRI behavior/experiment; Investigation 014.

372. **NOT GUARANTEED - Protected-operation normal result.** DRI protected mutations do not return a BDOS result to the caller; applications must not depend on an A result. Source: DRI source/experiment; Investigation 014.

373. **REQUIRED - Function 28 convention.** Write Protect Disk uses C=1Ch, has no function-specific input, and protects the currently selected disk. Source: Interface Guide; Investigation 014.

374. **REQUIRED - Function 28 transience.** Function 28 protection is BDOS state, not an on-disk file attribute. Source: Interface Guide/experiment; Investigation 014.

375. **REQUIRED - Function 29 convention.** Get Read-Only Vector uses C=1Dh and returns the 16-bit vector in HL. Source: Interface Guide; Investigation 014.

376. **REQUIRED - Read-only vector mapping.** Vector bits 0-15 correspond to drives A-P. Source: Interface Guide; Investigation 014.

377. **REQUIRED - Function 28 vector effect.** Function 28 sets the current drive's bit in the Function 29 vector. Source: Interface Guide/experiment; Investigation 014.

378. **REQUIRED - Reset clears software protection.** Function 13 clears the Function 28 read-only vector state. Source: Interface Guide/DRI source/experiment; Investigation 014.

379. **REQUIRED - Protected-disk Make.** Function 28 protection prevents Make on that disk. Source: Interface Guide/experiment; Investigation 014.

380. **REQUIRED - Protected-disk sequential write.** Function 28 protection prevents sequential write on that disk. Source: Interface Guide/experiment; Investigation 014.

381. **REQUIRED - Protected-disk random write.** Function 28 protection prevents random write on that disk. Source: Interface Guide/experiment; Investigation 014.

382. **REQUIRED - Protected-disk delete.** Function 28 protection prevents delete on that disk. Source: Interface Guide/experiment; Investigation 014.

383. **REQUIRED - Protected-disk rename.** Function 28 protection prevents rename on that disk. Source: Interface Guide/experiment; Investigation 014.

384. **REQUIRED - Protection before mutation.** In the tested DRI paths, rejected file/disk operations leave directory, allocation, and data-image state unchanged. Source: experiment; Investigation 014.

385. **POLICY PENDING - Fatal presentation.** Decide whether BetterCP/M must reproduce DRI's nonreturning diagnostic, blocking console response, and warm boot, or may report protected-operation failure through a defined extension. Source: DRI source/experiment; Investigation 014.

386. **NOT REQUIRED - Fatal handler internals.** BetterCP/M need not reproduce DRI's private error vectors, routine names, stack path, or internal dispatch. Source: DRI source; Investigation 014.

387. **POLICY PENDING - Exact diagnostic text.** Decide whether the exact `Bdos Err On d: File R/O` and `Bdos Err On d: R/O` strings are promised compatibility surface. Source: DRI behavior/experiment; Investigation 014.

388. **NOT GUARANTEED - Late attribute change versus dirty FCB.** Changing a directory entry read-only after a write has already dirtied an activated FCB does not retroactively reject that write; DRI Close can still return successfully. Source: experiment; Investigation 014.

389. **POLICY PENDING - Automatic media-change protection.** Define the required detection policy for disks made read-only by directory/media-change recognition, which this investigation did not force experimentally. Source: Interface Guide/DRI source; Investigation 014.

## 9. Unresolved policy questions

1. Must strict BetterCP/M exactly block for console input and warm-boot on protected operations, or may an opt-in API return an error while preserving strict default behavior?
2. Are the exact DRI diagnostic strings compatibility surface or presentation detail?
3. What media-change evidence is sufficient to set a drive bit automatically, and when may it be cleared other than Function 13/warm/cold initialization?
4. Should BetterCP/M detect stale dirty-FCB/late-attribute races more strictly than DRI, and if so only outside strict compatibility mode?

## 10. Recommended future investigations

1. Automatic read-only state caused by changed removable media and directory checksum differences.
2. Function 40 random write with zero fill under file/disk protection.
3. BIOS physical write errors versus BDOS read-only fatal presentation.
4. Cross-drive/vector behavior with several simultaneously logged/protected drives.

## 11. Completion audit

- The required Investigation 014 directory, report, source, binary, observed output, README, harnesses, fresh base image, twelve post-run images, transcripts, hashes, and directory listings exist in staging and final installation.
- PROT014.COM rebuilds byte-identically from PROT014.ASM; hashes are recorded in the README and observed output.
- Each fatal test used a fresh copy of the preserved base image and exactly one protected operation.
- Cases A-D and F-J, plus vector case K, left their images byte-identical. Only expected normal cases N/E changed images.
- The pre-existing Compatibility Ledger SHA-256 remains `316b2c6eda23a62581f073e95013d27009dab1c9561ec4762c77351131bd42f9`.
- Proposed entries 356-389, principal findings, unresolved policy questions, and future investigations are present.
- No existing BetterCP/M file outside the new Investigation 014 directory was modified. No ZIP archive was created.
