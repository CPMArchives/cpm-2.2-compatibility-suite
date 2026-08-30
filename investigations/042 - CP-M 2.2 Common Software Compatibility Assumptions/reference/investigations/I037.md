# Investigation 037 - CP/M 2.2 BDOS Remaining Functions and Interface Consolidation Semantics

Evidence classes: **A** documented behavior, **B** DRI implementation, **I**
controlled observation, and **D** unresolved policy.

## 1. Objective and scope

This investigation audits all CP/M 2.2 BDOS selectors, closes remaining
behavioral gaps where practical, and consolidates the application-visible
contract without redesigning BDOS. It does not repeat established file,
directory, console, or calling-convention investigations.

The audit found no forgotten implemented selector. It found one deliberately
deferred behavioral topic: Function 40 Random Write with Zero Fill. I037 supplies
the missing normal, boundary, zero-fill, overflow, and disk-full evidence. A
protection-specific Function 40 fixture remains useful, and two broader matters
remain policy rather than mechanism gaps.

## 2. Compatibility standard

The standard combines the CP/M 2.2 manuals, DRI BDOS source, controlled DRI
CP/M 2.2 behavior, prior accepted investigations, and evidenced software use.
Undocumented observations become requirements only when documentation or
historical dependency justifies that promotion. DRI-private addresses, labels,
and incidental register residue are not compatibility merely because observable.

## 3. Relationship to previous investigations

I002/I027 define the common gateway, parameters, returns, stack and register
limits. I007-I014 define disk state, FCB, directory, sequential, create/write,
delete/rename, random access and protection. I015/I025/I033 define logical and
physical failure boundaries. I017/I026 define system state, vectors and pointers.
I029-I031 strengthen directory, lifecycle and namespace behavior.

I037 uses these as the coverage baseline. Its five probes are consolidation
fixtures derived from accepted probes, with BDOS37 changed to call Function 40
for every random write and to read the preceding zero-filled record.

## 4. BDOS function coverage audit

The strict DRI CP/M 2.2 dispatch table contains selectors 0-40. Every selector
is accounted for in `probes/function-coverage.txt`.

- 0-36 have focused documentary and experimental coverage.
- 37 is mechanically characterized but remains POLICY PENDING because the
  examined Interface Guide does not document it.
- 38 and 39 are DRI zero-result stubs, not documented application services;
  their absence of a CP/M 2.2 service contract is characterized.
- 40 was identified correctly by I013/I026 but its zero-fill behavior was
  explicitly deferred. I037 closes the ordinary allocation/boundary gap.
- 41-255 are outside the 41-entry table and use the established strict-mode
  zero-result path; extension-mode reuse remains policy pending.

Thus the function list is complete. Remaining issues are bounded policy/profile
questions and the Function 40 write-protection cross-product, not unknown BDOS
functions.

## 5. Documentation findings

**A.** CALL 0005h is the common entry; C selects the function and DE/E carries
function-specific information. Returned bytes use A and words use HL, with the
established A=L/B=H alias convention on normal DRI returns. Each function defines
its own FCB, DMA, state and error effects.

The Interface Guide documents the main interface through Function 36. The CP/M
2.2 alteration material adds Function 40 Random Write with Zero Fill. It does not
turn 38/39 into later-system services or make 41 part of CP/M 2.2. Documentation
does not promise general register preservation, reentrancy, rollback, uniform
invalid-parameter codes, or exact FCB residue after failure.

## 6. Source findings

**B.** OS3BDOS dispatches 41 entries after rejecting C>=41. It initializes the
result to zero, copies E into C for character paths, switches to its private stack,
and restores the caller stack at the common return.

Functions 38 and 39 point to the zero-result return. Function 40 reselects the
FCB drive, marks the operation as random-write-with-zero-fill, seeks the random
record, and writes on success. The zero-fill path applies while allocating a new
physical allocation block; it is not a general sparse-file abstraction. Exact
search loops, work variables and private stack location are NOT REQUIRED.

## 7. Application-visible behavior review

For each returning function, compatibility consists of its documented selector,
input carrier, result, state mutation, FCB mutation, and DMA effect. Success does
not imply that unrelated registers, FCB bytes or private state are stable. Failure
does not imply transaction rollback.

The consolidated review found no contradiction requiring correction. Apparent
cross-report differences resolve through layering: physical failures suspend for
DRI presentation, while logical missing/full/bad-FCB conditions normally return;
BDOS may temporarily use directory DMA while preserving the recorded application
DMA; FCB mutations differ by operation and progress reached.

