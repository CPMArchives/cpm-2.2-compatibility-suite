# Investigation 066 - CP/M 2.2 Physical Fault and Recovery Validation

## 1. Objective and scope

This investigation validates the CP/M 2.2 compatibility boundary for physical storage faults, error propagation, operator recovery, repeated failure, unavailable media, and a write which reaches media before an error is reported. It is an evidence investigation only: it neither changes the Compatibility Ledger nor proposes a BetterCP/M storage architecture.

Evidence is labelled A (published interface), B (Digital Research implementation), I (experiment), or D (unresolved policy). The experimental platform is z80pack cpmsim 1.39 with the Z80 CBIOS 1.2 and unmodified CP/M 2.2 system software. An isolated emulator copy supplies deterministic fault injection; it is test instrumentation, not a CP/M interface.

The required ledger evidence identifier is `I066 STORAGE FAULT RECOVERY subsystem IG AG`.

## 2. Relationship to previous investigations

Investigation 015, not 014, is the archive's physical-disk-error investigation; the prompt's Investigation 014 title is inconsistent with the archive. Investigation 014 covers read-only state and protection and was reviewed for that distinction. Investigation 019 established BIOS logical-sector contracts. Investigation 033 established BDOS/BIOS propagation and recovery. Investigations 052 and 062 established regression and pilot-conformance methods. The authoritative ledger through Investigation 065 already incorporates their propositions.

I066 adds direct repeated-failure, unavailable-media, recovery, and write-then-error observations. It does not repeat every I015 operation-specific injection. Its decisive new evidence strengthens existing entries rather than creating duplicate propositions.

## 3. Fault scenario inventory

The validation matrix contains:

- normal operation: T01 successful sequential read;
- injected pre-transfer failure: T02 read and T03 write;
- repeated failure: T04 three separately injected faults followed by a healthy read;
- recovery attempts: T05 ignore and continue, T06 control-C abort and warm recovery;
- unavailable media: T07 explicit drive B with no attached B image;
- completion-before-error boundary: T08 ignore and T09 abort after a complete physical sector write followed by reported failure.

T08/T09 model one legitimate uncertainty boundary: media changed before failure became visible. They do not simulate or prove a torn or partially written sector, controller cache behavior, power loss, directory corruption, or allocation corruption.

## 4. Documentation findings

**A.** The CP/M 2.2 Alteration Guide defines CBIOS READ and WRITE as one-sector operations using selected disk, track, sector, and DMA state. Zero denotes success and nonzero denotes nonrecoverable error. It assigns recoverable-error retry to the BIOS, recommends at least ten attempts, and documents the BDOS `BAD SECTOR` intervention with carriage return to ignore or control-C to abort. The WRITE description adopts the READ error convention.

**A.** The CP/M 2.0 Interface Guide defines logical BDOS results (for example EOF/unwritten data and disk-full/directory outcomes), but does not define a physical-controller result returned to the file-call caller. It does not promise atomic sector writes, rollback, post-failure DMA/FCB validity, directory or allocation consistency after physical failure, or a finite response for unavailable hardware.

**A.** Documentation therefore supports a CP/M-visible error/recovery boundary while leaving media-specific failure progression and post-failure persistence unspecified.

## 5. Source findings

**B.** In the DRI BDOS source, the low-level read/write completion test returns only for zero BIOS status. Nonzero status enters the permanent-error path. That path prints a drive-qualified `Bad Sector` diagnostic and reads an operator character. Control-C enters the reboot path; another character resumes the interrupted higher-level path. BDOS does not translate the physical status into one of the file function's logical return codes.

**B.** Resuming after ignore can allow higher-level code to update FCB state and return its ordinary-looking result despite the failed transfer. The DRI routine names, addresses, stack path, flags, diagnostic typography, and exact reboot internals are implementation details unless separately required by visible behavior.

**B.** Retry mechanics remain a BIOS responsibility. The source establishes dispatch and control flow, but it cannot establish the range of real-media completion states; T08/T09 provide experimental evidence for that boundary.

## 6. Error propagation analysis

**REQUIRED (A/B/I):** BIOS READ/WRITE communicates physical success as zero and nonrecoverable failure as nonzero. BDOS consumes that status and suspends ordinary caller completion while presenting the physical-error intervention.

**REQUIRED (A/I):** Physical failure is distinct from ordinary BDOS logical results. In T02/T03 the intervention appeared; after ignore the caller printed `RETURNED 00`. That zero did not prove data transfer or persistence.

