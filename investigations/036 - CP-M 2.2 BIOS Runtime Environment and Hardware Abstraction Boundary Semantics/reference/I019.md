# Investigation 019 - CP/M 2.2 BIOS Disk Interface and Logical-Sector Semantics

Status: Complete evidence report; ledger not modified  
Date: 2026-08-15

## 1. Objective, scope, and evidence

This investigation defines the disk abstraction a CP/M 2.2 BIOS presents to
BDOS through SELDSK, SETTRK, SETSEC, SETDMA, READ, WRITE, and SECTRAN. It does
not standardize z80pack geometry or design BetterCP/M storage.

Evidence classes are **A** documented DRI interface, **B** DRI BDOS/source
assumption, **I** reference-fixture observation, and **D** unresolved policy.
The Alteration Guide pages covering BIOS calls, DPH/DPB, and blocking were
rendered and visually checked. BIOS019 wraps and delegates the real BIOS jump
entries while recording raw state; disk operations remain real.

## 2. Documented BIOS contract

### Stateful call sequence

SELDSK selects logical drive C (0=A through 15=P) and returns its 16-byte DPH
in HL, or 0000 for an unavailable drive. It may defer physical selection until
I/O. SETTRK takes a 16-bit logical track in BC; SETSEC takes the translated
sector in BC; SETDMA takes the buffer address in BC. These values persist and
are replaced by later setup calls. READ/WRITE receive no duplicate drive,
track, sector, or address arguments: they operate on this one current BIOS I/O
context. Track and sector are set before each transfer; drive and DMA may be
reused. The interface is consequently stateful and is not documented reentrant.

SELDSK may refresh private state, but must return the DPH on every successful
call. Re-selecting need not operate hardware. DRI BDOS uses successful selection
to establish its current/login state; those application semantics remain those
of Investigations 007/017.

### DPH and associated objects

The DPH is eight little-endian words in this order:

`XLT, scratch, scratch, scratch, DIRBUF, DPB, CSV, ALV`.

XLT points to zero-based logical-sector translation bytes, or is null for an
identity-configured disk. The three scratch words are BDOS workspace. DIRBUF is
a shared 128-byte directory scratch buffer. DPB describes logical geometry.
CSV and ALV are drive-specific workspace sized from CKS and DSM. Identical
drives may share XLT and DPB; all DPHs may share DIRBUF; CSV/ALV must be unique.
Exact addresses and placement are BIOS configuration, not compatibility.
Applications legitimately obtain DPB/ALV only through Functions 31/27 as
bounded in Investigation 017; a DPH return is a BIOS-to-BDOS interface object.

### Track, sector, and offset

SETTRK accepts logical track 0-65535; 0-76 is merely standard-floppy geometry.
DPB OFF is the reserved-track count. DRI BDOS adds OFF while mapping records,
so the BIOS sees the resulting medium-relative logical track. A BIOS may seek
then or defer it. CP/M does not require one logical track to equal a physical
cylinder/head.

BDOS computes a zero-based logical sector within SPT, calls SECTRAN with that
value in BC and DPH XLT in DE, then passes returned HL to SETSEC via BC.
Translation-table bytes are controller-facing sector identifiers (commonly
1-based on standard media). SETSEC therefore receives translated identifiers,
not the pre-translation index. Physical addressing beyond that is BIOS-private.

### DMA and 128-byte logical sectors

SETDMA selects the address used until replaced. Function 26 ultimately supplies
the same application address, but BDOS temporarily selects DIRBUF for directory
I/O and restores application DMA. READ writes and WRITE reads exactly one CP/M
logical sector: 128 bytes. This holds even when host sectors are larger; the
BIOS performs blocking/deblocking and read-modify-write. The controller need
not implement hardware DMA. CP/M applications and BDOS do not see host-sector
size through ordinary record I/O.

Directory records and file records are each 128-byte logical sectors. An
allocation block contains `128 << BSH` bytes and many records; a directory entry
is 32 bytes. These are distinct concepts.

### READ, WRITE, and errors

READ transfers the selected logical sector to DMA. WRITE transfers from DMA.
Zero in A means success; nonzero means unrecoverable physical failure after
BIOS recovery attempts. No exact nonzero code, retry count, or failed-DMA
contents are promised. Investigation 015 already establishes BDOS fatal-error
presentation, so it is not duplicated.

WRITE receives in C: 0 normal allocated-data write, 1 directory write, 2 first
logical sector of a newly allocated data block. These values permit a deblocking
BIOS to avoid unnecessary host-sector pre-reads and safely manage delayed
writes. The type is a semantic optimization indication; a simple 128-byte-sector
BIOS may ignore it while still writing correctly. A compatible BDOS boundary
must generate the defined values because existing BIOSes may rely on them.

