# Investigation 062 - CP/M 2.2 Compatibility Conformance Pilot Execution

## 1. Objective and scope

This investigation executes a development pilot of the conformance process specified by I052 and I059. It asks whether the inventory, traceability map, result schema, pass/fail rules, phased workflow and evidence requirements are sufficient to evaluate a CP/M-compatible implementation in practice.

The pilot runs nine selected I059 test identifiers against DRI CP/M 2.2 and Cromemco CDOS 2.58 on identical emulated hardware. It covers foundation, interface, command/lifecycle, BIOS, memory and ecosystem behavior. It does not certify either system, implement BetterCP/M, or claim execution of all 62 inventory identifiers. No Compatibility Ledger or prior investigation artifact was modified.

Evidence classes are **A** documented behavior, **B** DRI implementation, **I** experiment and **D** unresolved policy/process. Result classifications use I059's PASS, FAIL and BLOCKED values; investigation conclusions use **RELEASE READY**, **ADDITIONAL TESTING REQUIRED**, **POLICY PENDING** and **NOT REQUIRED**.

## 2. Compatibility standard

The pilot evaluates externally observable CP/M 2.2 behavior using the current Compatibility Ledger, documented interfaces, DRI reference behavior, common programming practice and significant software dependencies. Documentation remains normative where an independent implementation differs.

The I059 pass rules are applied without partial-credit inflation. An applicable REQUIRED observation must occur. Selected POLICY PENDING behavior is tested only under an explicit profile. NOT GUARANTEED and NOT REQUIRED entries are evaluated as permitted variation or anti-requirements, not as demands for DRI residue. A compound identifier is BLOCKED if only a subset of its stated cases ran.

The authoritative baseline is `02 Compatibility Ledger - Investigation 061.txt`, SHA-256 `61f231cb13d457b9c2e5b3a682f3fd78688cb5a47d977997b1eb3fda50f7b81a`.

## 3. Relationship to previous investigations

I052 defined regression categories and proposition-to-test concepts. I053 showed that historical software adds useful composition evidence. I055 defined baseline, strict ecosystem and profile-qualified claims. I059 formalized 62 test identifiers, phased dependencies, pass/fail rules and a result-record schema. I061 supplied the first controlled cross-implementation differential pair and exposed full-interface failures that common software alone did not reveal.

I062 imports immutable copies of the I059 inventory, schema, rules, organization and traceability map. It reuses proven probes from I041, I043 and I061, but all accepted transcripts and mutable disk results are fresh I062 executions. Reuse is explicit and source-backed probes rebuild byte-identically.

## 4. Conformance environment

**Reference:** DRI CP/M 2.2 Cromemco image, pristine SHA-256 `b1b3245029a19948ec04dff915595c3369a9f2d0f6bd028e8883ab7f2a53c5b2`.

**Candidate:** Cromemco CDOS 2.58, pristine SHA-256 `7ad2d79c859f28e5deee787a2e0d6f3aef24d62b1d65a64a307afc9d88acf754`. The declared claim is a development application subset; BIOS-001 is deliberately evaluated under a full BIOS-visible claim to demonstrate scoped failure.

Both use z80pack revision `91fd28eb04e675c2127df88ed3f40675e15282e2`, simulator releases 1.39/1.19, Z80, 64K Cromemco Z-1, the same RDOS ROM/FDC and IBM-3740 media. Commands are deterministic and input is scripted. Evidence includes raw transcripts, pristine/after images, extracted output files, probe sources/binaries/listings, rebuild products, inventory/schema copies and hashes.

The software corpus case is one identical DRI `PIP.COM` copy workflow plus each CCP's directory and missing-command handling. It is intentionally narrow.

## 5. Test execution results

Nine I059 identifiers were selected: MEM-001, BDOS-STATE-001, BDOS-CALL-001, MEM-003, CCP-007, BIOS-001, CCP-003, UTIL-001 and ERROR-001. Each has one schema-conformant record per implementation in `probes/conformance-pilot-records.tsv`.

