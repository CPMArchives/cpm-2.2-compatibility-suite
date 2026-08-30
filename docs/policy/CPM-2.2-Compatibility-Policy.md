# CP/M 2.2 Compatibility Policy

## Version 1.0-rc1

### 1. Purpose and authority

This policy governs the CP/M 2.2 Compatibility Standard release candidate.

Its proposition record is Compatibility Ledger 072:

`SHA-256 eb16466fdbff8fb2bc07bd02a07198b8426fb6452be3dd1f256cbff4af0547d3`

Investigation 070 contains the adopted policy decisions, and Investigation 071 supplies the conformance treatment.

The ledger controls. If a summary, explanation, or example in this document appears to conflict with a numbered ledger proposition, the proposition wins. This policy explains how the release is to be read; it does not amend the ledger.

That distinction matters because the compatibility work is deliberately proposition-based. The prose can explain why a class of behavior is treated one way or another, but it must not quietly broaden or narrow an individual requirement.

### 2. Compatibility principle

CP/M 2.2 compatibility is about externally observable behavior on which programs, users, documented direct-interface callers, and relevant ecosystem software may depend.

It is not a requirement to reproduce Digital Research's private implementation.

Algorithms, source organization, internal addresses, residual state, timing, and mechanisms remain free unless a ledger proposition makes some observable consequence of them part of a selected compatibility claim.

The evidence has to be kept in its proper place.

DRI documentation establishes the documented contract.

DRI source and binaries establish implementation behavior.

Controlled experiments establish what identified systems actually do.

Software evidence establishes whether a behavior became consequential in practice.

None of those sources, by itself, turns every incidental DRI behavior into a universal CP/M requirement.

That is the policy boundary the ledger is built to preserve.

### 3. Normative treatments

The ledger and conformance framework use five treatments.

#### REQUIRED

A generic REQUIRED proposition is part of every applicable baseline claim.

There is no profile or implementation choice that can waive it.

#### PROFILE REQUIRED

A PROFILE REQUIRED case is represented in the ledger as REQUIRED with explicit named applicability.

It becomes mandatory only when the corresponding versioned profile is selected.

Profiles can add requirements. They cannot subtract generic REQUIRED behavior.

This is what lets the project distinguish "generic CP/M 2.2 compatibility" from "generic compatibility plus exact DRI behavior in this additional area" without confusing the two claims.

#### OPTIONAL

OPTIONAL behavior is represented as NOT REQUIRED with explicit optional applicability.

It is outside the baseline unless claimed.

Once claimed, however, its mapped cases must pass, and the optional implementation must not disturb baseline semantics.

An optional feature is therefore not a loose extension point. It is an additional promise made only when selected.

#### NOT GUARANTEED

NOT GUARANTEED marks behavior for which portable software and generic certification may not require one exact result.

A reproducible DRI observation is not enough to turn the observation into a promise.

This category is especially important where DRI behavior is visible but the evidence does not justify making exact equality part of the generic contract.

#### OUTSIDE SCOPE

OUTSIDE SCOPE behavior is represented as NOT REQUIRED with explicit outside-scope applicability.

It is excluded from the CP/M compatibility claim.

This is stronger than saying "we have not tested it." It says that the behavior does not belong to the claim being made.

#### Release-candidate totals

Ledger 072 contains:

- 458 REQUIRED propositions;
- 116 NOT GUARANTEED propositions;
- 53 NOT REQUIRED propositions;
- 0 POLICY PENDING propositions.

The I070-derived conformance view contains:

- 430 generic REQUIRED cases;
- 28 PROFILE REQUIRED cases;
- 3 OPTIONAL cases;
- 116 NOT GUARANTEED cases;
- 50 OUTSIDE SCOPE cases.

Those totals are part of the release definition, not editorial summaries to be recomputed casually.

### 4. Generic baseline

`CPM22-BASE` contains every generic REQUIRED proposition.

It also includes the six generic decisions resolved in Investigation 070:

- the counted command tail includes the leading separating blank;
- command-tail text is converted to uppercase;
- BDOS Function 13 preserves the current user;
- sequential-write full-condition return codes are exact;
- random-write allocation-full returns `02h`;
- TAB remains distinct from CCP SPACE.

These are worth calling out because they are precisely the sort of cases where "what DRI did," "what the manuals said," and "what generic compatibility should require" were not safely interchangeable until the policy work settled them.

The baseline does **not** promise, unless a generic proposition explicitly says otherwise:

- exact residual registers;
- private addresses;
- unloaded-memory contents;
- undocumented processor results;
- DRI-only presentation details;
- active optional device mappings;
- universal hardware timing;
- host implementation details.

The general rule is simple: implementation residue stays free unless the ledger promotes an observable consequence into the contract.

### 5. Profiles and optional features

The public profile registry is:

`Compatibility Profile Registry 1.0-rc1`

All named profiles inherit `CPM22-BASE`.

The registry preserves ledger applicability and assigns stable IDs. It does not create new behavior.

Every named profile in this release candidate is AVAILABLE but unselected by default.

A product manifest states which profiles are selected, and a profile may be claimed only when every mapped case for that profile passes.

This keeps stronger fidelity claims explicit.

Exact DRI behavior in the following areas is profile-bound rather than silently folded into generic CP/M compatibility:

- console and editor behavior;
- CCP behavior;
- interactive error handling;
- diagnostic presentation;
- resident-command presentation;
- IOBYTE behavior;
- LIST behavior;
- removable-media behavior.

Two features are optional rather than baseline requirements:

- Function 37 compatibility;
- structured/headless error handling.

The undocumented wildcard Rename behavior remains outside the compatibility claim.

These distinctions are deliberate. A system can be a valid generic CP/M 2.2 implementation without reproducing every DRI presentation detail, every optional device arrangement, or every undocumented extension that can be observed on some systems.

### 6. Conformance and claims

Compatibility claims use the public Conformance Specification 1.0-rc1 and the frozen Investigation 071 tables.

Generic REQUIRED cases cannot be waived.

A failed profile case defeats that profile claim.

A failed optional case defeats only the optional claim.

NOT GUARANTEED and OUTSIDE SCOPE cases are not DRI-equality gates. They record permitted variation or explicit nonrequirements.

`BLOCKED` and `ERROR` cannot count as `PASS`.

Successful execution of real applications is useful evidence, but it does not replace narrow proposition tests.

That distinction matters. An application can run successfully while leaving a specific contract question unanswered, and a broad application failure may not identify which proposition was violated.

A compatibility claim therefore names the exact:

- ledger version;
- conformance version;
- environment;
- certification level;
- selected profiles;
- fixtures;
- runner;
- evidence hashes.

A claim is only as precise as the material it binds.

### 7. Change control

Release assembly may:

- copy frozen content;
- format it;
- index it;
- cross-reference it.

It may not:

- renumber propositions;
- change dispositions;
- change applicability;
- redefine oracles;
- silently repair semantics.

Any such semantic change requires a separately authorized investigation and a new controlled ledger or framework version.

This is not merely publication housekeeping. The ledger, profiles, oracles, and conformance mappings together define what the release means. Editing one of them semantically while leaving the version unchanged would produce a document that looks like the same release while making a different compatibility claim.

Draft 0.1 policy and strategy documents, together with earlier ledgers, remain historical material and are not current authority for this release candidate.