### SECTRAN

SECTRAN takes zero-based logical-sector index BC and XLT pointer DE, returns the
translated sector in HL, and performs no I/O. With a configured null XLT, the
BIOS must implement identity translation appropriate to that disk definition.
Translation supports skew/interleave; an equivalent algorithm is permissible.
Arbitrary host geometry mapping may continue in SETSEC/READ/WRITE.

## 3. DRI source findings

DRI selection copies DPH-supplied pointers and the DPB into private working
state. Record mapping divides by SPT, adds OFF to the track, calls SETTRK,
calls SECTRAN with the remainder and XLT, then SETSEC. `rdbuff`/`wrbuff` use the
selected DMA. Directory operations switch to DIRBUF. The allocator passes type
2 only for the first write into a newly allocated block, type 1 for directory
updates, and type 0 otherwise. Any nonzero READ/WRITE result enters the physical
error path. Exact call counts and private variables are not requirements.

The DRI implementation is single-tasked and uses one global BIOS disk context.
No interrupt/reentrant contract protects setup state; a BIOS interrupt handler
must not corrupt it before the pending transfer.

## 4. Experiment and results

BIOS019 captured ten cases: directory search, sequential read, Make, two
sequential writes, Close, random read/write, Delete, and direct translation.
Each trace row records event, drive, track, translated sector, DMA, write type,
and result. The fixture preserves/delegates original vectors; raw rows are in
`probes/transcripts/console.txt`.

Observed successful transfers returned 00. Directory operations used write
type 01. The first record of BIOS019.DAT used 02; its next sequential record and
an allocated random update used 00. SETTRK/SECTRAN/SETSEC/SETDMA state preceded
each transfer. Directory DMA differed from application DMA. First directory
track was 2, consistent with OFF=2 already applied by BDOS.

The controlled table mapped logical index 2 to sector identifier 10; SETSEC
received 10 and READ returned different bytes than the comparison sector.
This demonstrates the chain without promoting the table or backing offsets.
The configured z80pack SECTRAN assumes its non-null XLT; its result for a
fixture-supplied null pointer is incidental and is not generalized.

Reference A/B sharing and DPB values match Investigation 017. A changed through
the controlled create/write/delete lifecycle; B remained byte-identical.

## 5. Logical-versus-physical conclusion

CP/M requires a stateful array of logical drives, each presenting 128-byte
logical sectors addressed through logical track plus translated sector and a
DPH/DPB description. It does **not** require physical tracks, one-to-one
cylinders, controller sector IDs matching SETSEC, or 128-byte host sectors.
BIOS may map onto larger sectors, arbitrary storage, or synthesized records,
provided selected 128-byte transfers, persistence, ordering, and error results
remain correct. Physical sectors smaller than 128 bytes are not described by
the sample algorithm but may be composed privately if the same abstraction is
preserved.

## 6. Compatibility classifications

**REQUIRED:** documented call registers; persistent setup context; DPH layout
and pointer roles; DPB-driven logical mapping; 128-byte transfers; zero/nonzero
results; write types 0/1/2; zero-based SECTRAN input and returned SETSEC value.

**NOT GUARANTEED:** exact call counts, addresses, geometry, retries, failed-DMA
contents, register preservation beyond documented results, physical selection
timing, reentrancy, or exact host offset.

**NOT REQUIRED:** real cylinders, direct physical sector IDs, DRI private
variables, a particular skew table, hardware DMA, or the sample deblocking
algorithm itself.

**POLICY PENDING:** whether BetterCP/M exposes a separately replaceable legacy
BIOS boundary internally; this does not alter the external CP/M contract.

## 7. Proposed Compatibility Ledger additions (not applied)

### 0449. Stateful BIOS disk setup

SELDSK/SETTRK/SETSEC/SETDMA establish one persistent BIOS context consumed by
READ/WRITE until replaced. Disposition: **REQUIRED**. Evidence: I019; AG BIOS
entry contract; BDOS; BIOS019. Conformance: vary each setup value independently.

### 0450. SELDSK result and deferral

SELDSK takes C=0..15 for A..P, returns DPH in HL or zero for absent drive, and
may defer hardware selection. Disposition: **REQUIRED**. Evidence: I019; AG
SELDSK; distributed BIOS. Conformance: configured/absent drives and deferred I/O.

### 0451. Public DPH layout