Across 18 records the result is 9 PASS, 2 FAIL and 7 BLOCKED. DRI has 5 PASS, no FAIL and 4 BLOCKED. CDOS has 4 PASS, 2 FAIL and 3 BLOCKED.

PASS cases demonstrate that the record schema and disposition-aware rules can accept different numeric targets/SP/layout while requiring the public entry environment, version/current state, writable TPA and three termination paths. CDOS fails BDOS-CALL-001 because selector 41 diagnoses and terminates rather than returning zero. It fails BIOS-001 because native slots 0Fh and 10h are not the documented JMP entries.

CCP-003, UTIL-001 and ERROR-001 are BLOCKED on both because the available execution covers only a subcase. DRI BDOS-CALL-001 is also BLOCKED: selector 41 passes, but the compound identifier demands selectors 0-40 plus all register/result criteria. No subcase is mislabeled PASS.

## 6. Requirement traceability analysis

The I061 ledger has 652 proposition lines and 622 unique identifiers. The I059 traceability file has 652 rows, the same 622 identifiers, and no blank primary-test field. It references 51 unique primary identifiers; the other 11 of the 62 inventory identifiers are supplemental interface/ecosystem definitions.

This is complete syntactic traceability, but not complete executable traceability. One identifier may map broad ranges containing multiple dispositions and test modes. A primary mapping does not identify which exact sub-observation in a compound runner proves each proposition, and a row-level PASS could otherwise be mistaken for proof of every mapped entry.

The process therefore needs a case layer below `test_id`: stable case IDs, exact proposition subsets, fixture version, oracle version and dependency-result links. Until that exists, complete proposition coverage is **ADDITIONAL TESTING REQUIRED**, despite the sound high-level map.

## 7. Pass/fail analysis

I059's REQUIRED, POLICY PENDING, NOT GUARANTEED and NOT REQUIRED rules are conceptually effective. The pilot objectively accepts differing addresses and presentations, rejects two documented CDOS violations and prevents an incomplete utility run from becoming a pass. Failure classification (`product` versus `fixture`) is especially useful.

The weakness is granularity. Inventory expected observations are prose and often conjunctive. PASS/FAIL is objective only when a probe emits a machine-checkable marker or the criterion names exact observable bytes/relations. BLOCKED currently conflates missing fixture, missing provider/profile, incomplete subcases and unavailable authority; the `failure_classification` field reduces but does not eliminate this ambiguity.

For normative use, every compound row needs versioned subcases and explicit aggregation: all required subcases pass; selected-profile cases apply; variation cases accept an enumerated set or non-assertion review; blocked dependencies propagate without erasing independent results. The rule framework is **RELEASE READY**; the present executable oracle set needs **ADDITIONAL TESTING REQUIRED**.

## 8. Evidence collection analysis

Raw transcripts, exact environment description, source and executable hashes, before/after media, generated outputs and result records were sufficient to independently review every PASS and FAIL in this pilot. The CDOS failures can be located directly in one transcript, and the PIP payload can be checked independently of directory presentation.

Improvements are required for scale. `artifact_links` are descriptive paths rather than content-addressed objects; environment identity does not have one immutable manifest; result records do not carry timestamps/tool exit status; dependency results are not linked by run ID; and reviewer identity is underspecified for manual/profile cases. Repetition is a count but lacks per-repetition child records.

Required process improvement: bind each campaign to a manifest containing ledger, inventory, oracle, runner, emulator/build, profile, fixture and artifact hashes. This is conformance-process metadata, not a CP/M behavior proposition.

## 9. Software corpus analysis

The identical DRI PIP utility succeeds on both systems and creates the expected payload. This is useful composition evidence across CCP loading, BDOS file lifecycle, DMA, BIOS disk service and termination. It also reproduces the permitted DRI/CDOS final-length representation difference without confusing it with failure.

