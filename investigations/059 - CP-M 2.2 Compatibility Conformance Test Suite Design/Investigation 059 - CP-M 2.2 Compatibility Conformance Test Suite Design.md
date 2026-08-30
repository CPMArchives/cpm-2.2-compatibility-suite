# Investigation 059 - CP/M 2.2 Compatibility Conformance Test Suite Design

## 1. Objective and scope

This investigation defines the conformance contract for verifying CP/M 2.2 compatibility claims. It formalizes the I052 regression inventory into complete test definitions, adds claim levels, dependencies, disposition-aware pass rules, software-corpus integration and reproducible evidence requirements.

It does not implement a test runner, framework, database, dashboard or BetterCP/M component. It validates application-visible compatibility rather than internal architecture, and it does not modify the Compatibility Ledger or prior evidence.

## 2. Compatibility standard

Conformance is measured against the authoritative ledger and the declared baseline, strict-community, optional and hardware profiles established through I058. Evidence remains **A** documented behavior, **B** DRI implementation/software behavior, **I** controlled observation and **D** unresolved policy.

Every expected result is interpreted by disposition:

- **REQUIRED:** positive externally observable acceptance criterion.
- **POLICY PENDING:** diagnostic until a profile selects it, then positive within that profile.
- **NOT GUARANTEED:** permitted-variation/non-assertion criterion.
- **NOT REQUIRED:** anti-requirement preventing private mechanisms from becoming acceptance criteria.

Any later ledger citation must use exactly `I059 CONFORMANCE TESTING VALIDATION subsystem IG AG`.

## 3. Relationship to previous investigations

I052 supplies a 62-test regression inventory and proposition-level coverage for all 652 ledger lines. I053 supplies 13 representative software records. I055 defines claim categories. I056 maps requirements to responsibility owners; I057 defines personality/provider validation ownership; I058 defines extension-preservation rules.

I059 preserves those identifiers and semantics. `probes/proposed-conformance-test-inventory.tsv` adds classification treatment, execution phase, dependencies and evidence to each I052 test. It does not replace the original narrow investigation evidence or claim that every proposed test has already run against BetterCP/M.

The ledger has 622 unique identifiers; the 652 line count includes the known duplicate 0248-0277 block. Duplicate propositions map to the same tests and must not be counted as additional semantic coverage.

## 4. Requirement-to-test mapping

Every ledger proposition line requires conformance treatment, but not always a positive executable assertion. All 652 lines map to at least one primary test; no test reference is unknown.

The 62 definitions consist of:

- 8 CCP tests;
- 1 general BDOS-call test;
- 5 BDOS console tests;
- 3 BDOS state tests;
- 12 BDOS file/storage tests;
- 5 error/recovery tests;
- 7 BIOS/platform tests;
- 6 memory/runtime tests;
- 4 utility/toolchain tests;
- 4 application tests;
- 4 communications tests;
- 3 hardware-profile tests.

A test can cover propositions with several dispositions. Fifty-six tests contain REQUIRED mappings, 39 POLICY PENDING mappings, 45 NOT GUARANTEED mappings and 37 NOT REQUIRED mappings. These totals overlap. Each proposition receives its own decision rule; the suite must not demand an unspecified residual value merely because the same probe also checks a required result.

Eleven inventory items are supplemental ecosystem/profile acceptance definitions not used as a primary test in the proposition map; their classifications are derived from their declared scope. They supplement, never replace, the proposition-level mapping.

## 5. Conformance categories

Five result/claim categories are proposed:

1. **Development subset.** A named incomplete set for engineering progress. It reports omissions and may not be labelled “CP/M 2.2 conformant.”
2. **Baseline CP/M 2.2.** Every applicable baseline REQUIRED proposition plus negative/variability rules. Any applicable REQUIRED failure defeats the claim.
3. **Strict community.** Baseline plus SUBMIT/XSUB, writable/executable TPA and applicable historical utility/tool workflows.
4. **Profile-qualified.** Baseline or strict plus every selected terminal/device/communications/error/processor/hardware profile. Unselected profiles are not implied.
5. **Corpus-validated endorsement.** A passing underlying claim exercised by a pinned named software corpus. This is evidence breadth, not a substitute compatibility level.

