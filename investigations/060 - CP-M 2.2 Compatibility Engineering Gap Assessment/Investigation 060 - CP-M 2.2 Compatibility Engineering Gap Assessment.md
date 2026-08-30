# Investigation 060 - CP/M 2.2 Compatibility Engineering Gap Assessment

## 1. Objective and scope

This investigation independently challenges whether the CP/M 2.2 compatibility work through I059 is complete enough for release. It reviews semantic coverage, evidence breadth, contradictions, ecosystem representation, undocumented behavior, cross-layer interactions and the proposed conformance process from the perspective of a new implementation claiming practical CP/M compatibility.

It does not design or implement BetterCP/M. It distinguishes a missing compatibility boundary from insufficient validation, unresolved policy, editorial defects and optional-profile evidence gaps. No Compatibility Ledger or prior artifact is modified.

## 2. Relationship to previous investigations

I045 established healthy cross-layer composition. I046 declared baseline boundary closure while identifying policy and editorial work. I053 validated a representative corpus. I054 classified undocumented behavior. I055-I058 consolidated claims, responsibility, personality and extension boundaries. I052/I059 specify proposition-to-test mapping and a formal conformance process.

This assessment does not accept those conclusions merely because they agree. It rechecks ledger counts/duplicates, unresolved policy, test traceability, corpus breadth and evidence concentration, and asks which claims each gap actually blocks.

## 3. Evidence reviewed

The review covered:

- the authoritative Investigation 059 ledger: 652 proposition lines, 622 unique identifiers, 445 REQUIRED, 109 NOT GUARANTEED, 50 POLICY PENDING and 48 NOT REQUIRED;
- documentation and DRI source findings from I001-I046;
- narrow register, memory, FCB/DMA, BIOS, console and disk-image probes;
- I045 cross-layer tests and I047-I054 utility/toolchain/application/communications/hardware/undocumented validation;
- I053's 13 software-corpus records;
- I054's 21 undocumented/de facto behavior classifications;
- I052/I059's 62-test inventory and complete proposition mapping;
- I055-I058 claim, responsibility, personality and extension-boundary mappings;
- preserved reports, sources, binaries, transcripts, images and audit hashes.

The strongest evidence is detailed narrow behavioral observation plus DRI documentation/source. The principal limitation is concentration on DRI CP/M in a small set of emulator/platform configurations, with limited differential evidence from independent compatible implementations.

## 4. Compatibility coverage assessment

All major CP/M-visible interface families are addressed: transient entry/page zero, CCP, BDOS Functions 0-40, console/system state, FCB/DMA/directory/sequential/random/user/file lifecycle, BIOS jump table/boot/character/disk ABI, DPH/DPB/storage geometry, memory/loader/overlays/self-modification, termination/recovery and logical/physical errors.

No wholly missing generic subsystem boundary was found. The I052 mapping gives every proposition a primary test. I056-I058 give every proposition responsibility, personality and extension treatment. Core documented baseline semantics are therefore **RELEASE READY** as a review candidate.

That finding is narrower than normative release readiness. Processor/instruction assumptions are not comprehensively frozen; late physical faults remain incomplete; exact console/error/profile choices remain pending; and evidence does not yet demonstrate that DRI-specific observations were consistently separated from portable practice across independent implementations.

## 5. Software ecosystem assessment

The corpus is strong for standard utilities, assemblers/linkers/debuggers, WordStar, BASIC/Wumpus, Adventure and generic Kermit startup/failure. It tests ordinary, boundary and failure composition and confirms that the current contract explains every observed case.

It is not representative enough for an unrestricted “historical CP/M ecosystem” endorsement. Missing categories include spreadsheets, databases, packaged business applications, BBS software, printer workflows and full high-level compiled-language toolchains. Communications lacks successful paired send/receive, carrier loss and receive-side failures. Hardware evidence deliberately demonstrates mismatches rather than successful matching IMSAI/Dazzler/controller profiles.

These gaps do not block a narrow baseline interface specification. They do block a broad corpus-validated ecosystem claim and the affected communications/hardware profiles. **ADDITIONAL INVESTIGATION REQUIRED** for the broad claim; matching optional hardware remains **POLICY PENDING** until selected.

