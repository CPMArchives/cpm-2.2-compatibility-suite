#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Build the BetterCP/M executable-suite design and inventory deliverables."""

from __future__ import annotations

import csv
import hashlib
import re
import sys
import zipfile
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RC1 = ROOT / "docs"
TABLES = RC1 / "conformance/tables"
LEDGER = RC1 / "ledger/Compatibility Ledger.txt"
OUT = ROOT / "deliverables/bettercpm-executable-suite-initial-design"


def rows(path: Path):
    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f, delimiter="\t"))


def detailed_ledger_requirements() -> dict[str, str]:
    """Recover proposition wording omitted by the compact matrix summary."""
    text = LEDGER.read_text(encoding="utf-8")
    starts = list(re.finditer(r"(?m)^(\d{4})\.[^\n]*\n", text))
    result: dict[str, str] = {}
    for index, match in enumerate(starts):
        end = starts[index + 1].start() if index + 1 < len(starts) else len(text)
        block = text[match.end():end]
        body = re.split(r"(?m)^\s*Disposition:\s*", block, maxsplit=1)[0]
        wording = " ".join(line.strip() for line in body.splitlines() if line.strip())
        if wording:
            result[match.group(1)] = wording
    return result


DIRECTORY_LEDGER = (
    set(range(285, 317))          # Delete and Rename, including directory effects
    | set(range(356, 368))        # attributes and Function 30 directory metadata
    | {370, 371}                  # file read-only Delete/Rename protection
)

DISK_LEDGER = {
    155,                          # Function 13 disk reset state preservation
    255, 275, 276,                # controlled full-disk/allocation failures
    292, 293,                     # allocation release and reuse
    355,                          # physical allocation versus virtual size
    *range(373, 385),             # vectors, reset, and disk write protection
    558,                          # allocation order is not a compatibility contract
}

ERROR_LEDGER = {246, 283, 314, 354, 385, 386, 387}


def module_for(ledger: str, parent: str, requirement: str) -> str:
    if any(k in requirement.lower() for k in ("processor", "8080-compatible", "z80 extensions", "instruction semantics")):
        return "CPUTEST.COM"
    if parent.startswith("BDOS-CON") or parent.startswith("COMM"):
        return "CONSTEST.COM"
    if parent.startswith("BDOS-CALL") or parent.startswith("BDOS-STATE"):
        return "BDOSTEST.COM"
    if parent.startswith("BDOS-FILE"):
        number = int(ledger)
        # Ownership is proposition-based, not inferred from mutable prose.  The
        # two complete families below are directory/namespace contracts.
        if number in ERROR_LEDGER:
            return "ERRTEST.COM"
        if number in DISK_LEDGER:
            return "DISKTEST.COM"
        if parent in {"BDOS-FILE-003", "BDOS-FILE-010"} or number in DIRECTORY_LEDGER:
            return "DIRTEST.COM"
        if number >= 317:
            return "RANDTEST.COM"
        return "FILETEST.COM"
    if parent.startswith("CCP"):
        return "CCPTEST.COM"
    if parent.startswith("BIOS"):
        return "BIOSTEST.COM"
    if parent.startswith("MEM"):
        return "ENTRYTST.COM"
    if parent.startswith("ERROR"):
        return "ERRTEST.COM"
    if parent.startswith("HW"):
        return "HWTEST.COM"
    if parent.startswith("UTIL") or parent.startswith("APP"):
        return "ECOTEST.COM"
    return "CPUTEST.COM"