“Partial compatibility” is therefore an explicit development/subset report, not a weakened CP/M label. “Full” always means complete for the named baseline/strict/profile scope, not universal emulation of every historical machine or application.

## 6. Test organization

Tests execute in dependency order:

- **Phase 0:** validate claim/profile manifests and immutable fixtures.
- **Phase 1 (3 tests):** entry/page-zero, public BDOS gateway and BIOS discovery foundations.
- **Phase 2 (19 tests):** console/state/memory/lifecycle and BIOS interfaces.
- **Phase 3 (12 tests):** FCB/DMA/directory/sequential/random/storage behavior.
- **Phase 4 (13 tests):** eight CCP/command and five controlled failure/recovery cases.
- **Phase 5 (15 tests):** utility/application/communications/hardware profile composition.

Each mutating or destructive case begins from a restored fixture. One failure scenario is injected per fault case. A dependent test may be marked BLOCKED when its healthy prerequisite fails, but blocked is never converted to pass. Foundation failure should stop dependent execution while preserving evidence.

Most observations are automatable. Profile/manual or reviewed validation remains appropriate for damaged media, physical/visual devices, direct hardware profiles and selected utility presentation. Manual review must record the profile, raw evidence and reviewer action; it cannot replace an unperformed deterministic test.

## 7. Software corpus integration

Representative software tests contribute composition evidence only after their mapped narrow tests pass. They confirm that CCP, BDOS, BIOS, memory, storage and profiles work together without identifying exact register/byte semantics by themselves.

Each corpus record pins software/version/hash, provenance, environment, profiles, deterministic input, expected OS-level observations and before/after image relation. Startup is smoke evidence, not full functional certification. Vendor UI text, banners and protocol diagnostics are ignored unless a named presentation profile independently requires them.

Failure classification precedes judgment: fixture/harness defect, implementation defect, permitted variation, unresolved policy, unsupported/mismatched profile or blocker. An unexplained repeatable dependency begins a new investigation; it does not automatically become a compatibility rule.

I053's 13 records form the initial corpus. Successful paired communications, matching hardware and several business/database/BBS/printer/compiler categories remain explicit endorsement gaps.

## 8. Pass/fail criteria

Allowed structured results are PASS, FAIL, NOT-APPLICABLE, BLOCKED and UNRESOLVED, constrained by classification and claim level.

**REQUIRED:** PASS only when every applicable expected external observation occurs. NOT-APPLICABLE requires genuine profile/configuration exclusion. No waiver is allowed within the same claim.

**POLICY PENDING:** Unselected cases are diagnostic/NOT-APPLICABLE or UNRESOLVED, never baseline passes. Once selected, failure defeats that profile and any aggregate claim depending on it.

**NOT GUARANTEED:** PASS means the implementation lies within the permitted set and the test does not demand one unspecified result. A single repeated value does not create a guarantee. Differential variants should be accepted where practical.

**NOT REQUIRED:** PASS means required public behavior works without inspecting or depending on the excluded DRI mechanism. Safe substitution/reorganization must remain conforming.

Implementation variation is acceptable only within the relevant NOT GUARANTEED/NOT REQUIRED boundary. A visible contradiction of a REQUIRED proposition is not excused by architectural difference. Exceptions narrow the declared claim or trigger a policy investigation; they do not silently rewrite expected results.

## 9. Evidence traceability

The traceability chain is:

`ledger hash -> proposition -> original A/B/I/D evidence -> I052 test identifier -> I056/I057 owner -> I059 run record -> raw artifacts`.

Every run record includes run/test IDs, exact ledger entries, claim level/profiles, disposition treatment, expected and actual observations, result, environment/build, repetition count, fixture/software/configuration hashes, artifact links and failure classification. Manual/profile cases also record review action.

