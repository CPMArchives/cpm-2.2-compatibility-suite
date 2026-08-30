# Investigation 071 - CP/M 2.2 Conformance Framework Finalization

Evidence label: **I071 CONFORMANCE FRAMEWORK FINALIZATION subsystem IG AG**

## 1. Objective and scope

This investigation converts the I052/I059 conformance design, the I062 pilot lessons, the canonical I069 numbering, and the resolved I070 policy into a normative, reproducible certification framework. It defines test and case identity, exact proposition oracles, evidence, campaign ordering, result aggregation, and certification claims. It does not add CP/M behavior, execute a candidate, or alter BetterCP/M.

The authority is `02 Compatibility Ledger - Investigation 070.txt`, SHA-256 `c835279df858edc752b1393a3bcc3238671885138e1fa4a8df8fc44b518c9dfa`. Evidence classes are A (documented behavior), B (DRI implementation), I (experimental observation), and D (unresolved policy). I071 is framework evidence, not fresh behavioral observation.

## 2. Relationship to previous investigations

I052 supplied the regression inventory concept. I059 defined 62 parent identifiers and preliminary schemas. I062 proved that the design distinguishes product failures from blocked fixtures but found compound identifiers too coarse for normative PASS. I069 established 627 unique canonical propositions. I070 eliminated all POLICY PENDING dispositions and made profile applicability explicit.

I071 preserves the 62 I059 identifiers and adds a stable case layer. It regenerates traceability from Ledger 070 rather than inheriting I059's pre-I069 duplicate numbering or pre-I070 policy classes.

## 3. Conformance inventory

`frozen-test-inventory.tsv` freezes 62 top-level test identifiers at version 1.0.0. `conformance-framework-matrix.tsv` defines 627 proposition cases. Each case has one ledger entry, parent identifier, versioned oracle, applicability, evidence rule, pass/fail rule and certification impact.

The 627 cases classify as 430 REQUIRED, 28 PROFILE REQUIRED, 3 OPTIONAL, 116 NOT GUARANTEED, and 50 OUTSIDE SCOPE. 12 parent identifiers remain supplemental ecosystem/profile compositions without primary proposition ownership; they may strengthen a claim but never replace a failed narrow case.

## 4. Test identifier freeze

The 62 parent IDs are immutable at version 1.0.0. Normative child IDs use `<parent>-P<ledger-entry>`, for example `MEM-001-P0001`. A correction that changes an oracle or procedure increments its version; a semantically different case receives a new ID. Published IDs are never reassigned or silently edited.

Parent PASS is conjunctive: every applicable REQUIRED or PROFILE REQUIRED child must pass. A child FAIL fails the parent. A child BLOCKED prevents PASS. NOT_APPLICABLE is valid only from an unselected named profile or optional claim recorded in the campaign manifest.

## 5. Requirement traceability

`ledger-case-traceability.tsv` maps every canonical entry 0001-0627 exactly once to a primary normative case and oracle. No blank or unknown mapping remains. Profile applicability is copied from Ledger 070 into each case. Manual validation remains appropriate for physical hardware, timing, device, fault, presentation, and reviewer-dependent cases, but manual cases use the same result schema and artifact hashes.

The mapping is a certification assignment, not a new compatibility proposition. A candidate may implement one runner for multiple cases, but must still emit separate result records and observations for each case.

## 6. Oracle definitions

`oracle-definitions.tsv` freezes 627 oracle IDs at version 1.0.0. REQUIRED cases use positive predicates from the ledger's Conformance field. PROFILE REQUIRED cases use the same predicate only when the named profile is selected. NOT GUARANTEED cases accept documented variation and forbid promotion of incidental DRI state into a portable guarantee. OPTIONAL cases are excluded unless claimed, then tested for isolation. OUTSIDE SCOPE cases are anti-requirements: they cannot become positive baseline gates.

PASS requires the complete applicable predicate and evidence. DRI equality is not an oracle unless the selected profile explicitly requires it. Missing bytes, truncated transcripts, inferred observations, or source reconstruction cannot satisfy an experimental oracle.

## 7. Campaign structure

