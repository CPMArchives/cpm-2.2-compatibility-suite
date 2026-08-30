# Investigation 025 - CP/M 2.2 BDOS File Operation Error Semantics and Application-Visible Failure Behavior

## 1. Objective and scope

This investigation defines what a CP/M 2.2 application observes when a BDOS
file operation cannot complete. It consolidates the function-specific logical
failure codes, distinguishes directory and allocation exhaustion, measures FCB
and DMA aftermath, and separates returning failures from DRI's nonreturning
operator-error paths. Physical-media injection is not repeated; I015 governs
that boundary.

## 2. Relationship to previous investigations

I008 established Open/Close activation. I010-I013 established sequential,
creation/write, delete/rename, and random I/O semantics. I014 established
read-only policy; I015 established physical-error presentation; I017 established
allocation state; I023 established caller FCB construction; and I024 established
that termination does not close FCBs. I025 adds a controlled cross-function
failure matrix and avoids duplicating their success-path tests.

Evidence classes used internally are A (documented), B (DRI source), I
(experiment), and D (unresolved policy). Ledger proposals cite actual sources.

## 3. Documentation findings

The Interface Guide documents per-function results, not one universal BDOS
error number. Open, Close, Search, Make, Delete, and Rename use directory codes
0-3 for success and FFh for the documented no-match/no-directory-space cases.
Sequential Read returns zero for a transferred record and nonzero at EOF.
Sequential Write returns zero for success and nonzero for full-disk failure.
Random I/O defines more specific nonzero values, including unwritten data,
missing extent, extent-creation failure, and random-address overflow.

The manuals make caller preconditions material: read/write FCBs must be
activated, Make requires a unique name, and the FCB fields required by each
operation must be initialized. They do not promise useful error classification,
FCB stability, or DMA contents when those preconditions are violated.

Read-only disk/file violations and BIOS/controller failures are not ordinary
logical return codes in DRI CP/M 2.2. They enter diagnostic/operator handling.
The documentation does not require FFh for every failure and does not make a
nonzero write result interchangeable with physical-error presentation.

## 4. BDOS source findings

OS3BDOS.ASM routes directory searches and directory-space failures through
shared FFh directory-code returns. Sequential and random data paths use their
own status values. Allocation exhaustion is detected separately from absence of
a free directory entry. The common returning epilogue supplies the established
A=L and B=H aliases.

Selection, read-only, and permanent BIOS errors dispatch to diagnostic routines
which may wait for an operator response and warm-start rather than return to the
application. Search failure can leave a copied private directory record in DMA;
the FFh status makes that DMA record invalid as a match.

The exact private search buffer, failure branch order, FCB mutation sequence,
and diagnostic routine addresses are NOT REQUIRED.

## 5. Error matrix

| Operation/condition | Observed result | Portable classification |
|---|---:|---|
| Open missing | FF | REQUIRED |
| Open file existing only in user 1 while user 0 | FF | REQUIRED namespace isolation |
| Open wildcard matching ONE25 | 03 | wildcard Open succeeded; exact slot NOT GUARANTEED |
| Close missing/unactivated identity | FF | REQUIRED documented no-match |
| Delete missing | FF | REQUIRED |
| Rename missing source | FF | REQUIRED |
| Make duplicate name | 02 success, duplicate entry created | NOT GUARANTEED caller-precondition violation |
| Make with full directory, data free | FF | REQUIRED |
| Make with data full, directory free | 01 success | REQUIRED distinction |
| Sequential Write after that Make | 02 | nonzero REQUIRED; exact 02 policy remains pending |
| Search First no match | FF | REQUIRED |
| Search Next exhausted | FF | REQUIRED |
| Sequential Read empty file | 01 | nonzero REQUIRED; exact 01 policy remains pending |
| Sequential Read unactivated FCB | 01 here | NOT GUARANTEED |
| Random Read record 1 beyond EOF | 01 | REQUIRED DRI-compatible code |
| Random Read record 128, missing extent | 04 | REQUIRED DRI-compatible code |
| Random Read r2=04 | 06 | REQUIRED random-range code |
| Delete on Function-28 read-only drive | no return; `R/O` diagnostic | REQUIRED strict DRI presentation / policy alternative per I014 |
| Open unavailable C | no return; `Bad Sector` diagnostic | BIOS/error-policy dependent |
| Open invalid drive code 17 | no return; `Select` diagnostic naming Q | NOT GUARANTEED malformed input |
| Close after corrupting activated FCB name | 00 here | NOT GUARANTEED malformed input |

FFh therefore means several directory-oriented failures, but is not the common
error value for all file calls. A program must interpret results according to
the selected function.

## 6. Experimental methodology

Seven assembly probes were built:

- FILEERR25: missing directory operations and duplicate Make;
- OPEN25: missing, user-isolated, wildcard, unavailable- and invalid-drive Open;
- WRITE25: Make/Write on independently full resources;
- READ25: sequential and random failures;
- SEARCH25: no-match/exhaustion and DMA;
- FCB25: malformed activated-FCB Close;
- DISK25: read-only drive mutation.

Every returning case ran in a fresh image copy. Fatal paths used an Expect
harness that waited for the exact diagnostic and supplied Control-C. DMA was
prefilled with A5h or AAh before failure. FCBs were dumped in full. The
directory-full image had 64 entries but 178K free; the allocation-full image
had 0K free and available directory slots. This isolates the two resources.

## 7. Results

### Directory-oriented failures

Missing Open, Close, Delete, and Rename each returned FFh. Their caller FCB
identity/control sentinels and the AAh DMA sentinel remained byte-for-byte in
the tested cases. This is useful DRI evidence but only fields explicitly defined
for a failure are portable.

Make did not enforce its documented uniqueness precondition: a duplicate Make
returned directory code 02 and created a second ONE25.DAT entry. Applications
must Delete or otherwise ensure uniqueness; duplicate behavior is not a portable
failure contract.

### Search failures

Search First no-match and Search Next exhaustion returned FFh. DMA did not stay
A5h; DRI copied a directory record even on failure. Likewise, a successful
Search First returned code 03 while the matching entry occupied slot 3 of the
128-byte record, not its first 32 bytes. Applications must use the returned slot
only on 0-3 and must not treat DMA as a match after FFh.

### Read failures

Sequential Read on an activated empty file returned 01h and left DMA A5h. An
unactivated but formatted FCB also returned 01h in this build, while its
allocation bytes became FFh. That result and mutation are outside the API
precondition and NOT GUARANTEED.

Random record 1 beyond a one-record file returned 01h; record 128 whose extent
did not exist returned 04h; r2=04 returned 06h. DMA remained A5h in each case.
These codes distinguish logical conditions that FFh does not represent.

### Write/resource failures

With all 64 directory entries occupied but 178K storage free, Make returned FFh
and the image was unchanged. With 0K storage free but directory space available,
Make returned 01 (a success slot), created an empty file, and Write Sequential
returned 02 without allocating a block or advancing CR. The after-image differs
only because Make itself succeeded. This directly separates directory capacity
from allocation capacity and finds no partial data write.

### Read-only, drive, and malformed conditions

Function 28 followed by Delete produced `Bdos Err On A: R/O` and did not return;
Control-C warm-started. An unavailable C drive produced `Bad Sector`, whereas
invalid FCB drive 17 produced `Select` on the displayed Q drive. These are
operator/BIOS presentations, not FFh Open returns.

After a successful Open, changing the first filename byte before Close still
returned 00h; with no dirty metadata, the disk image remained unchanged.
Malformed active FCB behavior cannot be used to infer either reliable failure
or preservation. The proper compatibility contract is the documented FCB
precondition.

## 8. Compatibility conclusions

**REQUIRED:** function-specific result interpretation; directory codes 0-3 and
FFh where documented; nonzero sequential EOF/write-full results; documented
random failure distinctions; separation of directory-full Make from
allocation-full Write; current-user isolation; and the existing read-only and
physical-error boundaries.

**NOT GUARANTEED:** universal FFh failure, exact FCB image after failure unless a
function defines it, DMA after any failed operation, malformed/unactivated FCB
behavior, duplicate Make behavior, invalid-drive results, and partial internal
mutation before a reported failure.

**NOT REQUIRED:** DRI private failure routines, exact directory slot, exact
search-buffer residue, or private mutation order.

**POLICY PENDING:** exact sequential EOF/write-full codes where the manuals only
require nonzero; strict interactive fatal presentation versus a documented
BetterCP/M extension; and precise unavailable-drive presentation across BIOSes.

## 9. Proposed Compatibility Ledger additions

The ledger is not modified. New proposals begin at 0513.

### 0513. File-operation failures are function-specific

CP/M 2.2 does not define one universal BDOS file-error sentinel. Directory
operations use FFh for specified no-match/no-space cases, sequential calls use
zero/nonzero success distinctions, and random I/O defines additional nonzero
codes. Applications shall interpret A according to the selected function.

Disposition: REQUIRED

Evidence: I025; IG; BDOS; I008-I013

Conformance: Exercise representative directory, sequential, and random failures
and reject an implementation that maps all failures indiscriminately to FFh.

### 0514. Failure does not generally validate DMA contents

A failed file operation does not generally make DMA a valid result record and
does not universally promise that DMA is unchanged. In particular, DRI Search
may copy directory data even when it returns FFh, whereas tested logical read
failures left the caller's sentinel unchanged.

