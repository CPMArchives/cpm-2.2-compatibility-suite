# Investigation 069 - CP/M 2.2 Compatibility Ledger Integrity Resolution

## 1. Objective and scope

This investigation resolves the structural defects identified by Investigations 060 and 068 and produces a clean canonical Compatibility Ledger for Investigations 070-072. It is an authorized ledger-maintenance investigation: the Investigation 068 ledger remains immutable, and the corrected result is a new cumulative `02 Compatibility Ledger - Investigation 069.txt`.

The work is deliberately narrow. It normalizes identifiers, resolves a documented overlapping proposition relationship, assigns canonical identifiers and dispositions to the five I063 processor proposals, repairs the stale source catalogue, and appends cumulative history. It does not decide pending compatibility policy, redesign conformance, implement BetterCP/M, or rewrite unrelated proposition language.

## 2. Authoritative baseline

Input: `compatibility/02 Compatibility Ledger - Investigation 068.txt`, SHA-256 `f826cf83d7e611e473169c5956c6e0c8c7d604a4f1eba5d66a40709189e1ccac`.

The input contains 652 numbered proposition lines but only 622 unique identifiers. Identifiers 0248-0277 each occur twice. Existing unique identifiers are otherwise contiguous from 0001 through 0622. The input has 445 REQUIRED, 50 POLICY PENDING, 48 NOT REQUIRED, and 109 NOT GUARANTEED lines, including repeated dispositions in the duplicate block.

The input is preserved under `reference/` and was not modified.

## 3. Identifier integrity audit

The canonical ledger contains 627 proposition lines, 627 unique identifiers, no duplicates, and no missing identifier in the contiguous range 0001-0627.

Existing stable identifiers 0001-0622 were not renumbered. I063's provisional labels 0766-0770 were never canonical ledger IDs; using them would create an unexplained 143-ID gap. They are mapped to the next available canonical sequence, 0623-0627.

The complete audit is `probes/identifier-audit.txt`. Empty `missing-identifier-report.txt` and `duplicate-identifier-report.txt` files are machine-verifiable success artifacts, not omitted reports.

## 4. Duplicate block resolution

The second Investigation-011 section header and the second 0248-0277 block were verbatim duplicates. The first header and first occurrence of every entry remain unchanged. The repeated copy was removed as structural duplication, not as deletion or merger of 30 compatibility propositions.

The normalized I068 semantic set therefore contains 622 propositions: 422 REQUIRED, 49 POLICY PENDING, 47 NOT REQUIRED, and 104 NOT GUARANTEED. No evidence citation or independently testable meaning existed only in the removed copy.

The canonical transformation and complete unified diff make this disposition explicit; no silent deletion occurred.

## 5. Missing and reference integrity

No identifier was missing within the existing 0001-0622 range, and none is missing after extending the sequence through 0627. Explicit cross-references to entries 0006, 0178, 0248-0277, 0435, and 0620 all resolve in the canonical ledger.

The source catalogue in the input stopped at I029 even though cumulative evidence and history continued through I068. It now lists I001-I069 contiguously. Investigation evidence references used by retained propositions remain represented by reports in the archive. The canonical history now includes I069.

Details are in `probes/cross-reference-audit.txt`.

## 6. Function 37 overlap resolution

Entries 0435 and 0523 had the same title and substantially overlapping Function 37 behavior, but arose from different investigations and conformance scopes. Deleting either stable ID would break history and create a numbering hole. Leaving both as unqualified compatibility-status statements would preserve ambiguity.

Entry 0435 is now explicitly the canonical compatibility-status proposition. Entry 0523 remains POLICY PENDING and is retitled `Function 37 state-effect profile scope`; it conditionally states the detailed vector effects if 0435 is adopted and explicitly cites 0435. The I026 and related evidence plus inactive/current/multiple/read-only test scope remain represented.

This is a documented clarification, not a policy decision. Investigation 070 must decide whether the optional Function 37 profile is adopted.

## 7. Processor proposition dispositions

