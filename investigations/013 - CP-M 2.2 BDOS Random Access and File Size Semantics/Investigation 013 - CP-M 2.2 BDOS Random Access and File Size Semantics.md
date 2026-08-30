# Investigation 013 - CP/M 2.2 BDOS Random Access and File Size Semantics

Date: 14 August 2026  
Status: evidence report only; no Compatibility Ledger or pre-existing BetterCP/M file modified

## 1. Scope and prior findings

This investigation defines Functions 33 (Read Random), 34 (Write Random), 35 (Compute File Size), and 36 (Set Random Record), including FCB bytes 33-35, random/sequential state conversion, virtual holes, extent creation, DMA, results, and Close.

Investigations 008-012 supply FCB/Open/Close, directory/DMA, sequential I/O, creation, and destructive-operation contracts. The current ledger ends at 316; proposals here begin at 317. CP/M Plus extensions, timestamps, host seeks, and application record formats are excluded.

## 2. Sources

1. DRI, *CP/M 2.0 Interface Guide*, `<reference-archive>/CPM_2_0_Interface_Guide.pdf`, SHA-256 `e10f525fcf399897fa86703eb930e21ba59fa54c0708c1cf5909e92beaf7a279`: Functions 33-36, printed pp. 25-29 / PDF pp. 31-35. Relevant pages were rendered and visually inspected.
2. DRI, *CP/M 2.2 Alteration Guide*, `<reference-archive>/CPM_2.2_Alteration_Guide_1979.pdf`, SHA-256 `98a176be191c68207b5859371cf3d95eb90f517a72bdeb3b3699833e7c368891`.
3. `<reference-archive>/cpm2-plm/OS3BDOS.ASM`, February 1980 BDOS 2.2, SHA-256 `a22b7dd0f8adaa8dd9affe2cbb0f5749ddf278bf36ca9f94e38f9acf335a44d8`: `rseek`, `randiskread`, `randiskwrite`, `compute$rr`, `getfilesize`, `setrandom`, and dispatch.
4. z80pack commit `91fd28eb04e675c2127df88ed3f40675e15282e2`, cpmsim 1.39, DRI CP/M 2.2, Z80 CBIOS 1.2, and preserved disposable A/B images.

Evidence classes are **A** documented, **B** DRI behavior, **I** incidental, and **D** unresolved.

## 3. Documented model

FCB bytes 33-35 form a 24-bit little-endian random record: r0 low, r1 middle, r2 high. CP/M 2.2 random I/O uses r0/r1 as a zero-based 16-bit record number 0-65535; r2 must be zero. Function 35 may return r2=1 to represent size 65536.

The random field is caller-visible state separate from EX/S2/CR/RC/allocation. Random I/O maps it into logical extent/current-record working fields but does not increment it. The last random record is reread/rewritten if immediately switching to sequential I/O unless the application advances position appropriately.

Function 36 is frequently misunderstood: it computes bytes 33-35 **from current sequential EX/S2/CR state**. It does not take a random number and set EX/CR, and it performs no file I/O.

Function 35 scans the unambiguous filename and writes the virtual record address following EOF into r0-r2. This is a record count, not bytes or extents. Sparse holes count toward virtual size.

## 4. Function contracts

### 4.1 Read Random (33)

C=21h, DE=activated FCB. It reads the selected random record into current DMA, leaves r0-r2 unchanged, and sets EX/S2/CR to correspond to that record. Success is 00. Documented codes include 01 unwritten data, 03 cannot close current extent, 04 seek to unwritten extent, and 06 r2 nonzero/physical-limit overflow. Nonzero generally means missing data/failure.

### 4.2 Write Random (34)

C=22h, DE=activated FCB. It writes exactly one 128-byte current-DMA record, allocates missing blocks/extents, leaves r0-r2 unchanged, and sets EX/S2/CR to the addressed record. Unlike sequential write, writing the last record of an extent does not automatically switch to the next extent. Close remains required. Write additionally defines code 05 when a new extent cannot be created; DRI uses 02 when no block can be allocated.

### 4.3 Compute File Size (35)

C=23h, DE=FCB containing an unambiguous filename and bytes 33-35. It returns the maximum virtual record count in those bytes. It need not activate/open the file and specifies no meaningful A result.

### 4.4 Set Random Record (36)

C=24h, DE=FCB. It maps the FCB's current sequential position into r0-r2. The manual specifies no A result. It modifies the FCB only.

## 5. DRI implementation findings

`rseek` decodes r0 bits 0-6 as CR, higher r0/r1 bits as extent/module, rejects nonzero r2 with 06, closes the current extent when switching, and opens the selected extent. Read of a missing extent returns 04; write creates it or returns 05. It then uses the ordinary disk-read/write paths in nonsequential mode.

Function 35 scans all matching extents, computes `module/extent/RC` end positions, and stores the maximum. Its final A/`lret` is incidental (observed FFh), because the documented result is solely r0-r2.

