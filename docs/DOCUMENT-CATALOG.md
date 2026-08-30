# CP/M Compatibility Document Catalog

This directory contains the documents selected from the BetterCP/M compatibility work for review and development into the official CP/M Compatibility project documentation.

These files have not yet been rewritten or consolidated. Some are current baseline material, some are machine-readable normative inputs, and others are retained as editorial or historical sources. A file's presence here does not mean it should be published unchanged.

## Primary compatibility documents

### `standard/BetterCPM CP-M 2.2 Compatibility Standard 1.0-rc1.txt`

Normative RC1 overview of the compatibility target, baseline claim, profiles, exclusions, conformance model, certification status, and authority relationships.

### `ledger/02Compatibility Ledger FINAL.txt`

The owner-designated baseline ledger. It contains 627 compatibility propositions covering observable CP/M 2.2 behavior, permitted variation, evidence references, applicability, and conformance expectations. This is the manually cleaned successor to the packaged Ledger 072 and includes the correction to proposition 0381.

### `policy/BetterCPM Compatibility Policy 1.0-rc1.txt`

Normative RC1 rules for interpreting compatibility evidence and applying REQUIRED, PROFILE REQUIRED, OPTIONAL, NOT GUARANTEED, and OUTSIDE SCOPE treatments.

### `conformance/BetterCPM CP-M 2.2 Conformance Specification 1.0-rc1.txt`

Normative conceptual specification for conformance cases, applicability, aggregation, campaigns, evidence, certification levels, and result handling. It defines validation rules rather than implementing test executables.

### `profiles/Compatibility Profile Registry 1.0-rc1.txt`

Normative prose defining profile identities, availability, inheritance, selection, and the rule that profiles may add requirements but cannot weaken the baseline.

### `profiles/Compatibility Profile Registry 1.0-rc1.tsv`

Machine-readable normative registry of the baseline and named compatibility profiles, including their identifiers, versions, status, inheritance, and scope.

## Normative conformance tables

### `conformance/tables/frozen-test-inventory.tsv`

Inventory of the 62 frozen top-level conformance test identifiers and their scopes.

### `conformance/tables/conformance-framework-matrix.tsv`

The principal 627-row machine-readable mapping of ledger propositions to case IDs, classifications, applicability rules, dependencies, and oracle identities. The conformance tools derive their executable catalog from this table.

### `conformance/tables/ledger-case-traceability.tsv`

Explicit one-to-one traceability between all ledger propositions, frozen cases, and oracle definitions.

### `conformance/tables/oracle-definitions.tsv`

Normative expected-result and interpretation definitions for every proposition-level conformance case.

### `conformance/tables/certification-levels.tsv`

Definitions of development, baseline, interface, full-system, profile, and optional claim levels and their required gates.

### `conformance/tables/campaign-manifest-schema.tsv`

Schema for binding a conformance campaign to a candidate, ledger, cases, profiles, fixtures, environment, tools, reviewers, evidence, and hashes.

### `conformance/tables/result-record-schema.tsv`

Schema for recording proposition-level results, observations, evidence, dependencies, and failure information consistently.

### `conformance/tables/campaign-phases.tsv`

Defines the purpose and ordering of the conformance campaign phases.

### `conformance/tables/failure-handling.tsv`

Defines result states, failure classifications, aggregation consequences, preservation requirements, and rerun treatment.

### `profiles/profile-case-map.tsv`

Normative mapping of profile-specific and optional conformance cases to stable profile identifiers.

## User-facing and editorial source material

### `BetterCPM_CP-M_2.2_Compatibility_Specification_RC1_Community_Edition.txt`

The first intentional attempt to present the compatibility work in a CP/M hobbyist voice rather than a standards-committee voice. It is non-normative but is important source material for the planned public rewrite.

### `standard/BetterCPM CP-M 2.2 Compatibility Standard Guide 1.0-rc1.txt`

Plain-language companion to the normative Standard. It explains the target, baseline, profiles, variation, conformance, and certification status more accessibly.

### `README.txt`

Original RC1 package entry point. It explains the package's purpose, controlling documents, non-certification status, and reproduction process. It is useful source material for a future GitHub landing document.

### `PUBLICATION-INDEX.txt`

Original RC1 authority and publication map, listing each package artifact and whether its role was normative, informative, inventory, integrity, or validation.

### `RELEASE-NOTES.txt`

Concise record of RC1 scope, included artifacts, profile status, known limitations, non-certification status, and supersession of earlier drafts.

## Historical and release-provenance material

### `VALIDATION-REPORT.txt`

Records the integrity checks performed on the original RC1 package: proposition counts, case and oracle coverage, profile mappings, resolved references, and package consistency. It validates the older packaged ledger hash, not the later cleaned FINAL baseline.

### `ledger/02 Compatibility Ledger - Investigation 072.txt`

Frozen Ledger 072 snapshot referenced and hash-bound by the original RC1 package, normative tables, and current conformance-suite design. It is retained for provenance and comparison; the working documentation baseline is `02Compatibility Ledger FINAL.txt`.

### `policy/01 Compatibility Policy.txt`

Superseded Draft 0.1 policy. It preserves fuller reasoning about evidence sources, de facto compatibility, unresolved behavior, hardware boundaries, experimental discipline, and implementation freedom. It is retained as editorial research material, not current authority.

## Documents intentionally not extracted

- The intermediate root-level Ledger 072 copy, because it has neither the package ledger's frozen provenance role nor the FINAL ledger's baseline role.
- Ledgers 003–071, because they are cumulative superseded snapshots rather than independent investigation reports.
- Duplicate ZIP archives, release-construction metadata, macOS metadata, and implementation artifacts already maintained elsewhere in the conformance-tools project.

