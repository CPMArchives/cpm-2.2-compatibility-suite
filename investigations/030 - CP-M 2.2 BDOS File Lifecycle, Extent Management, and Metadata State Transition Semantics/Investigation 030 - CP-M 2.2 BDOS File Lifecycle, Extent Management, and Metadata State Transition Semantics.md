# Investigation 030 - CP/M 2.2 BDOS File Lifecycle, Extent Management, and Metadata State Transition Semantics

Date: 17 August 2026  
Status: complete evidence report; no Compatibility Ledger or previous BetterCP/M file modified

Evidence classes: A documented interface; B DRI implementation; I controlled observation; D unresolved policy.

## 1. Objective and scope

This report integrates the application-visible lifecycle from Make through writes, extent transitions, Close, Open, and reopened access. It does not redefine individual calls, propose storage architecture, or extend the CP/M 2.2 contract.

## 2. Relationship to previous investigations

I008-I013 establish FCB/Open/Close, search/DMA, sequential read/write, Make, rename/delete, random access, and size. I017 establishes DPB/allocation-vector meaning. I025-I027 establish failures, system state, and ABI. I029 establishes that searches expose individual extent entries. I030 reran the comprehensive I011 and I013 fixtures and relates their states rather than duplicating their per-function ledgers.

## 3. Documentation findings

Make creates and activates an empty FCB. Sequential write consumes one 128-byte DMA record, updates working position/length/allocation, and automatically opens the next extent at a boundary. Random write addresses r0-r2, may create extents and holes, and leaves the random address unchanged. Close permanently records modified FCB information. Open activates an existing identity by reconstructing usable working state from its directory entry. Multi-extent files remain one logical file accessed through automatic sequential transitions or random-record mapping.

The documentation specifies public FCB fields and results but not private dirty flags, allocator order, exact intermediate directory-write timing, literal post-call values of reserved fields, or atomic recovery after physical failure.

## 4. BDOS source findings

DRI `make` reserves an empty directory slot, clears public working fields, and marks private not-yet-written state. `diskwrite` allocates on demand and updates the working FCB. `open$reel` closes/opens physical extents when logical position crosses a boundary. `close` merges working RC/allocation into the directory entry. `rseek` maps r0-r2 into EX/S2/CR and may close the current extent before opening or creating another. These mechanisms explain observations but their variables, buffer sequence, and allocation search order are NOT REQUIRED.

## 5. File creation behavior

Successful Make returned a slot code, EX=0, RC=0, CR=0 and a zero allocation map. Search immediately found the empty entry before Close. No data block was required. Make followed directly by write worked without Open. Make/Close preserved an empty file; Make/write/Close/reopen preserved data. Duplicate and wildcard Make remain outside the documented precondition.

## 6. File growth behavior

Each successful sequential write advanced CR, extended RC when needed, and acquired allocation. A one-record and three-record file reopened with the recorded lengths. At 128 records the full extent was durable and the working FCB was prepared for the next extent; record 129 created extent 1 with RC=1. Random overwrite retained size, append increased it, and a write beyond EOF made virtual size at least record N+1 after Close.

## 7. Extent behavior

In this reference format an extent covers 128 logical records. EX/S2 identify the logical extent/module; CR is the next sequential record and RC records valid records in the working extent. Directory search exposes each matching extent separately. Applications sequentially cross extents without issuing a new Open; random access selects the addressed extent. Exact physical directory placement and allocation order are not interfaces.

## 8. FCB state behavior

After Make, the FCB is activated and empty. Open reconstructs working extent data and uses private high S2 bits internally; applications rely only on documented field meanings. Sequential write changes CR, RC and allocation, and can change EX/S2 at transition. Random I/O changes EX/S2/CR working state but does not increment r0-r2. Close does not promise to restore or canonicalize every incidental byte. Reopen reconstructs usable state from persistent directory metadata rather than preserving the writer's FCB byte-for-byte.

## 9. Directory metadata behavior

Make's zero-record entry is immediately searchable. During writes the activated FCB can lead the directory: before Close, Search still returned RC=0 while the FCB had RC=1 and allocation. Successful Close exposed the new RC/allocation. Full extents can become persistent during automatic transition, but applications must not use intermediate visibility as a commit protocol. I029's enumeration of `BIGMULTI.DAT` confirmed that extent metadata remains separately visible.

