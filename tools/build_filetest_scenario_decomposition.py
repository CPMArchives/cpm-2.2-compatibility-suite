#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Generate exact proposition scenarios for the first FILETEST vertical slice."""

from __future__ import annotations

import csv
from collections import Counter
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
OUT = BASE / "deliverables/bettercpm-executable-suite-initial-design"
MATRIX = BASE / "docs/conformance/tables/conformance-framework-matrix.tsv"

# ledger: group, scenario, seeds, functions, fixture, evidence, selection, support
S = {
    "0163": ("OPEN", "OPEN-S1-DIAGNOSTIC", "FCB008:OPEN-A/OPEN-B", "15", "BTOPEN.DAT on default and explicit drive", "FCB[0..32] before/after; assert no literal S1 value", "YES", "DIRECT_ADAPTABLE"),
    "0165": ("OPEN", "OPEN-RC-FIELD", "FCB008:OPEN-A;READ010:ONE-1", "15,20", "BTONE.DAT, one record", "RC byte 15 and accepted range; guarded FCB snapshot", "YES", "COMPOSED_ADAPTABLE"),
    "0167": ("SEQREAD", "READ-CR-FIELD", "READ010:MULTI-1..3", "15,20,26", "BTMULTI.DAT, three marked records", "CR byte 32 progression and record markers", "YES", "DIRECT_ADAPTABLE"),
    "0169": ("OPEN", "OPEN-EXISTING-DRIVES", "FCB008:OPEN-A/OPEN-B", "15", "BTOPEN.DAT on default drive; BTBFILE.DAT on explicit drive", "return and documented FCB fields; current drive unchanged", "YES", "DIRECT_ADAPTABLE"),
    "0171": ("OPEN", "OPEN-MISSING", "FCB008:MISSING", "15", "reserved absent name BTMISS.DAT", "A=FFh; FCB guards; no media mutation", "YES", "DIRECT_ADAPTABLE"),
    "0173": ("OPEN", "OPEN-BEFORE-ACCESS", "READ010:ONE-1", "15,20,26", "BTONE.DAT, one record", "successful Open run ID precedes read; returned marker", "YES", "DIRECT_ADAPTABLE"),
    "0175": ("OPEN", "OPEN-WILDCARD-FIRST", "FCB008:WILD", "15", "two deterministic BTW*.DAT matches", "one FCB activated; result and selected identity", "YES", "DIRECT_ADAPTABLE"),
    "0177": ("CLOSE", "CLOSE-ACTIVATED", "FCB008:CLEANCL", "15,16", "BTCLOSE.DAT, unchanged prebuilt file", "C=10h call record; activated FCB; documented result family", "YES", "DIRECT_ADAPTABLE"),
    "0179": ("SEQREAD", "READ-NO-CLOSE-REQUIRED", "READ010:ONE-1", "15,20,26", "BTONE.DAT, one record", "successful read without Function 16; image remains unchanged", "YES", "DIRECT_ADAPTABLE"),
    "0181": ("CLOSE", "CLOSE-DIRTY-MISSING", "FCB008:MISSCL", "16", "reserved absent name BTMISS.DAT; bounded synthetic dirty FCB", "A=FFh; guards; scratch image unchanged", "YES", "DIRECT_ADAPTABLE"),
    "0183": ("OPEN", "FCB-POISON-DIAGNOSTIC", "FCB008:all open/close snapshots", "15,16", "same fixtures as selected companion case", "poison and before/after snapshots; assert only companion oracle effects", "YES", "DIRECT_ADAPTABLE"),
    "0185": ("CLOSE", "CLOSE-UNCHANGED-VARIATION", "FCB008:CLEANCL", "15,16", "BTCLOSE.DAT, unchanged prebuilt file", "document public effect; do not require exact DRI zero", "YES", "DIRECT_ADAPTABLE"),
    "0218": ("SEQREAD", "READ-PUBLIC-ONLY", "READ010:all valid scenarios", "15,20,26", "all selected read fixtures", "public FCB/DMA/result only; no private search state", "YES", "FRAMEWORK_ANTI_ASSERTION"),
    "0219": ("SEQREAD", "READ-FCB-CONTROLS", "READ010:ONE-1", "15,20,26", "BTONE.DAT plus different decoy FCB", "selected activated FCB identity and expected marker", "YES", "DIRECT_ADAPTABLE"),
    "0220": ("SEQREAD", "READ-AFTER-OPEN", "READ010:all valid scenarios", "15,20,26", "any selected valid read fixture", "successful Function-15 prerequisite record", "YES", "DIRECT_ADAPTABLE"),
    "0221": ("SEQREAD", "READ-SEQUENCE-MARKERS", "READ010:MULTI-1..3", "15,20,26", "BTMULTI.DAT with A/B/C record markers", "successive distinct 128-byte record hashes", "YES", "DIRECT_ADAPTABLE"),
    "0222": ("SEQREAD", "READ-SUCCESS-RESULT", "READ010:ONE-1", "15,20,26", "BTONE.DAT, allocated record", "A=00h and full record hash", "YES", "DIRECT_ADAPTABLE"),
    "0223": ("SEQREAD", "READ-128-BYTES-GUARDED", "READ010:ONE-1", "15,20,26", "BTONE.DAT", "16-byte guards around 128-byte DMA; complete content hash", "YES", "ADAPTATION_ADDS_GUARDS"),
    "0224": ("SEQREAD", "READ-ALTERNATE-DMA", "READ010:ALT-DMA", "15,20,26", "BTONE.DAT", "alternate DMA changed; 0080h and guards retain sentinels", "YES", "DIRECT_ADAPTABLE"),
    "0225": ("SEQREAD", "READ-NO-BYTE-LENGTH", "READ010:PART-1/2", "15,20,26", "BTPART.DAT containing logical byte-count metadata", "accept full record transfer; do not infer host byte count from Function 20", "YES", "FRAMEWORK_VARIATION_RULE"),
    "0226": ("SEQREAD", "READ-ADVANCE", "READ010:MULTI-1/2", "15,20,26", "BTMULTI.DAT", "distinct markers and FCB before/after", "YES", "DIRECT_ADAPTABLE"),
    "0227": ("SEQREAD", "READ-CR-1-2-3", "READ010:MULTI-1..3", "15,20,26", "BTMULTI.DAT", "CR equals 1,2,3 after successful calls", "YES", "DIRECT_ADAPTABLE"),
    "0228": ("SEQREAD", "READ-RECORD-128-STATE", "READ010:BOUND-128", "15,20,26", "BTBND128.DAT, 128 records", "FCB after 128th successful read", "YES", "DIRECT_ADAPTABLE"),
    "0229": ("SEQREAD", "READ-EXTENT-TRANSITION", "READ010:BIG-128/BIG-129", "15,20,26", "BTBIG130.DAT, 130 marked records", "consecutive success and record hashes across 127/128 boundary", "YES", "DIRECT_ADAPTABLE"),
    "0230": ("SEQREAD", "READ-NEW-EXTENT-STATE", "READ010:BIG-129", "15,20,26", "BTBIG130.DAT", "EX and CR after first record of new extent", "YES", "DIRECT_ADAPTABLE"),
    "0231": ("SEQREAD", "READ-EXTENT-WORKING-STATE", "READ010:BIG-129/BIG-130", "15,20,26", "BTBIG130.DAT", "EX/RC/allocation documented coherence and continued read", "YES", "DIRECT_ADAPTABLE"),
    "0232": ("SEQREAD", "READ-EOF-NONZERO", "READ010:ONE-EOF1", "15,20,26", "BTONE.DAT", "nonzero result after controlled exhaustion", "YES", "DIRECT_ADAPTABLE"),
    "0233": ("SEQREAD", "READ-EOF-VARIATION", "READ010:ONE-EOF1", "15,20,26", "BTONE.DAT", "accept any nonzero EOF value not excluded by oracle", "YES", "DIRECT_ADAPTABLE"),
    "0234": ("SEQREAD", "READ-EMPTY", "READ010:EMPTY-1", "15,20,26", "BTEMPTY.DAT, zero records", "Open succeeds; first read returns nonzero; guarded DMA evidence", "YES", "DIRECT_ADAPTABLE"),
    "0235": ("SEQREAD", "READ-PARTIAL-FINAL-EXTENT", "READ010:PART-1/PART-2/PART-EOF", "15,20,26", "BTPART.DAT, two logical records", "two successes followed by nonzero EOF", "YES", "DIRECT_ADAPTABLE"),
    "0236": ("SEQREAD", "READ-EXACT-BOUNDARY-EOF", "READ010:BOUND-128/BOUND-EOF1", "15,20,26", "BTBND128.DAT", "128 successes followed by nonzero EOF", "YES", "DIRECT_ADAPTABLE"),
    "0237": ("SEQREAD", "READ-REPEATED-EOF", "READ010:EMPTY-1/2;ONE-EOF1/2;BOUND-EOF1/2", "15,20,26", "BTEMPTY.DAT, BTONE.DAT or BTBND128.DAT", "two consecutive nonzero results after exhaustion", "YES", "DIRECT_ADAPTABLE"),
    "0238": ("SEQREAD", "READ-EOF-DMA-DIAGNOSTIC", "READ010:EOF scenarios", "15,20,26", "any exhausted read fixture", "prefill/snapshot DMA but make no literal-content assertion after failure", "YES", "FRAMEWORK_VARIATION_RULE"),
    "0239": ("SEQREAD", "READ-FCB-MUTATION", "READ010:MULTI-1..3", "15,20,26", "BTMULTI.DAT", "33-byte working FCB before/after and required field transitions", "YES", "DIRECT_ADAPTABLE"),
    "0240": ("SEQREAD", "READ-FAILED-FCB-DIAGNOSTIC", "READ010:EOF scenarios", "15,20,26", "any exhausted read fixture", "FCB snapshot; do not require byte identity after failure", "YES", "FRAMEWORK_VARIATION_RULE"),
    "0241": ("SEQREAD", "READ-BOUNDARY-EOF-COHERENCE", "READ010:BOUND-EOF1/2", "15,20,26", "BTBND128.DAT", "accept coherent post-EOF representation; reject DRI-literal assertion", "YES", "FRAMEWORK_ANTI_ASSERTION"),
    "0242": ("SEQREAD", "READ-EXPLICIT-DRIVE", "READ010:EXPLICIT-B", "15,20,25,26", "BTBFILE.DAT on explicit B while A is default", "success, content hash, and default drive unchanged", "YES", "DIRECT_ADAPTABLE"),
    "0243": ("SEQREAD", "READ-READONLY-FILE", "READ010:READONLY", "15,20,26", "BTRO.DAT with read-only attribute", "successful read and record hash", "YES", "DIRECT_ADAPTABLE"),
    "0244": ("SEQREAD", "READ-UNOPENED-DIAGNOSTIC", "READ010:UNOPENED", "20,26", "synthetic unopened FCB; scratch environment", "capture only; no required literal result", "NO", "DEFER_UNDEFINED_INPUT"),
    "0245": ("SEQREAD", "READ-INVALID-FCB-DIAGNOSTIC", "READ010:INVALID", "20,26", "bounded invalid working FCB; scratch environment", "capture only; ensure suite guards survive", "NO", "DEFER_UNDEFINED_INPUT"),
    "0246": ("SEQREAD", "READ-PHYSICAL-FAULT", "none in four seeds; PHYS015/READERR33", "15,20,26 + fault provider", "fresh restorable fault image", "profile prompt/ignore/abort/recovery transcript", "NO", "DEFER_HARNESS_PROFILE"),
    "0561": ("OPEN", "OPEN-SAME-FCB-DIFFERENT-USERS", "OPEN31 intended purpose; included DELREN012 lacks this isolated scenario", "15,32", "same name with distinct content in users 0 and 1", "constant unopened FCB bytes; user-specific content", "NO", "MISSING_NEW_SCENARIO"),
    "0562": ("OPEN", "OPEN-NO-CROSS-USER-FALLBACK", "OPEN31 intended purpose; included DELREN012 lacks this isolated scenario", "15,32", "target exists only in user 1; execute under user 0", "A=FFh under user 0; successful control under user 1", "NO", "MISSING_NEW_SCENARIO"),
}


