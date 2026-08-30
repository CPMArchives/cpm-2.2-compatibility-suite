# Investigation 010 - CP/M 2.2 BDOS Sequential Read Semantics

Date: 14 August 2026  
Status: evidence report only; no Compatibility Ledger, prior investigation, architecture, roadmap, or BetterCP/M implementation modified

## 1. Investigation question and scope

This investigation defines BDOS function 20 (Read Sequential): its C/DE convention, activated-FCB precondition, current-record state, 128-byte DMA transfer, return convention, end-of-file behavior, automatic extent transition, explicit-drive behavior, and observable FCB mutation.

Function 15 is used only to establish the read lifecycle and function 26 only to select DMA. Random I/O, write/make/delete/rename, allocation policy, and the general BIOS protocol remain out of scope.

Evidence classes are **A** documented CP/M 2.2 requirement, **B** DRI implementation behavior, **C** possible de facto dependency, **I** incidental behavior, and **D** unresolved policy.

## 2. Why this matters to BetterCP/M

Sequential reading is stateful. A successful call must deliver the correct 128-byte logical record and transform the caller's FCB into the position for the next call. At an extent boundary, this includes finding and activating the next directory extent without an application reopen. Compatibility therefore requires more than copying bytes: return status, DMA selection, FCB mutation, drive selection, and EOF must agree.

## 3. Relationship to existing findings

The current ledger incorporates Investigations 001-009 and runs through entry 218. This report relies on its BDOS ABI, drive, DMA, and FCB/open requirements, especially the function-selector/input/result convention, current versus explicit FCB drive rules, the 36-byte FCB layout, and Function-15 activation. It neither edits nor restates those entries wholesale. Proposed additions begin at 219.

## 4. Sources examined

### 4.1 Digital Research documentation

1. Digital Research, *CP/M 2.0 Interface Guide*, copyright 1979, `<reference-archive>/CPM_2_0_Interface_Guide.pdf`, SHA-256 `e10f525fcf399897fa86703eb930e21ba59fa54c0708c1cf5909e92beaf7a279`: FCB form at printed pp. 5-7 / PDF pp. 11-13; Function 20 at printed p. 18 / PDF p. 24; Function 26 at printed p. 21 / PDF p. 27.
2. Digital Research, *CP/M 2.2 Alteration Guide*, copyright 1979, `<reference-archive>/CPM_2.2_Alteration_Guide_1979.pdf`, SHA-256 `98a176be191c68207b5859371cf3d95eb90f517a72bdeb3b3699833e7c368891`: incorporated interface and disk/BIOS separation.

The relevant scans were rendered and visually inspected. As in preceding investigations, the 2.0 interface text is applicable because the identified CP/M 2.2 source and reference system implement it.

### 4.2 Original DRI source and callers

3. `<reference-archive>/cpm2-plm/OS3BDOS.ASM`, “Bdos Interface, Bdos, Version 2.2 Feb, 1980,” SHA-256 `a22b7dd0f8adaa8dd9affe2cbb0f5749ddf278bf36ca9f94e38f9acf335a44d8`: `seqdiskread`, `diskread`, `open$reel`, `setfcb`, automatic drive reselection, and function dispatch.
4. DRI callers including DUMP, AS1IO, and SYSGEN were inspected. They initialize CR for sequential traversal and treat a nonzero Function-20 result as termination rather than decoding multiple portable error codes.

### 4.3 Reference environment

- z80pack commit `91fd28eb04e675c2127df88ed3f40675e15282e2`;
- `cpmsim` Release 1.39 in Z80 mode, executable SHA-256 `30374c2df2f44118d2b36a8bfef651a9f2d0ee9b9ddd0039c044b9f06df4708d`;
- byte-identified DRI CP/M 2.2 CCP+BDOS and z80pack Z80 CBIOS V1.2;
- disposable controlled A/B images, unchanged by the accepted run;
- cpmtools used only for deterministic preparation and inspection.

## 5. Documented contract

**A:** Function 20 is selected with C=14h. DE addresses an FCB previously activated by Open (15) or Make (22).

**A:** BDOS reads the next 128-byte record into the current DMA address. The record is selected by the FCB current-record field `cr`; successful access automatically increments that position.

**A:** A=00h reports success. A nonzero result reports that no data exists at the next sequential position, ordinarily end of file. The interface does not specify a portable family of richer read-error result codes.

**A:** When `cr` overflows, BDOS automatically opens the next logical extent and resets `cr` to zero in preparation for the next read. Because that read then succeeds and increments the position, the returned FCB describes the new extent with CR=1.

**A:** Function 26 controls the DMA address used by the read. A successful read supplies one complete CP/M logical record; Function 20 has no byte-count result for a partially occupied host representation.

