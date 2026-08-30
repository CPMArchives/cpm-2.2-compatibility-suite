# Investigation 017 - CP/M 2.2 BDOS Disk State, Allocation Vector, and Disk Parameter Block Semantics

Status: Complete evidence report; ledger not modified  
Date: 2026-08-15

## 1. Objective and method

This investigation defines the smallest externally observable contract for
BDOS Functions 24 (Return Login Vector), 27 (Get Address (Alloc)), and 31 (Get
Disk Parameters), plus the additional Function 37 state interactions needed
to interpret those results. Functions 13, 14, 25, 28, and 29 are used only as
controlled state transitions. Investigation 007 and ledger entries 132-155
already define their ordinary reset, selection, current-drive, and login rules;
Investigation 014 defines read-only state.

Evidence labels are: **A** documented application/BIOS interface; **B** DRI
CP/M 2.2 source; **I** experimentally observed configuration-specific behavior;
and **D** unresolved BetterCP/M policy. Source review selected tests but did not
substitute for them. STATE017 records pointers and bytes without interpreting
them inside CP/M, using fresh preserved images and deterministic automation.

## 2. Documentation findings

### 2.1 Function 24 - Return Login Vector

**A:** C=18h; HL receives a 16-bit value. Bits 0-15 map A-P. A set bit means
the drive is online after explicit selection or an implicit explicit-drive FCB
operation; a clear bit means offline. Function 24 returns the vector value, not
an address, so the result is a snapshot in registers. Investigation 007 already
established that reset leaves A logged, selection accumulates bits, and an
explicit-drive FCB can log a drive without changing the default.

Login and read-only vectors are distinct. Reset Disk System clears prior login
and read-only state before selecting/logging A. Neither vector is exposed as a
writable object by Function 24 or 29.

### 2.2 Function 27 - Get Address (Alloc)

**A:** C=1Bh; HL receives the base address of the allocation vector for the
currently selected disk. CP/M maintains one allocation vector per online disk.
The Interface Guide warns that the returned allocation information may be
invalid if the selected disk has been marked read-only and says applications do
not normally use the function.

The Alteration Guide defines the ALV storage length as `(DSM / 8) + 1` bytes,
where DSM is the maximum allocation-block number. Bit number *n* represents
allocation block *n*, ordered from the high bit of the first byte. One means
allocated/reserved; zero means available. The DPB AL0/AL1 bits reserve leading
allocation blocks for the directory, so those bits appear set independently of
ordinary file data. Directory entries' allocation maps cause their file blocks
to be set when a disk is initialized.

The manuals do not grant applications a supported right to edit the ALV, state
a stable numeric address, or promise validity after changing/resetting disks.
It is BDOS scratch state supplied by the BIOS DPH for the selected drive.

### 2.3 Function 31 - Get Address (Disk Parameters)

**A:** C=1Fh; HL receives the address of the BIOS-resident DPB for the current
disk. The public 15-byte layout, with words stored low byte first, is:

| Offset | Size | Field | Meaning |
|---:|---:|---|---|
| 0 | 2 | SPT | 128-byte logical sectors per track |
| 2 | 1 | BSH | allocation-block shift |
| 3 | 1 | BLM | allocation-block mask |
| 4 | 1 | EXM | extent mask |
| 5 | 2 | DSM | highest allocation-block number |
| 7 | 2 | DRM | highest directory-entry number |
| 9 | 1 | AL0 | high eight directory-reservation bits |
| 10 | 1 | AL1 | low eight directory-reservation bits |
| 11 | 2 | CKS | directory check-vector size |
| 13 | 2 | OFF | reserved-track offset |

The DPB is drive/configuration data, not a universal geometry. Drives with the
same characteristics may share one DPB; different drives may use different
ones. The Interface Guide expressly allows transient programs to display/use
the values and to change them dynamically when disk conditions change. That
permission is specific to the documented DPB, not to the DPH or other BIOS
private tables. No exact address or lifetime across BIOS replacement, reset,
warm start, or later selection is guaranteed; callers must re-query for the
current disk.

### 2.4 Function 37 - Reset Drive

