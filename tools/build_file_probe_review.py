#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Generate the source-reviewed FILE/DIR/DISK probe-reuse deliverable."""

from __future__ import annotations

import csv
from collections import Counter
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
DELIV = BASE / "deliverables/bettercpm-executable-suite-initial-design"

# This is a source-level reuse decision, not a claim that a probe already
# implements every child case of the named parent scope.
GROUPS = [
    ("008", "FCB008", "BDOS-FILE-001;BDOS-FILE-011", "ADAPTABLE", "TEMP_FILES", "Functions 15/16; dumps 33 FCB bytes for existing, missing, wildcard, explicit-drive, extent, clean/dirty Close cases.", "Split scenarios; replace raw dump with guarded, oracle-specific records; use reserved fixtures."),
    ("009", "DSRCH009", "BDOS-FILE-003", "ADAPTABLE", "SAFE_READ_ONLY", "Functions 17/18/26; exact, wildcard, repeated, alternate-DMA, drive-change and all-user searches; dumps full DMA.", "Preserve enumeration scenarios; add DMA guards, bounded selectors and fixture hash validation."),
    ("010", "READ010", "BDOS-FILE-004", "ADAPTABLE", "SAFE_READ_ONLY", "Functions 15/20/26 across empty, single, partial, 128/129-record, explicit-drive, read-only and invalid/unopened FCB scenarios.", "Strong vertical-slice seed; isolate scenarios and replace console dump with case records and prebuilt fixtures."),
    ("011", "WRITE011", "BDOS-FILE-002;BDOS-FILE-005;BDOS-FILE-011", "ADAPTABLE", "SCRATCH_DESTRUCTIVE", "Functions 15/16/17/20/21/22/26; Make, sequential write, boundary, reopen, directory-full and disk-full scenarios.", "Reuse scenario logic only; require dedicated restored image, reserved names, per-case cleanup and early report persistence."),
    ("012", "DELREN012", "BDOS-FILE-006;BDOS-FILE-007;BDOS-FILE-011", "ADAPTABLE", "SCRATCH_DESTRUCTIVE", "Functions 15/16/17/19/21/22/23; single/wildcard delete, rename variants, explicit drive and user isolation.", "Split delete and rename ownership into DIRTEST; verify allocation restoration with image diffs."),
    ("013", "RAND013", "BDOS-FILE-008;BDOS-FILE-012", "ADAPTABLE", "SCRATCH_DESTRUCTIVE", "Functions 15/16/22/26/33-36/40; random position/read/write, size, sparse and boundary/full-disk cases.", "Retain deterministic positions; separate zero-fill, permitted sparse variation, and full-disk harness cases."),
    ("014", "PROT014", "BDOS-FILE-009", "ADAPTABLE", "INTERACTIVE", "Read-only file/drive protection operations and DRI-style presentation paths.", "Separate portable refusal semantics from selected DRI interactive profile; require recovery and cleanup records."),
    ("015", "PHYS015", "ERROR-002;ERROR-003", "HARNESS_REQUIRED", "FAULT_ASSISTED", "Physical disk error and presentation probe; cannot deterministically provoke the condition through portable CP/M alone.", "Keep transient caller logic; replace investigation-only injection assumptions with declared fault-provider API."),
    ("017", "STATE017", "BIOS-006;BDOS-STATE-003", "ADAPTABLE", "SAFE_READ_ONLY", "Inspects disk state, allocation vector and DPB returned through public interfaces.", "Move structure checks to DISKTEST/BIOSTEST; validate coherence, never fixed private addresses."),
    ("025", "OPEN25", "BDOS-FILE-001;ERROR-001", "ADAPTABLE", "TEMP_FILES", "Open failures: missing, user-isolated, wildcard, unavailable and invalid drive.", "Split returning failures from fatal invalid-drive presentation; gate the latter by profile/harness."),
    ("025", "WRITE25", "BDOS-FILE-002;BDOS-FILE-005;ERROR-001", "ADAPTABLE", "SCRATCH_DESTRUCTIVE", "Make/write against independently full directory and data resources.", "Use separately verified full-directory and full-allocation fixtures; do not conflate their verdicts."),
    ("025", "READ25", "BDOS-FILE-004;BDOS-FILE-008;ERROR-001", "ADAPTABLE", "TEMP_FILES", "Sequential and random logical failure cases.", "Use prebuilt EOF/unwritten fixtures; physical failures belong to fault-assisted modules."),
    ("025", "SEARCH25", "BDOS-FILE-003;ERROR-001", "ADAPTABLE", "SAFE_READ_ONLY", "No-match/search exhaustion and DMA observations.", "Merge scenario logic with DSRCH009/SEARCH29; keep a single canonical fixture and oracle evaluator."),
    ("025", "DISK25", "BDOS-FILE-009;ERROR-001", "ADAPTABLE", "INTERACTIVE", "Mutation attempts on a read-only drive.", "Require restorable scratch media; separate BDOS return behavior from DRI diagnostic presentation."),
    ("025", "FCB25", "BDOS-FILE-001;BDOS-FILE-011;ERROR-001", "ADAPTABLE", "TEMP_FILES", "Close using malformed or activated FCB state.", "Use bounded malformed inputs and guards; do not assert unspecified post-error bytes."),
    ("025", "FILEERR25", "ERROR-001", "ADAPTABLE", "SCRATCH_DESTRUCTIVE", "Composite missing-directory-operation and duplicate-Make failures.", "Decompose into single-fault cases so a fatal path cannot hide independent results."),
    ("029", "SEARCH29", "BDOS-FILE-003", "ADAPTABLE", "SAFE_READ_ONLY", "Exact/wildcard/restart/alternate-DMA/drive/all-user enumeration matrix.", "Preferred modern search seed; reconcile overlap with DSRCH009 and retain one implementation per scenario."),
    ("029", "MATCH29", "BDOS-FILE-003", "ADAPTABLE", "SAFE_READ_ONLY", "Exact, name/type wildcard, lowercase mismatch and multi-extent enumeration.", "Retain fixed-width matching cases; ensure lowercase is evaluated only under its frozen disposition."),
    ("029", "DMA29", "BDOS-FILE-003", "ADAPTABLE", "SAFE_READ_ONLY", "Captures complete 128-byte directory DMA record and selected slot.", "Strong guarded-DMA helper seed; add pre/post guards and slot-bound verification."),
    ("029", "STATE29", "BDOS-FILE-003", "ADAPTABLE", "SAFE_READ_ONLY", "Search sequence across Functions 12/25, DMA relocation and replacement by Search First.", "Preserve sequence-state cases individually; avoid asserting unspecified state after failure."),
    ("029", "USER29", "BDOS-FILE-003;BDOS-FILE-010", "ADAPTABLE", "SAFE_READ_ONLY", "User isolation plus special drive-byte '?' directory scan.", "Share multi-user fixture with Investigation 031 probes; restore original user on every exit."),
    ("029", "ERROR29", "BDOS-FILE-003;ERROR-001", "HARNESS_REQUIRED", "INTERACTIVE", "No-match/Next failures plus fatal invalid-drive DRI Select diagnostic.", "Returning no-match logic is adaptable; fatal invalid-drive scenario needs transcript harness and profile gate."),
    ("030", "CREATE30", "BDOS-FILE-005;BDOS-FILE-011", "ADAPTABLE", "TEMP_FILES", "Make/search/write/Close/reopen lifecycle.", "Use reserved files; emit separate records for creation, visibility, persistence and cleanup."),
    ("030", "GROW30", "BDOS-FILE-002;BDOS-FILE-005;BDOS-FILE-011", "ADAPTABLE", "SCRATCH_DESTRUCTIVE", "Growth at 1, 3, 128 and 129 records.", "Retain boundary scenarios; verify required transitions without demanding DRI allocation placement."),
    ("030", "EXTENT30", "BDOS-FILE-005;BDOS-FILE-011", "ADAPTABLE", "SCRATCH_DESTRUCTIVE", "Normal and one-slot extent-boundary growth/failure.", "Requires purpose-built near-full-directory fixture and image restoration."),
    ("030", "FCB30", "BDOS-FILE-008;BDOS-FILE-011;BDOS-FILE-012", "ADAPTABLE", "SCRATCH_DESTRUCTIVE", "Random overwrite, append, sparse and boundary lifecycle fields.", "Reuse public-field observations; exclude private/residual bytes from positive assertions."),
    ("030", "CLOSE30", "BDOS-FILE-002;BDOS-FILE-011", "ADAPTABLE", "TEMP_FILES", "Search before/after Close and omitted-Close comparison.", "Good persistence seed; use restored images so omitted Close does not contaminate later cases."),
    ("030", "OPEN30", "BDOS-FILE-001;BDOS-FILE-011", "ADAPTABLE", "SAFE_READ_ONLY", "Reopen/read persisted files and reconstruct usable FCB state.", "Preferred open vertical-slice seed with verified prebuilt fixture; compare only promised fields."),
    ("030", "FAIL30", "BDOS-FILE-002;BDOS-FILE-005;BDOS-FILE-011;ERROR-001", "ADAPTABLE", "SCRATCH_DESTRUCTIVE", "Directory, data and extension exhaustion.", "Split three resource failures; exact codes remain oracle-specific and profile-sensitive."),
    ("031", "USER31", "BDOS-FILE-010", "ADAPTABLE", "TEMP_FILES", "Function 32 user query/set/persistence/restoration.", "Use shared save/restore wrapper; a restoration failure is framework ERROR."),
    ("031", "VIS31", "BDOS-FILE-010", "ADAPTABLE", "SAFE_READ_ONLY", "Cross-user visibility and same-name isolation.", "Strong prebuilt-fixture case; no create dependency required."),
    ("031", "OPEN31", "BDOS-FILE-001;BDOS-FILE-010", "ADAPTABLE", "SAFE_READ_ONLY", "Open/read resolves only the current-user target.", "Merge with FILETEST open group using multi-user prebuilt fixture."),
    ("031", "SEARCH31", "BDOS-FILE-003;BDOS-FILE-010", "ADAPTABLE", "SAFE_READ_ONLY", "Ordinary current-user search and all-user scan.", "Merge with DIRTEST search group and restore user/DMA state."),
    ("031", "CREATE31", "BDOS-FILE-005;BDOS-FILE-010", "ADAPTABLE", "TEMP_FILES", "Make/recreate under current user with duplicate name in another user.", "Requires scratch fixture; keep current-user state changes explicit and reversible."),
    ("031", "RENAME31", "BDOS-FILE-007;BDOS-FILE-010", "ADAPTABLE", "TEMP_FILES", "Rename within current user while preserving identity.", "Move to DIRTEST; compare directory/user identity and allocation preservation."),
    ("031", "DELETE31", "BDOS-FILE-006;BDOS-FILE-010", "ADAPTABLE", "TEMP_FILES", "User-scoped delete and wildcard behavior.", "Move to DIRTEST; restore pristine image rather than depending on recreate cleanup."),
    ("033", "READERR33", "ERROR-002;ERROR-004", "HARNESS_REQUIRED", "FAULT_ASSISTED", "Injected sequential/random/directory read failures with prompt and DMA/FCB capture.", "Retain transient observer; require declared one-shot fault provider and fresh image per scenario."),
    ("033", "WRITEERR33", "ERROR-003;ERROR-004", "HARNESS_REQUIRED", "FAULT_ASSISTED", "Injected sequential/random/Make/Close write failures with image evidence.", "Fresh restored image and pre-transfer verification mandatory; never run on valuable media."),
    ("033", "DIRERR33", "ERROR-002;ERROR-003;ERROR-004", "HARNESS_REQUIRED", "FAULT_ASSISTED", "Injected Search directory-read and Delete directory-write failures.", "Keep in ERRTEST; one injected fault per case and verify no stale DMA is accepted."),
    ("033", "RECOVER33", "ERROR-004", "HARNESS_REQUIRED", "FAULT_ASSISTED", "Repeated failure, ignore/abort, warm-boot and later healthy operation.", "Requires transcript/controller harness and exact dependency run IDs."),
    ("033", "CCPERR33", "ERROR-004", "HARNESS_REQUIRED", "FAULT_ASSISTED", "CCP recovery scripts after BDOS/BIOS errors.", "Keep outside FILETEST; automated sequencing requires SUBMIT/host harness."),
    ("036", "DISK36", "BIOS-004;BIOS-006", "ADAPTABLE", "SCRATCH_DESTRUCTIVE", "Direct BIOS disk state sequence, sector translation, read and all write types.", "Use as BIOSTEST/DISKTEST boundary seed; require dedicated scratch disk and instrumented BIOS where needed."),
    ("036", "ERROR36", "ERROR-002;BIOS-004", "HARNESS_REQUIRED", "FAULT_ASSISTED", "One-shot pre-transfer BIOS read failure and BDOS presentation boundary.", "Fault-provider-only; do not make z80pack-specific status values normative."),
]


