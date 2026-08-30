# Investigation 070 - CP/M 2.2 Policy Pending Resolution

Evidence classes are **A** documented CP/M behavior, **B** Digital Research implementation/distributed-software behavior, **I** controlled experimental observation, and **D** project compatibility policy.

## 1. Objective and scope

This investigation resolves every POLICY PENDING proposition in the canonical Investigation 069 Compatibility Ledger and defines what BetterCP/M promises in its generic baseline, named compatibility profiles, optional extensions, and exclusions.

This is a compatibility-policy decision, not new behavioral discovery. It does not implement BetterCP/M, design architecture or conformance infrastructure, edit the ledger, or alter previous evidence. Recommendations are for a later controlled ledger update.

## 2. Relationship to previous investigations

I055 defines baseline, strict-community, optional, hardware-profile and unsupported claim categories. I056 maps observable requirements to responsibility without prescribing architecture. I057 defines personality accountability and provider delegation. I058 requires extensions to remain observationally neutral, opt-in or profile-qualified. I059 defines disposition-aware conformance. I068 identifies policy selection as a release gate. I069 supplies the structurally canonical 627-entry ledger and leaves 49 POLICY PENDING propositions. I070A independently confirms that the adopted cross-layer contract composes; it is corroboration, not the source of these policy choices.

The original investigations named by each pending entry remain the behavioral evidence. I070 decides promise scope only.

## 3. Policy inventory

The canonical ledger contains 49 POLICY PENDING entries. `probes/policy-resolution-matrix.tsv` records, for every entry, identifier, title, originating investigation, evidence basis, compatibility significance, decision, applicability, rationale and conformance impact.

Inventory distribution by subject:

- transient command tail/default FCB: 0012, 0016, 0019-0021;
- formatted console and buffered input: 0069-0073, 0086-0088, 0103-0104, 0125-0129;
- drive/user/FCB state: 0154-0155, 0183;
- file and physical-error results: 0233, 0246, 0276, 0283, 0309, 0314, 0346, 0354, 0385, 0387, 0389, 0411-0413;
- undocumented/device calls: 0435, 0446, 0472;
- CCP presentation/capacity/parsing/lifecycle: 0476, 0478, 0480, 0490, 0506, 0508, 0512, 0580;
- Function 37 conditional detail: 0523.

The validator confirms the matrix covers exactly all 49 pending identifiers once.

## 4. Evidence review

**A.** Documentation defines the generic page-zero, command-tail, BDOS, FCB/DMA, BIOS, logical result, physical-error and lifecycle interfaces. Where the manuals explicitly permit implementation choice—such as optional active IOBYTE routing—or define predicates rather than exact values, the generic promise must preserve that breadth.

**B.** DRI source and shipped software establish exact CCP, console-editor, error-presentation, undocumented Function-37 and resident-output behavior. These observations justify named fidelity profiles when externally useful, but source implementation alone does not make them universal CP/M requirements.

**I.** The earlier deterministic probes confirm all selected exact behaviors. Later cross-layer, fault, corpus, differential and hardware-profile investigations show which results are consequential, which vary safely, and which depend on a configured provider or profile. I070A further confirms the normal/logical/physical boundary composition without deciding product policy.

**D.** Policy chooses promise scope. It may adopt stable consequential behavior, profile-qualify DRI fidelity, leave residue variable, permit an opt-in extension, or explicitly exclude unsupported behavior. It may not weaken documented CP/M because implementation is inconvenient or universalize a quirk merely because it existed.

## 5. Resolution methodology

Each entry was evaluated in this order:

1. Is the exact result documented as a universal CP/M 2.2 obligation?
2. If not, is there credible historical-software dependency or cross-layer necessity sufficient for the generic baseline?
3. If exact fidelity is useful but environment-, UI-, CCP-, BIOS- or device-dependent, can a named additive profile state it precisely?
4. If behavior is incidental residue or conflicting exactness with only a portable predicate, should software be forbidden to depend on it?
5. If an opt-in compatibility feature can be isolated from baseline, should it be optional?
6. If undocumented, hazardous and unsupported by consequential dependency, should it be outside the claim?

Implementation ease and personal preference were not decision criteria. Profiles add promises and cannot waive generic requirements.

## 6. Policy resolution matrix

The 49 decisions are:

| Resolution | Count | Meaning |
|---|---:|---|
| REQUIRED | 6 | Universal BetterCP/M generic CP/M promise |
| PROFILE REQUIRED | 28 | Mandatory only when the named profile is claimed |
| OPTIONAL | 3 | Opt-in compatibility feature/extension, absent from baseline |
| NOT GUARANTEED | 11 | Portable software and certification must not require one exact result |
| OUTSIDE SCOPE | 1 | Intentionally excluded from BetterCP/M's CP/M compatibility claim |

The direct baseline additions are: leading command-tail blank (0019), uppercase command tail (0020), Function-13 user preservation (0155), sequential-write full-condition codes 01/02 (0276), random-write allocation-full code 02 (0346), and TAB remaining distinct from CCP SPACE (0480).

The complete proposition-level matrix is normative for this report. Summary prose does not override an individual row.

## 7. Compatibility commitment analysis

BetterCP/M promises exactness where CP/M documentation or consequential ecosystem behavior establishes a useful stable contract. It does not promise an exact DRI clone.

The generic claim includes the canonical ledger's existing REQUIRED propositions plus the six I070 baseline decisions. It treats eleven exact/residual matters as permitted variation. In particular, command-tail consumers use the counted length rather than a trailing NUL; ready/EOF callers use documented zero/nonzero predicates; and software does not depend on private retained-input or failed-FCB residue.