def safety_for(parent: str, requirement: str, applicability: str) -> tuple[str, str]:
    text = (requirement + " " + applicability).lower()
    if parent.startswith("ERROR") or any(k in text for k in ("physical error", "bad sector", "media change", "recovery")):
        return "FAULT_ASSISTED", "fault provider or restorable emulator image"
    if parent.startswith("HW") or parent.startswith("COMM") or "device" in text:
        return "HARDWARE_PROFILE", "selected device/profile provider"
    if parent.startswith("BDOS-CON") or any(k in text for k in ("console", "operator", "presentation")):
        return "INTERACTIVE", "console transcript and operator input where required"
    if any(k in text for k in ("directory full", "disk full", "allocation", "read-only", "protection")):
        return "SCRATCH_DESTRUCTIVE", "dedicated restorable scratch disk"
    if parent.startswith("BDOS-FILE") or any(k in text for k in ("file", "fcb", "directory", "dma")):
        return "TEMP_FILES", "designated writable scratch drive and reserved filenames"
    if parent.startswith("UTIL") or parent.startswith("APP"):
        return "MANUAL_REVIEW", "pinned software corpus and reviewer evidence"
    return "SAFE_READ_ONLY", "none beyond runnable CP/M environment"


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    matrix = rows(TABLES / "conformance-framework-matrix.tsv")
    profiles = rows(RC1 / "profiles/profile-case-map.tsv")
    profile_by_case = defaultdict(list)
    detailed = detailed_ledger_requirements()
    for p in profiles:
        profile_by_case[p["case_id"]].append(p["profile_id"])

    counters = defaultdict(int)
    catalog = []
    for r in matrix:
        requirement = r["requirement"]
        if re.fullmatch(r"Investigation \d+ finding", requirement):
            requirement = detailed.get(r["ledger_entry"], requirement)
        exe = module_for(r["ledger_entry"], r["parent_test_id"], requirement)
        counters[exe] += 1
        safety, fixture = safety_for(r["parent_test_id"], requirement, r["applicability"])
        catalog.append({
            "ledger_entry": r["ledger_entry"], "case_id": r["case_id"],
            "case_version": r["case_version"], "oracle_id": r["oracle_id"],
            "oracle_version": r["oracle_version"], "parent_test_id": r["parent_test_id"],
            "executable": exe, "module_case": f"{exe[:3]}-{counters[exe]:03d}",
            "requirement": requirement, "classification": r["classification"],
            "applicability": r["applicability"],
            "rc1_dependencies": r["dependencies"],
            "selected_profile_ids": ",".join(profile_by_case[r["case_id"]]) or "CPM22-BASE",
            "safety_class": safety, "required_fixture": fixture,
            "implementation_status": "INVENTORIED_NOT_IMPLEMENTED",
            "proposed_reuse": "REVIEW_REQUIRED",
        })
    fields = list(catalog[0])
    with (OUT / "case-to-executable-catalog.tsv").open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fields, delimiter="\t", lineterminator="\n")
        w.writeheader(); w.writerows(catalog)

    if "--catalog-only" in sys.argv:
        return

    inv = []
    extensions = {".asm", ".mac", ".com"}
    for p in sorted((ROOT / "investigations").rglob("*")):
        if not p.is_file() or p.suffix.lower() not in extensions or "/rebuild/" in str(p):
            continue
        rel = p.relative_to(ROOT)
        m = re.search(r"investigations/(\d{3})", str(rel))
        inv_id = m.group(1) if m else "SUPPLEMENTAL"
        status = "SOURCE_REVIEW_REQUIRED" if p.suffix.lower() in {".asm", ".mac"} else "BINARY_ONLY_OR_BUILD_PRODUCT"
        inv.append({"investigation": inv_id, "artifact": str(rel), "kind": p.suffix[1:].upper(),
                    "bytes": p.stat().st_size, "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
                    "reuse_status": status, "notes": "Not approved for suite reuse until behavior, fixtures, safety, and reproducibility are reviewed."})
    for archive in sorted((ROOT / "investigations").glob("*.zip")):
        m = re.match(r"(\d{3})", archive.name)
        inv_id = m.group(1) if m else "SUPPLEMENTAL"
        with zipfile.ZipFile(archive) as zf:
            for member in sorted(zf.infolist(), key=lambda x: x.filename.lower()):
                suffix = Path(member.filename).suffix.lower()
                if (member.is_dir() or suffix not in extensions or "/rebuild/" in member.filename.lower()
                        or member.filename.startswith("__MACOSX/") or Path(member.filename).name.startswith("._")):
                    continue
                data = zf.read(member)
                status = "SOURCE_REVIEW_REQUIRED" if suffix in {".asm", ".mac"} else "BINARY_ONLY_OR_BUILD_PRODUCT"
                inv.append({"investigation": inv_id,
                            "artifact": f"{archive.relative_to(ROOT)}!{member.filename}",
                            "kind": suffix[1:].upper(), "bytes": len(data),
                            "sha256": hashlib.sha256(data).hexdigest(), "reuse_status": status,
                            "notes": "Archive member; not approved for suite reuse until behavior, fixtures, safety, and reproducibility are reviewed."})
    inv.sort(key=lambda x: (x["investigation"], x["artifact"].lower()))
    with (OUT / "existing-probe-inventory.tsv").open("w", newline="", encoding="utf-8") as f:
        fields2 = list(inv[0]); w = csv.DictWriter(f, fields2, delimiter="\t", lineterminator="\n")
        w.writeheader(); w.writerows(inv)

    mod_counts = Counter(r["executable"] for r in catalog)
    safety_counts = Counter(r["safety_class"] for r in catalog)
    class_counts = Counter(r["classification"] for r in catalog)
    probe_counts = Counter(r["reuse_status"] for r in inv)
    design = f"""# BetterCP/M Executable Conformance Test Suite — Initial Design and Inventory

Status: design baseline; no executable claims are made.  
Normative input: BetterCP/M CP/M 2.2 Compatibility Standard 1.0-rc1.  
Frozen tables: 1.0.0. Ledger SHA-256: `eb16466fdbff8fb2bc07bd02a07198b8426fb6452be3dd1f256cbff4af0547d3`.

## 1. Scope and invariants

This project implements an end-user executable layer over RC1. It does not alter any ledger proposition, classification, applicability rule, oracle, or aggregation rule. All 627 proposition cases remain independently reportable. Shared execution is permitted; shared verdicts are not. `BLOCKED` and `ERROR` never count as `PASS`.

The generated catalog contains {len(catalog)} unique ledger entries and {len(set(r['case_id'] for r in catalog))} unique case IDs. Classification totals are {dict(class_counts)}.

## 2. Proposed suite architecture

| Artifact | Responsibility | Catalog cases |
|---|---|---:|
| `CPMTEST.COM` | Inspect environment, validate reports, aggregate only complete child records | 0 (runner) |
| `ENTRYTST.COM` | transient entry, page zero, memory, termination/runtime | {mod_counts['ENTRYTST.COM']} |
| `BDOSTEST.COM` | BDOS call convention and system-state functions | {mod_counts['BDOSTEST.COM']} |
| `CONSTEST.COM` | console, character devices, communications-facing behavior | {mod_counts['CONSTEST.COM']} |
| `FILETEST.COM` | FCB lifecycle, open/close/create, sequential I/O | {mod_counts['FILETEST.COM']} |
| `RANDTEST.COM` | random I/O, file size, protection, and lifecycle | {mod_counts['RANDTEST.COM']} |
| `DIRTEST.COM` | directory search, DMA enumeration, users, rename/delete | {mod_counts['DIRTEST.COM']} |
| `DISKTEST.COM` | disk state/parameters/allocation and disk-level behavior | {mod_counts['DISKTEST.COM']} |
| `CCPTEST.COM` | CCP parsing, loading, dispatch, lifecycle | {mod_counts['CCPTEST.COM']} |
| `BIOSTEST.COM` | documented BIOS interfaces | {mod_counts['BIOSTEST.COM']} |
| `CPUTEST.COM` | 8080 baseline and selected processor-profile behavior | {mod_counts['CPUTEST.COM']} |
| `ERRTEST.COM` | controlled errors, recovery and fault-provider tests | {mod_counts['ERRTEST.COM']} |
| `HWTEST.COM` | selected hardware profiles | {mod_counts['HWTEST.COM']} |
| `ECOTEST.COM` | pinned utility/application corpus and reviewed workflows | {mod_counts['ECOTEST.COM']} |
| `RUNTEST.SUB` | optional CCP/SUBMIT sequencing; no embedded child loader | — |
| `TESTDOC.TXT` | operator guide, code registry, safety and fixture instructions | — |

Each test executable links a small shared library for console output, hex formatting, guarded DMA buffers, report records, aggregation, checksums, and cleanup tracking. Modules must fit a conservative TPA target established during the vertical slice; large tables stay host-side or are streamed from compact records.

### FILE/DIR/DISK ownership decision

The earlier `FILETEST.COM = 205` figure was preliminary and is retired. Exact
proposition ownership now assigns 142 cases to FILETEST, 72 to DIRTEST, and 20
to DISKTEST; seven fatal or injected BDOS file-error propositions move to
ERRTEST. FILETEST owns FCB lifecycle and record I/O. DIRTEST owns Search
First/Next, directory-entry enumeration, user namespaces, Delete, Rename and
directory attributes. DISKTEST owns reset/vector/protection and allocation or
capacity contracts. ERRTEST owns physical/fatal error presentation. Direct
BIOS operations remain in BIOSTEST.

These assignments are encoded by frozen ledger identity in the generator,
not inferred from requirement wording. Later scenario decomposition may
refine implementation grouping, but any ownership change requires an explicit
architecture decision and regenerated 627-row catalog.

### Distribution and fixture-media decision

Suite executables are independently deployable. A focused distribution may contain only one test executable, its configuration, and the fixtures it requires; no utility may assume that another suite utility is present unless the dependency is explicitly declared. Releases provide per-utility media and may additionally provide a complete-suite convenience disk when the target format has sufficient capacity.

Test media are nonbootable and implementation-neutral. The normal three-drive arrangement is: A = the candidate implementation's own boot/system disk; B = the mounted per-utility disk containing the executable, configuration and primary fixtures; C = a secondary fixture disk for cases that require a distinct drive. The operator boots A, selects B (or invokes `B:UTILITY` where supported), and runs the desired selector. Default fixture manifests therefore use `PRIMARY_DRIVE B` and `SECONDARY_DRIVE C`.

A bootable reference image may be generated to automate validation in a named emulator, but it is not a universal test disk and is not part of the portable fixture contract. An environment adapter combines a target-supplied A image with unchanged suite B/C images and records their hashes. Two-drive systems use a documented media-swap/installation adapter for explicit-drive cases or report those cases `BLOCKED`; they never require the suite to replace the candidate's boot disk. Loose copies of executables, configuration and logical fixtures accompany images for installation on other formats.

Two physical-media families are maintained from the same logical manifests: IBM 3740 images for z80pack and native DMK images for TRS-80 Model 4/4P Montezuma Micro CP/M. Montezuma per-utility B/C media default to its standard 40-track SS/DD 200K DATA format; the standard 400K DS/DD DATA format is selected when capacity requires it or for a complete-suite convenience disk. The selected geometry is adapter metadata and evidence for capacity/disk-parameter cases, never a change to case identity or oracle semantics.

### Processor portability decision

The generic executable suite targets the Intel 8080 instruction set. `FILETEST`, `DIRTEST`, `DISKTEST`, `BDOSTEST`, generic console/entry/CCP/BIOS cases, the runner, and shared runtime must not require Z80 extensions. This preserves operation on original or emulated 8080 CP/M systems and prevents the test framework from imposing a Z80 requirement on the generic CP/M 2.2 baseline.

This is an executable portability rule, not a new conformance proposition. It does not change any frozen oracle or require the candidate implementation itself to be internally 8080-based. Processor-profile cases whose subject necessarily uses later instructions are isolated in clearly named companion executables, declare their minimum processor, and remain selected only by the applicable profile. Generic and processor-specific companions share case IDs, report grammar and aggregation rules where their scopes intersect.

Every executable and report declares `PROCESSOR_REQUIRED`; the generic value is `8080`. Release validation executes generic modules in both Intel 8080 and Z80 environments. Introduction of a Z80-only opcode into a generic binary is a framework build failure. Source may use an assembler's Z80-style mnemonics only when the emitted opcode exists on the 8080; emulator execution and opcode auditing provide independent checks.

## 3. Catalog contract

`case-to-executable-catalog.tsv` is the suite-owned mapping. Its key is `case_id`; `ledger_entry`, `oracle_id`, and versions are copied from RC1. `module_case` is an implementation-local stable identifier. A release check must prove exactly one row for each frozen case and reject unknown, missing, duplicate, or semantically changed rows.

The initial module split is mechanical and reviewable. In particular, BDOS-FILE cases are divided by requirement wording among file, directory, and disk modules; maintainers may move execution ownership without changing the frozen case/oracle identity.

## 4. Report grammar

Reports are ASCII, CRLF on CP/M, one header followed by one blank-line-delimited record per case. Values are printable single-line text; control bytes use two-digit hex. Unknown fields may be preserved by parsers, but required fields may not be omitted.

```text
REPORT CPM22-COMPAT-RPT 1
SUITE_VERSION 0.1.0
EXECUTABLE FILETEST.COM
EXECUTABLE_VERSION 0.1.0
PROCESSOR_REQUIRED 8080
RUN_MODE DEVELOPMENT_SUBSET
RUN_PURPOSE DEVELOPMENT
WORKFLOW GENERAL
REQUESTED_SCOPE GROUP:OPEN,GROUP:CLOSE
LEDGER_VERSION 1.0-rc1
LEDGER_SHA256 eb16466f...
TABLE_VERSION 1.0.0
TABLE_SHA256 <sha256>
PROFILES CPM22-BASE
ENVIRONMENT <implementation and machine>
DRIVE B
RUN_STATUS PARTIAL

CASE BDOS-FILE-004-P0223
LEDGER 0223
PARENT BDOS-FILE-004
MODULE_CASE FIL-003
ORACLE OR-0223
ORACLE_VERSION 1.0.0
RESULT PASS
EXPECTED <oracle-derived expectation>
OBSERVED <actual observation>
EVIDENCE <artifact or inline evidence description>
END_CASE
```

Required case-result values are `PASS`, `FAIL`, `BLOCKED`, `ERROR`, and `NOT_APPLICABLE`. `CODE` is mandatory for non-PASS except `NOT_APPLICABLE`, where `REASON` and manifest-supported applicability are mandatory. `EXPECTED` must be derived from the frozen oracle, never reconstructed from the candidate result. `RUN_STATUS COMPLETE` is legal only when every case selected by `REQUESTED_SCOPE` has a valid result record. Completeness for a subset does not imply module or certification completeness.

The report sink is independent of the case oracle. `CONSOLE` is the mandatory development sink so an early implementation can test a function without first implementing Make/Write merely to save the report. `FILE` is optional in development and requires its own declared BDOS prerequisites. A conformance campaign must preserve the regular console stream through an external capture provider, a verified file sink, or both; loss of required evidence affects campaign completeness, not the candidate observation already made by the case.

## 5. Diagnostic codes

Codes are outcome-oriented and centrally registered. Initial reserved families:

- `C001` result outside required set; `C002` required return code wrong; `C003` memory/FCB/DMA mutation wrong; `C004` required state transition wrong; `C005` required presentation or routing wrong.
- `B001` writable scratch drive absent; `B002` selected profile provider absent; `B003` prerequisite case did not pass; `B004` physical fault injection absent; `B005` operator/manual authority absent.
- `E001` fixture creation failed; `E002` fixture verification failed; `E003` report write/parse failed; `E004` cleanup failed; `E005` guard or self-check detected suite corruption.
- `W001` permitted `NOT GUARANTEED` variation observed; `W002` partial evidence retained; `W003` cleanup retry succeeded.

No code alone determines a verdict. The case oracle and evidence determine the verdict; the code explains it.

## 6. Safety model and fixture lifecycle

Catalog safety allocation is {dict(safety_counts)}. Before mutation, a module must identify its scratch drive, user area, reserved filenames, expected free space, selected profiles, and cleanup plan. Reserved names use the `BT` prefix and a run-specific suffix where space permits; the exact set is printed before confirmation.

Lifecycle: discover → validate manifest and prerequisites → obtain explicit authority for destructive classes → snapshot/hash pristine fixture → create isolated test objects → execute one case/scenario → flush and capture evidence → clean up → verify restoration → close the case record. A cleanup failure is `ERROR`, preserves the partial report, and stops later mutation on that fixture.

Safe/read-only tests may run without confirmation. Temporary-file tests require a designated writable drive. Scratch-destructive and fault-assisted tests require a dedicated restorable disk and explicit confirmation. Interactive, hardware, and manual-review tests require named providers/reviewers; absence yields `BLOCKED` or manifest-supported `NOT_APPLICABLE`, never `PASS`.

## 7. Profiles

`CPM22-BASE` is always selected. Additional registry IDs are supplied through a small text manifest rather than command-tail complexity. Selecting a profile activates every mapped `PROFILE REQUIRED` row. Optional profiles activate only when explicitly claimed. Profiles add gates and never waive baseline cases. Every report records profile IDs and versions; the runner rejects an aggregate if profile manifests and case applicability disagree.

## 8. Development-subset execution

The suite supports incomplete CP/M implementations without weakening conformance semantics. An implementor may select one frozen case, one internal case, a BDOS function, a functional group, a parent test, or an entire executable. Selection affects what runs, never what an oracle means.

Three run modes are defined:

- `DEVELOPMENT_SUBSET`: execute only the requested cases and their explicitly approved prerequisites. It may be complete for the requested scope but is never certification-eligible.
- `MODULE_COMPLETE`: execute every applicable case assigned to one executable. It establishes module completeness only.
- `CERTIFICATION_CAMPAIGN`: execute every applicable case required by the declared certification level and selected profiles.

Modules must provide discovery and selection interfaces equivalent to `FILETEST /LIST`, `/GROUP:OPEN`, `/FN:15`, and `/CASE:FIL-017`. Exact spelling may be adjusted for CCP command-tail limits, but the report must preserve the normalized requested scope. A selector expands deterministically to frozen case IDs before execution, and that expansion is written to the report or a hashed scope manifest.

Cases outside the selected scope have campaign state `NOT_RUN`. `NOT_RUN` is not an RC1 case verdict and therefore does not appear as a case result record; it appears only in scope/coverage summaries. It must never be converted to `NOT_APPLICABLE`, `BLOCKED`, or `PASS`. `NOT_APPLICABLE` remains reserved for a selected case excluded by a manifest-supported profile or optional-feature rule.

Each catalog case must acquire machine-readable prerequisite metadata at implementation time. Missing or failed prerequisites block only their dependent selected cases; independent selected cases continue. The runner records the exact prerequisite case and run ID. A partially implemented BDOS must not be forced through unrelated calls merely because cases share an executable.

An optional explicit capability manifest is the safety authority for incomplete implementations. It declares which BDOS functions, BIOS routines, drives and report sinks the implementor authorizes the suite to call. A selected case whose required service is undeclared becomes `BLOCKED` without making that call. Declarations are never evidence that a service conforms and never create a `PASS`; they only prevent the framework from entering unfinished code that may hang or corrupt state. Conformance purpose requires the complete applicable capability set and does not use omission to narrow the claim.

Fixtures should minimize dependencies on unimplemented services. For example, open/read tests may use a verified prebuilt disk image rather than requiring create/write first. Create/write tests may rely on host-side pristine-image restoration rather than requiring delete to work. Fixture construction and restoration remain framework operations with hashes and may not substitute for the CP/M operation actually under test.

The maintained z80pack fixture distribution uses nonbootable IBM 3740 images. The candidate supplies its own boot/system disk on A; a per-utility B image contains that independently runnable utility, its configuration and primary fixtures; C contains distinct-drive fixtures. A complete-suite image may also be provided as a capacity-dependent convenience. Loose copies of utilities, configuration, fixture payloads, listings and hashes accompany the images. A reproducible host generator starts from pinned pristine data-disk hashes, installs artifacts, verifies required presence/absence and attributes, and regenerates the manifest. A separately labeled bootable reference A may automate emulator validation but is not portable test media. Other environments may reproduce the same logical fixture without adopting IBM 3740 physical format.

A development summary reports requested, selected, executed, passed, failed, blocked, errored, not-applicable, and not-run counts, plus `COMPLETE_FOR_REQUESTED_SCOPE` and `CERTIFICATION_ELIGIBLE NO`. User-facing wording must say “development subset,” never “CP/M compatible,” even when every selected case passes.

## 9. Implementation-neutral development and regression use

The suite is a development tool for any project implementing a CP/M-compatible system. BetterCP/M is an intended consumer, but it is not a privileged candidate, reference oracle, or source of expected results. The same executable cases, frozen RC1 applicability, and verdict rules apply to BetterCP/M, another clean-room implementation, an emulator, a reimplementation for new hardware, or a homebrew system integration.

Run purpose and workflow are separate metadata dimensions. Two run purposes are defined:

- `DEVELOPMENT`: incremental implementation and regression work; focused selectors and incomplete scopes are expected; never certification-eligible.
- `CONFORMANCE`: immutable campaign/profile/fixture manifests, complete applicable scope, strict evidence preservation, aggregation and review gates.

Development runs also name a workflow. Initial workflow IDs are:

- `GENERAL`: ordinary cross-component implementation and regression work.
- `BIOS_BRINGUP`: direct BIOS selectors, staged prerequisites, safe-first ordering, explicit device/scratch gates and hardware-oriented troubleshooting.
- `BDOS_BRINGUP`: BDOS-function and functional-group selectors with prebuilt fixtures that minimize dependence on unfinished calls.
- `CCP_BRINGUP`: command parsing, loading, entry and lifecycle fixtures with transcript-oriented diagnostics.
- `FILESYSTEM_BRINGUP`: FCB, DMA, directory, extent and disk-capacity workflows with controlled images.

`BIOS_BRINGUP` is therefore a specialization of `DEVELOPMENT`, not a peer purpose. Additional workflow IDs may be registered without changing frozen case semantics. A conformance run normally records `WORKFLOW NONE`; a development run must select exactly one registered workflow.

Purpose and workflow are report metadata and policies for default selection, sequencing, verbosity, fixture provider and evidence packaging. Neither may change an oracle, classification, applicability, accepted result set, prerequisite truth, or the verdict for the same observation. Purpose/workflow-invariance tests must run representative cases under applicable combinations and prove identical case evaluation.

The implementation workflow is incremental and cumulative: implement one behavior; run its `/NNNN` case; run its group; run dependent module cases; run the accumulated safe baseline; retain results against the exact candidate build. Reports record candidate name/version, source or binary hash, build/toolchain identity, configuration, environment, run purpose and workflow so regressions can be compared across revisions.

The suite must support machine-readable result comparison by case ID. A comparison tool distinguishes newly passing, newly failing, newly blocked, newly applicable, and observation-changed cases without treating a reduced requested scope as improvement. Historical failures and framework errors remain preserved rather than overwritten.

Developer diagnostics may include non-normative likely causes, relevant implementation areas and captured state. Such guidance must be labeled separately from `EXPECTED` and cannot be generated from BetterCP/M internals in a way that makes those internals normative. Test expected data comes only from frozen oracles and independently pinned fixtures.

No candidate-specific accommodation may silently enter common case logic. A workaround needed only for one implementation is either test-framework portability work that preserves the oracle, an explicit provider adapter recorded in the manifest, or evidence of candidate nonconformance. Differential execution against DRI CP/M 2.2 and independent implementations is validation evidence for the suite, not a replacement for the frozen oracle.

## 10. BIOS-template and test-suite co-design

The BetterCP/M BIOS template, BIOS developer guide, configuration system, bring-up checklist, and `BIOSTEST.COM` are one coordinated developer interface. They must be designed and released together. A BIOS routine must not be documented independently from the tests that verify its public contract.

A suite-owned, machine-readable BIOS routine catalog is the single source for this coordination. Each routine record contains at least:

- routine ID and public BIOS entry-point name;
- jump-table position and BetterCP/M template symbol;
- purpose, input contract, output contract, and permitted side effects;
- registers and memory whose preservation is required or unspecified;
- configuration symbols consumed by the routine;
- prerequisite routines and minimum bring-up stage;
- applicable ledger entries, frozen case IDs, and oracle versions;
- canonical single-routine, single-ledger, and functional-group selectors;
- safety classification, required fixture/device, and whether interaction or harness assistance is required;
- implementation state (`STUB`, `IMPLEMENTED_UNVERIFIED`, or `VERIFIED`), maintained by the developer/build rather than inferred from conformance results;
- non-normative troubleshooting topics kept distinct from oracle text.

Generated template comments must show the contract and immediately runnable verification commands beside each fill-in point. For example:

```asm
; SELDSK -- Select disk
; Input:  C = drive number (0=A)
; Output: HL = DPH address, or 0000H if unavailable
; Config: NDRIVES, DPHTAB
; Verify: BIOSTEST /0421
;         BIOSTEST /BIOS:SELDSK
; Safety: read-only
SELDSK:
        ; TODO: validate drive and return its DPH
        LXI     H,0000H
        RET
```

Catalog-derived or catalog-validated outputs are: assembly-template comments, BIOS developer-guide reference entries, a staged bring-up checklist, `BIOSTEST /LIST`, selector-expansion tables, and ledger/case traceability. Generation is preferred; where source comments cannot be generated cleanly, a release validator must prove that their embedded catalog ID and catalog hash are current.

Bring-up stages should follow useful hardware-development dependencies rather than ledger order: page-zero/jump-table discovery; console output; console status/input; disk selection and parameter structures; track/sector/DMA positioning; known-sector read; sector translation; scratch-only write; warm boot; error/recovery; selected hardware profiles. A hobbyist can therefore fill one routine, run the command printed beside it, and proceed without completing unrelated BIOS or BDOS services.

`BIOSTEST.COM` supports at least `/NNNN`, `/BIOS:name`, `/GROUP:name`, `/SAFE`, and `/LIST`. `/NNNN` always denotes a zero-padded ledger entry. If the requested entry belongs to another executable, the program reports the owning executable and does not fabricate a result. `/SAFE` expands only to cases whose current catalog safety and fixture declarations permit non-destructive execution in the declared environment.

Formal verdicts remain oracle-driven. Troubleshooting hints may suggest likely checks such as drive-number interpretation, DPH address construction, register preservation, or DMA setup, but they are explicitly non-normative and cannot alter `PASS`, `FAIL`, `BLOCKED`, `ERROR`, or applicability.

The BIOS kit release gate requires bidirectional completeness: every fill-in BIOS routine maps to its relevant test selectors or carries an explicit reason why direct automated testing is unavailable, and every BIOS selector maps back to documented routine contracts and frozen cases. Stale catalog hashes, unknown ledger IDs, missing safety metadata, or a template/test mismatch fail the kit build.

## 11. Existing-probe reuse matrix

`existing-probe-inventory.tsv` inventories {len(inv)} non-rebuild `.ASM`, `.MAC`, and `.COM` artifacts with content hashes. It intentionally excludes `rebuild/` duplicates. Status totals are {dict(probe_counts)}. This is an artifact inventory, not an approval list.

Reuse decisions occur per logical probe after source review: `REUSABLE`, `ADAPTABLE`, `MISSING`, `MANUAL`, `PROFILE_SPECIFIC`, or `HARNESS_REQUIRED`. Review records must state exact frozen cases, preconditions, destructive effects, determinism, unsupported assumptions, build recipe, source/binary hash relation, and how regular case records replace ad-hoc console output. Binary-only artifacts may serve as historical evidence but are not release sources.

The z80pack CP/M 2.2 images and simulators are candidate validation environments, not normative oracles. External DRI source and binaries used as reference or toolchain inputs require recorded licensing and provenance before redistribution.

## 12. Implementation phases

1. Freeze this design, case catalog, BIOS routine catalog schema, selection/scope grammar, code registry, and release checks.
2. Complete source-level probe review for the FILE/DIR/DISK families and approve only mapped behaviors.
3. Implement shared runtime and `FILETEST.COM` as the vertical slice: guarded DMA, FCB snapshots, temporary fixtures, per-case reports, aggregation, and cleanup failure handling.
4. Validate the slice on a pinned DRI CP/M 2.2 environment and at least one independent implementation, including deliberately induced FAIL/BLOCKED/ERROR paths.
5. Expand safe baseline entry, BDOS, console, directory, disk, CCP, BIOS, and CPU/runtime coverage.
6. Add destructive, interactive, fault, hardware/profile, and manual-review modules behind explicit gates.
7. Implement `CPMTEST.COM`, host validator, coverage audit, reproducible builds, and release packaging.

## 13. Validation and release gates

A release requires: 627/627 catalog integrity; implementation-neutral case logic; generic-binary 8080 opcode audit and execution under 8080 and Z80 environments; explicit processor declarations for every executable; representative purpose/workflow-invariance checks; BIOS template/catalog/test bidirectional traceability; deterministic selector expansion; distinction between `NOT_RUN` scope state and RC1 verdicts; frozen-input hash verification; reproducible source-to-COM builds; source and executable hashes; conservative TPA-size checks; parser round trips; deliberately exercised PASS/FAIL/BLOCKED/ERROR/NOT_APPLICABLE paths; fixture restoration tests; no destructive default; DRI CP/M 2.2 reference results; at least one independent implementation; retained raw transcripts and disk diffs; profile applicability audit; independent review of manual/destructive cases; documentation and diagnostic registry synchronization.

No aggregate compatibility claim is emitted from a development subset or partial run. A subset may report completion only for its exact requested scope. A crash or blocked module preserves independent records and leaves any broader campaign incomplete.

## 14. Immediate FILETEST vertical-slice acceptance criteria

The first implementation milestone is complete only when it builds reproducibly, names every assigned catalog case, lists and deterministically expands selectable cases/groups/BDOS functions, refuses to mutate without a designated scratch drive, inventories reserved filenames before use, uses DMA guards, captures FCB/DMA before-and-after evidence, emits parseable records during the run, distinguishes candidate failure from fixture/framework failure, verifies cleanup, and is validated against both conforming and deliberately perturbed behavior. Unselected or unimplemented assigned cases are `NOT_RUN`, not result records; selected cases whose required facility is absent are `BLOCKED`. Neither state is a pass, and neither permits a broader compatibility claim.
"""
    (OUT / "INITIAL-DESIGN.md").write_text(design, encoding="utf-8")

    bios_schema = [
        ("routine_id", "required", "Stable suite-owned BIOS routine identifier."),
        ("entry_name", "required", "Public BIOS entry-point name."),
        ("jump_table_slot", "required", "Public jump-table position or explicit non-table classification."),
        ("template_symbol", "required", "Symbol used by the fill-in BIOS template."),
        ("purpose", "required", "Concise routine responsibility."),
        ("input_contract", "required", "Defined input registers and memory."),
        ("output_contract", "required", "Defined outputs and return behavior."),
        ("permitted_side_effects", "required", "Allowed externally visible side effects."),
        ("register_contract", "required", "Required preservation and explicitly unspecified registers."),
        ("configuration_symbols", "required", "Configuration values consumed, or NONE."),
        ("prerequisite_routines", "required", "Exact routine IDs required for isolated execution, or NONE."),
        ("bringup_stage", "required", "Ordered hardware-development stage."),
        ("ledger_entries", "required", "Zero-padded ledger entries, or NONE with rationale."),
        ("case_ids", "required", "Frozen case IDs, or NONE with rationale."),
        ("oracle_versions", "required", "Frozen oracle versions corresponding to case_ids."),
        ("selectors", "required", "Canonical /NNNN, /BIOS:name, and /GROUP:name selectors."),
        ("safety_class", "required", "Suite safety classification."),
        ("fixture_device", "required", "Required fixture/device, or NONE."),
        ("validation_mode", "required", "AUTOMATED, INTERACTIVE, HARNESS_ASSISTED, or MANUAL_REVIEW."),
        ("implementation_state", "required", "STUB, IMPLEMENTED_UNVERIFIED, or VERIFIED."),
        ("troubleshooting_topics", "required", "Non-normative diagnostic topics, or NONE."),
        ("catalog_version", "required", "Schema/catalog version embedded in generated or validated outputs."),
    ]
    with (OUT / "bios-routine-catalog-schema.tsv").open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(("field", "requirement", "definition")); w.writerows(bios_schema)

    readme = """# Deliverable contents

- `INITIAL-DESIGN.md`: architecture, grammar, safety, fixtures, profiles, phases, and release gates.
- `ARCHITECTURE-DECISIONS.md`: accepted implementation-policy decisions, beginning with the 8080 generic-suite baseline.
- `case-to-executable-catalog.tsv`: all 627 frozen RC1 proposition cases mapped to proposed executables.
- `bios-routine-catalog-schema.tsv`: required single-source metadata tying BIOS template routines to tests and documentation.
- `existing-probe-inventory.tsv`: hashed non-rebuild source/binary probe artifacts; no probe is approved merely by appearing here.
- `FILE-DIR-DISK-PROBE-REVIEW.md`: source-reviewed reuse findings and first FILETEST vertical-slice scope.
- `file-dir-disk-probe-reuse-matrix.tsv`: per-logical-probe decisions, source hashes, safety and required adaptations.
- `FILE-DIR-DISK-PROBE-REVIEW-VALIDATION.txt`: review integrity summary.
- `FILETEST-VERTICAL-SLICE-DECOMPOSITION.md`: exact proposition-level first-slice specification.
- `filetest-vertical-slice-scenarios.tsv`: selectors, seeds, prerequisites, fixtures, oracles and evidence for each mapped case.
- `FILETEST-VERTICAL-SLICE-DECOMPOSITION-VALIDATION.txt`: scenario decomposition integrity checks.
- `VALIDATION.txt`: generated integrity checks and counts.

Regenerate with `python3 tools/build_initial_deliverable.py`, `python3 tools/build_file_probe_review.py`, and `python3 tools/build_filetest_scenario_decomposition.py` from the workspace root.
"""
    (OUT / "README.md").write_text(readme, encoding="utf-8")

    checks = [
        (len(catalog) == 627, "catalog has 627 rows"),
        (len({r['ledger_entry'] for r in catalog}) == 627, "ledger entries unique"),
        (set(r['ledger_entry'] for r in catalog) == {f"{i:04d}" for i in range(1, 628)}, "ledger entries contiguous 0001-0627"),
        (len({r['case_id'] for r in catalog}) == 627, "case IDs unique"),
        (len({r['oracle_id'] for r in catalog}) == 627, "oracle IDs unique"),
        (all(r['oracle_version'] == '1.0.0' for r in catalog), "oracle versions are 1.0.0"),
        (mod_counts['FILETEST.COM'] == 93, "FILETEST executable ownership is 93 cases"),
        (mod_counts['RANDTEST.COM'] == 49, "RANDTEST executable ownership is 49 cases"),
        (mod_counts['DIRTEST.COM'] == 72, "DIRTEST authoritative ownership is 72 cases"),
        (mod_counts['DISKTEST.COM'] == 20, "DISKTEST authoritative ownership is 20 cases"),
        (sum(mod_counts[x] for x in ('FILETEST.COM', 'RANDTEST.COM', 'DIRTEST.COM', 'DISKTEST.COM')) == 234,
         "FILE/DIR/DISK ownership accounts for 234 non-error cases"),
    ]
    lines = [f"{'PASS' if ok else 'FAIL'}\t{name}" for ok, name in checks]
    lines += [f"INFO\tprobe artifacts inventoried: {len(inv)}", f"INFO\tmodule counts: {dict(sorted(mod_counts.items()))}"]
    (OUT / "VALIDATION.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    if not all(ok for ok, _ in checks):
        raise SystemExit("validation failed")


if __name__ == "__main__":
    main()