Function 36's `compute$rr` accepts CR=128 as the same boundary position as EX advanced/CR=0. DRI private module packing, close/open ordering, allocation choice, and exact internal flags are not required.

## 6. Deterministic experiment and principal findings

`probes/RAND013.ASM` reports result, current drive, all 36 FCB bytes, and DMA marker. Preserved A contains empty/1/127/128/130-record fixtures; B is allocation-full with directory space. The accepted run and hashes are decoded in `observed-output.txt`.

- Function 36 yielded 0,1,127,128,255,256,65535 exactly; CR=128 and EX=1/CR=0 both yielded 128.
- Function 35 yielded 0,1,127,128,130 records for controlled shapes.
- Reads 0/64/129 succeeded; record 130 and empty record 0 returned 01; missing extent 256 returned 04; r2=1 returned 06. DMA stayed sentinel on failure.
- Random fields never advanced. Successful reads/writes changed EX/S2/CR to the addressed record.
- Overwrite and append succeeded; Close made ONE two records.
- Writing only sparse record 10 produced virtual size 11; record 5 returned 01 and record 10 returned S.
- Writing record 128 created extent 1 and produced size 129 without automatic random-field advance.
- Writing record 65535 produced virtual size 65536 (`00 00 01`) while allocating only one block.
- Allocation-full random write returned 02; the empty made file remained zero records.

## 7. Answers to required questions

1-4. Bytes 33/34/35 are low/middle/high little-endian. Random I/O range is zero-based 0-65535 with r2=0; the field is independent caller state, though operations derive EX/S2/CR working state from it.

5-9. Function 36 is C=24h, DE=FCB; it maps sequential state to random state, not the reverse. Tested boundaries are exact. It changes only bytes 33-35, performs no disk access, and has no specified A return.

10-15. Function 33 is C=21h, DE=activated FCB. It reads current random record to DMA, does not advance r0-r2, but sets sequential fields. Existing succeeds; EOF/unallocated/missing extents return documented nonzero codes.

16-21. Function 34 is C=22h. It writes one DMA record, allocates blocks/extents, supports sparse/boundary/65535 writes, updates working extent/RC/CR, leaves random field unchanged, and requires Close. Zero succeeds; documented failures are nonzero.

22-26. Function 35 is C=23h, DE=unambiguous FCB. It writes virtual record count to r0-r2, including 65536 as r2=1. It modifies those bytes, not file contents.

27-29. Manual ABI/state/size/error rules are REQUIRED. Exact allocator/internal extent machinery is NOT REQUIRED. Physical-error presentation and any guarantees beyond documented codes remain POLICY PENDING.

## 8. Proposed Compatibility Ledger additions

Proposals only; the ledger was not modified.

317. **REQUIRED - Random field location.** FCB bytes 33-35 are r0, r1, r2. Source: Interface Guide; Investigation 013.

318. **REQUIRED - Random field byte order.** r0 is least significant, r1 middle, r2 high. Source: Interface Guide; Investigation 013.

319. **REQUIRED - CP/M 2.2 random range.** Functions 33/34 address zero-based records 0-65535 with r2=0. Source: Interface Guide; Investigation 013.

320. **REQUIRED - Random/sequential state distinction.** r0-r2 are not automatically advanced with EX/CR/RC; conversion occurs only through specified operations. Source: Interface Guide; Investigation 013.

321. **REQUIRED - Function 36 convention.** Set Random Record uses C=24h and DE=FCB. Source: Interface Guide; Investigation 013.

322. **REQUIRED - Function 36 direction.** Function 36 computes r0-r2 from current EX/S2/CR sequential state. Source: Interface Guide; Investigation 013.

323. **REQUIRED - Function 36 boundary equivalence.** CR=128 and the following extent's CR=0 represent the same random boundary. Source: documented position model; Investigation 013.

324. **REQUIRED - Function 36 no I/O.** Function 36 modifies FCB random-position bytes without reading/writing file data. Source: Interface Guide/DRI source; Investigation 013.

325. **NOT GUARANTEED - Function 36 A value.** Function 36 specifies no meaningful A result. Source: Interface Guide; Investigation 013.

326. **REQUIRED - Function 33 convention.** Read Random uses C=21h and DE=activated FCB. Source: Interface Guide; Investigation 013.

327. **REQUIRED - Random read destination.** Successful Function 33 transfers exactly one 128-byte record to current DMA. Source: Interface Guide; Investigation 013.

328. **REQUIRED - Random read success.** Function 33 returns 00 for a successful record. Source: Interface Guide; Investigation 013.

329. **REQUIRED - Random read position.** Function 33 addresses r0-r2 and sets logical extent/current-record fields to that record. Source: Interface Guide; Investigation 013.

330. **REQUIRED - Random read no advance.** Function 33 leaves r0-r2 unchanged. Source: Interface Guide; Investigation 013.

331. **REQUIRED - Random read unwritten data.** Function 33 returns nonzero for EOF/unallocated data; DRI code 01 denotes unwritten data. Source: Interface Guide; Investigation 013.