The FCB is working state, not an immutable filename argument. Its `ex`, `s1`, `s2`, `rc`, allocation map, and `cr` include fields BDOS may use or replace during traversal.

## 6. DRI implementation analysis

`seqdiskread` marks sequential mode and enters the common disk-read path. That path takes `cr` as the virtual record and compares it with `rc`. If `cr < rc`, it maps and reads one physical/logical record to `dmaad`, then `setfcb` advances the FCB.

If `cr == rc` below 128, DRI returns 1 without a disk transfer. If `cr == 128`, `open$reel` seeks the next extent. On success it copies that extent's directory state into the caller FCB, reads its record zero, and leaves CR=1. On failure it returns 1.

A zero allocation entry for a purported record also returns 1. Physical BIOS failures use the BDOS disk-error/retry/warm-start path rather than a documented additional Function-20 status.

The DRI `open$reel` failure path has an observable corner case: after an exactly full 128-record last extent, a failed read increments EX while leaving CR=80h; repeated failed reads repeat the EX change. This is **B/I**, conflicts with treating the post-EOF FCB representation as stable, and is not necessary to implement the documented sequential-read abstraction.

## 7. Deterministic probe

`probes/READ010.ASM` is a noninteractive COM probe. It opens controlled files with Function 15, fills DMA with EEh, invokes Function 20, and prints the open result, read result, current drive, byte 0080h, all 33 sequential FCB bytes, and all 128 bytes at the active DMA address.

The fixtures cover zero, one, three, 200-host-byte/two-record, exactly 128-record, and 130-record files; alternate DMA; explicit B drive; read-only attribute; repeated EOF; unopened FCB; and invalid allocation state. `observed-output.txt` specifies the images, hashes, and decoded results. `observed-raw.txt` preserves the terminal transcript, while `capture.exp` records the automated invocation.

The accepted image hashes were unchanged before and after execution. Thus the read probe caused no disk mutation.

## 8. Experimental results

### 8.1 Ordinary success, DMA, and CR

One- and three-record files returned 00h for every available record. DMA received the expected A and M/N/O marker records; CR advanced from 0 to 1, 2, and 3. The 200-byte host fixture occupied two CP/M records: both reads returned full 128-byte DMA records and CR reached 2. Function 20 conveyed no original host byte length.

### 8.2 EOF forms and repetition

The empty file returned 01h immediately and again on repetition. One-record, three-record, and partial-final-record files returned 01h on the first read beyond RC and again thereafter. Their EEh-filled DMA was untouched and their captured FCB state remained at the next position.

An exactly 128-record file returned record 128 successfully with CR=80h, then returned 01h. Its subsequent EX drift reproduced the DRI source behavior described above. The portable fact is the nonzero read result; neither usable DMA data nor an exact post-failure FCB image follows from it.

### 8.3 Extent transition

For the 130-record file, record 128 succeeded at EX=0/CR=80h. The next call succeeded without a new Function 15, returned record 129, and left EX=1, RC=2, CR=1 with the second extent's allocation map. Record 130 then succeeded with CR=2; the following call returned 01h.

### 8.4 Alternate DMA and drives

After Function 26 selected an alternate buffer, the record appeared there and the sentinel at 0080h remained unchanged. An explicit-drive FCB (`dr=2`) opened and read B:BFILE.DAT while Function 25 still reported A as the default drive. This confirms temporary automatic drive selection, not a default-drive change.

### 8.5 Read-only, unopened, and invalid FCBs

The read-only file opened and read normally; read-only status restricts mutation, not reading.

The synthetic unopened FCB and an inconsistent FCB with RC=1 but a zero allocation map each returned 01h in DRI and left DMA untouched. These inputs violate the documented activated-FCB precondition. Their apparent conflation with EOF is implementation behavior, not a compatibility interface applications may rely upon.

## 9. Answers to the required questions

1. **Convention:** C=14h, DE=address of an activated FCB; result in A under the established BDOS convention.
2. **Success:** A=00h; one 128-byte record is delivered and the sequential position advances.
3. **DMA:** the complete logical record is written at the current Function-26 DMA address.
4. **Current record:** CR advances after each success; before transition it can reach 80h.
5. **Extents:** a following extent is automatically found/opened; its record zero is read and the returned CR is 1.
6. **File shapes:** empty files immediately return nonzero; partial final extents stop at RC; multi-extent files cross automatically; exact-boundary files return their last record successfully and report EOF on the next call.
7. **Returns:** zero means success and nonzero means no data/EOF. DRI normally returns 01h. Additional portable error-result meanings are not established.
8. **Special cases:** unopened/invalid behavior is not guaranteed; read-only files can be read; changed DMA is honored.
9. **FCB mutation:** yes—at least CR changes on success, and extent transition replaces extent-related working fields. Failed-read mutation must not be inferred from ordinary cases.
10. **BetterCP/M:** implement the documented activated-FCB, 128-byte DMA, zero/nonzero, position, automatic-extent, drive, and read-only rules; do not expose internal DRI mechanisms as requirements.

