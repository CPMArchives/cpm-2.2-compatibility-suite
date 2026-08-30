# Investigation 072 - Final Release Candidate Engineering Gap Assessment

## 1. Objective and scope

This investigation determines whether the BetterCP/M CP/M 2.2 compatibility specification is ready to proceed to controlled release-candidate preparation. It audits existing evidence and release authority only. It performs no new CP/M research, changes no compatibility proposition, modifies no prior artifact, creates no release package, and implements no BetterCP/M code.

Evidence classes are A (documented CP/M behavior), B (DRI implementation behavior), I (controlled experimental observation), and D (project/release decision). The final readiness answer is **NO, not yet**: the normative research core is complete, but four release-integration blockers must close first.

## 2. Authoritative inputs

The primary contract is Ledger 071, SHA-256 `e8e1acd1ddeb74daf9e2a3642abf3ab8917eff48058ff217f42152abf48e15d5`. It is supported by I069's canonicalization audit, I070's 49-row policy resolution, and I071's frozen framework. Release-facing files reviewed are `01 Compatibility Policy.txt`, `03 Conformance Strategy.txt`, and `compatibility/gophermap`. Their hashes and the exact I069-I071 inputs are preserved in `hashes/source-inputs.sha256`.

The ledger has 627 unique contiguous identifiers 0001-0627: 458 REQUIRED, 116 NOT GUARANTEED, 53 NOT REQUIRED, and zero POLICY PENDING. I071 supplies 62 unique parent tests, 627 unique cases, and 627 unique oracles.

## 3. Relationship to previous investigations

I069 repaired duplicate numbering, cross-references, source history, and processor propositions. I070 resolved every pending policy choice into generic, profile, optional, non-guaranteed, or outside-scope treatment. The controlled Ledger 070/071 state incorporates those decisions. I071 converted the prior design into a versioned test, oracle, evidence, campaign, failure, and certification framework.

I072 does not reopen those conclusions. It asks whether that authority is assembled coherently enough to start RC preparation without improvising policy or framework semantics.

## 4. Compatibility readiness assessment

The compatibility boundary itself is ready. [A/B/I/D: I045-I058, I063-I070, Ledger 071.] The ledger distinguishes mandatory generic behavior, additive named-profile behavior, optional features, behavior software must not assume, and excluded behavior. Commitments are observable rather than implementation-prescriptive. Processor, BIOS/device, machine, CCP/presentation, error, and application boundaries are layered so profiles add but cannot waive generic requirements.

The public compatibility policy is not release-ready. [D: `01 Compatibility Policy.txt`; I070.] It remains Draft 0.1, includes obsolete DEFERRED/UNRESOLVED final-disposition language, and does not publish the final profile/NOT GUARANTEED model. The canonical evidence is clear, but the public policy currently presents an earlier workflow rather than the resolved release contract.

## 5. Ledger readiness assessment

Ledger readiness passes. [I/D: I069; I070; I071 audits.] Identifiers are contiguous and unique; every proposition has a final disposition, evidence, and Conformance field; I071 maps every proposition to one case and oracle. No structural, disposition, or traceability defect blocks RC work.

Ledger 071 must be the explicit immutable authority in the eventual release manifest. Historical ledgers may remain available, but the current directory and Gopher index do not adequately prevent a reader from choosing an older version.

## 6. Policy readiness assessment

Substantive policy readiness passes at the canonical evidence level. [D supported by A/B/I: I070 matrix and Ledger 071.] All 49 pending entries were resolved; 28 profile-required, three optional, eleven non-guaranteed, one outside-scope, and six generic decisions were integrated. No unresolved compatibility-policy question remains.

Release applicability does not yet pass. [D: I070 section 12; I071 manifest schema.] Stable public profile identifiers, versions, inheritance, and first-RC included/available/excluded status are absent. A generic-only RC is possible, but that exclusion must itself be explicit and all conditional cases must resolve deterministically.

## 7. Conformance readiness assessment

Framework definition readiness passes. [D/I: I059; I062; I071.] Test IDs, proposition cases, oracles, applicability, evidence, dependencies, campaign phases, result states, aggregation, and certification levels are defined and machine-audited. No framework redesign is required.

Publication readiness fails because `03 Conformance Strategy.txt` still says only “Draft 0.1 — Under development.” I071's authority must be promoted into a versioned public conformance specification. Executable runners and fixtures remain implementation follow-up: their absence blocks certifying a candidate, but it is not missing compatibility research.

## 8. Release artifact readiness assessment

`probes/release-artifact-checklist.tsv` audits the required set. Ledger, frozen inventory, cases/oracles, certification rules, and evidence schemas are ready. The compatibility standard is only partially assembled; the conformance specification is defined but unpublished; the profile registry is partial; the release manifest is missing; and the publication index is stale.

The current Gopher index points to `02 Compatibility Ledger.txt`, which does not exist, describes the structure as intentionally incomplete, and does not identify Ledger 071 or I071 as authoritative. This is a publication defect, not a compatibility proposition.

## 9. Identified gaps

Nine gaps are recorded in `probes/gap-register.tsv`. Four concern release authority: synchronized policy, public conformance specification, profile registry/applicability, and the release manifest. Two concern publication hygiene: current links and supersession labels. Two concern later implementation/certification execution. One concerns future corpus and scarce-hardware endorsements.

No gap calls for new CP/M behavior research, ledger renumbering, disposition change, or conformance redesign.

## 10. Gap classifications

**RELEASE BLOCKER:** G072-01 through G072-04. These must close before controlled RC preparation begins because otherwise the preparation process would have to choose normative policy, profile scope, or authority precedence ad hoc.

**RELEASE RECOMMENDATION:** G072-05 and G072-06. They should close during RC assembly and certainly before publication, but they do not alter the standard's semantics.

**IMPLEMENTATION FOLLOW-UP:** G072-07 and G072-08. Runners, fixtures, and a BetterCP/M campaign are required before product certification, not before freezing the specification documents.

**FUTURE ENHANCEMENT:** G072-09. Expanded corpus/hardware endorsements remain separately scoped.

## 11. Required actions before release candidate preparation

1. Publish a synchronized, versioned compatibility policy derived from I070 and Ledger 071.
2. Promote I071 into a versioned public conformance specification while preserving its frozen identifiers and oracle semantics.
3. Freeze a profile registry with stable IDs, versions, inheritance, required cases, and first-RC status; explicitly permit a generic-only RC if that is the decision.
4. Create a machine-verifiable release manifest binding policy, Ledger 071, conformance specification and tables, profile registry, certification/evidence rules, versions, hashes, authority, and supersession order.

These are controlled editorial and release-engineering actions. They must not silently change proposition text, dispositions, applicability, or I071 oracles. Link repair and historical supersession labeling should accompany package assembly.

## 12. Final release readiness conclusion

**The BetterCP/M CP/M 2.2 compatibility specification is not yet ready to proceed to controlled release-candidate preparation.** The behavioral specification, canonical ledger, resolved policy decisions, and frozen conformance framework are complete and internally consistent. The blocking deficiency is that these authorities have not been consolidated into release-facing normative documents, a frozen profile registry, and a hash-bound release manifest.

Once G072-01 through G072-04 close with validation and without semantic drift, no further compatibility investigation is required before RC preparation. Executable conformance tooling and a candidate campaign remain subsequent implementation/certification work.

Final review: every investigation question is answered; findings cite evidence sources; all nine gaps are classified; compatibility requirements are separated from implementation and release choices; unsupported assumptions are excluded; and no Compatibility Ledger, previous investigation artifact, or BetterCP/M implementation file was modified.
