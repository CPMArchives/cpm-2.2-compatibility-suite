# Investigation 040 - CP/M 2.2 Disk Format, Drive Geometry, and Direct Structure Compatibility Semantics

Status: Complete evidence report; Compatibility Ledger not modified  
Date: 2026-08-18

## 1. Objective and scope

This investigation defines the CP/M 2.2 compatibility boundary created by
disk parameters, logical sectors, directory entries, allocation maps, and
direct BIOS use. It does not design BetterCP/M storage or require a particular
host image. Evidence classes are **A** documented behavior, **B** DRI source
behavior, **I** controlled observation, and **D** unresolved policy.

## 2. Compatibility standard

A behavior is REQUIRED when documented or needed by demonstrated CP/M 2.2
software through the public BDOS/BIOS structures. DRI algorithms and one
machine's raw offsets are not promoted merely because they were observed.
NOT GUARANTEED marks facts software cannot portably assume; NOT REQUIRED marks
replaceable implementation form; POLICY PENDING is reserved for BetterCP/M
profile decisions.

## 3. Relationship to previous investigations

I017 established Functions 27/31 and live ALV/DPB semantics. I019 established
the stateful 128-byte BIOS disk boundary. I029/I030 established visible
directory extents and coherent file lifecycle. I036 established the public
direct-BIOS boundary, and I037 completed ordinary BDOS coverage. I040 adds a
cross-layer disk-format matrix and historical utility evidence without
duplicating those propositions.

## 4. Disk format compatibility boundary

CP/M disk organization is a practical compatibility interface, but not one
universal physical format. BDOS clients see FCBs, 128-byte records, directory
search records, allocation state, and DPB fields. Direct BIOS clients also see
DPH pointers, logical tracks, translated sector identifiers, and system-track
placement. Controller geometry, host-sector size, raw-file offsets, and
deblocking remain below that boundary.

## 5. Documentation findings

**A:** The Alteration Guide defines the DPH as XLT, three scratch words,
DIRBUF, DPB, CSV, and ALV. The 15-byte DPB contains SPT, BSH, BLM, EXM, DSM,
DRM, AL0/AL1, CKS, and OFF. SPT counts 128-byte logical sectors; block size is
`128 << BSH`; DSM bounds allocation-block numbers; DRM bounds 32-byte directory
entries; AL0/AL1 reserve directory blocks; CKS sizes removable-media checking;
OFF reserves leading logical tracks.

The manual explicitly permits different drive definitions, shared DPBs for
identical drives, null or non-null translation tables, nonstandard track
ranges, and blocking/deblocking. It does not define one portable raw image,
controller sector numbering, allocation order, directory slot order, or
recovery algorithm for structurally damaged media.

## 6. Source findings

**B:** DRI BDOS derives directory/data locations from the selected DPB,
reconstructs ALV from reserved bits plus active directory maps, and uses
DIRBUF for directory transfers. Allocation search and scratch state are
private. DRI STAT decodes the public DPB. DRI SYSGEN discovers BIOS entry
addresses from WBOOT and directly performs selected track/sector/DMA reads and
writes. DRI DUMP instead uses geometry-independent BDOS file calls.

## 7. Directory structure assumptions

**A/I:** A directory is a DPB-sized sequence of 32-byte entries packed four per
128-byte logical sector. Active CP/M 2.2 entries carry user, fixed-width 8.3
name/type, EX/S1/S2/RC, and a DPB-dependent allocation map; E5h marks a free
entry. Search exposes the containing logical directory record, so these bytes
are application-visible. Directory sector physical placement depends on OFF
and translation; a raw contiguous-offset assumption is not portable.

## 8. Allocation vector compatibility

**A/I:** AL0/AL1 reserve leading allocation blocks for directory storage. Each
active extent map contributes allocated blocks to the live ALV returned by
Function 27, high bit first. With DSM below 256, entries contain sixteen
one-byte block numbers; larger definitions use eight little-endian words.
The resulting ownership and capacity must be coherent. Exact block choice,
search direction, and ALV address are not guaranteed.

## 9. Disk parameter block compatibility

**A/I:** All public DPB fields affect observable interpretation and therefore
must be self-consistent with the drive actually presented. On the reference
disk DPB040 returned `1A00030700F2003F00C00010000200`, and DRI STAT decoded
the same geometry. Applications may read the DPB; they may not assume those
literal IBM 3740 values on another configured drive.