Disposition: NOT GUARANTEED

Evidence: I025; I009; I010; I013; BDOS

Conformance: Treat DMA as valid only when the selected function's successful
result defines transferred data; permit failure-path contents to vary.

### 0515. FCB state after precondition or operation failure

Except for fields explicitly defined by a particular call, CP/M 2.2 does not
guarantee an exact FCB byte image after failure, especially for unactivated,
malformed, or caller-modified FCBs.

Disposition: NOT GUARANTEED

Evidence: I025; I008; I010-I013; BDOS

Conformance: Require documented success/failure and position semantics but do
not compare undefined failure-path FCB bytes to a DRI snapshot.

### 0516. Directory-full and allocation-full are distinct

Function 22 fails with FFh when no directory entry exists even if data blocks
remain. Exhausted data blocks do not by themselves prevent creation of an empty
file when a directory entry remains; a subsequent write returns nonzero when it
cannot allocate the requested record.

Disposition: REQUIRED

Evidence: I025; I011; IG; BDOS

Conformance: Test a full-directory/free-data image separately from a
free-directory/full-data image and verify the two-stage Make/Write behavior.

### 0517. Malformed FCB behavior is outside the portable contract

Invalid drive encodings, unactivated read/write FCBs, and identity corruption
after activation have no portable CP/M 2.2 return or mutation guarantee beyond
safe implementation handling.

Disposition: NOT GUARANTEED

Evidence: I025; I008; I010-I013; IG

Conformance: Do not require DRI's observed return, diagnostic, or disk mutation
for calls that violate documented FCB preconditions.

## 10. Existing-entry updates

- **0001-0034:** no new propositions; add I025 only to common-return alias rules
  for normally returning failures.
- **0080-0170:** strengthen Function 13/14 and Open/Close evidence; retain
  unavailable/invalid-drive policy limits.
- **0191, 0206, 0216-0218:** strengthen Search FFh and invalid-DMA evidence;
  avoid duplicates.
- **0232-0246:** strengthen sequential EOF, failure-DMA, invalid-FCB, and
  physical-error distinctions. Exact EOF 01 remains policy-pending.
- **0253-0256, 0274-0283:** strengthen directory-full/allocation-full and exact
  code evidence. Duplicate Make and unactivated write remain unguaranteed.
- **0290, 0303, 0308-0315:** strengthen missing Delete/Rename and invalid-drive
  evidence; protection/physical presentation remains governed by I014/I015.
- **0331-0334, 0345-0346, 0354:** strengthen random logical-code and failure-DMA
  evidence without merging physical errors into those codes.
- **0368-0389:** strengthen the nonreturning read-only boundary; no disposition
  change is proposed here.
- **0390-0413:** no duplicate physical-error entries; I025 confirms their
  separation from ordinary logical returns.
- **0506-0512:** no lifecycle or entry-state changes.

## 11. Open questions

1. Should strict BetterCP/M reproduce blocking DRI diagnostics for read-only and
   unavailable-drive errors, with a separate opt-in structured-error extension?
2. Should exact DRI sequential codes 01/02 be elevated where documentation
   guarantees only nonzero?
3. What safe containment should BetterCP/M apply to malformed FCB drive codes
   without accidentally creating a new portable API?

No required experiment is incomplete.

## 12. Artifact preservation audit

- The Investigation 025 directory contains report, seven sources/binaries and
  listings, harnesses, ten accepted transcripts, normal/resource-specialized
  before-images, accepted after-images, directory listings, build instructions,
  and SHA-256 manifests.
- All seven binaries rebuild byte-identically.
- Directory-full before/after images match exactly. Allocation-full after differs
  only because Make succeeded before Write returned 02.
- Normal read/search/open, malformed clean Close, and fatal-path images are
  unchanged; the duplicate-Make change is preserved rather than hidden.
- Ledger 024 SHA-256 before and after is
  `19b8aee350e5f95bb1b16b6947944071c505329f10599848e693bb0d25d005a3`.
- No prior investigation, ledger, architecture, roadmap, specification, or
  source file was modified. All writes are confined to Investigation 025.
- No ZIP archive was created.

## 13. Sources

- Digital Research, *CP/M Features and Facilities*.
- Digital Research, *CP/M 2.0 Interface Guide*.
- Digital Research, *CP/M 2.2 Alteration Guide*.
- Digital Research CP/M 2.2 `OS2CCP.ASM` and `OS3BDOS.ASM`.
- BetterCP/M Investigations 008, 010-015, 017, 023, and 024 and their ledger propositions.
- z80pack cpmsim Release 1.39, commit `91fd28eb04e675c2127df88ed3f40675e15282e2`.
- Investigation 025 probes, transcripts, directory listings, images, and hashes.