Raw evidence includes console/BIOS transcripts, registers, memory, FCB/DMA and call activity where relevant, plus before/after images or byte/sector/directory diffs for mutations. Results are invalid for certification if expected output is reconstructed from source after an unperformed test, fixtures are not restored, raw output is discarded or profile applicability cannot be reproduced.

The schema and preservation checklist are `probes/result-record-schema.tsv` and `probes/evidence-preservation.txt`.

## 10. Compatibility conclusions

**REQUIRED:** Every applicable REQUIRED proposition receives positive external validation; claim/profile identity, dependencies, raw evidence and reproducibility are mandatory. Narrow tests precede corpus composition tests.

**POLICY PENDING:** Unselected profile tests remain diagnostic and cannot fail or pass the baseline. Selection activates explicit positive criteria.

**NOT GUARANTEED:** The suite must accept permitted variation and prevent accidental guarantees of residual/private state.

**NOT REQUIRED:** Conformance must not inspect internal architecture, DRI private mechanisms or invisible algorithms. Alternative implementations are valid when public results agree.

The existing 62-test inventory is sufficient as a formal conformance specification when combined with the disposition rules, claim levels, dependency phases and evidence schema defined here. It specifies what to validate without specifying test infrastructure.

## 11. Proposed ledger additions

None. Test process, claim levels and evidence preservation are conformance metadata, not CP/M application-visible behavior. Adding “must pass the suite” would be circular and duplicate the propositions the tests evaluate.

No missing runtime requirement or classification correction was found. The known duplicated ledger block remains an editorial issue outside this investigation.

## 12. Existing-entry updates

No ledger file was modified and no wording/disposition update is proposed.

At a future authorized integration, `I059 CONFORMANCE TESTING VALIDATION subsystem IG AG` may be used in test/claim traceability documentation. It should not replace the original behavioral evidence for any proposition and should not be cited as proof that a proposed test has run against an implementation.

Stable test identifiers should be retained when a test procedure is refined; changed expected semantics require a new investigated ledger decision, not an unnoticed inventory edit.

## 13. Open questions

1. Which project artifact will bind a release to ledger, test-inventory, profile and result-manifest hashes? (**D**, process)
2. Which of the 50 POLICY PENDING proposition lines will be selected for the first conformance claim? (**D**)
3. What repeat count and timing tolerance are sufficient for asynchronous console/serial/retry cases? (**D**)
4. Which physical/manual hardware environments are authoritative enough for profile certification? (**D**)
5. What independent review is required for manual, destructive and profile cases? (**D**, certification process)
6. Which rights-cleared corpus expands spreadsheet, database, business, BBS, printer and compiler coverage? (**D**)
7. How should equivalent alternative evidence be accepted without making the test runner itself normative? (**D**)
8. When will the ledger duplicate block and Function-37 overlap be normalized while preserving stable identifiers? (**D**, editorial)

## 14. Conformance implications

A conformance declaration names its exact scope and cannot claim beyond tested profiles. It publishes complete results, including NOT-APPLICABLE, BLOCKED and UNRESOLVED cases, rather than reporting only passes. Any applicable REQUIRED failure defeats the associated claim until corrected or the claim is honestly narrowed.

The proposed inventory is implementation-independent: it specifies inputs and observable results. A runner may use any architecture so long as evidence is reproducible and manual reconstruction does not replace execution. Provider substitution and extension-enabled/disabled runs should be used to expose accidental private dependencies.

Final review confirms that requirements are evidence-based, tests target external compatibility rather than implementation, conformance categories are distinct, all ledger lines are mapped, and unsupported assumptions are removed.

Completion audit: this 14-section report, 62 complete test definitions, 652-line traceability map, five claim levels, phased organization, pass/fail rules, corpus policy, result schema, evidence checklist, generator, validation output and hashes are present; the authoritative Investigation 058 ledger remained unchanged; no previous BetterCP/M file or implementation changed; and no ZIP archive was created.
