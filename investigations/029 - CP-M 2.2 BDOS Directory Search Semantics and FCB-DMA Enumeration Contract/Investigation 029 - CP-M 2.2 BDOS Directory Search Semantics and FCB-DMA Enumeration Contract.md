# Investigation 029 - CP/M 2.2 BDOS Directory Search Semantics and FCB/DMA Enumeration Contract

Date: 16 August 2026  
Status: complete evidence report; no Compatibility Ledger or prior BetterCP/M file modified

Evidence classes used below are A (documented), B (DRI implementation), I (experiment), and D (unresolved policy).

## 1. Objective and scope

This investigation defines the application-visible CP/M 2.2 contract for BDOS Function 17 (Search First), Function 18 (Search Next), FCB matching, returned directory records, DMA placement, continuation, users, and drives. Allocation, file mutation, random access, CP/M 3, and host-filesystem enumeration are excluded.

## 2. Relationship to previous investigations

I008 supplies FCB layout and drive interpretation; I009 supplies the foundational search/DMA contract; I017 supplies the disk parameter and logical-directory context; I021/I023/I028 supply CCP parsing, default FCB, and transient-handoff boundaries; I025 supplies returned-versus-fatal failure distinctions; I026 supplies current drive/user state; I027 supplies the BDOS ABI. I029 repeats foundational cases only to cross-check them while concentrating on enumeration, multiple extents, case handling, and state lifetime.

## 3. Documentation findings

The Interface Guide documents C=11h, DE=FCB for Search First and C=12h for Search Next. Success returns A=0..3, places a complete 128-byte directory record at current DMA, and identifies the matching 32-byte entry at `DMA + 32*A`; FFh means no match/no further match. Question marks wildcard FCB filename/type positions. Ordinary drive byte 0 means current drive and 1..16 means A:..P:. The special `dr='?'` scan uses the current drive and admits all user numbers. Function 26 (C=1Ah, DE=new DMA) changes the transfer address.

The manuals define the directory-entry form but do not promise alphabetic ordering, lowercase folding by BDOS, continuation after drive/user/media mutation, valid DMA contents after FFh, or a portable return from invalid/unavailable-drive failures. The Alteration Guide preserves the BDOS/BIOS boundary and disk-parameter model; it does not replace the Function 17/18 interface.

## 4. BDOS source findings

The February 1980 DRI `OS3BDOS.ASM` implementation saves one `searcha` FCB address and one `searchl`, initializes directory position in `search`, and reuses them in `searchn`. Matching is bytewise, with `?` accepted at a compared position and special masking for documented user/extent/attribute fields. It scans directory positions forward, derives the low two entry-index bits for A, reads into private `buffa`, and `dir$to$user` copies 128 bytes to `dmaad`. A new Search First replaces the one private continuation context. Search Next reloads the saved FCB pointer; exact private variables and copy sequence are B and NOT REQUIRED.

DRI also calls `dir$to$user` on the FFh path. Because documentation defines result data only on success, that residual transfer is not a valid result contract. Invalid-drive selection reaches the normal DRI disk-error presentation path rather than a documented Function 17 return code.

## 5. Search First semantics

The caller supplies a readable FCB whose drive/name/type fields define the search. Search First begins at the directory start and replaces any earlier sequence. A successful call returns the matching slot 0..3 and a genuine four-entry directory record at current DMA. Exact `ALPHA.TXT`, filename wildcard, type wildcard, drive-default, explicit-drive, and all-user cases succeeded. Ordinary searches selected only the current user. The special `dr='?'` case returned entries from users 0 and 1 on the current drive.

## 6. Search Next semantics

Search Next supplies no new documented FCB argument. It continues after the last match using BDOS-maintained state and returns the same slot/DMA tuple until FFh. Tests showed continuation across Function 25, Function 12, and Function 26; the latter redirected the next record to the new DMA. A subsequent Search First replaced the earlier sequence. Continuation after a default-drive or user change, termination, warm boot, media change, or directory mutation is not a portable interface. A new transient must establish a new search with Function 17.

The DRI saved pointer means modifying or invalidating the original FCB storage can affect later Search Next calls. Applications therefore must keep the search FCB and its relevant contents valid and stable for the sequence; exact private copying versus referencing is not guaranteed.

## 7. Matching rules

The 8-byte name and 3-byte type are fixed-width FCB fields. `?` matches the corresponding compared character. The accepted probe separately confirmed exact matching, name-field wildcarding, and type-field wildcarding. A lowercase `alpha.txt` FCB did not match uppercase directory bytes: CCP normally canonicalizes command FCBs, but BDOS does not promise ASCII case folding for an application-built FCB.

Enumeration is of matching directory entries, not a deduplicated modern filename list. `BIGMULTI.DAT` occupied extent 0 and extent 1 and was returned twice, in successive calls, with distinct extent/record/allocation fields. Empty/deleted entries do not match ordinary searches. The documented special `dr='?'` complete-directory scan admits allocated and free directory values regardless of user; the accepted USER29 run demonstrated cross-user entries but did not continue far enough to claim a separate experimental observation of an E5h slot.

## 8. DMA format

