INVESTIGATION 052 ARTIFACT GUIDE

This directory contains a proposed compatibility regression specification,
not an implementation of a test framework.

ledger-requirement-map.tsv
  Mechanical extraction of all 652 independently numbered propositions in
  the authoritative Investigation 051 ledger, including disposition and
  conformance language.

regression-test-inventory.tsv
  Sixty-two proposed regression tests. Every row supplies the required test
  identifier, area, requirement range, procedure, expected result, evidence
  source, and validation mode.

ledger-test-coverage.tsv
  One row per ledger proposition, assigning a validation class and one or
  more primary proposed tests.

section-suite-map.tsv / ledger-section-ranges.txt
  Auditable intermediate mapping from ledger sections to proposed tests.

preserved-artifact-index.tsv
  Index of existing COM programs, harnesses, observed-output summaries, and
  READMEs available from Investigations 001-051. These remain read-only and
  were not copied or modified.

coverage-summary.txt
  Mapping audit: 652 mapped entries, zero missing primary tests, 62 inventory
  tests, and zero malformed inventory rows.

Validation rule
  REQUIRED means positive conformance. NOT GUARANTEED means a variability or
  non-assertion test. POLICY PENDING means the test is gated by the selected
  profile. NOT REQUIRED means an anti-requirement test that prevents incidental
  behavior from becoming mandatory.
