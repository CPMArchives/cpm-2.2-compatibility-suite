BETTERCP/M CP/M 2.2 COMPATIBILITY STANDARD 1.0-rc1
Release candidate package

Release ID: bettercpm-cpm22-standard-1.0-rc1
Publication base: /bettercpm/compatibility/releases/BetterCPM-CPM22-Compatibility-Standard-1.0-rc1/
Authoritative manifest: RELEASE-MANIFEST.tsv
Package hashes: PACKAGE-SHA256SUMS

This package publishes the compatibility specification; it does not contain
a BetterCP/M implementation, candidate campaign, conformance certificate, or
claim that an implementation has passed the suite.

Start with PUBLICATION-INDEX.txt. Compatibility behavior is controlled by
Ledger 072. The Standard summarizes scope, the Policy defines treatment, the
Conformance Specification defines validation, and the Profile Registry assigns
stable profile identity. In a conflict about a numbered compatibility
proposition, Ledger 072 controls.

Reproduction: copy every source identified by SOURCE-MAP.tsv byte-for-byte to
its package path, generate the four publication metadata files from the F073-02
task, then verify PACKAGE-SHA256SUMS. The task evidence preserves generation
and validation records; no archived ZIP is required.
