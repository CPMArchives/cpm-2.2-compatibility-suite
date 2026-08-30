# CP/M 2.2 Compatibility Standard

## Release Candidate 1 — Version 1.0-rc1

### 1. What this standard defines

This standard defines the CP/M 2.2 compatibility target against which an implementation can be tested.

It is not a certification report and it does not imply that any particular implementation has already passed the conformance suite. It says what a compatibility claim means and how that claim is bounded.

The definition rests on four pieces of the release:

- the Compatibility Ledger;
- the Compatibility Policy;
- the Conformance Specification and its frozen tables;
- the Compatibility Profile Registry.

The division of labor is important. The ledger records the individual compatibility propositions and their dispositions. The policy says how those dispositions are used in a claim. The conformance specification says how they are tested. The profile registry gives stable names to additional applicability groups that may be selected on top of the generic baseline.

The current ledger contains 627 propositions, numbered 0001 through 0627.

### 2. The compatibility target

The target is the CP/M 2.2 environment that software can actually observe and reasonably depend upon.

That includes:

- transient execution and memory conventions;
- BDOS behavior;
- CCP behavior;
- FCB and DMA conventions;
- disk and file-system behavior;
- documented BIOS interfaces;
- boot and restart behavior;
- the processor baseline;
- error and recovery behavior;
- consequential ecosystem conventions.

The point is not to reproduce Digital Research's source tree, instruction sequences, or private machinery.

Two implementations may arrive at the same visible result by very different routes. That is not a compatibility problem. It becomes one only when the difference crosses an interface boundary that the compatibility record says matters.

The useful question is therefore not, "Does this look internally like DRI CP/M?" but, "Does software encounter the CP/M behavior it was entitled to rely on?"

### 3. The Compatibility Ledger

The Compatibility Ledger is the detailed proposition record behind the standard.

For this release candidate it contains 627 unique propositions:

- **458 REQUIRED**
- **116 NOT GUARANTEED**
- **53 NOT REQUIRED**
- **0 POLICY PENDING**

For conformance purposes, those same propositions are treated as:

- 430 generic REQUIRED;
- 28 PROFILE REQUIRED;
- 3 OPTIONAL;
- 116 NOT GUARANTEED;
- 50 OUTSIDE SCOPE.

These are not two competing classifications and they do not add up to a second body of requirements. They are two views of the same ledger.

The first records the proposition disposition. The second says how that proposition participates in an actual compatibility claim.

That distinction is what allows a proposition to be REQUIRED in the ledger but required only when a named profile is selected.

### 4. The baseline claim

The generic baseline is `CPM22-BASE`.

An implementation claiming `CPM22-BASE` must satisfy every applicable generic REQUIRED proposition for the certification level and environment it declares.

"Applicable" matters. The standard does not require every CP/M system to expose the same machine-dependent facilities, optional devices, presentation details, or implementation residue. Where the ledger permits variation, an implementation may vary.

A compatibility claim therefore has to say what was actually established.

A narrower certification level or a profile-qualified claim must be identified as such. A bare statement such as **"CP/M 2.2 compatible"** cannot reasonably be read as a promise of untested profiles, optional facilities, or machine-specific behavior.

The standard is intended to make that scope visible instead of leaving "compatible" to mean whatever the reader happens to assume.

### 5. Compatibility profiles

Some historically important CP/M behavior is real and testable without belonging in the generic baseline.

Profiles are how the standard handles that distinction.

Every named profile inherits `CPM22-BASE` and then adds its own requirements. A profile can strengthen a claim; it cannot weaken the baseline beneath it.

A profile marked **AVAILABLE** means that the profile is defined and may be selected. It does not mean that an implementation supports it, enables it, or has passed it.

Once a profile is claimed, its ID and version become part of the claim and every mapped PROFILE REQUIRED case becomes mandatory.

Unselected profiles do not burden the baseline.

Likewise, a profile cannot simply promote arbitrary NOT GUARANTEED behavior into a new requirement. If exact behavior is to be promised through a profile, that promise must already be represented by the profile mapping.

This is the practical difference between generic CP/M compatibility and closer fidelity to some particular DRI behavior or optional facility.

### 6. What compatibility does not require

Not every observable difference between two CP/M systems is a compatibility failure.

A proposition marked **NOT GUARANTEED** identifies behavior for which the standard deliberately permits variation. Portable software cannot demand one exact result there merely because a DRI system happened to produce it.

Behavior marked **OUTSIDE SCOPE** is not a compatibility gate.

Optional features do not become baseline requirements merely because some CP/M systems supplied them.

Machine-specific, hardware-specific, device-specific, presentation-specific, and application-specific behavior matters only when it is exposed through the generic contract or brought into the claim by a selected profile.

That boundary is deliberate. A conformance suite that failed an implementation for every observable difference from one DRI binary would be testing imitation, not CP/M compatibility.

The standard instead asks which differences software was actually entitled to care about.

### 7. How conformance is tested

The frozen conformance system contains:

- 62 top-level test identifiers;
- 627 proposition-level cases;
- versioned oracles defining the expected results.

A top-level test passes only when all applicable required child cases pass.

A **FAIL** defeats the claim gated by that case.

**BLOCKED** and **ERROR** do not count as PASS.

**NOT_APPLICABLE** is allowed only where the campaign record establishes that the case belongs to an unselected profile or optional feature.

A conformance result is not just a screenful of PASS messages. The campaign records enough material to make the result identifiable and auditable: the candidate, ledger, inventory, cases, oracles, selected profiles, fixtures, runners, environment, dependencies, observations, and resulting artifacts.

Those materials are bound to the campaign by hashes.

Source inspection can explain why an implementation probably behaves a certain way. It cannot replace an experiment where the conformance specification requires observed behavior.

That rule keeps "the code appears correct" separate from "the required interface behavior was demonstrated."

### 8. Certification status

This release candidate does not certify any implementation.

Certification requires a complete campaign under Conformance Specification 1.0-rc1.

Running a useful body of CP/M software is valuable supporting evidence, but it is not a substitute for the proposition tests. A successful application may never exercise the disputed behavior, while a failed application may provide no useful indication of which compatibility rule was violated.

Application and corpus testing therefore supplement the conformance record; they do not overrule it.

### 9. Frozen release material

For this release candidate, the compatibility propositions, their classifications and applicability, the test identifiers, and the oracle meanings are frozen.

Editorial work may make the material easier to read. It may not change what a proposition requires, move a case into or out of a profile, alter an oracle, or otherwise change the technical meaning while pretending the release is still the same one.

Earlier ledgers and Draft 0.1 public documents remain part of the project's history. They are not the current release authority.

The reason for freezing the RC is straightforward: when somebody says that an implementation passed a CP/M 2.2 compatibility campaign, both the implementer and the reader should be able to determine exactly what was required, what was permitted to vary, and what evidence supports the claim.