The five I063 proposals are independently testable and are not equivalent to existing entries about incidental entry/return register residue. I068 correctly identified their absence from the numbered contract. They are incorporated as follows:

| Canonical ID | I063 label | Disposition | Compatibility scope |
|---|---|---|---|
| 0623 | 0766 | REQUIRED | Generic CP/M 8080-compatible binary baseline |
| 0624 | 0767 | REQUIRED | Any explicitly declared processor profile plus inherited generic requirements |
| 0625 | 0768 | NOT REQUIRED | Z80 extensions in a generic claim without a Z80 profile |
| 0626 | 0769 | NOT GUARANTEED | Undocumented or out-of-profile processor behavior |
| 0627 | 0770 | NOT REQUIRED | Universal timing, wait-state, refresh, and interrupt topology |

Entry 0624 explicitly preserves the layered model: a processor profile may add behavior but cannot waive generic CP/M. I064 and I067 strengthen the I063 evidence. `probes/processor-proposition-dispositions.tsv` records the complete decisions.

## 8. Disposition consistency

No existing proposition disposition changed. Entry 0523 remains POLICY PENDING. Removing the duplicate block removes duplicate disposition lines only. Adding 0623-0627 changes the normalized semantic totals by exactly two REQUIRED, two NOT REQUIRED, and one NOT GUARANTEED.

Canonical totals are therefore:

- REQUIRED: 424
- POLICY PENDING: 49
- NOT REQUIRED: 49
- NOT GUARANTEED: 105

The totals sum to 627. They are recorded with input and normalized comparisons in `probes/disposition-audit.tsv`.

## 9. Required proposition preservation

Every unique REQUIRED identifier from the Investigation 068 input remains in the canonical ledger with REQUIRED disposition. The only new REQUIRED entries are 0623 and 0624. No existing REQUIRED proposition was merged into a broader statement or reduced to a profile exclusion.

The direct before/after audit compares identifier, title, and disposition. Apart from the documented 0523 clarification, all existing unique identifiers retain their titles and dispositions. The unified diff permits independent review of all textual changes.

## 10. Canonical ledger production

`canonicalize069.awk` deterministically transforms the preserved Investigation 068 input into the canonical ledger. Its allowed operations are explicit:

1. extend the source catalogue through I069;
2. remove the second duplicate Investigation-011/0248-0277 block;
3. replace entry 0523 with its cross-reference clarification;
4. insert entries 0623-0627 after 0622;
5. append the I069 cumulative-history section.

No other proposition text is intentionally rewritten. `probes/change-log.tsv` maps every change to its rationale and preservation treatment.

## 11. Validation results

The deterministic validator confirms:

- 627 proposition lines and 627 unique IDs;
- contiguous 0001-0627 ordering;
- zero duplicate and missing identifiers;
- one Investigation-011 section header;
- entries 0623-0627 present;
- entry 0523 has the explicit cross-reference title;
- I001-I069 source catalogue completeness;
- I069 cumulative history present;
- empty duplicate and missing reports.

All explicit ledger entry references resolve. Existing REQUIRED IDs are preserved. The before/after ledger diff, report artifacts, and SHA-256 manifest are included. Validation output is `I069 ledger validation PASS`.

## 12. Canonical outcome and handoff

`compatibility/02 Compatibility Ledger - Investigation 069.txt` is the authoritative baseline for Investigation 070 Policy Pending Resolution, Investigation 071 Conformance Framework Finalization, and Investigation 072 release-candidate preparation.

The canonical ledger resolves every known identifier-integrity issue and assigns explicit dispositions to all processor-profile propositions. It intentionally leaves 49 POLICY PENDING entries for Investigation 070. It does not claim that conformance or release-manifest work is complete.

Completion audit: the report, prompt, canonicalizer, preserved input, canonical ledger, full diff, identifier/duplicate/missing/reference/disposition/processor/change audits, validator and output, before/after ledger hashes, protected-tree manifests, and artifact hashes are present. The only BetterCP/M file outside the new Investigation 069 directory is the newly created canonical Investigation 069 ledger. No existing file was modified.