## 10. Compatibility conclusions

The compatibility boundary is transaction-like: only a zero result validates the new 128-byte DMA record and the successful next-position state. EOF is a nonzero result, not a partial successful record. Callers should not consume DMA after failure or construct an unopened FCB and expect DRI's observed 01h shortcut.

BetterCP/M may organize files and extents differently internally. It must nevertheless update the public FCB coherently after every successful record and automatically bridge logical extents. It need not reproduce DRI's exact-boundary EX drift, private S2 flags, allocation walk, buffer addresses, or error-handler internals.

## 11. Proposed Compatibility Ledger additions

The following are proposals only. The ledger was not modified.

219. **REQUIRED — Function 20 call convention.** With C=14h, DE shall address the FCB used for Read Sequential. Source: CP/M 2.0 Interface Guide Function 20; Investigation 010. Conformance: invoke with a known activated FCB and verify that this object controls the read.

220. **REQUIRED — Activated-FCB precondition.** A Function-20 FCB shall have been successfully activated by Open or Make. Source: Interface Guide; Investigation 010. Conformance: use Function 15 before the ordinary read sequence.

221. **REQUIRED — Sequential position source.** Function 20 shall select the next record from the caller FCB's current extent/current-record state. Source: Interface Guide; DRI source; Investigation 010. Conformance: set up a known open FCB and compare successive markers.

222. **REQUIRED — Successful result.** Function 20 shall return A=00h when it reads the requested sequential record. Source: Interface Guide; Investigation 010. Conformance: read an allocated record.

223. **REQUIRED — Successful transfer size.** A successful Function 20 shall transfer exactly one 128-byte logical record. Source: Interface Guide; Investigation 010. Conformance: guard and inspect the complete DMA area.

224. **REQUIRED — Current DMA destination.** A successful Function 20 shall place the record at the current DMA address, including an address selected by Function 26. Source: Interface Guide Functions 20/26; Investigation 010. Conformance: move DMA and protect 0080h with a sentinel.

225. **NOT GUARANTEED — Partial-byte count.** Function 20 does not return the number of meaningful host bytes in its 128-byte record. Source: CP/M record model; Investigation 010. Conformance: programs shall derive any byte-level length from file-format content, not Function 20.

226. **REQUIRED — Advance after success.** After a successful Function 20, the public FCB shall identify the next sequential record. Source: Interface Guide; Investigation 010. Conformance: inspect CR and read distinct consecutive markers.

227. **REQUIRED — CR progression within an extent.** Successful reads within one extent shall increment CR once per record. Source: Interface Guide; DRI source; Investigation 010. Conformance: observe CR=1,2,3 after three reads from CR=0.

228. **REQUIRED — Full-extent position.** After successfully reading record 128 of an extent, CR may represent the overflow position 80h pending the next sequential call. Source: Interface Guide; DRI source; Investigation 010. Conformance: inspect the FCB after the 128th read.

229. **REQUIRED — Automatic extent transition.** If a next logical extent exists when CR overflows, Function 20 shall activate it automatically without requiring another application Open. Source: Interface Guide; Investigation 010. Conformance: read records 128 and 129 in consecutive calls.

230. **REQUIRED — New-extent first-record state.** After successfully reading record zero of an automatically opened next extent, the returned FCB shall represent that extent with CR=1. Source: Interface Guide; Investigation 010. Conformance: inspect EX and CR after record 129.

231. **REQUIRED — Extent working-state replacement.** Automatic extent transition shall update the caller FCB's extent-related public working fields sufficiently for continued sequential access. Source: FCB contract; DRI source; Investigation 010. Conformance: verify EX, RC/allocation state, and continued reading.

232. **REQUIRED — EOF/no-data result.** Function 20 shall return a nonzero A when no data exists at the next sequential position. Source: Interface Guide; Investigation 010. Conformance: read once beyond a controlled file.

233. **POLICY PENDING — Exact EOF code.** DRI CP/M 2.2 returns 01h for ordinary sequential EOF, but the documented contract requires only nonzero. Source: Interface Guide; DRI source; Investigation 010. Conformance: decide whether BetterCP/M promises exact 01h or only the documented nonzero predicate.

234. **REQUIRED — Empty-file behavior.** Reading an activated empty file shall return nonzero before any successful record. Source: Interface Guide; Investigation 010. Conformance: open and read a zero-record file.

235. **REQUIRED — Partial-final-extent EOF.** When CR reaches RC in a partially occupied final extent, the next Function 20 shall return nonzero. Source: DRI source implementing documented EOF; Investigation 010. Conformance: exhaust a two-record final extent.