The DPH comprises XLT, three scratch words, DIRBUF, DPB, CSV, ALV as eight
little-endian words with documented sharing rules. Disposition: **REQUIRED**.
Evidence: I019; AG Disk Parameter Tables; BDOS. Conformance: validate pointers
and per-drive/shared objects without fixed addresses.

### 0452. DPH address and private workspace

Exact DPH/object addresses and the three scratch-word contents are not portable.
Disposition: **NOT GUARANTEED**. Evidence: I019; AG; BIOS configurations.
Conformance: prohibit fixed-address/private-workspace dependencies.

### 0453. Track mapping and OFF

SETTRK takes 16-bit BC; BDOS supplies logical track plus DPB OFF, while physical
mapping is BIOS-private. Disposition: **REQUIRED**. Evidence: I019; AG DPB/
SETTRK; BDOS; BIOS019. Conformance: trace boundary tracks with nonzero OFF.

### 0454. Sector translation chain

BDOS calls SECTRAN with zero-based logical sector BC and XLT DE, then passes HL
to SETSEC in BC. Disposition: **REQUIRED**. Evidence: I019; AG SECTRAN; BDOS;
BIOS019. Conformance: controlled nonidentity XLT.

### 0455. Translation implementation freedom

Exact XLT values and algorithm are not guaranteed; null-XLT disk definitions
use identity behavior and equivalent algorithmic translation is permitted.
Disposition: **NOT GUARANTEED**. Evidence: I019; AG Disk Parameter Tables/
SECTRAN. Conformance: accept table or algorithm with identical results.

### 0456. BIOS DMA state

SETDMA takes BC and selects the exact 128-byte transfer buffer until replaced;
BDOS may select DIRBUF internally. Disposition: **REQUIRED**. Evidence: I019;
AG SETDMA; BDOS; BIOS019. Conformance: trace application/directory buffers.

### 0457. BIOS logical-sector transfer

READ/WRITE transfer exactly one 128-byte logical sector using current state;
zero succeeds and nonzero is physical failure. Disposition: **REQUIRED**.
Evidence: I019; AG READ/WRITE; I015; BIOS019. Conformance: successful and
fault-injected transfers.

### 0458. BIOS WRITE type codes

WRITE C=0 normal allocated data, C=1 directory, C=2 first sector of a newly
allocated block. Disposition: **REQUIRED**. Evidence: I019; AG Blocking and
Deblocking; BDOS; BIOS019. Conformance: controlled lifecycle must produce all.

### 0459. Physical storage freedom

Physical geometry, host-sector size, deblocking algorithm, controller commands,
and backing offsets are not required if the 128-byte logical contract holds.
Disposition: **NOT REQUIRED**. Evidence: I019; AG Blocking and Deblocking.
Conformance: run the same BDOS tests over distinct physical mappings.

### 0460. BIOS disk-call reentrancy

CP/M 2.2 does not guarantee reentrant/interleavable BIOS disk setup contexts.
Disposition: **NOT GUARANTEED**. Evidence: I019; AG stateful sequence; DRI
single-context source. Conformance: do not require nested setup preservation.

## 8. Existing-ledger evidence updates

No correction is proposed. Entries from Investigations 009, 015, and 017 on
DMA, physical errors, DPB, and ALV gain lower-level corroboration from I019;
their propositions and dispositions need not change.

## 9. Incomplete and unresolved cases

No required experiment was blocked. Not directly tested: a host sector larger
or smaller than 128 bytes, invalid SELDSK through the instrumented transient,
multiple geometries, failed-transfer DMA residue, or concurrent interrupts.
Those conclusions remain bounded to documentation/source or explicitly
NOT GUARANTEED. The fixture restored its saved vectors and requested warm start
after its last capture, but the accepted run did not regain a CCP prompt before
the automated timeout. This post-evidence shutdown anomaly remains a fixture
limitation and supplies no disk-interface evidence; all requested traces had
already printed.

## 10. Artifact and preservation audit

Probe source/COM/listing, harness, raw/derived output, before/after images,
directory listing, and hashes are present. The COM rebuild is byte-identical.
The authoritative Ledger 018 hash before/after is recorded unchanged. Prior
investigation report hashes were recorded and no pre-existing BetterCP/M file
was modified. No ZIP was created.

## 11. Sources

Digital Research *CP/M 2.2 Alteration Guide*; *CP/M 2.0 Interface Guide*;
February 1980 OS3BDOS source; distributed BIOS/CBIOS and blocking examples;
BetterCP/M Investigations 007-018; authoritative Compatibility Ledger 018;
z80pack commit `91fd28eb04e675c2127df88ed3f40675e15282e2`.