def main() -> None:
    inventory_path = DELIV / "existing-probe-inventory.tsv"
    with inventory_path.open(newline="", encoding="utf-8") as f:
        inventory = list(csv.DictReader(f, delimiter="\t"))
    by_key = {}
    for r in inventory:
        if r["kind"] not in {"ASM", "MAC"}:
            continue
        stem = Path(r["artifact"].split("!")[-1]).stem.upper()
        by_key[(r["investigation"], stem)] = r

    output = []
    missing = []
    for inv, probe, scope, decision, safety, behavior, work in GROUPS:
        src = by_key.get((inv, probe))
        if not src:
            missing.append(f"I{inv}:{probe}")
            continue
        output.append({
            "investigation": f"I{inv}", "probe": probe,
            "source_artifact": src["artifact"], "source_sha256": src["sha256"],
            "candidate_parent_scope": scope, "decision": decision,
            "safety_class": safety, "observed_source_behavior": behavior,
            "required_adaptation": work,
            "case_mapping_status": "PARENT_SCOPE_ONLY_SCENARIO_DECOMPOSITION_REQUIRED",
            "release_source_status": "NOT_APPROVED_UNTIL_ADAPTED_AND_REBUILT",
        })
    if missing:
        raise SystemExit("missing sources: " + ", ".join(missing))

    out_path = DELIV / "file-dir-disk-probe-reuse-matrix.tsv"
    with out_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(output[0]), delimiter="\t", lineterminator="\n")
        writer.writeheader(); writer.writerows(output)

    counts = Counter(r["decision"] for r in output)
    safety = Counter(r["safety_class"] for r in output)
    report = f"""# FILE/DIR/DISK Probe Review and FILETEST Vertical-Slice Specification

Status: source-level reuse triage complete for {len(output)} logical probes. This review does not approve an existing `.COM` as a conformance executable.

## Findings

Decision totals: {dict(counts)}. Safety totals: {dict(safety)}.

The archive contains strong experimental coverage, but the probes are not drop-in suite modules. They generally combine multiple scenarios, print raw state instead of verdict records, assume investigation-specific filenames/images, and lack suite-wide selection, guard, cleanup and aggregation behavior. `ADAPTABLE` means the scenario and observation logic are credible seeds. `HARNESS_REQUIRED` means deterministic execution also depends on fault injection, transcript control, or restart coordination unavailable through portable CP/M alone.

The TSV matrix records source hashes, actual source behavior, reuse decision, safety class and required work. Parent scope is deliberately conservative: it identifies frozen test families to which a probe may contribute, not a claim that the probe covers every child case. Exact proposition coverage must be assigned only after each monolithic probe is decomposed into independently evaluated scenarios.

## Corrected ownership direction

- `FILETEST.COM`: Open/Close/Make, sequential read/write, random access/size/zero-fill, extent and persistence lifecycle.
- `DIRTEST.COM`: Search First/Next and DMA directory records, user namespaces, rename and delete.
- `DISKTEST.COM`: DPB/DPH/allocation/read-only disk state and controlled capacity fixtures.
- `ERRTEST.COM`: fatal or injected read/write/directory errors and recovery workflows.
- `BIOSTEST.COM`: direct BIOS disk sequencing, sector translation and raw status; it supplies prerequisite evidence to higher-level file tests.

The preliminary 205-case FILETEST ownership is retired. The regenerated
627-case catalog assigns 142 cases to FILETEST, 72 to DIRTEST, and 20 to
DISKTEST; seven BDOS file-error cases move to ERRTEST. Direct BIOS scenarios
remain in BIOSTEST. Ownership is now explicit generator policy keyed by frozen
ledger identity rather than requirement-text keywords.

## First vertical slice

The first implementation slice is `FILETEST` open/close/sequential-read using verified prebuilt fixtures. It deliberately avoids requiring Make, Write, Delete or Rename, making it usable on an incomplete BDOS.

Candidate source seeds are `OPEN30`, `FCB008`, `OPEN31`, and `READ010`. The initial groups are:

1. `OPEN`: existing current-drive file, missing file, explicit-drive file, user-isolated file, wildcard/malformed cases only where their frozen oracle permits a deterministic verdict.
2. `CLOSE`: successfully opened unchanged file, promised FCB state/persistence only, and bounded malformed Close cases.
3. `SEQREAD`: empty, one-record, partial final record, repeated EOF, alternate DMA, exact 128-record boundary and 129-record transition.

Required interfaces for the slice:

```text
FILETEST /LIST
FILETEST /NNNN
FILETEST /CASE:<frozen-case-id>
FILETEST /FN:15
FILETEST /FN:16
FILETEST /FN:20
FILETEST /GROUP:OPEN
FILETEST /GROUP:CLOSE
FILETEST /GROUP:SEQREAD
FILETEST /SAFE
```

The selector expands to exact frozen case IDs before execution. Unselected cases are `NOT_RUN` coverage state, not result records. Missing functions block only dependent selected cases. `/NNNN` requires four digits and denotes a ledger entry.

## Fixture set

The pristine fixture contains reserved `BT` files for: empty, one-record, partial-record, 128-record, 129-record, explicit-drive and alternate-user cases. A host manifest records full image hash and per-file expected 128-byte record hashes. The read-only slice never constructs these fixtures through BDOS. Every run saves/restores current drive, user and DMA state where possible; inability to restore is `ERROR`.

## Implementation gate

The four seed probes are decomposed in the companion `filetest-vertical-slice-scenarios.tsv`, with exact ledger/case/oracle IDs, selectors, BDOS functions, fixtures and evidence. The next implementation work is shared report writing, selector expansion, guarded DMA/FCB snapshots, fixture verification and summary aggregation. The slice passes its development milestone only after reproducible build, DRI CP/M 2.2 reference execution, an independent CP/M implementation run, and deliberately exercised FAIL/BLOCKED/ERROR paths.

## Explicit gaps

- No existing probe is `REUSABLE` unchanged.
- Fault cases require a provider contract that does not yet exist.
- Exact executable ownership is complete for all 627 cases. Detailed runnable scenario decomposition is complete only for the four first-slice seeds; the remaining cases still require that implementation work.
- Future ownership changes require an explicit architecture decision and catalog regeneration.
"""
    (DELIV / "FILE-DIR-DISK-PROBE-REVIEW.md").write_text(report, encoding="utf-8")

    validation = [
        f"PASS\tlogical probes reviewed: {len(output)}",
        f"PASS\tsource hashes resolved: {sum(bool(r['source_sha256']) for r in output)}/{len(output)}",
        f"PASS\treuse decisions assigned: {dict(counts)}",
        f"PASS\tsafety classifications assigned: {sum(bool(r['safety_class']) for r in output)}/{len(output)}",
        "PASS\tno probe approved unchanged",
    ]
    (DELIV / "FILE-DIR-DISK-PROBE-REVIEW-VALIDATION.txt").write_text("\n".join(validation) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