**NOT GUARANTEED (A/B/I):** An application cannot infer a particular controller cause, retry count, DMA validity, FCB validity, media state, or persistence from an ignored physical error or from the apparent BDOS result afterward.

**NOT REQUIRED (B):** A compatible implementation need not reproduce DRI's private dispatch routines or preserve a hardware-specific nonzero status beyond the specified BIOS/BDOS boundary.

## 7. Recovery behavior analysis

**REQUIRED (A/I):** The operator path permits ignore and control-C abort. T05 showed that ignore resumed the caller and that a later directory search and normal read succeeded. T06 showed that control-C abandoned the caller (no `RETURNED` line), established `A>`, and allowed the same subsequent operations.

**REQUIRED (I; existing ledger scope):** Abort recovery establishes a usable command environment. This is an externally observable result, not a promise about exact memory, drive-login internals, open FCBs, or stack state.

**NOT GUARANTEED (A/I):** T04 showed that separate failures can produce separate interventions and that later healthy I/O can succeed. T07 showed repeated interventions for unavailable drive-B media, but the automated run did not reach a confirmed CCP recovery before its timeout. CP/M does not guarantee a particular prompt count, delay, automatic abandonment, or eventual success while media remains unavailable.

**NOT REQUIRED (A/B):** Exact controller retries, delays, recalibration, cache management, and device-reset algorithms belong to the BIOS/storage profile, subject to the documented BIOS recovery duty.

## 8. File-system consistency analysis

T01-T07 left their restored drive-A images byte-identical. These controls show that the selected pre-transfer injector did not alter media; they do not create a general no-change guarantee.

In T08, the instrumented controller completed the selected 128-byte physical write and then returned a nonzero status. BDOS displayed `Bad Sector`; ignore resumed the caller with `00`. The image changed, and extracted `CLOSEME.DAT` contained 128 bytes of `50h` (`P`). In T09 the same write occurred, control-C abandoned the caller, and the post-run image and extracted file were byte-identical to T08.

**NOT GUARANTEED (I):** Neither ignore nor abort rolls media back. A physical-error report does not prove that the attempted transfer made no change. CP/M 2.2 promises neither transactionality nor atomic rollback across data, directory, and allocation structures.

**NOT GUARANTEED (A):** Directory and allocation consistency after failures at other points remain device- and timing-dependent. I066 did not inject torn sectors or directory/allocation writes and makes no observation about them.

## 9. Experimental results

All tests began from the same restored `base066.dsk`. The complete records are in `probes/fault-validation-records.tsv`; transcripts and before/after images are in `probes/cases/`.

| Test | Scenario and operation | Observation | Compatibility conclusion |
|---|---|---|---|
| T01 | Normal sequential read | Returned 00; DMA first byte 41h; image unchanged | Normal control |
| T02 | Pre-transfer sequential-read failure; ignore | `Bad Sector`; returned 00; DMA sentinel EEh remained; image unchanged | Result is not transfer validation |
| T03 | Pre-transfer sequential-write failure; ignore | `Bad Sector`; returned 00; image unchanged | Result is not persistence validation |
| T04 | Read/write/read failures, then healthy read | Three interventions; each ignored call returned 00; healthy read returned 00/41h | Repeated faults remain interventions; recovery is possible after fault removal |
| T05 | Ignore then directory/read recovery | Caller returned; DIR and normal read succeeded | Ignore can resume, but affected state is not guaranteed |
| T06 | Control-C then directory/read recovery | Caller abandoned; `A>` returned; DIR and normal read succeeded | Usable command recovery is required |
| T07 | Explicit B with unavailable media | Repeated drive-B `Bad Sector` interventions; harness timed out after two captured prompts; no application return | Prompt count/timing and availability recovery are profile-dependent; post-abort result not claimed |
| T08 | Write completed physically, error reported; ignore | Returned 00; image changed; file became 128 `P` bytes | Failure and media change can coexist; no rollback/atomicity guarantee |
| T09 | Same completion-before-error; control-C | Caller abandoned; image/file equal T08 | Abort restores execution control, not prior media state |

