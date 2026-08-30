# BetterCP/M CP/M 2.2 Conformance Specification

## Version 1.0-rc1 — Frozen tables 1.0.0

### 1. What this document does

This document describes how the BetterCP/M project tests CP/M 2.2 compatibility.

It publishes the conformance framework developed in Investigation 071 without redesigning it. The framework evaluates the behavior recorded in Compatibility Ledger 072, identified by SHA-256:

`eb16466fdbff8fb2bc07bd02a07198b8426fb6452be3dd1f256cbff4af0547d3`

The conformance tables included with this specification are the same tables frozen in Investigation 071. Their identifiers and oracles remain version 1.0.0.

The purpose of the framework is to make a compatibility claim testable. A claim should be tied to specific ledger propositions, specific test cases, specific expected results, and preserved evidence showing what actually happened.

### 2. Test inventory and traceability

The conformance inventory contains 62 fixed top-level test identifiers.

Below those are 627 proposition-level test cases, one for each entry in the compatibility ledger. Each case uses an identifier in this form:

`<parent>-P<entry>`

Every ledger proposition from 0001 through 0627 maps exactly once to:

- a proposition-level conformance case;
- a top-level test;
- and a versioned oracle describing how the result is interpreted.

A test runner may perform shared setup or execute several related checks together, but it must still produce a separate result record for every proposition-level case.

That one-to-one mapping is important. It lets us trace a compatibility claim all the way from a ledger proposition to the test that examined it and the evidence produced by that test.

### 3. Applicability and oracle rules

Not every ledger proposition is treated the same way during a conformance campaign.

**REQUIRED** propositions use a positive predicate and gate every applicable baseline compatibility claim.

**PROFILE REQUIRED** propositions become gates only when the corresponding stable compatibility profile has been selected.

**OPTIONAL** behavior is not part of the claim unless it is explicitly claimed. If an optional feature is present, it must not break required baseline behavior.

**NOT GUARANTEED** propositions allow the variation or nonassertion stated by the ledger. They do not require every implementation to reproduce one exact Digital Research result.

**OUTSIDE SCOPE** propositions are not positive compatibility requirements and never become baseline gates.

Exact equality with Digital Research behavior is required only when a selected profile already contains a proposition that requires that equality.

The oracle for each case defines the expected interpretation. The runner collects the observation; the oracle tells us what that observation means for the claim.

### 4. How parent tests are evaluated

A top-level test passes only when every applicable REQUIRED and PROFILE REQUIRED child case passes.

If any applicable required child produces **FAIL**, the parent fails and so does any compatibility claim gated by that parent.

A **BLOCKED** or **ERROR** result prevents the parent from receiving PASS.

**NOT_APPLICABLE** may be used only when the campaign manifest proves that the relevant profile or optional feature was not selected.

Dependencies do not erase independent results. If one case is blocked because another prerequisite failed, results from unrelated cases can still be recorded and reported.

This keeps the report useful even when a campaign cannot complete cleanly.

### 5. Campaign structure

A conformance campaign proceeds through a series of phases:

- manifest;
- foundation;
- interface;
- storage;
- command and failure behavior;
- ecosystem and profile testing;
- review.

Healthy prerequisite behavior should be tested before fault and recovery cases that depend on it.

Where tests modify disk images or other mutable fixtures, those fixtures must be restored from verified pristine copies between scenarios.

Dependencies between cases should refer to exact result run IDs rather than informal descriptions such as "the previous test."

The aim is to make each result traceable to the exact environment and prerequisite results that produced it.

### 6. Evidence and reproducibility

A conformance result is useful only if we can tell exactly what was tested and reproduce the conditions under which it was tested.

The campaign therefore begins with an immutable manifest.

That manifest binds the campaign to the relevant:

- candidate implementation;
- compatibility ledger;
- test inventory;
- case matrix;
- oracle set;
- certification level;
- selected profiles;
- fixture manifest;
- runner, emulator, and build manifest;
- execution environment;
- repetition rules;
- reviewers;
- artifact index.

These are bound by hashes so that the campaign cannot silently change underneath its results.

Each proposition-level result records the evidence needed to understand what happened. Depending on the case, that includes:

- raw observations;
- normalized observations;
- tool status;
- execution times;
- dependencies;
- failure classification;
- content-addressed artifacts.

The point is not bureaucracy for its own sake. If someone later questions a result, the campaign should contain enough information to reconstruct what was tested and why the result was reported.

### 7. Certification levels

The framework recognizes several levels of conformance claim.

#### BASELINE

BASELINE covers the generic CP/M 2.2 environment declared by the campaign, including the applicable transient-program, BDOS, CCP-visible, and processor-baseline behavior.

#### INTERFACE

INTERFACE adds selected documented public BDOS and BIOS interfaces to the baseline scope.

#### FULL-SYSTEM

FULL-SYSTEM adds broader system behavior, including:

- boot behavior;
- CCP behavior;
- BIOS-visible behavior;
- disk behavior;
- recovery behavior;
- generic ecosystem commitments.

#### PROFILE

PROFILE adds one or more named compatibility profiles from the profile registry.

The claim must identify the profile IDs being tested.

#### OPTIONAL

OPTIONAL records an explicit claim for an optional feature.

An optional feature does not become part of baseline compatibility merely because an implementation provides it.

#### DEVELOPMENT

DEVELOPMENT results are useful during implementation and debugging, but they are not certification.

A development run may tell us a great deal about the current state of an implementation without satisfying all of the requirements for a formal conformance claim.

### 8. Failure handling

A proposition-level result has one of five states:

- **PASS**
- **FAIL**
- **BLOCKED**
- **NOT_APPLICABLE**
- **ERROR**

A result other than PASS also receives a failure classification where appropriate:

- **PRODUCT**
- **FIXTURE**
- **ENVIRONMENT**
- **FRAMEWORK**
- **UNRESOLVED**

These classifications help distinguish an implementation defect from a broken fixture, a bad test environment, a framework problem, or a failure that cannot yet be assigned confidently.

Fixing a problem does not erase the original run.

A repaired test receives a new run ID, while the earlier evidence is preserved.

Partial campaign results may still be published as reports, but they are not certificates unless a separately declared lower-level claim satisfies every gate required for that scope.

### 9. The frozen conformance tables

The `tables/` directory contains the machine-readable parts of the frozen framework, including:

- the test inventory;
- case matrix;
- ledger-to-case traceability;
- oracle definitions;
- certification levels;
- campaign and result schemas;
- failure-handling rules;
- campaign phases.

Their hashes are recorded in the Investigation 074 normative artifact inventory and SHA-256 manifest.

These tables are frozen for this release.

Editorial work may explain them more clearly, but it must not change their meaning.

A semantic change to a test, proposition mapping, applicability rule, or oracle requires a separately authorized update to the framework or compatibility ledger.

### 10. Current implementation status

This specification defines how CP/M 2.2 conformance is to be evaluated.

It does not itself provide the executable test runners, and it does not certify any implementation.

A candidate can be certified only after the required executable fixtures and runners exist and a complete campaign has been performed.

That campaign must preserve its evidence and satisfy the verification requirements for the certification level being claimed.

In other words, this document defines the rules of the test. Passing the test still requires an actual candidate, executable conformance tools, a complete campaign, and evidence that can be independently checked.