## 10. Drive geometry assumptions

**A:** BIOS logical geometry is SPT logical sectors per track plus OFF reserved
tracks. SETTRK accepts a logical track, SECTRAN maps a zero-based logical
sector, and SETSEC receives the translation result. A logical track need not
equal a cylinder/head, translated identifiers need not be contiguous, and a
physical sector need not be 128 bytes. The tested IBM profile uses 77 tracks,
26 logical sectors, OFF=2, and skew 6; this profile is not CP/M-wide.

## 11. Direct disk access

**A/B/I:** Direct callers must discover the configured BIOS, select a drive,
obtain/use its DPH/DPB/XLT, establish track/sector/DMA state, and transfer one
logical sector per READ/WRITE. BIOS040 observed that chain and distinct bytes
for differently translated sectors. Direct access bypasses BDOS allocation,
directory protection, open-file state, and fatal presentation. Software that
writes raw structures must coordinate or reset BDOS state; CP/M supplies no
transactional protection for such mixing.

## 12. Disk utility findings

**B/I:** SYSGEN is a real direct-BIOS consumer and therefore establishes more
than hypothetical visibility of system tracks and BIOS calls. STAT is a DPB
consumer; its native result matched DPB040. DUMP shows the other valid model:
a disk utility can use ordinary BDOS and remain geometry-independent. The
particular SYSGEN system image, retry count, and IBM-sector loop are not
universal requirements.

## 13. Disk format variations

**A/I:** The matrix compared IBM 3740 with a z80pack hard-disk definition. The
latter has 128 sectors/track, 2,048-byte blocks, 2,040 blocks, 1,024 directory
entries, sixteen directory blocks, OFF=0, and identity translation. Both are
expressible by the same CP/M structures despite radically different capacity
and map width. This demonstrates parameterized compatibility, not universal
interchange of their raw images.

## 14. Storage error interaction

**I:** A controlled damaged IBM image assigned block 2 to two active extents.
The Investigation parser and an independent checker both detected the
duplicate. This proves structural ambiguity is observable to utilities; it
does not establish a CP/M BDOS repair result. Physical read/write errors remain
I015/I025/I033 territory. CP/M 2.2 does not document automatic repair,
duplicate-block arbitration, or useful operation on corrupt metadata.

## 15. Software ecosystem findings

Common practice therefore creates two compatibility populations: ordinary
applications using BDOS's geometry-neutral file contract, and configured
system/diagnostic utilities using BIOS and public disk structures. The latter
can require a matching machine/disk profile but cannot turn that profile's raw
geometry into a universal CP/M rule. Filesystem checkers and imagers may also
legitimately interpret documented 32-byte entries and DPB-derived maps.

## 16. Experimental results

**I:** Empty IBM media had zero entries, two reserved blocks, and 241 free data
blocks. Normal media had 35 active extent entries and ten free blocks. The
nearly full fixture placed FILLER.BIN in 15 extents, leaving seven blocks. The
damaged fixture produced the intended duplicate. The empty alternate image had
1,024 free directory slots and 2,024 non-directory blocks.

DPB040 observed live ALV changes during create/write/close/delete and restored
its test file. DRI STAT reported 1,944 records, 243 KB, 64 entries, 64 checked
entries, 128 records/extent, eight records/block, 26 sectors/track, and two
reserved tracks. BIOS040 captured translated directory/data transfers and
WRITE types 0/1/2. Raw matrix images were byte-identical after read-only tests;
native A images changed only through controlled probe installation/lifecycle.

## 17. Compatibility conclusions

**REQUIRED:** coherent DPH/DPB structures; DPB-driven directory size,
allocation-map width, capacity and reserved-area interpretation; 32-byte
extent entries in 128-byte logical directory records; coherent ALV ownership;
configured logical-track/translation behavior; documented direct BIOS access.

**NOT GUARANTEED:** IBM 3740 geometry, alphabetical/physical directory order,
particular block or slot selection, raw-image offsets, controller sector IDs,
corrupt-media recovery, or interchange between unlike disk definitions.

**NOT REQUIRED:** DRI allocation algorithm, literal skew table, physical
cylinders, host-sector size, host image container, DRI STAT formatting, and
SYSGEN's private retry loop.

**POLICY PENDING:** which legacy disk profiles BetterCP/M will advertise and
whether it will offer raw-media interchange for each profile.

