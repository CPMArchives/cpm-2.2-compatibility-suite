# Investigation 068 - CP/M 2.2 Final Engineering Gap Assessment

## 1. Objective and scope

This investigation determines whether the CP/M 2.2 compatibility evidence base through Investigation 067 is sufficient for specification freeze and release. It audits closure of every Investigation 060 gap, the current numbered Compatibility Ledger, software and cross-layer evidence, conformance readiness, hardware/profile separation, and remaining policy uncertainty.

This is an evidence and release-readiness assessment. It performs no BetterCP/M implementation or architecture work, changes no ledger or previous artifact, and does not manufacture behavioral evidence where a closure campaign was incomplete.

Evidence classes are **A** (documented), **B** (DRI implementation), **I** (experiment), and **D** (unresolved policy). Readiness classifications are **RELEASE READY**, **TARGETED FOLLOW-UP REQUIRED**, **POLICY PENDING**, and **NOT READY**. Later integration must identify this report as `I068 FINAL ENGINEERING GAP ASSESSMENT subsystem IG AG`.

## 2. Relationship to previous investigations

I060 found the semantic boundary substantially complete but withheld normative release pending differential validation, a conformance pilot, processor definition, expanded software, communications, physical-fault and hardware-profile campaigns, ledger normalization, policy selection, and a release manifest.

I061-I067 executed the seven targeted behavioral campaigns: cross-implementation comparison, conformance pilot, processor profile, compiler/corpus expansion, communications profile, physical fault/recovery, and hardware-profile validation. I068 does not accept their closure language uncritically. It compares their performed evidence and explicit exclusions against I060's exact gates and the current release artifacts.

## 3. Evidence reviewed

The review covered the authoritative `02 Compatibility Ledger - Investigation 067.txt`, all investigation reports through I067 with emphasis on I060-I067, I052/I059 conformance specifications, I062 result records, I063 processor probes, I064 compiler workflows, I065 communications records, I066 fault records, I067 hardware-profile records, and the release-facing `03 Conformance Strategy.txt`.

Mechanical audit extracted 652 numbered proposition lines and 622 unique identifiers. It found 30 duplicate identifiers, 50 `POLICY PENDING` lines representing 45 unique identifiers, and no conflicting disposition among duplicated entries. The current ledger SHA-256 is recorded in `hashes/ledger-sha256-before.txt`.

The required final readiness matrix is `probes/final-readiness-matrix.tsv`. The row-by-row I060 closure review is `probes/i060-gap-closure.tsv`.

## 4. I060 gap closure analysis

The seven requested behavioral campaigns materially closed their intended boundary questions:

- **I061:** cross-implementation behavior on DRI CP/M and CDOS distinguished required semantics from permitted numeric/layout variation.
- **I062:** a real pilot demonstrated that the conformance framework can identify PASS, FAIL, BLOCKED, product defects, fixture defects, and permitted variation.
- **I063:** controlled 8080, Z80, undocumented-opcode, timing, flag, and register tests established the processor/profile boundary.
- **I064:** Turbo Pascal and FORTRAN/LINK added substantial high-level compiler and generated-program workflows.
- **I065:** matched QTERM/XMODEM transfer, retry, unavailable endpoint, disconnect, and interrupted transfer closed the named communications-profile gap.
- **I066:** pre-transfer and completion-before-error cases established physical failure, operator intervention, recovery, and absence of rollback/atomicity guarantees.
- **I067:** fresh and inherited matched/mismatched tests validated generic, processor, BIOS/device, machine, and application claim layering.

This evidence closes the generic behavioral boundary. It does not close every optional ecosystem or machine claim. Spreadsheet, database, packaged business, BBS, printer, physical UART, Dazzler, VIO, raw-controller, front-panel, Altair, and Intel MDS success workflows remain unperformed. They must be excluded from release claims or receive targeted evidence later.

Four I060 release-artifact gaps remain: ledger normalization, policy applicability, conformance subcase/oracle granularity, and an immutable release manifest. A fifth was exposed by this audit: the processor propositions established in I063 were not incorporated into the numbered ledger.