## 6. Undocumented behavior assessment

I054's method is sound: observability, stability, consequential dependency and scope determine promotion. SUBMIT/XSUB and writable/executable TPA have strong ecosystem evidence; private targets, exact entry residue, internal algorithms and physical order are correctly excluded or left unguaranteed.

No important high-evidence undocumented behavior was found to be incorrectly excluded. However, the “not widespread” conclusion is based on a limited corpus and mostly one implementation family. Rare dependencies on console edge behavior, private targets, Function-6 E=FEh or processor instructions have not been quantitatively ruled out.

The current classifications are **RELEASE READY** for a conservative baseline because exclusions do not deny documented behavior. Cross-implementation and expanded-corpus evidence is still required before claiming the classifications exhaust all historically significant de facto behavior.

## 7. Cross-layer assessment

Healthy composition is well covered: CCP launch, page zero, BDOS, BIOS, storage, lifecycle, utilities/toolchains and selected applications. The personality/delegation analysis correctly prevents host abstractions from replacing CP/M semantics.

Weak areas are late or asynchronous composition: physical failure after partial transfer, Delete/Rename/controller error paths, carrier/timing behavior, background/concurrent state mutation and recovery after provider-specific failures. These are not evidence of a missing generic layer, but they leave some declared error/device profiles under-supported.

The cross-layer baseline is **RELEASE READY** for healthy and documented logical-error paths. **ADDITIONAL INVESTIGATION REQUIRED** for a strong physical-error or communications/timing profile.

## 8. Conformance assessment

The conformance model is structurally complete. It maps all 652 proposition lines to 62 stable tests, defines disposition-aware pass rules, dependency phases, claim levels, corpus integration, result records and evidence preservation. No unknown primary-test identifier exists.

Design completeness is not demonstrated certification. There is no preserved end-to-end result set showing the I059 decision process on reference CP/M and a materially independent or new implementation. Eleven supplemental interface/ecosystem tests are inventory definitions rather than primary proposition mappings; their role is sensible but must remain supplemental unless explicitly bound to a claim.

Manual/profile cases require an authoritative environment and review process. Timing/repetition thresholds are unresolved. Therefore objective evaluation is specified in principle but not yet demonstrated in practice. A conformance pilot is **ADDITIONAL INVESTIGATION REQUIRED** before normative release.

## 9. Identified gaps

`probes/gap-assessment-matrix.tsv` records 24 areas with coverage, evidence, gap, severity, action and classification. The critical/high gaps are:

1. The ledger contains a duplicate 0248-0277 block; Function-37 entries 0435/0523 overlap. No conflicting disposition exists, but the normative machine-countable artifact is not clean.
2. Fifty POLICY PENDING proposition lines lack one release-wide applicability decision/manifest.
3. Cross-implementation differential evidence is insufficient to test portability versus DRI behavior.
4. The proposed conformance suite has not completed a preserved end-to-end pilot.
5. Processor/instruction compatibility assumptions need an explicit baseline/profile.
6. Major software categories remain absent from the ecosystem corpus.
7. Paired communications, matching hardware and late physical faults remain incomplete for their profiles.
8. A release-wide immutable ledger/test/profile/evidence manifest is not yet defined.

No contradiction in duplicated classifications was found. All 30 duplicated identifiers have identical dispositions. The Function-37 pair also agrees on POLICY PENDING, though its conformance scopes differ.

## 10. Recommended additional investigations

Seven focused evidence campaigns are recommended, in priority order:

1. **Cross-implementation differential validation:** run selected public, NOT GUARANTEED and policy probes on materially independent CP/M-compatible implementations.
2. **Conformance pilot execution:** produce complete I059 result sets on reference CP/M and one independent/new implementation.
3. **Processor/instruction profile:** establish the processor baseline plus historically significant instruction, flag and timing dependencies.
4. **Expanded application/compiler corpus:** add deterministic compiler, spreadsheet, database, business, BBS and printer workflows.
5. **Paired communications:** successful send/receive plus cancel, carrier loss and storage failures.
6. **Late/natural physical faults:** inject failures after selected transfer counts across read/write/Make/Close/Delete/Rename.
7. **Matching hardware profiles:** demonstrate successful named IMSAI/Dazzler/controller/peripheral behavior.