On success DMA contains exactly one 128-byte logical directory record: four consecutive 32-byte entries. A is a slot index, not a byte offset or global ordinal. Each selected entry retains its user byte, name/type (including attribute high bits), EX/S1/S2/RC, and allocation map. Neighboring entries are real compatibility-visible directory bytes even when they did not match. `DMA29` captured all 128 bytes; the preserved dump demonstrates two extents of `BIG.DAT` in adjacent slots.

Function 26 changes only the destination address. It does not restart enumeration. Contents at the old DMA are not implicitly recopied or cleared. After FFh, DMA must be treated as unspecified and the previous successful entry must not be reinterpreted as a new match.

## 9. Failure behavior

No match on Search First and exhaustion on Search Next both returned FFh. The probe deliberately initialized its result snapshot to zero and did not treat failure DMA as evidence. An FCB with lowercase identity simply returned FFh. Invalid drive code 17 (`Q:` in DRI's diagnostic mapping) printed `Bdos Err On Q: Select` and did not return to the caller before the harness supplied Control-C; therefore no portable A/register result is claimed. Unavailable-media behavior was not separately induced and remains covered only by the established BDOS disk-error boundary, not by an invented search result code.

## 10. Experimental results

The deterministic fixture contained controlled files on two drives and users, plus a 16,640-byte `BIGMULTI.DAT` with two directory extents. Six assembled probes ran under z80pack cpmsim Release 1.39 without typed timing dependencies.

| Probe | Accepted observations |
|---|---|
| SEARCH29 | Exact success/FFh, four wildcard matches, repeatable restart, alternate DMA, explicit B:, current-drive change, and all-user scan. |
| MATCH29 | Exact/name-`?`/type-`?` succeeded; lowercase failed; two `BIGMULTI.DAT` extents returned separately, then FFh. |
| DMA29 | A=0 and a complete 128-byte record; selected entry at offset 0 and all neighboring entries preserved. |
| STATE29 | Next survived Functions 25 and 12; Next survived DMA relocation; new Search First replaced the old sequence. |
| USER29 | User 0 did not see user-1-only `UONE.TXT`; user 1 did; `dr='?'` traversed entries from multiple users. |
| ERROR29 | Missing First and following Next returned FFh; invalid drive entered fatal DRI Select diagnostic and did not normally return. |

Directory order was stable across restored identical fixtures and followed directory scan position, not a promised alphabetic sort. Controlled disks were read-only during search except for emulator bookkeeping absent here; before/after hashes remained identical.

## 11. Compatibility conclusions

REQUIRED: Function 17/18 call conventions; 0..3/FFh results; complete successful 128-byte record at current DMA; selected slot formula; fixed-width FCB and `?` matching; current/explicit drive and user filtering; the documented `dr='?'` complete-directory mode; forward continuation; separate entries for matching extents; Function 26 redirection without restart.

NOT GUARANTEED: alphabetical or cross-image order; BDOS lowercase folding; useful DMA after FFh; continuation after changing drive/user/media/directory state, termination, or warm boot; a normal return for BIOS/media/invalid-drive fatal paths; exact neighboring contents beyond the actual directory record.

NOT REQUIRED: DRI private buffer, `searcha`, `searchl`, scan/copy instruction order, or internal directory representation.

POLICY PENDING: whether BetterCP/M should deliberately preserve a continuation across additional harmless BDOS queries beyond tested/documented cases, and what operator UI should present for invalid/unavailable drives. These choices must not weaken the required result interface.

## 12. Proposed Compatibility Ledger additions

Foundational propositions already exist as entries 0188-0218 from I009. The following are independently testable additions beginning at 0542.

0542. Enumeration returns directory entries, not unique filenames

    A Search First/Search Next sequence returns every matching directory entry; BDOS does not deduplicate entries having the same 8.3 identity.

    Disposition: REQUIRED

    Evidence: I029; BDOS; IG; I009.

    Conformance: Search a controlled multi-extent file and observe each matching extent entry.

0543. Matching extents remain separately visible

    Multiple matching extents of one file are returned on separate successful calls with their own EX/S2, RC, and allocation fields.

    Disposition: REQUIRED

    Evidence: I029; BDOS; IG; I017.

    Conformance: Enumerate a file exceeding one extent and compare returned 32-byte entries.

0544. Application-built FCB case is not folded

    BDOS directory matching does not guarantee lowercase-to-uppercase canonicalization; applications requiring ordinary CP/M names supply canonical uppercase FCB bytes.

    Disposition: NOT GUARANTEED

    Evidence: I029; BDOS; IG; CCP; I023.

    Conformance: Compare uppercase and lowercase application-built FCB searches against one uppercase directory entry.

0545. Search FCB lifetime

    The FCB storage and relevant search fields used for Search First remain valid and unchanged until the corresponding Search Next sequence is complete.

    Disposition: REQUIRED

    Evidence: I029; BDOS; IG.

    Conformance: Use stable FCB storage for a multi-result sequence; separately diagnose mutation as nonportable.

0546. Harmless state-query calls need not end enumeration

    Calls that only return version or current-drive state do not, by themselves, terminate an active DRI-compatible Search Next sequence.

    Disposition: REQUIRED

    Evidence: I029; BDOS; IG; I026.

    Conformance: Interpose Functions 12 and 25 between successful First and Next calls.

0547. Search context does not survive program lifecycle reset

    A transient may not rely on Search Next state surviving termination, warm boot, disk-system reset, or entry into a later transient.

    Disposition: NOT GUARANTEED

    Evidence: I029; BDOS; CCP; I024; I026; I028.

    Conformance: Require each new lifecycle to begin enumeration with Search First.

0548. Physical enumeration order is not a sort contract

    Repeated searches of unchanged directory state preserve scan order, but applications may not require alphabetical order or identical order on independently constructed disks.

    Disposition: NOT GUARANTEED

    Evidence: I029; BDOS; IG; I009.

    Conformance: Accept directory-order results and reject tests that require alphabetical sorting.

0549. Invalid-drive search need not return a result code

    A directory search that encounters invalid or unavailable drive/media state may enter the CP/M disk-error presentation path instead of returning a Function 17/18 status.

    Disposition: NOT GUARANTEED

    Evidence: I029; BDOS; IG; I025.

    Conformance: Test returned no-match separately from a controlled invalid-drive fatal path.

0550. Special drive-question search exposes complete directory values

    With FCB `dr='?'`, Search First disables automatic drive selection and scans the current drive without ordinary user filtering, including allocated and free directory values as documented.

    Disposition: REQUIRED

    Evidence: I029; BDOS; IG; I009.

    Conformance: Continue a controlled `dr='?'` scan across user bytes and an E5h free directory slot.

## 13. Proposed existing-entry updates

- 0188-0207: add I029 evidence for the Function 17/18 ABI, restart, wildcard, explicit/default drive, all-user, success, exhaustion, record, and slot contracts; no disposition change.
- 0210: add I029 evidence that Function 26 redirects the next transfer without restarting enumeration.
- 0211-0213: add I029 controlled-order evidence; retain the distinction between scan order and non-guaranteed alphabetic/cross-image order.
- 0214-0217: add I029 failure/state evidence without promoting default-drive mutation or FFh DMA residue.
- 0290-0315 and 0513-0525: add I029 only where current drive/user, DMA, and lifecycle state are referenced; no semantic correction proposed.
- 0534-0541: add I029 evidence to the transient lifecycle boundary; no reclassification proposed.

No existing entry requires correction. Proposed 0546 deliberately concerns harmless query calls and does not make a general interleaving guarantee.

## 14. Open questions

1. Which additional non-directory BDOS calls must preserve an active sequence in software practice?
2. What exact portable rule, if any, should cover mutation or media replacement during enumeration?
3. Should BetterCP/M emulate DRI's FFh-path DMA copy for diagnostic fidelity while keeping it outside conformance?
4. A separate controlled run should carry `dr='?'` through an E5h slot to supplement the documentary/source evidence experimentally.
5. Should invalid drive selection use DRI text and retry/Control-C interaction or a different policy-compatible presentation?
6. Public-file fallback is not a CP/M 2.2 directory-search feature; no such fallback was inferred.

## 15. Artifact preservation audit

- New Investigation 029 tree only: yes.
- Six required ASM, COM, and listing artifacts: present.
- Automated harnesses, transcripts, fixture scripts, images, listings, DMA/memory dumps, and build instructions: present.
- All six COM files rebuilt byte-identically: verified by `rebuild-sha256.txt`.
- Restored fixture reproducibility and image hashes: recorded in `image-sha256.txt`.
- Authoritative ledger SHA-256 before and after: `87b05c75b33282be5f5242b824c740a0dbbba9030d3b1c680109f66ea29cff28`.
- Previous investigations/protected files modified: no; pre/post protected-tree manifests match.
- The required title contains `FCB/DMA`; the filesystem directory/file uses `FCB-DMA` because `/` is a path separator.
- No ZIP archive created.

## 16. Sources

1. Digital Research, *CP/M 2.0 Interface Guide*, printed pp. 5-7, 17, and 21 (PDF pp. 11-13, 23, 27), SHA-256 `e10f525fcf399897fa86703eb930e21ba59fa54c0708c1cf5909e92beaf7a279`.
2. Digital Research, *CP/M 2.2 Alteration Guide* (1979), interface/directory/BIOS boundary, SHA-256 `98a176be191c68207b5859371cf3d95eb90f517a72bdeb3b3699833e7c368891`.
3. Digital Research, *An Introduction to CP/M Features and Facilities*, directory/FCB background.
4. Digital Research, `OS3BDOS.ASM`, “Bdos, Version 2.2 Feb, 1980,” search, matching, `dir$to$user`, dispatch, and DMA paths, SHA-256 `a22b7dd0f8adaa8dd9affe2cbb0f5749ddf278bf36ca9f94e38f9acf335a44d8`.
5. I008, I009, I017, I021, I023, I025-I028 reports and preserved artifacts.
6. z80pack `cpmsim` Release 1.39 with Z80 CBIOS V1.2; emulator and fixture identities are preserved under `probes/`.