The examined CP/M 2.0 Interface Guide ends its function descriptions at 36,
and the examined CP/M 2.2 Alteration Guide does not publish an application-call
definition for Function 37. Therefore no Function 37 proposition is presented
as class A from these manuals. DRI's shipped 2.2 BDOS nevertheless dispatches
C=25h and interprets the 16-bit DE value as a drive vector. Source and experiment
agree that selected bits are removed from both login and read-only vectors,
without changing the current-drive number. It has no function-specific result.
Whether this de facto DRI 2.2 service is mandatory BetterCP/M surface remains
policy pending absent an identified DRI application-interface statement.

Function 13 is broader: it resets disk state, DMA to 0080h, current drive to A,
and then logs A. Function 37 only removes the selected vector bits in DRI; it
does not select A, set DMA, reconstruct ALV/DPB, or force relogin.

## 3. DRI source findings

OS3BDOS keeps `dlog` and `rodsk` as private words. Function 24 copies `dlog`
into HL. Function 27 loads the current DPH-derived ALV address. Function 31
loads the current DPH-derived DPB address. On selection, DRI separately copies
the 15 DPB bytes into private working variables, while retaining the public
BIOS DPB pointer for Function 31.

First login initializes the per-drive ALV: it zeroes `(DSM/8)+1` bytes, writes
the DPB directory-reservation bits, scans valid directory entries, and marks
their allocation blocks. File allocation and deletion update this live vector.
The exact scan algorithm, private working-copy address, and variable placement
are **B/I**, not compatibility requirements.

Function 37 computes `dlog &= ~DE` and `rodsk &= ~DE`. It does not alter
`curdsk`, current DPH-derived addresses, or DPB working values. This directly
motivated the single-bit, multi-bit, unlogged-drive, and current-drive tests.

## 4. Experimental design and results

### 4.1 Environment and capture

The accepted run used z80pack cpmsim 1.39 at commit
`91fd28eb04e675c2127df88ed3f40675e15282e2`, DRI CP/M 2.2, and Z80 CBIOS 1.2.
No manual input or timed response was required. Every snapshot records current
drive, login vector, read-only vector, ALV pointer and all 31 ALV bytes, plus
DPB pointer and all 15 DPB bytes. Raw evidence is preserved under `probes/`.

### 4.2 Cross-drive pointer and object state

After Function 13, A returned ALV FCB0h, login 0001h, and read-only 0000h.
Selecting B returned ALV FCCFh and login 0003h. Returning to A restored FCB0h
and A's prior content. The two addresses and exact bytes are **I**; the required
facts are that Function 27 identifies the current disk's correctly represented
allocation state and that per-drive state is not conflated.

Both drives returned DPB FA8Dh with identical bytes because this BIOS gives A
and B identical geometry. The decoded configuration was SPT=26, BSH=3, BLM=7,
EXM=0, DSM=242, DRM=63, AL0=C0, AL1=00, CKS=16, OFF=2. Sharing and these values
are configuration observations, not universal CP/M requirements.

When B was selected and marked read-only, its pointer and bytes remained
observable unchanged. This does not override the manual's explicit warning
that allocation information may be invalid for a marked read-only disk.

### 4.3 Live storage diagnostic

The probe temporarily changed the first ALV byte FFh->FEh, re-queried Function
27, and read FEh through the returned pointer. It restored FFh before any disk
operation. It similarly changed DPB SPT low byte 1Ah->1Bh, re-queried Function
31, observed 1Bh, and restored 1Ah. Thus these were live addressable objects in
the tested DRI/BIOS stack. Only DPB modification is expressly documented for
applications; arbitrary ALV writes remain unsupported and unsafe.

### 4.4 Allocation lifecycle

The controlled Make returned directory code 02h and did not change ALV data
allocation. The first successful sequential Write returned 00h and set one
previously clear allocation bit. Close returned directory code 02h without a
further ALV change. Delete returned 00h and cleared that bit. This confirms the
vector describes current allocation, with Make reserving a directory entry but
data allocation occurring on Write, and Delete releasing it. The exact chosen
block is not guaranteed (ledger entry 270 already says so).