Baseline image SHA-256 was `24677b906a0a58ed259892d8f95efa8df3fe32f14bb05ca7cddb5371d6be5e34`. T08/T09 image SHA-256 was `e6294c9fdba0abef6ab57ae361dcbb67bb45b9d001a2d757de86f297a4a767c0`. Baseline `CLOSEME.DAT` was `3941d04d249c019df8e2ade684bb894be1b6ad3b17a4378536be3f005088d091`; T08/T09 extracted files were `f16ef3e254ffb74b7e3c97d99486ef8c549e4c80bc6dfed7fe8c5e7e76f4fbcd`.

## 10. Compatibility conclusions

The existing CP/M 2.2 physical-fault boundary is sufficiently understood for compatibility-specification release.

- **REQUIRED:** BIOS zero/nonzero physical result contract; BIOS recovery responsibility; separation from BDOS logical results; operator-visible physical-error intervention; ignore and abort choices; abort abandonment of the caller; establishment of a usable command environment after abort.
- **NOT GUARANTEED:** ordinary-looking result after ignore; affected DMA/FCB state; persistence or non-persistence; sector, directory, or allocation atomicity; rollback after ignore or abort; exact state after recovery; finite behavior while unavailable media remains unavailable.
- **NOT REQUIRED:** DRI private routines and exact internal state; hardware-specific status values; private retry/reset algorithms; the I066 injection port; transactional recovery absent an explicit storage-profile promise.
- **POLICY PENDING:** exact diagnostic typography and accepted ignore characters; optional structured/headless error handling; optional storage profiles that promise stronger guarantees while preserving strict CP/M behavior.

No additional general validation is required before releasing this compatibility boundary. Device-specific profiles and optional extensions require their own tests if adopted.

## 11. Proposed ledger additions

No new compatibility propositions are proposed. Entries 0390-0403 and 0581-0588 already express the independently testable requirements and non-guarantees. Adding I066 restatements would duplicate them.

## 12. Existing-entry updates

Do not modify the ledger as part of this investigation. At the next authorized ledger-integration step, add evidence identifier `I066 STORAGE FAULT RECOVERY subsystem IG AG` as follows:

- strengthen 0398 and 0400 with T02/T03/T08: a normal-looking post-ignore result does not validate transfer or persistence;
- strengthen 0403 with T08/T09: direct experimental evidence that a reported physical write failure can coexist with a changed sector/file;
- strengthen 0585 with T05/T08: continuation does not define the affected state;
- strengthen 0586 and 0587 with T06/T09: abort abandons the caller and restores a usable command environment, while media is not rolled back;
- optionally cross-reference 0394-0396 and 0581 for the repeated operator-path observations.

No classification correction is warranted. In particular, 0403 remains `NOT GUARANTEED`, and the exact recovery internals remain `NOT REQUIRED` under 0588.

## 13. Open questions

**D / POLICY PENDING:** Must strict mode reproduce exact `Bdos Err On x: Bad Sector` capitalization, spacing, and accepted ignore characters?

**D / POLICY PENDING:** Should a headless or hosted profile offer structured physical-error reporting, and how is it kept distinct from the strict CP/M path?

**D / POLICY PENDING:** Should any named BetterCP/M storage profile promise stronger atomicity, rollback, or bounded unavailable-media behavior? Such promises would be profile features, not baseline CP/M 2.2 compatibility.

**D:** Historical cross-BIOS measurements could characterize retry delays and unavailable-media loops, but would not alter the baseline boundary without evidence of software dependency.

## 14. Conformance implications

A baseline conformance suite should verify the BIOS zero/nonzero boundary, physical/logical separation, intervention, ignore, abort, caller abandonment, and usable post-abort command environment. It should verify that applications are not promised valid DMA, trustworthy success, unchanged media, rollback, or exact recovery state after physical failure.

The suite should use at least a pre-transfer failure and a completion-before-error case. The latter may be a complete write followed by error, as here; a torn-sector test belongs to a concrete storage profile. It should not require the I066 port numbers, z80pack controller statuses, exact retry mechanism, or exact DRI internals.

Audit: the investigation directory, report, prompt, probe source/binary/listing, isolated emulator source/binary, scripts, nine case records, console transcripts, preserved before/after images, extracted files, and hashes are present. `FAULT066.COM` rebuilds byte-identically. The authoritative ledger SHA-256 remains `7ecdd6cd7d2dd2fa25d7883dfdf0b232fd4e91380f82b036b664eda05837a241`. The protected-tree before/after manifests compare identically after excluding the newly created Investigation 066 directory. No prior investigation, ledger, or BetterCP/M implementation file was modified.