`campaign-phases.tsv` defines manifest, foundation, interface, storage, command/failure, ecosystem/profile, and review phases. Dependencies gate only dependent cases; an independent case result remains reportable. A blocked prerequisite propagates BLOCKED rather than FAIL unless the candidate itself caused the prerequisite failure.

Every campaign begins from verified pristine fixtures and an immutable manifest binding candidate, Ledger 071, inventories, oracles, profiles, runner, emulator/build, environment, repetitions, media, and artifact index. Mutation tests restore fixtures between scenarios.

## 8. Evidence requirements

The minimum evidence is the campaign manifest, raw transcript or observation, normalized result, probe/runner sources, executable hashes, tool exit status, environment/profile identity, dependency run IDs, and content-addressed artifacts. Mutable-media cases preserve pristine and after images and their hashes. Manual cases record reviewer identity, time, authority, and the exact observed artifact.

The schemas intentionally distinguish raw evidence from normalized observations. Every accepted claim must be independently recomputable from preserved artifacts; descriptive filenames alone are insufficient.

## 9. Certification model

`certification-levels.tsv` defines BASELINE, INTERFACE, FULL-SYSTEM, PROFILE, OPTIONAL, and non-certifying DEVELOPMENT reports. A certificate states candidate identity, claim level, selected profiles, excluded optional features, campaign ID, framework versions, ledger hash, and all non-PASS results.

Generic REQUIRED cases cannot be waived. A profile may add gates but cannot weaken the underlying level. Successful applications and utilities are supplemental composition evidence and cannot conceal a failed narrow requirement. BLOCKED or ERROR prevents certification at every level whose gate includes that case.

## 10. Failure handling

`failure-handling.tsv` freezes PASS, FAIL, BLOCKED, NOT_APPLICABLE, and ERROR. Non-PASS records classify PRODUCT, FIXTURE, ENVIRONMENT, FRAMEWORK, or UNRESOLVED. Framework/fixture repair permits a new run ID; prior results remain preserved. Product exceptions are reported, never edited into the oracle after observing the candidate.

Partial conformance is a result report, not certification. A candidate may receive a lower claim only if a separately declared campaign scope satisfies every gate at that lower level; failures remain disclosed.

## 11. Recommended conformance updates

Adopt the I071 matrices and schemas as normative framework version 1.0.0. Require proposition-level result records, immutable manifests, content-addressed artifacts, dependency links, explicit profile selection, and conjunctive aggregation. Migrate future runners incrementally while retaining the frozen parent IDs.

No compatibility proposition or disposition update is recommended. Runner implementations remain future engineering work.

## 12. Existing-entry impacts

All 627 Ledger 070 entries receive explicit test traceability. Their proposition text, disposition, applicability, evidence, and Conformance wording remain unchanged. I071 should appear in the ledger source catalogue and history as the framework authority, but its label should not be appended to proposition evidence as though it were new behavioral proof.

The separately generated Ledger 071 is therefore cumulative and contract-preserving: it adds source/history/traceability metadata only and keeps every numbered proposition block byte-identical to Ledger 070.

## 13. Open questions

No policy question blocks framework freeze. Implementation choices remain for runner language, certificate serialization/signature, long-term artifact storage, acceptable independent reviewer authorities for scarce hardware, repetition counts for asynchronous/fault tests, and which candidate/profile combination should receive the first full campaign. These are campaign or release decisions, not CP/M compatibility propositions.

## 14. Release implications

The compatibility contract is now mechanically traceable and free of POLICY PENDING cases. Certification still requires executable runners, verified fixtures, and actual candidate campaigns; I071 alone certifies nothing. A release claim must cite a complete campaign and may not substitute source inspection or corpus success for missing narrow observations.

Completion audit: the 62 parent IDs are unique and frozen; 627 contiguous unique ledger entries map to 627 unique cases and oracles; no oracle is blank; profile/optional applicability is explicit; schemas and campaign phases are present; source hashes and final artifact hashes are recorded; no prior investigation, implementation, or canonical ledger was modified while producing the report. The detailed machine audit is `probes/validation-audit.txt`.