## 10. Close File behavior

Close is the application-visible commit operation for the final modified extent. After successful Close, later Open/Read and Compute File Size must see consistent recorded content and length. Omitting Close left the made file visible but zero-length after restart, making the written block unreachable through the file. Exact DRI merge order is not required. A failed Close does not establish persistence and must be handled as failure.

## 11. Open File behavior

Open requires an unambiguous existing FCB identity and returns an activated FCB or FFh. Reopening NEW.DAT reconstructed extent-zero RC/allocation and read marker A. Reopening MULTI and BIG reconstructed the applicable working extent and permitted continued sequential access. Open need not reproduce private S2 flags or the preceding writer's literal allocation scratch state; it must support the documented access represented by persistent directory entries.

## 12. Multi-extent behavior

A logical file may have several directory entries sharing 8.3 identity and differing in extent/module fields. Sequential access treats them as one record stream; random access maps record numbers to them; Compute File Size selects the maximum virtual end; directory Search returns them individually. Closing the final extent and any boundary-triggered commits together make the reopened stream coherent.

## 13. Failure behavior

Directory-full Make returned FFh without creating a file. Allocation-full media still allowed empty Make but the first write returned 02 and left length/allocation zero. With only one directory slot, all 128 records of extent 0 succeeded and remained valid; the later write requiring extent 1 returned 01 and added no record. Random allocation-full write returned 02. The manuals guarantee appropriate nonzero failures but do not make every DRI 01/02 distinction portable. Physical-error presentation remains governed by I015/I025, not inferred here.

## 14. Experimental results

Fresh restored I011 and I013 images were run under z80pack cpmsim 1.39. Seven required named, rebuildable views preserve the audited bodies and identify the lifecycle evidence:

| Probe | Purpose/procedure | Observation and conclusion |
|---|---|---|
| CREATE30 | Make/search/write/Close/reopen | Empty entry preceded allocation; Close made new metadata persistent. |
| GROW30 | 1, 3, 128, 129 records | Working fields and allocation grew; sequential boundary transition was automatic. |
| EXTENT30 | Normal and one-slot boundary | Completed extent survived; failed next extent added no record. |
| FCB30 | Random overwrite/append/sparse/boundary | Documented working and random fields mapped lifecycle state; private bytes are not portable. |
| CLOSE30 | Search before/after Close and omit Close | Final working metadata requires successful Close. |
| OPEN30 | Reopen/read persisted files | Open reconstructed usable state, not byte identity with the writer FCB. |
| FAIL30 | Directory/data/extension exhaustion | Failures were local and distinguishable; exact DRI codes beyond documentation remain policy-sensitive. |

All seven COM files rebuilt byte-identically. Complete transcripts and before/after images are preserved.

## 15. Compatibility conclusions

REQUIRED: activated empty state after Make; on-demand growth; coherent public CR/RC/EX/S2/allocation behavior; automatic sequential extent crossing; separately represented extent metadata; Close persistence; Open reconstruction; coherent reopened content/size; unsuccessful extension adds no claimed record.

NOT GUARANTEED: pre-Close directory currency; unclosed final-extent persistence; literal FCB byte identity after reopen; exact 01/02 failure distinction where documentation says nonzero; recovery from physical errors without successful Close.

NOT REQUIRED: DRI dirty flags, private FCB bits, allocator order, directory-slot choice, buffer addresses, internal extent algorithm, or exact intermediate update timing.

POLICY PENDING: whether BetterCP/M promises DRI's detailed write-failure codes and whether it offers a stronger optional transactional extension outside baseline compatibility.

## 16. Proposed Compatibility Ledger additions

The authoritative I029 ledger ends at 0550. These additions describe lifecycle relationships not already captured by individual-operation entries.

0551. Make-to-open lifecycle equivalence

    A successful Make activates an empty FCB for immediate I/O; after successful Close, a later Open of that identity reconstructs an equivalent usable empty or written file state.

    Disposition: REQUIRED

    Evidence: I030; BDOS; IG; I008; I011.

    Conformance: exercise Make-only, Make/Close, Make/write/Close, and reopen.