The leading reserved bits were already set and matched DPB AL0/AL1 plus existing
file allocations. With DSM=242, the documented length is 31 bytes.

### 4.5 Function 37 transitions

- DE=0002h removed B from login while A remained current.
- DE=0006h when B/C were not logged caused no additional visible change.
- With B logged and read-only, DE=0002h cleared both B bits.
- With A and B logged, DE=0003h cleared both login bits in one call.
- Clearing A's login bit did not change Function 25 (still A) and did not alter
  the current A ALV/DPB pointers or captured bytes.
- Function 13 afterward restored current A, login 0001h, and read-only 0000h.

No function-specific return value was interpreted. Exact residual registers
are excluded by the established BDOS ABI rules.

## 5. Compatibility conclusions

### REQUIRED

- Function 24's established register value and A-P bit mapping.
- Function 27 returns a valid current-disk ALV pointer with documented length,
  high-bit-first block mapping, reserved directory bits, and live allocation.
- Allocation changes must become visible consistently with successful block
  allocation and release; exact chosen blocks and addresses are not fixed.
- Function 31 returns a current-disk DPB pointer with the public 15-byte layout.
- DPB values may differ by drive/configuration and identical drives may share.
- Documented transient-program DPB inspection and dynamic modification must be
  possible while the pointer is valid.

### NOT GUARANTEED

- Exact ALV/DPB addresses or adjacency; pointer identity across drives; pointer
  validity after selection, reset, warm/cold start, BIOS change, or relogin.
- Useful Function 27 contents after the selected disk is marked read-only.
- Effects of application-written ALV bytes or any result from Function 37.
- Residual registers and DRI's precise allocation scan/update sequence.

### NOT REQUIRED

- DRI symbol names, private DPB working copy, DPH layout exposure through BDOS,
  exact BIOS geometry, or the observed fact that A/B shared one DPB.
- The observed numeric pointers FCB0h/FCCFh/FA8Dh.

### POLICY PENDING

- Whether Function 37 is a required de facto CP/M 2.2 application service, and
  if so whether BetterCP/M must exactly implement DRI's vector-clearing behavior.
- Whether to protect ALV from writes or emulate writable DRI RAM.
- Whether DPB edits persist across selection/reset or trigger validation; the
  guide permits dynamic edits but does not specify a universal lifetime.

## 6. Proposed Compatibility Ledger additions (not applied)

Existing entries, including 147-149, 270, 292, and Investigation 016 proposals,
are not repeated. Proposals begin at 424 as directed.

### 0424. Function 27 allocation-vector pointer

Function 27 uses C=1Bh and returns in HL the base address of the allocation
vector for the currently selected disk.

Disposition: **REQUIRED**  
Evidence: A; B; experiment.  
Conformance: Select disks with different known allocation state and verify HL
addresses an ALV describing the selected disk.

### 0425. Allocation-vector length and bit mapping

The ALV contains `(DSM/8)+1` bytes; high-bit-first bit number n describes
allocation block n, with one allocated/reserved and zero available.

Disposition: **REQUIRED**  
Evidence: A Alteration Guide; B; experiment.  
Conformance: Derive length from DPB DSM and compare bits with controlled files.

### 0426. Reserved directory allocation bits

Blocks reserved by DPB AL0/AL1 appear allocated in the ALV independently of
ordinary file-data allocation.

Disposition: **REQUIRED**  
Evidence: A; B; experiment.  
Conformance: Verify the leading reserved block bits on a controlled empty disk.

### 0427. Live allocation state

Successful data-block allocation sets the corresponding ALV bit and successful
release clears it for reuse; Make without data need not allocate a data block.

Disposition: **REQUIRED**  
Evidence: A representation; B; Make/Write/Close/Delete experiment.  
Conformance: Compare ALV around a controlled one-record file lifecycle.

### 0428. Allocation-pointer address and lifetime

The exact ALV address and continued validity after disk selection, reset,
relogin, or warm/cold start are not portable; applications must re-query.

Disposition: **NOT GUARANTEED**  
Evidence: A silence/current-disk wording; per-drive B; experiment.  
Conformance: Do not require DRI addresses or stale-pointer behavior.

