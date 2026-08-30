Investigation 071 conformance-framework artifacts

This directory freezes the 62 I059 top-level test identifiers at version 1.0.0
and defines one proposition-level normative case for each of the 627 canonical
Ledger 070 entries. No probe execution is claimed by I071.

Primary files:
  frozen-test-inventory.tsv             62 stable parent test identifiers
  conformance-framework-matrix.tsv      627 normative proposition cases
  ledger-case-traceability.tsv          one-to-one proposition/case map
  oracle-definitions.tsv                versioned normative oracles
  campaign-manifest-schema.tsv          immutable campaign identity fields
  result-record-schema.tsv              per-case result requirements
  certification-levels.tsv              claim gates
  failure-handling.tsv                  result and aggregation semantics
  campaign-phases.tsv                   execution order and dependencies
  validation-audit.txt                  machine-checked framework audit

Evidence label: I071 CONFORMANCE FRAMEWORK FINALIZATION subsystem IG AG
Classification counts: {'REQUIRED': 430, 'PROFILE REQUIRED': 28, 'NOT GUARANTEED': 116, 'OUTSIDE SCOPE': 50, 'OPTIONAL': 3}