However, UTIL-001 bundles DIR/ERA/REN/SAVE/TYPE, PIP, STAT, SUBMIT and DDT. One PIP/DIR workflow cannot satisfy it. More importantly, broad software should run only after its mapped narrow prerequisites pass; CDOS's PIP success does not erase its selector-41 or BIOS failures.

Corpus integration is **RELEASE READY** as supplemental evidence policy. The present corpus coverage remains **ADDITIONAL TESTING REQUIRED** for broad endorsement, particularly development toolchains, business software, successful communications transfer and matching hardware profiles already identified by I060.

## 10. Compatibility conclusions

1. The phased methodology, disposition-aware rules, failure reduction and record schema are practical and **RELEASE READY** as a development conformance framework.
2. The current 62-row inventory is **ADDITIONAL TESTING REQUIRED** before normative certification because many rows are specifications, not complete executable fixtures/oracles.
3. Full syntactic ledger mapping does not prove meaningful executable coverage; stable subcase-to-proposition traceability is required.
4. Evidence preservation is adequate for this small pilot but needs an immutable campaign manifest and content-addressed run relationships.
5. The process correctly distinguishes product failures, permitted implementation variation and fixture blockage.
6. Profile applicability and the release-wide disposition of pending requirements remain **POLICY PENDING**.
7. Internal architecture validation and DRI-private mechanism checks are **NOT REQUIRED**.

## 11. Proposed ledger additions

None. The pilot identifies conformance-process and fixture requirements, not new application-visible CP/M behavior. Adding propositions about manifests, case identifiers or runners would mix certification machinery into the compatibility contract.

Future behavioral campaigns should propose ledger additions only if an executed case reveals a repeatable missing CP/M-visible requirement. Neither CDOS failure is new; both are already represented by existing entries.

## 12. Existing-entry updates

No ledger file was modified and no disposition change is proposed. At the next authorized integration, `I062 CONFORMANCE PILOT VALIDATION subsystem IG AG` may strengthen evidence for the tested public entry, version/state, writable TPA, termination, out-of-range and BIOS-vector propositions.

The CDOS results confirm rather than revise the I061 conclusions: selector-41 zero and the 17-entry BIOS remain REQUIRED for their applicable claims. Exact SP, gateway targets and presentation remain outside required equality. Process BLOCKED results must not be attached as behavioral evidence.

## 13. Open questions

1. What stable case-ID and aggregation format should sit below each compound I059 test identifier? (**D**)
2. Which exact ledger/inventory/profile manifest defines the first normative claim? (**D**)
3. How should dependency BLOCKED results propagate while preserving independently testable subcases? (**D**)
4. What repetition and timing record structure is required for asynchronous console, communications and physical-error cases? (**D**)
5. Which manual/profile authorities and reviewer identities are acceptable for hardware cases? (**D**)
6. Should application-only, BDOS-complete and BIOS-visible claims be formal conformance levels rather than informal scope text? (**D**)
7. What minimum corpus supports a broad historical-software endorsement? (**D**)

## 14. Conformance implications

A second pilot should convert one complete vertical slice—preferably foundation plus one console, storage, command/error and utility chain—into versioned subcases with executable oracles and dependency-linked results. It should then run the full slice on DRI and an independent implementation. Only after that should the process attempt all 62 identifiers.

Normative reporting must state claim level and profiles, never count BLOCKED or unselected pending cases as PASS, and never let a successful application replace failed narrow requirements. A full-BIOS claim for CDOS 2.58 fails this pilot; a narrower application-subset claim can still report the cases it passes.

Completion audit: the report has all 14 required sections; 18 result records use the I059 schema; accepted transcripts, source-backed probes, rebuild products, pristine/after images, extracted payloads, I059 reference files, traceability analysis and hashes are present. All source-backed probes rebuild byte-identically. The authoritative ledger remains SHA-256 `61f231cb13d457b9c2e5b3a682f3fd78688cb5a47d977997b1eb3fda50f7b81a`. Protected-tree comparison excludes only the new Investigation 062 directory and is empty. No BetterCP/M implementation or prior artifact was modified.

