# Investigation 074 - Release Artifact Production and Synchronization

## 1. Objective and scope

I074 produces the four normative publication artifacts authorized by the prompt: Compatibility Standard 1.0-rc1, Compatibility Policy 1.0-rc1, Conformance Specification 1.0-rc1 with frozen tables 1.0.0, and Compatibility Profile Registry 1.0-rc1. It performs controlled synthesis only and does not modify Ledger 072, discover behavior, change policy decisions, redesign conformance, or implement tooling.

## 2. Authoritative inputs

Authority is Ledger 072 (`eb16466fdbff8fb2bc07bd02a07198b8426fb6452be3dd1f256cbff4af0547d3`), I070 policy/profile artifacts, I071 framework and frozen tables, I072 readiness gaps, and I073 content/synchronization plans. Exact input hashes are recorded in `hashes/source-inputs.sha256`.

## 3. Artifact production status

All four required groups are produced under `release-artifacts/`. `probes/normative-artifact-inventory.tsv` records 15 normative documents/tables and hashes. Nine conformance tables are byte-identical I071 copies. Package manifest, Gopher publication index, and release notes remain deliberately outside I074 for the next assembly task.

## 4. Compatibility standard status

`BetterCPM CP-M 2.2 Compatibility Standard 1.0-rc1.txt` is complete. It states authority, target, 627-proposition totals, baseline/profile layering, exclusions/variation, conformance, non-certification status, and change control without restating or rewriting individual propositions.

## 5. Policy publication status

`BetterCPM Compatibility Policy 1.0-rc1.txt` supersedes Draft 0.1 for release use while preserving it as history. It publishes I070's five treatments, generic decisions, profile/optional applicability, evidence discipline, claim rules, and change control. All 49 former pending decisions are already embodied by Ledger 072; no ledger edit occurs.

## 6. Conformance specification status

`conformance/BetterCPM CP-M 2.2 Conformance Specification 1.0-rc1.txt` promotes I071 without redesign. It defines inventory/traceability, oracle applicability, aggregation, campaign phases, evidence, certification levels, failure handling, and implementation status. Its nine tables are byte-identical to I071 as verified by `frozen-table-copy-audit.tsv`.

## 7. Profile registry status

The registry assigns stable versioned IDs to the 17 exact named profile/optional applicability labels plus CPM22-BASE. CPM22-BASE is INCLUDED. All named profiles are AVAILABLE but unselected by default; AVAILABLE is definitional and makes no implementation claim. Every named row inherits CPM22-BASE.

`profile-case-map.tsv` maps all 28 PROFILE REQUIRED and three OPTIONAL cases exactly once, retaining exact ledger/I071 applicability labels. Profile organization changes no proposition meaning and cannot waive baseline requirements.

## 8. Synchronization validation

`synchronization-validation.tsv` records ten PASS checks: ledger identity, proposition/disposition totals, release classifications, test and case/oracle identity, profile coverage/inheritance/applicability, and terminology. Frozen table hashes match I071 byte-for-byte. Ledger 072 remains `eb16466fdbff8fb2bc07bd02a07198b8426fb6452be3dd1f256cbff4af0547d3`.

## 9. Remaining issues

Remaining work is F073-02 only: create the release manifest, release notes, publication index/Gopher map, package inventory, supersession metadata, link audit, and assembled RC package. Executable runners and a candidate campaign remain later implementation/certification work. No unresolved semantic issue or new compatibility investigation is required.

## 10. Completion assessment

I074 is complete. The standard, policy, conformance specification, profile registry, profile-case mapping, and frozen conformance tables are present and synchronized. All artifacts have hashes and validation records. Compatibility decisions, proposition blocks, dispositions, applicability, test IDs, and oracle semantics remain unchanged. Remaining work is limited to package assembly, manifest creation, publication, and later implementation certification.