Ledger normalization is also required, but it is an authorized editorial maintenance audit rather than behavioral research. Each recommendation's minimum evidence and claim impact is in `probes/recommended-investigations.tsv`.

## 11. Release readiness assessment

**Core semantic boundary:** **RELEASE READY** as a review candidate. All generic public subsystems have identified, classified and test-mapped observations.

**Normative machine-countable specification:** **ADDITIONAL INVESTIGATION REQUIRED** before release. Normalize the ledger and demonstrate the conformance process.

**Baseline claim definition:** **POLICY PENDING** until all pending rows are explicitly selected, excluded or assigned to named profiles in a release manifest.

**High-confidence portable/de facto distinction:** **ADDITIONAL INVESTIGATION REQUIRED** because evidence is dominated by DRI reference behavior.

**Broad ecosystem endorsement:** **ADDITIONAL INVESTIGATION REQUIRED** because important software categories are absent.

**Optional communications/hardware/error profiles:** **POLICY PENDING** or additional investigation as specified; they need not block a narrowly declared baseline.

Overall verdict: the work is ready for a public review draft or release candidate, but not for a normative “CP/M 2.2 high-confidence ecosystem compatibility specification 1.0.” The ten explicit gates are in `probes/release-gates.tsv`.

## 12. Proposed ledger additions

None. Gaps in validation breadth, editorial quality, release policy and certification execution are not new application-visible CP/M behavior. Adding “must have cross-implementation evidence” or “must pass conformance” would be circular process metadata.

If a recommended behavioral investigation finds a repeatable contradiction or missing dependency, it must propose a narrow independently testable ledger entry then. No such proposition is justified now.

## 13. Existing-entry updates

No Compatibility Ledger file was modified and no disposition correction is proposed by this assessment.

The required normalization work is:

- remove the second verbatim 0248-0277 block without renumbering stable identifiers;
- consolidate or explicitly cross-reference the overlapping Function-37 entries 0435 and 0523 while preserving their distinct evidence/test scopes;
- produce an audited post-normalization map proving identical semantics and coverage.

At future authorized integration, `I060 ENGINEERING GAP ASSESSMENT subsystem IG AG` may identify release status and evidence gaps in project documentation. It is not behavioral evidence for individual entries.

## 14. Open questions

1. Which independent CP/M-compatible implementations are sufficiently different and well-preserved for differential validation? (**D**)
2. What exact release claim distinguishes baseline, strict community and profile-qualified conformance? (**D**)
3. Which 50 pending proposition lines activate in that claim? (**D**)
4. What processor baseline is part of generic CP/M 2.2 versus a named Z80 profile? (**D**)
5. What minimum expanded corpus supports the phrase “historical CP/M ecosystem”? (**D**)
6. Which manual/hardware environments and reviewers are authoritative for certification? (**D**)
7. What repetition and timing thresholds apply to asynchronous behavior? (**D**)
8. Can the ledger normalization preserve external references while eliminating duplicate line counts? (**D**, editorial audit)
9. What artifact binds a specification release to immutable ledger, test, profile and evidence hashes? (**D**, release process)

## 15. Conformance implications

Until the release gates close, conformance results should be labelled development subsets or review-candidate pilots, not final certification. A narrowly declared baseline may exclude unselected profiles, but it must still resolve applicability for every pending row and pass every applicable REQUIRED proposition.

The pilot should first reproduce expected results on reference CP/M, then run the same versioned inventory on an independent/new implementation. Disagreements must be classified as implementation defect, fixture defect, permitted variation, DRI-specific behavior, unresolved policy or newly evidenced compatibility question.

Final review confirms that previous assumptions were challenged, evidence gaps are explicit, conclusions use RELEASE READY / ADDITIONAL INVESTIGATION REQUIRED / POLICY PENDING / NOT REQUIRED, additional investigations are prioritized, and compatibility requirements remain separate from implementation design.

Completion audit: this 15-section report, 24-area gap matrix, duplicate/policy audits, seven recommended investigations, ten release gates, evidence summary, source mappings, validation output and hashes are present; the authoritative Investigation 059 ledger remained unchanged; no prior BetterCP/M file or implementation changed; and no ZIP archive was created.