0552. Working FCB may lead directory metadata

    During a modified open lifecycle, the activated FCB may contain newer RC and allocation state than directory Search exposes before required Close.

    Disposition: NOT GUARANTEED

    Evidence: I030; BDOS; IG; I011; I029.

    Conformance: compare the working FCB and Search record before Close.

0553. Successful Close establishes reopened consistency

    After successful Close, Open, sequential/random access, directory extent entries, and Compute File Size describe a mutually consistent persistent file.

    Disposition: REQUIRED

    Evidence: I030; BDOS; IG; I008-I013; I029.

    Conformance: close a grown multi-extent file, reopen it, enumerate extents, read boundary markers, and compute size.

0554. Reopen reconstructs behavior, not FCB byte identity

    Open reconstructs a usable working FCB from directory state; applications may not require incidental or private bytes to equal the preceding writer's FCB.

    Disposition: NOT GUARANTEED

    Evidence: I030; BDOS; IG; I008; I027.

    Conformance: compare access and documented fields rather than all literal FCB bytes.

0555. Extents form one logical record stream

    Multiple directory extents sharing a file identity are one logical file for sequential crossing, random addressing, reopening, and file-size computation.

    Disposition: REQUIRED

    Evidence: I030; BDOS; IG; I010; I011; I013; I029.

    Conformance: verify records 127-129 through sequential, random, search, reopen, and size interfaces.

0556. Completed extent survives later extension failure

    Failure to create or allocate a following extent does not invalidate records already successfully written and committed in the completed extent.

    Disposition: REQUIRED

    Evidence: I030; BDOS; IG; I011; I025.

    Conformance: fill extent 0 with no slot for extent 1 and verify its 128 records after the next write fails.

0557. Failed growth does not claim a new record

    A failed sequential or random extension must not make the unsuccessful target record part of the reopened file length.

    Disposition: REQUIRED

    Evidence: I030; BDOS; IG; I011; I013; I025.

    Conformance: exhaust directory or allocation space, attempt extension, then reopen and compute size.

0558. Allocation order is outside lifecycle compatibility

    Compatibility requires sufficient usable allocation reflected in FCB/directory state, not DRI's exact block-search order or directory-slot choice.

    Disposition: NOT REQUIRED

    Evidence: I030; BDOS; AG; I011; I017.

    Conformance: compare content, length, and valid allocation rather than exact block numbers.

## 17. Proposed existing-entry updates

Add I030 evidence without disposition change to FCB/Open/Close entries 0156-0187; Make/write entries 0248-0284; sequential-read entries 0219-0247; random/size entries 0317-0356; allocation entries from I017; I025 failure entries; I026 state entries; and I029 extent-enumeration entries 0542-0550. No correction or reclassification is proposed.

## 18. Open questions

1. Should exact DRI codes 01 (new extent unavailable) and 02 (no data block) become a BetterCP/M promise?
2. What recovery guarantee, if any, applies after physical failure during Close?
3. Should a nonbaseline BetterCP/M API offer stronger transactional durability while leaving CP/M behavior unchanged?
4. Corrupt duplicate/missing extent resolution remains outside this healthy-file lifecycle.

## 19. Conformance implications

A lifecycle conformance suite must inspect working FCB, directory records, allocation vector, content, and size at creation, pre-Close, post-Close, and reopen; test 0/1/127/128/129 records; test sequential and random beyond-EOF growth; separately exhaust directory slots and data blocks; and validate failed extension without requiring DRI allocation order or private bytes.

### Preservation audit

The I029 ledger began and ended SHA-256 `de99ee716dd7338659d8aca01bbfb5bfca539bac3675e79d5359b63241f921d2`. Protected-tree hashes were recorded before creation and verified afterward. Seven ASM/COM/listing sets, fresh transcripts, before/after images, rebuild evidence, source references, and manifests are present. No ZIP archive or BetterCP/M implementation change was made.

### Sources

Digital Research, *CP/M 2.0 Interface Guide*, printed pp. 5-7, 15-19, 25-29 (PDF pp. 11-13, 21-25, 31-35); Digital Research, *CP/M 2.2 Alteration Guide*; DRI `OS3BDOS.ASM` February 1980; I008-I013, I017, I025-I027, I029; z80pack cpmsim 1.39 with DRI CP/M 2.2 and Z80 CBIOS 1.2.