### 0429. Application modification of allocation vector

CP/M 2.2 does not define supported results for application writes through the
Function 27 pointer.

Disposition: **NOT GUARANTEED**  
Evidence: A describes BDOS-maintained state and says applications do not
normally use it; writable DRI RAM experiment is incidental.  
Conformance: Programs must not require arbitrary ALV writes to control BDOS.

### 0430. Read-only allocation information

Function 27 allocation information may be invalid while the selected disk is
marked read-only.

Disposition: **NOT GUARANTEED**  
Evidence: explicit Interface Guide warning; experiment observed unchanged DRI
bytes but cannot strengthen the contract.  
Conformance: Do not require current ALV accuracy after Function 28.

### 0431. Function 31 DPB pointer and layout

Function 31 uses C=1Fh and returns in HL a current-disk DPB with the documented
15-byte SPT/BSH/BLM/EXM/DSM/DRM/AL0/AL1/CKS/OFF layout and little-endian words.

Disposition: **REQUIRED**  
Evidence: A Interface/Alteration Guides; B; experiment.  
Conformance: Decode all fields from at least two configured drives.

### 0432. DPB configuration and sharing

DPB values are disk-format/BIOS configuration, not universal constants; drives
may have different DPBs and identical drives may share one.

Disposition: **REQUIRED**  
Evidence: A Alteration Guide; experiment confirms allowed sharing.  
Conformance: Accept shared or distinct pointers while validating each geometry.

### 0433. Documented DPB modification

While valid, the Function 31 object is addressable by a transient program and
may be dynamically changed as documented when disk conditions require it.

Disposition: **REQUIRED**  
Evidence: explicit Interface Guide statement; live-object experiment.  
Conformance: Temporarily change a safe DPB field, re-query/read, then restore.

### 0434. DPB address and lifetime

No exact DPB address, pointer identity, or validity across disk/reset/warm-start
transitions is guaranteed; callers must query for the current disk.

Disposition: **NOT GUARANTEED**  
Evidence: A current-disk/BIOS-resident wording and silence; B/I variability.  
Conformance: Do not compare against fixed addresses or require stale pointers.

### 0435. Function 37 compatibility status

DRI CP/M 2.2 Function 37 uses C=25h and DE as an A-P drive vector, clearing
selected bits from both login and read-only vectors without changing current
drive; the examined application manuals do not define this call.

Disposition: **POLICY PENDING**  
Evidence: B; deterministic single/multiple/unlogged-drive experiment; missing A
definition in examined manuals.  
Conformance: If adopted, test each vector effect independently and require no
function-specific result.

## 7. Incomplete and unresolved cases

No required experiment was blocked. Not tested: a BIOS with different A/B DPBs;
drives C-P; pointer dereference after warm/cold start (unsafe by definition);
media-change reconstruction; and persistence/validation policy for DPB edits.
Function 37 remains documentary-policy pending because the two named primary
application/alteration manuals do not define it. No behavior is inferred for
these cases.

## 8. Artifact and preservation audit

- Report, source, COM, build/run instructions, raw transcript, before/after
  images, directory listings, and SHA-256 files: present.
- STATE017 rebuilt byte-for-byte with z80asm 2.1.
- A changed only through the documented controlled lifecycle; B was unchanged.
- Current ledger selected at audit: `02 Compatibility Ledger - Investigation
  015.txt`; its content hash matched the initially verified current ledger
  content, and the before/after hash is recorded unchanged.
- No Compatibility Ledger or pre-existing BetterCP/M file was modified.
- Only the new Investigation 017 directory is installed; no ZIP is created.

## 9. Sources

1. Digital Research, *CP/M 2.0 Interface Guide*, Functions 24, 27, and 31.
2. Digital Research, *CP/M 2.2 Alteration Guide*, disk parameter tables.
3. Digital Research, CP/M 2.2 `OS3BDOS.ASM`, February 1980.
4. BetterCP/M Investigations 007, 008, 011, 012, 014, 015, and 016.
5. Current BetterCP/M Compatibility Ledger, used only to avoid duplication.
6. z80pack CP/M 2.2 reference environment identified above.