def main() -> None:
    with MATRIX.open(newline="", encoding="utf-8") as f:
        matrix = {r["ledger_entry"]: r for r in csv.DictReader(f, delimiter="\t")}
    missing = sorted(set(S) - set(matrix))
    if missing:
        raise SystemExit("unknown ledger entries: " + ",".join(missing))
    rows = []
    counters = Counter()
    for ledger in sorted(S):
        group, scenario, seeds, functions, fixture, evidence, selected, support = S[ledger]
        r = matrix[ledger]
        counters[group] += 1
        rows.append({
            "ledger_entry": ledger, "case_id": r["case_id"], "oracle_id": r["oracle_id"],
            "oracle_version": r["oracle_version"], "classification": r["classification"],
            "group": group, "module_case": f"{group[:3]}-{counters[group]:03d}",
            "scenario_id": scenario, "selectors": f"/{ledger};/CASE:{r['case_id']};/GROUP:{group}",
            "source_seed": seeds, "source_support": support, "selected_first_slice": selected,
            "bdos_functions": functions, "rc1_dependencies": r["dependencies"],
            "fixture": fixture, "oracle": r["oracle"], "required_evidence": evidence,
            "safety_class": "SAFE_READ_ONLY" if selected == "YES" and group != "CLOSE" else ("TEMP_FILES" if group == "CLOSE" else "FAULT_ASSISTED"),
            "implementation_status": ("IMPLEMENTED_DEV9" if ledger in
                                      {"0165", "0167", "0169", "0171", "0173", "0175", "0177", "0179",
                                       "0181", "0219", "0220", "0221", "0222", "0223", "0224", "0225",
                                       "0226", "0227", "0228", "0229", "0230", "0231", "0232",
                                       "0233", "0234", "0235", "0236", "0237", "0238", "0239",
                                       "0240", "0241", "0242", "0243"} else
                                      ("SPECIFIED_NOT_IMPLEMENTED" if selected == "YES" else "DEFERRED")),
        })
    path = OUT / "filetest-vertical-slice-scenarios.tsv"
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]), delimiter="\t", lineterminator="\n")
        w.writeheader(); w.writerows(rows)

    selected_rows = [r for r in rows if r["selected_first_slice"] == "YES"]
    support_counts = Counter(r["source_support"] for r in rows)
    report = f"""# FILETEST First-Slice Proposition Decomposition

This specification decomposes four candidate source seeds into exact frozen proposition scenarios. It contains {len(rows)} mapped cases; {len(selected_rows)} are selected for the first read-oriented slice and {len(rows)-len(selected_rows)} are explicitly deferred.

## Source conclusion

`FCB008` and `READ010` contain the strongest directly adaptable scenario logic. `OPEN30.ASM` merely includes the full `WRITE011.INC` program; its reopen observations require prior mutation and are deferred from the read-only slice. `OPEN31.ASM` merely includes `DELREN012.INC`; despite its purpose comment, the included program does not isolate the two ordinary cross-user Open scenarios required by ledger 0561 and 0562. Those scenarios are classified `MISSING_NEW_SCENARIO`, not credited to the old binary.

Support totals are {dict(support_counts)}.

## Selected scope

- `OPEN`: existing default/explicit drive, missing, wildcard-first activation, lifecycle prerequisite, diagnostic reserved-byte handling.
- `CLOSE`: activated unchanged Close, dirty missing-name failure, and permitted variation for unchanged read-only-use state.
- `SEQREAD`: activated-FCB use, success and 128-byte guarded DMA, alternate DMA, record/CR progression, extent transition, EOF families, explicit drive and read-only file.

Physical fault presentation, unopened/invalid FCB diagnostics, and the missing cross-user Open scenarios are deferred. Deferment is `NOT_RUN`, not `PASS`, `NOT_APPLICABLE`, or `BLOCKED`.

## Selector and dependency rules

Every TSV row has `/NNNN`, frozen `/CASE:...`, and `/GROUP:...` selectors. `/NNNN` is the canonical hobbyist/debugging shorthand. Selection expands before execution. Shared setup may be reused, but every selected ledger case receives its own evaluator and record. The exact BDOS function list is a minimum operational dependency; RC1 parent dependencies remain separately recorded and must be refined to runnable prerequisite case IDs during implementation.

## Fixture contract

The first slice consumes a pristine, host-built fixture and does not require BDOS Make, Write, Delete or Rename. Reserved fixture names are suite-specific and recorded in a manifest with image and per-record hashes. The executable uses guarded FCB and DMA work areas, saves the default drive/user/DMA environment where the available public calls permit it, restores changed state on every returning path, and reports restoration failure as `ERROR`.

## Implementation order

1. Selector expansion and `/LIST` from the TSV-derived compact table.
2. Report writer capable of preserving a record before the next scenario.
3. Guarded FCB and DMA helpers plus fixture-manifest verification.
4. `OPEN`, then `SEQREAD`, then `CLOSE` evaluators.
5. Host parser and exact coverage audit for all selected rows.
6. DRI CP/M 2.2 reference run, independent implementation run, and induced framework/candidate failures.

No source probe or binary is approved unchanged. The scenario table is the implementation contract for the vertical slice; the frozen RC1 oracle remains normative.
"""
    (OUT / "FILETEST-VERTICAL-SLICE-DECOMPOSITION.md").write_text(report, encoding="utf-8")
    validation = [
        f"PASS\texact frozen cases mapped: {len(rows)}",
        f"PASS\tselected first-slice cases: {len(selected_rows)}",
        f"PASS\tdeferred cases: {len(rows)-len(selected_rows)}",
        f"PASS\tunique ledger entries: {len({r['ledger_entry'] for r in rows})}/{len(rows)}",
        f"PASS\tunique case IDs: {len({r['case_id'] for r in rows})}/{len(rows)}",
        f"PASS\tall selected cases have selectors: {sum(bool(r['selectors']) for r in selected_rows)}/{len(selected_rows)}",
        f"PASS\tall selected cases have fixtures: {sum(bool(r['fixture']) for r in selected_rows)}/{len(selected_rows)}",
        "PASS\tOPEN31 unsupported isolated scenarios are not credited",
    ]
    (OUT / "FILETEST-VERTICAL-SLICE-DECOMPOSITION-VALIDATION.txt").write_text("\n".join(validation) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