## 8. Register and memory side effects

REGISTER37 reconfirmed A=L/B=H, function-defined results, balanced return, and no
general DE preservation. IX/IY happened to survive but remain NOT GUARANTEED.
Selector 41 returned zero in strict DRI CP/M 2.2.

STATE37 reconfirmed independent drive/user/login/read-only state and persistent
selected DMA. DMA37 reconfirmed Function 32 modulo-32 normalization and malformed
Open behavior. ERROR37 showed an AA-filled DMA remained untouched by logical
metadata failures, while FCB residue varied. These are function-specific outcomes,
not a universal no-side-effects rule. Page-zero gateways were not changed by the
returning calls.

## 9. Undocumented convention analysis

The following observations are not promoted:

- IX/IY preservation and exact DE/flag residue;
- exact zero results of documented void functions unless their specific contract
  or accepted evidence requires it;
- Functions 38/39 as callable future services;
- DRI Function 37 as universally mandatory before the existing policy decision;
- exact internal DMA/FCB work bytes after failure;
- extension selectors 41-255 in strict CP/M 2.2 mode.

Function 40 itself is not an undocumented convention. Its newly measured zero-fill
boundary is required because it is the defining distinction from Function 34.

## 10. Software ecosystem findings

The reviewed DRI CCP, PIP-related documentation, SYSGEN/XSUB source, assemblers'
standard CALL 0005h convention, and prior probe corpus use documented selectors,
FCBs, DMA and page-zero gateways. Common utilities depend on A/HL results and FCB
mutation; language runtimes and applications commonly wrap the same calls.

No local quantitative corpus supports requiring incidental register residue,
reserved selectors 38/39, or malformed-FCB internals. Communications programs'
unusual console use is already covered by Functions 1/2/6/10/11 and BIOS device
investigations, not a new BDOS function. Historical significance therefore
strengthens the documented ABI but does not manufacture new undocumented services.

## 11. Error consistency review

There is no single universal BDOS error code. The consistent model is layered:

- search/open/delete/close/rename failures commonly return FFh;
- duplicate Make returned directory code 01h in this controlled layout;
- sequential/random I/O use their documented result families;
- Function 40 returned 06 for invalid R2 overflow and 02 for exhausted storage;
- invalid parameters are function-specific and may be outside a safe contract;
- final physical BIOS errors enter DRI presentation rather than returning an
  ordinary logical code unless the operator chooses ignore.

ERROR37 preserved DMA but showed operation-specific FCB residue. Applications may
not infer universal rollback, immutability, or persistence from a shared-looking
return value.

## 12. Experimental results

Five deterministic probes ran in one fresh two-disk environment. The harness
provided all commands. Before/after images and the full transcript are preserved.

BDOS37 changed the accepted I013 matrix so every random write used Function 40.
Overwrite and append succeeded. Writing record 10 to a new file produced size 11;
record 9 then read successfully with byte 0 equal to 00, while record 10 contained
`S`. This directly establishes zero filling inside the newly allocated block.
Writing record 128 crossed an extent; record 65535 produced logical size 65536.
R2 nonzero returned 06 and the controlled full disk returned 02.

The maximum-record test creates a logically large sparse file; it does not imply
8 MiB of physical media. Filling B deliberately led to the harness's expected
terminal emulator state after the result had been captured. Both changed images
are preserved rather than misreported as unchanged.

## 13. Compatibility gap analysis

The CP/M 2.2 selector namespace and ordinary application-visible function behavior
are now substantially complete. No new numbered function investigation is needed
merely to find a missing selector.

Remaining gaps are:

1. **D:** whether Function 37's undocumented DRI behavior is required;
2. **D:** strict-only versus extension-mode policy for selectors 41-255;
3. focused experimental confirmation of Function 40 under file and disk write
   protection (recommended by I014); generic random-write protection rules exist,
   but this exact cross-product was not isolated here;
4. wider software-corpus evidence before elevating any undocumented residue;
5. target/profile-specific physical media errors remain governed by I015/I033.

These do not obscure the baseline CP/M 2.2 ABI; they are explicit policy or
cross-product tests.

## 14. Compatibility conclusions

- **REQUIRED:** selectors 0-40 and each documented function-specific contract;
  CALL 0005h, C, DE/E, A/HL aliases, restored SP, and strict out-of-range behavior.