## 18. Proposed ledger additions

### 0613. Parameterized disk-structure coherence

Each advertised CP/M 2.2 drive profile shall provide mutually coherent DPH,
DPB, directory, allocation-map, ALV, logical-sector, and capacity semantics.
Disposition: **REQUIRED**. Evidence: I040 STORAGE DISK BDOS BIOS subsystem IG
AG; DPB040; STAT; raw matrix. Conformance: validate empty, populated, and
nearly full media against every public field.

### 0614. DPB-dependent directory allocation-map width

Directory entries use sixteen one-byte allocation numbers when DSM is below
256 and eight little-endian word allocation numbers for larger disks.
Disposition: **REQUIRED**. Evidence: I040 STORAGE DISK BDOS BIOS subsystem IG
AG; disk definitions. Conformance: exercise both DSM classes.

### 0615. Logical directory placement

Directory entries occupy DPB-reserved allocation blocks and are transferred as
128-byte logical sectors; their raw physical offsets depend on OFF and sector
translation. Disposition: **REQUIRED**. Evidence: I040 STORAGE DISK BDOS BIOS
subsystem IG AG; BIOS040; matrix. Conformance: parse a nonidentity translation
profile without assuming contiguous physical directory sectors.

### 0616. Raw-format universality

CP/M 2.2 does not guarantee one raw disk image layout, physical geometry,
sector numbering, skew table, or host-sector representation across systems.
Disposition: **NOT GUARANTEED**. Evidence: I040 STORAGE DISK BDOS BIOS
subsystem IG AG; two definitions. Conformance: accept distinct declared
profiles implementing the same logical interfaces.

### 0617. Direct-structure caller responsibility

A direct disk caller must use the configured BIOS and its returned disk
parameters/translation and receives no BDOS allocation, directory, or
open-file protection for raw writes. Disposition: **REQUIRED**. Evidence: I040
STORAGE DISK BDOS BIOS subsystem IG AG; SYSGEN; BIOS040. Conformance: compare a
configured direct read with BDOS access and reject hard-coded foreign geometry.

### 0618. Damaged-directory recovery

CP/M 2.2 does not guarantee automatic repair or deterministic ownership when
directory allocation maps conflict or contain otherwise corrupt metadata.
Disposition: **NOT GUARANTEED**. Evidence: I040 STORAGE DISK BDOS BIOS
subsystem IG AG; damaged matrix. Conformance: detect/report corrupt fixtures
without requiring a particular repair choice.

## 19. Existing-entry updates

Add I040 evidence without changing dispositions to 0149-0155 (directory-entry
form), I017's DPB/ALV entries 0411-0428, 0449-0459 (BIOS disk mapping),
0542-0550 (directory-entry enumeration), 0551-0558 (extent/allocation
lifecycle), and 0598-0601 (direct BIOS boundary). No correction is proposed.
Entries 0453-0455 and 0459 already prevent duplicating physical geometry and
translation propositions; 0598-0600 already require the public direct ABI.

## 20. Open questions

1. **D:** Which named floppy and hard-disk profiles will BetterCP/M advertise?
2. **D:** Will each profile promise byte-for-byte raw-image interchange or only
   logical CP/M interchange?
3. **D:** Which read-only inspection and corruption diagnostics belong in the
   conformance suite rather than the implementation?
4. **D:** Should a profile include DRI-compatible system-track/SYSGEN layout,
   or declare a different installation mechanism while retaining runtime BIOS?
5. No claim was made that the reference BIOS can mount the alternate hard-disk
   image; it was tested structurally because the active BIOS advertises only
   its configured IBM profile.

## 21. Conformance implications

For each advertised profile, test empty, normal, nearly full, and damaged
media; compare Functions 27/31 with directory/allocation interpretation; cross
the DSM=255 allocation-map-width boundary; exercise identity and nonidentity
translation; trace BDOS directory and data DMA; and perform configured direct
BIOS reads. Validate logical content and coherent structures, not DRI block
order or raw offsets. Corrupt-media tests must verify declared detection/error
behavior without inventing automatic CP/M repair.

Artifacts preserve both native probes, builds, transcripts, five controlled
before/after image pairs, source excerpts, independent structural checks,
hashes, and the complete preservation audit. No BetterCP/M implementation or
Compatibility Ledger file was changed.