## 5. Compatibility Ledger assessment

The substantive classifications remain coherent. No closure investigation found a repeatable CP/M-visible contradiction requiring an existing disposition to be weakened. I061/I062 properly treated independent implementation failures as implementation results, not as reasons to redefine documented CP/M. I066 preserved physical uncertainty as non-guarantees. I067 kept machine behavior profile-scoped.

The current ledger is not freeze-quality:

1. The duplicated 0248-0277 block remains: 652 proposition lines but 622 unique identifiers.
2. The overlapping Function-37 coverage identified by I060 remains to be normalized or explicitly cross-referenced.
3. Fifty pending lines (45 identifiers) have no release-wide baseline/strict/profile/deferred applicability decision.
4. I063 proposed five independently testable processor propositions, but the numbered ledger contains none; it contains only an Investigation 063 narrative note stating that no propositions were added.

The fourth issue is normative, not cosmetic. Correct execution of documented Intel 8080 instructions is a prerequisite for binary compatibility, while Z80-only and undocumented behavior must be scoped. These conclusions cannot remain only narrative if the ledger is the normative machine-countable contract.

Ledger semantic evidence: **RELEASE READY**. Current numbered ledger artifact: **TARGETED FOLLOW-UP REQUIRED**.

## 6. Software ecosystem assessment

The executed corpus now covers standard utilities, assembler/linker/debugger toolchains, WordStar, BASIC, games/adventures, Generic Kermit boundary behavior, QTERM/XMODEM, Turbo Pascal, FORTRAN/LINK, direct-hardware mismatches, generated COM programs, normal operations, logical failures, processor mismatch, endpoint failure, and physical-fault recovery.

Every observed OS dependency is explained by the existing semantic contract. No performed workflow exposed a missing generic subsystem or new behavioral proposition. The evidence is sufficient for a narrowly worded CP/M 2.2 baseline and for the specific processor/communications/hardware profiles actually identified and tested.

It is not sufficient for an unrestricted claim that all historically significant CP/M software is validated. Spreadsheet, database, packaged business/accounting, BBS, and printer workflows remain absent. Exhaustive historical coverage is impossible, but these are material categories rather than mere product variants.

Narrow baseline and named tested fixtures: **RELEASE READY**. Broad ecosystem endorsement: **TARGETED FOLLOW-UP REQUIRED**, or it must be expressly excluded from the release claim.

## 7. Cross-layer compatibility assessment

Healthy composition is well supported across CCP acquisition/dispatch, transient loading, page zero, BDOS, BIOS, storage, files, utilities, compilers, applications, termination, warm restart, direct devices, and profiles. Failure composition now includes logical errors, unsupported instruction/profile mismatch, absent/disconnected communications peers, repeated physical errors, ignore/abort, and media change before error report.

The boundaries remain clear:

- public CP/M behavior is normative regardless of implementation address or mechanism;
- processor instruction semantics belong to the declared processor profile;
- BIOS/device behavior belongs to documented standard calls plus selected profile promises;
- direct ports/MMIO/private firmware belong to machine profiles;
- protocol and UI behavior belong to applications unless promoted by an explicit profile;
- post-failure persistence, residue, private recovery, and hardware timing remain unguaranteed unless separately promised.

No hidden generic cross-layer assumption was discovered. Untested asynchronous/provider cases cannot support optional claims, but they do not reveal a missing baseline layer. Cross-layer baseline: **RELEASE READY**.

## 8. Conformance readiness assessment

I052/I059 provide complete syntactic proposition-to-test mapping and disposition-aware rules. I062 proves the framework can accept permitted variation, reject real documented violations, and avoid treating incomplete compound tests as PASS. Evidence capture in I061-I067 is reproducible and reviewable.