- **REQUIRED:** Function 40 is distinct from 34 by zero filling the unwritten
  records of a newly allocated physical block before the target write.
- **NOT GUARANTEED:** universal sparse-hole readability, register preservation,
  identical FCB/DMA residue, rollback, reentrancy, or exact private state.
- **NOT REQUIRED:** DRI internal dispatch layout, Functions 38/39 as services,
  later-system selector meanings, and exact private error implementation.
- **POLICY PENDING:** Function 37 and optional extension selector consumption.

## 15. Proposed ledger additions

The authoritative ledger ends at 0601; the next available entry is 0602.

### Proposed Compatibility Ledger additions

0602. Function 40 selector and input

    BDOS Function 40 is Random Write with Zero Fill. It takes DE pointing to an
    activated FCB whose random-record fields select the target, and writes the
    128-byte record from the current DMA address.

    Disposition: REQUIRED
    Evidence: I037; BDOS; FILE; AG
    Conformance: Open or create a controlled file, select a random record in the
    FCB, set DMA, call Function 40, and verify the target record.

0603. Function 40 allocation-block zero fill

    When Function 40 allocates a physical allocation block for a target random
    record, unwritten records in that newly allocated block preceding the target
    are written as zero-filled 128-byte records.

    Disposition: REQUIRED
    Evidence: I037; BDOS; FILE; AG
    Conformance: Write record 10 of a new file on a multi-record allocation-block
    disk and verify preceding record 9 reads successfully as 128 zero bytes.

0604. Function 40 is not universal sparse-hole materialization

    Function 40 does not guarantee that every logical hole before a distant target
    record becomes allocated or readable; zero fill is bounded by allocation-block
    processing and configured file-system geometry.

    Disposition: NOT GUARANTEED
    Evidence: I037; BDOS; FILE; IG; AG
    Conformance: Vary allocation-block size and distant target records; applications
    shall not require holes outside allocated blocks to read as zeros.

0605. Function 40 result family

    Function 40 returns the CP/M 2.2 random-write result family, including zero on
    success, 02h when storage is unavailable, and 06h when the 24-bit random record
    is outside the supported range.

    Disposition: REQUIRED
    Evidence: I037; BDOS; FILE; IG; AG
    Conformance: Test success, exhausted storage, and nonzero R2 overflow with
    controlled images and verify the corresponding codes.

## 16. Existing-entry updates

No ledger was modified. Proposed evidence updates:

- random-access entries from I013: add I037 Function 40 evidence and distinguish
  allocation-block zero fill from ordinary Function 34 sparse behavior;
- **0404-0408:** add I037 logical Function 40 success/overflow/full evidence;
- **0518-0525:** add coverage-audit confirmation; retain Function 37 policy and
  Function 39 NOT REQUIRED conclusions;
- **0526-0533:** add REGISTER37/DMA37 consolidation evidence without promoting
  residual registers or a universal invalid-parameter rule;
- protection entries from I014: record the remaining Function 40-specific
  protection test as open; do not infer it from the normal matrix;
- no duplicate entries are proposed for already complete selectors 0-39.

## 17. Open questions

1. Should BetterCP/M strict mode implement undocumented Function 37, and with
   exactly DRI's simultaneous login/read-only vector clearing?
2. Should a separate extension mode consume selectors above 40 while strict mode
   retains zero returns?
3. Does Function 40 under file/disk write protection produce precisely the same
   public FCB and return behavior as Function 34 on every tested boundary?
4. Which preserved application corpus, if any, demonstrates dependency on void
   results or register residue currently classified NOT GUARANTEED?

## 18. Conformance implications

A baseline conformance suite can now enumerate 0-40 with a per-function contract
matrix rather than treating BDOS as one generic call. It must test success,
documented boundaries and failures; snapshot only relevant FCB/DMA/state; poison
unpromised registers; and distinguish logical returns from physical-error handling.

Function 40 needs geometry-aware tests: choose a target within a newly allocated
multi-record block, verify zero-filled predecessors in that block, then separately
test extent crossing, R2 overflow and disk full. It must not demand that all sparse
holes be allocated. Policy tests for Function 37 and extensions must be kept out of
the strict baseline until decided.

### Completion audit

The report, coverage map, five required probe sources/binaries, listings, README,
observed output, transcript, before/after images, references, scripts and hashes are
present. All five binaries rebuild byte-identically. The authoritative ledger was
read but not modified. The protected-tree manifest is verified before installation;
no prior investigation or BetterCP/M implementation file was changed.