332. **REQUIRED - Random read missing extent.** DRI-compatible Function 33 returns 04 when the selected extent has not been created. Source: Interface Guide; Investigation 013.

333. **REQUIRED - Random overflow.** Nonzero r2 on Function 33/34 is beyond the CP/M 2.2 random-I/O range and returns 06. Source: Interface Guide; Investigation 013.

334. **NOT GUARANTEED - DMA after failed random read.** Nonzero Function 33 does not establish valid new DMA data. Source: Interface Guide; Investigation 013.

335. **REQUIRED - Function 34 convention.** Write Random uses C=22h and DE=activated FCB. Source: Interface Guide; Investigation 013.

336. **REQUIRED - Random write transfer.** Successful Function 34 writes exactly one 128-byte record from current DMA. Source: Interface Guide; Investigation 013.

337. **REQUIRED - Random write success.** Function 34 returns 00 on success. Source: Interface Guide; Investigation 013.

338. **REQUIRED - Random write allocation.** Function 34 allocates missing data blocks and extents where space permits. Source: Interface Guide; Investigation 013.

339. **REQUIRED - Random write holes.** Function 34 may create a virtual file with unwritten records before the selected record. Source: Interface Guide; Investigation 013.

340. **REQUIRED - Random write virtual length.** Writing record N beyond EOF makes virtual size at least N+1 records after required Close. Source: Interface Guide; Investigation 013.

341. **REQUIRED - Random write working fields.** Function 34 sets EX/S2/CR/RC working state corresponding to the addressed record. Source: Interface Guide; Investigation 013.

342. **REQUIRED - Random write no advance.** Function 34 leaves r0-r2 unchanged. Source: Interface Guide; Investigation 013.

343. **REQUIRED - No automatic random extent switch.** Writing the last record of an extent in random mode does not advance to the next extent. Source: Interface Guide; Investigation 013.

344. **REQUIRED - Random write Close.** Random writes require Close to persist final directory metadata. Source: Interface Guide; Investigations 011/013.

345. **REQUIRED - Random write extent failure.** Function 34 returns 05 when a required new extent cannot be created because the directory overflows. Source: Interface Guide; Investigation 013.

346. **POLICY PENDING - Allocation-full exact code.** DRI returns 02 when random write cannot allocate a block; determine whether BetterCP/M promises this exact code beyond the manual table commentary. Source: DRI source/experiment; Investigation 013.

347. **REQUIRED - Function 35 convention.** Compute File Size uses C=23h and DE=an unambiguous filename FCB. Source: Interface Guide; Investigation 013.

348. **REQUIRED - Function 35 result location.** Function 35 writes virtual size into r0-r2. Source: Interface Guide; Investigation 013.

349. **REQUIRED - Function 35 unit.** Returned size is a count of 128-byte records/address following EOF, not bytes or extents. Source: Interface Guide; Investigation 013.

350. **REQUIRED - Function 35 maximum.** Size 65536 is represented as r0=0,r1=0,r2=1. Source: Interface Guide; Investigation 013.

351. **REQUIRED - Sparse virtual size.** Function 35 reports highest written record plus one even when intervening records are unallocated. Source: Interface Guide; Investigation 013.

352. **NOT GUARANTEED - Function 35 A value.** Function 35 specifies its result only in r0-r2; exact A is not guaranteed. Source: Interface Guide; Investigation 013.

353. **NOT REQUIRED - DRI random seek machinery.** BetterCP/M need not reproduce DRI's module packing, close/open order, allocation search, or private flags. Source: DRI source; Investigation 013.

354. **POLICY PENDING - Physical random-I/O errors.** BIOS/media error presentation beyond documented random return codes remains a broader policy question. Source: Interface Guide/DRI source; Investigation 013.

355. **NOT REQUIRED - Physical allocation equals virtual size.** Sparse virtual size need not imply physical allocation for every preceding record. Source: Interface Guide; Investigation 013.

## 9. Unresolved policy questions

1. Guarantee DRI's exact 02 allocation-full code or only documented nonzero failure?
2. How should BIOS/media failures coexist with random-access codes 01/03/04/05/06?
3. Should BetterCP/M offer optional hole reads as zero-filled extensions while strict mode returns missing-data codes?

## 10. Recommended future investigations

1. Function 40 zero-fill random write and its allocation semantics.
2. Read-only disk/file and physical error handling for random I/O.
3. Corrupt/multiply represented extents and Function 35 resolution.
4. CCP/tool dependencies on exact random-access return codes.

## 11. Completion audit

- Required report/probe artifacts, raw transcript, reset script, and preserved images exist.
- RAND013.COM rebuilds byte-identically and SHA-256 is recorded.
- A/B image mutations are expected; preserved pre-run images are unchanged.
- Compatibility Ledger hash is unchanged; no pre-existing BetterCP/M file was modified.
- Proposed entries 317-355, principal findings, policy questions, and future investigations are present.
- No ZIP archive was created.