Normative certification is not yet ready. I062 explicitly found that many inventory rows are compound prose specifications rather than versioned executable cases. Stable subcase identifiers, exact oracles, aggregation rules, dependency-result links, run identity, and immutable campaign manifests remain incomplete. Seven of eighteen pilot records were BLOCKED; the pilot was a development slice, not full certification.

The release-facing `03 Conformance Strategy.txt` still says only `Draft 0.1` and `Under development.` The substantive methods exist in investigations, but have not been consolidated into an authoritative release artifact.

Framework concept: **RELEASE READY**. Normative conformance package: **TARGETED FOLLOW-UP REQUIRED**.

## 9. Hardware profile assessment

I063, I065, and I067 establish a coherent profile hierarchy. Generic CP/M does not imply every Z80 instruction, UART, display, controller, clock, interrupt topology, port, or firmware extension. A profile may add requirements but cannot waive the generic CP/M requirements it claims. I067's IMSAI B03 Function 12 failure usefully demonstrates fixture qualification: a machine label does not turn a failed generic requirement into compatible variation.

The matched IMSAI QTERM/SIO case supports one narrow communications/device profile. The mismatched QTERM and KSCOPE cases support exclusion boundaries. No evidence supports universal IMSAI, Dazzler, VIO, Altair, Intel MDS, printer, raw-controller, or physical-UART claims.

Profile model: **RELEASE READY**. Choice of shipping profiles and exact optional promises: **POLICY PENDING**. Untested named profiles must not appear as conforming claims.

## 10. Remaining gaps

The remaining freeze gates are precise and bounded:

1. Normalize duplicate and overlapping ledger material under an audit that preserves stable semantics and mappings.
2. Incorporate or explicitly map the five I063 processor propositions into the numbered normative ledger.
3. Classify every pending identifier for the release's baseline, strict, named-profile, deferred, or excluded scope.
4. Refine compound conformance tests into stable subcases with executable or exact reviewable oracles, aggregation, and dependency rules; demonstrate at least an audited complete vertical slice on reference and independent implementations.
5. Publish a content-addressed release manifest binding ledger, applicability, test inventory, oracles, profiles, fixtures, reports, results, and hashes.
6. State the exact release claim and its exclusions, particularly untested ecosystem categories and hardware profiles.

These are **TARGETED FOLLOW-UP REQUIRED** or **POLICY PENDING**, not invitations to reopen established CP/M behavior wholesale. Additional behavioral investigations are unnecessary for a narrow baseline unless one of these audits exposes a true contradiction.

## 11. Release readiness determination

**Behavioral evidence base:** **RELEASE READY** for a narrow CP/M 2.2 compatibility specification.

**Compatibility boundary and classifications:** **RELEASE READY**, subject to adding the already-evidenced processor propositions and retaining explicit profile scope.

**Current numbered ledger:** **TARGETED FOLLOW-UP REQUIRED** because duplicates and the processor incorporation omission prevent a clean normative freeze.

**Release policy:** **POLICY PENDING** because pending-entry applicability and claim levels are not selected.

**Normative conformance package:** **TARGETED FOLLOW-UP REQUIRED** because subcase/oracle granularity and the release-facing strategy/manifest are incomplete.

**Broad historical ecosystem endorsement:** **TARGETED FOLLOW-UP REQUIRED** unless missing categories are explicitly excluded.

Overall determination: TARGETED FOLLOW-UP REQUIRED.

The series has sufficient behavioral evidence to stop broad compatibility investigation and prepare a release candidate. It does not yet have a freezeable normative artifact bundle. `NOT READY` would overstate the deficiency: no foundational semantic subsystem is missing. `RELEASE READY` would ignore concrete machine-countable and policy blockers.

## 12. Proposed ledger additions

No new behavioral compatibility proposition was discovered by Investigation 068. However, the five propositions already proposed and evidenced by I063 must be incorporated or mapped before freeze:

1. **REQUIRED — Intel 8080-compatible binary execution baseline.** A generic CP/M 2.2 binary personality executes documented Intel 8080 instructions with their documented register, flag, stack, control-flow, and encoding semantics sufficiently to run CP/M and 8080 transient programs.
2. **REQUIRED — Declared processor-profile instruction semantics.** A configuration advertising a processor profile implements that profile's documented instructions, registers, flags, and encodings while retaining every lower-level compatibility promise it inherits.
3. **NOT REQUIRED — Z80 extensions outside generic CP/M.** Documented Z80-only instructions and registers are not required by a generic CP/M 2.2 claim that does not advertise a Z80 profile.
4. **NOT GUARANTEED — Undocumented processor behavior.** Undocumented opcodes, undocumented flag bits, and instructions outside the selected processor profile are not guaranteed by generic CP/M.
5. **NOT REQUIRED — Universal processor timing and interrupt topology.** Generic CP/M does not require a universal CPU clock, exact cycle timing, wait-state/refresh pattern, or machine interrupt topology.

Evidence: `I063 PROCESSOR INSTRUCTION PROFILE subsystem IG AG`, strengthened by I064 and `I067 HARDWARE PROFILE VALIDATION subsystem IG AG`. Assign numbers only during the authorized normalization/integration step and check for semantic overlap before insertion.

## 13. Existing-entry updates

No existing disposition change is proposed. At the next authorized release-preparation step:

- remove the duplicate 0248-0277 block without renumbering the surviving stable identifiers;
- resolve or cross-reference Function-37 overlap while preserving distinct evidence and test scope;
- add I061-I067 strengthening evidence where their reports specify, without turning product/profile observations into universal requirements;
- attach `I068 FINAL ENGINEERING GAP ASSESSMENT subsystem IG AG` to release-status documentation, not as behavioral proof for unrelated propositions;
- regenerate proposition/test/personality/profile mappings and prove semantic equivalence after normalization.

The I067 IMSAI Function 12 failure strengthens conformance testing for entry 0414; it does not justify changing that entry's `REQUIRED` disposition.

## 14. Open questions

1. What exact baseline, strict-ecosystem, and profile-qualified claims will version 1.0 publish? (**D / POLICY PENDING**)
2. How will each of the 45 unique pending identifiers be selected, scoped, deferred, or excluded? (**D**)
3. Will the five I063 propositions be inserted verbatim or mapped to newly normalized equivalent entries? (**D**, editorial/normative)
4. What stable subcase/oracle/aggregation format becomes authoritative for conformance? (**D**)
5. What content-addressed manifest format binds the release? (**D**)
6. Which absent application categories are required before using the phrase “historical CP/M ecosystem compatibility,” rather than a narrower compatibility claim? (**D**)
7. Which named hardware/device profiles, if any, ship in the first release? (**D**)

## 15. Final specification recommendations

Freeze behavioral investigation intake except for a demonstrated contradiction or an explicitly selected new profile. Perform one bounded release-preparation campaign:

1. normalize the ledger and integrate the processor propositions;
2. publish the pending-entry applicability and claim manifest;
3. convert a complete conformance vertical slice to stable executable subcases and exact aggregation;
4. consolidate the release-facing conformance strategy;
5. create and verify the immutable release manifest;
6. issue a release candidate for independent audit before final freeze.

The release should state inclusions and exclusions plainly. It may claim a narrow generic CP/M 2.2 personality plus only the processor/device/application profiles actually selected and evidenced. It must not imply transactional physical storage, universal machine hardware, undocumented processor behavior, or validation of absent software categories.

Final review: previous closure claims were challenged against actual artifacts; all 24 I060 gaps are traced; the current ledger was mechanically audited; the processor incorporation omission and incomplete conformance/release artifacts are explicit; behavioral requirements remain separated from implementation; and the overall decision follows the required readiness vocabulary.

Completion audit: this 15-section report, final readiness matrix, I060 closure matrix, current-ledger extraction, duplicate and pending audits, release conditions, validation script/output, copied immutable references, source/report hashes, ledger before/after hashes, protected-tree manifests, and artifact manifest are present. The authoritative Investigation 067 ledger and all previous BetterCP/M files remain unchanged.