236. **REQUIRED — Exact-boundary EOF.** A file ending at record 128 shall return that record successfully and return nonzero on the following Function 20. Source: Interface Guide extent rule; Investigation 010. Conformance: exhaust an exact 128-record file.

237. **REQUIRED — Repeated EOF indication.** Repeating Function 20 without restoring a valid earlier position or extending the file shall continue to report no data rather than fabricate a successful record. Source: sequential abstraction; DRI behavior; Investigation 010. Conformance: issue two reads beyond EOF.

238. **NOT GUARANTEED — DMA contents after failure.** A nonzero Function-20 result does not make the DMA buffer a valid new file record; its exact post-call contents are not guaranteed. Source: Interface Guide success condition; Investigation 010. Conformance: applications shall inspect DMA only after zero.

239. **REQUIRED — FCB mutation.** Function 20 may and on success shall modify sequential working fields in the caller's FCB. Source: Interface Guide; Investigation 010. Conformance: compare the 33 working bytes before and after reads.

240. **NOT GUARANTEED — Exact FCB image after failed read.** Beyond preserving a valid API-level failure result, the exact FCB byte image after a nonzero Function 20 is not guaranteed by the interface. Source: DRI exact-boundary behavior; Investigation 010. Conformance: applications shall not require byte-for-byte FCB stability after failure.

241. **NOT REQUIRED — DRI exact-boundary EX drift.** BetterCP/M need not reproduce DRI's increment of EX on each failed read beyond an exactly full last extent. Source: DRI source and experiment; Investigation 010. Conformance: accept any coherent post-EOF working representation.

242. **REQUIRED — Explicit-drive read.** Function 20 shall honor a valid explicit drive in an activated FCB and shall not change the caller's default drive merely to perform the read. Source: FCB automatic selection contract; Investigation 010. Conformance: read a B-drive FCB while A remains default.

243. **REQUIRED — Read-only readability.** A file's read-only attribute shall not by itself prevent successful Function-20 reads. Source: attribute semantics; Investigation 010. Conformance: open and read a read-only file.

244. **NOT GUARANTEED — Unopened-FCB result.** Function 20 behavior for an FCB not activated by successful Open or Make is outside the interface contract; DRI's observed 01h is not guaranteed. Source: Interface Guide precondition; Investigation 010. Conformance: compatible applications shall not depend on such a call.

245. **NOT GUARANTEED — Invalid-FCB result.** Function 20 behavior for internally inconsistent extent, record-count, or allocation state is outside the interface contract. Source: FCB contract; DRI source; Investigation 010. Conformance: compatible applications shall not synthesize activated working fields.

246. **POLICY PENDING — Physical read-error presentation.** The portable Function-20 interface does not establish additional application-visible codes for BIOS/media read failures; DRI routes them through its disk-error handling. Source: Interface Guide; DRI source; Investigation 010. Conformance: BetterCP/M must choose and document an error policy without redefining zero as failure or nonzero as success.

247. **NOT REQUIRED — DRI internal read machinery.** BetterCP/M need not reproduce DRI's private sequential flag, `open$reel`, allocation-vector walk, private buffers, or S2 bookkeeping, provided public Function-20 behavior conforms. Source: DRI source; Investigation 010. Conformance: test observable results and FCB state, not internal addresses or routines.

## 12. Unresolved policy questions

1. Should BetterCP/M deliberately promise DRI's exact EOF value 01h, exceeding the manual's nonzero contract?
2. How should BetterCP/M surface unrecoverable BIOS/media errors while retaining CP/M-compatible ordinary Function-20 returns and warm-start behavior?
3. Should BetterCP/M offer a stronger stable-FCB-after-EOF extension, while keeping software from depending on it as baseline CP/M behavior?

## 13. Engineering implications

The implementation should validate an internal open handle/state corresponding to the public FCB, calculate a logical 128-byte position, transfer only on success, and commit the next public position coherently. Extent crossing should be atomic from the application's perspective: either the next record succeeds with new-extent state or the call reports nonzero and exposes no valid new DMA record.

A conformance suite should retain the marker fixtures used here and assert result, all 128 DMA bytes, CR/EX transition, default-drive stability, and behavior on both partial and exact extent boundaries. It should permit nonessential FCB differences after failure and avoid treating DRI's invalid-input shortcuts as requirements.

## 14. Completion audit

- The Investigation 010 directory and required report/probe files exist.
- READ010.COM rebuilds byte-identically from READ010.ASM with the command in README.txt.
- The accepted raw transcript, decoded observations, fixture definitions, and unchanged image hashes are preserved.
- The authoritative compatibility ledger and all existing BetterCP/M files outside the new Investigation 010 directory were not modified.
- Proposed ledger entries 219-247 and all unresolved policy questions are contained only in this report.
- No ZIP archive was created; the investigation remains as a direct loose directory.