Profiles are additive contracts. Selecting strict DRI CCP, console/editor, interactive disk-error, presentation, IOBYTE/device, LISTST/device or removable-media behavior activates every associated conditional requirement and test. An implementation may claim generic CP/M without those profiles, but it must state that scope plainly.

Optional Function 37 and structured physical errors are not baseline semantics. Wildcard Rename is intentionally outside the compatibility claim. Exact DRI internal routines, addresses, stacks, allocation choices, timing residue and provider mechanics remain excluded under existing ledger dispositions.

## 8. Profile boundary analysis

`probes/profile-boundaries.txt` defines the selected boundaries:

- strict DRI CCP/ecosystem;
- DRI formatted-console and line-editor;
- interactive CP/M disk-error;
- DRI diagnostic/resident presentation;
- IOBYTE/logical-device and BIOS/list-device;
- removable-media/hardware;
- optional Function-37 compatibility;
- optional structured/headless error extension.

Processor and machine profiles established by I063/I067 remain orthogonal. A Z80 or machine profile does not automatically activate DRI CCP or presentation fidelity. An application/ecosystem endorsement may require one or more profiles and must name them.

Entries 0012 and 0506 share one strict-CCP policy but retain separate testable meanings. Entries 0435 and 0523 remain the canonical Function-37 adoption/detail pair established by I069.

## 9. Conformance impact analysis

Every baseline REQUIRED decision receives a positive test in all generic claims. Every PROFILE REQUIRED decision is NOT-APPLICABLE when its profile is unselected and becomes a positive, claim-defeating requirement when selected. OPTIONAL features require isolation tests and may not alter baseline results. NOT GUARANTEED decisions require non-assertion or permitted-variation oracles. OUTSIDE SCOPE behavior is excluded from certification and advertising.

Required test updates include:

- add exact leading-blank/uppercase/TAB command cases to baseline CCP tests;
- preserve user across Function 13 in baseline state tests;
- split directory-full and allocation-full sequential/random write cases with exact 01h/02h oracles;
- gate default-FCB2, CCP capacity, console/editor, diagnostics, physical-error interaction, IOBYTE, LISTST, media-change and resident-layout subcases by profile identifiers;
- change Function-11 ready, EOF, trailing NUL, retained-input and failure-residue tests from exact assertions to permitted-variation rules;
- exclude wildcard Rename from certification except as an explicitly unsupported diagnostic;
- test structured errors only as an extension with strict-path equivalence.

Conformance results must name the ledger hash and selected profile manifest. No implementation can report a profile pass while omitting one of its conditional REQUIRED rows.

## 10. Recommended ledger updates

Do not edit the canonical ledger in this investigation. In the separately authorized controlled update, eliminate all 49 POLICY PENDING dispositions using `probes/recommended-ledger-treatment.txt`:

- six entries become ordinary REQUIRED;
- twenty-eight are rewritten as conditional profile propositions and become REQUIRED;
- three become baseline NOT REQUIRED with explicit optional-profile/extension applicability;
- eleven become NOT GUARANTEED;
- wildcard Rename becomes NOT REQUIRED with an explicit outside-scope statement.

This approach preserves the ledger's existing machine-readable disposition vocabulary. `PROFILE REQUIRED`, `OPTIONAL` and `OUTSIDE SCOPE` are release-applicability decisions represented through proposition wording and profile metadata, not ambiguous new historical evidence classes.

Every affected entry should add the evidence string `I070 POLICY PENDING RESOLUTION subsystem IG AG`. I070 is policy evidence and must not replace the entry's original A/B/I behavioral evidence.

## 11. Existing-entry impacts

No existing non-pending disposition changes. No identifier is added, removed, merged or renumbered. The affected set is exactly the 49 matrix identifiers.

For 0012/0506, retain both entries and cross-reference their shared strict-CCP applicability. For 0435/0523, retain I069's canonical/conditional relationship and give both the same optional Function-37 profile key. For presentation entries, preserve the related existing semantic REQUIRED propositions so profile exactness does not replace baseline behavior. For NOT GUARANTEED entries, ensure conformance language explicitly rejects accidental exact promises.

The controlled update must regenerate disposition counts, profile applicability mappings and I052/I059 test traceability, and must prove that all former POLICY PENDING identifiers received exactly one treatment.

## 12. Open questions

No CP/M behavioral policy item remains unresolved after this matrix. Release-process choices remain:

1. Which named profiles ship enabled, available-but-disabled, or absent in the first BetterCP/M release?
2. Whether the public marketing name “strict community” bundles strict CCP, console/editor and presentation profiles or lists them separately.
3. What stable profile identifiers and versioned manifest syntax the release process adopts.
4. Whether structured physical errors and Function 37 are implemented in the first release; their optional classification does not require implementation.
5. Which additional application corpus is required for endorsements beyond the generic CP/M claim.

These are release packaging and feature-selection questions, not remaining POLICY PENDING ledger behavior.

## 13. Release implications

The policy gate identified by I068 is closed at the evidence/report level. A release may claim generic CP/M 2.2 only after the controlled ledger update and corresponding conformance-oracle changes are incorporated. It may claim only the profiles named in its immutable release manifest and passed in full.

The first release need not implement Function 37, structured errors, wildcard Rename, exact DRI presentation, active IOBYTE routing, removable-media detection or any other unselected profile. It must implement all generic REQUIRED behavior and must not overclaim NOT GUARANTEED or excluded results.

Final review: all 49 pending entries are present exactly once; decisions use the required five classifications; behavioral evidence and policy judgment are separated; compatibility commitments and profile boundaries are explicit; conformance consequences are defined; no BetterCP/M implementation or architecture was changed; and the canonical ledger was not modified.

The authoritative ledger SHA-256 before and after is `40d5e514a698bbabdfe8c7d926cea39b9962e17d83b25f2a2915ea4882014097`.

