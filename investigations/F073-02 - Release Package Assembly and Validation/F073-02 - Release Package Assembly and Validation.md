# F073-02 - Release Package Assembly and Validation

## Objective and authority

This release-engineering task assembled BetterCP/M CP/M 2.2 Compatibility Standard 1.0-rc1 from Ledger 072 and the validated I074 artifacts. It made no compatibility, policy, profile, or conformance semantic change.

## Package contents

The package is `BetterCPM-CPM22-Compatibility-Standard-1.0-rc1`. It contains the Standard, byte-identical Ledger 072, Policy, Conformance Specification, nine frozen tables, Profile Registry and case mapping, README, authoritative release manifest, publication index, release notes, source map, hash manifest, and validation report.

## Manifest and publication

`RELEASE-MANIFEST.tsv` is the authoritative inventory for every payload artifact other than itself and the companion hash file. It records relative/package publication paths, SHA-256, versions, authority roles, and supersession. `PACKAGE-SHA256SUMS` hashes every package file except itself, including the release manifest. `PUBLICATION-INDEX.txt` exposes only current RC1 paths and labels historical Draft 0.1 documents and Ledgers 001-071 non-current.

## Validation

All 16 normative copies are byte-identical to their sources. The manifest has 21 payload rows with no missing, extra, or mismatched artifact. The package hash manifest validates. Ledger 072 remains `eb16466fdbff8fb2bc07bd02a07198b8426fb6452be3dd1f256cbff4af0547d3`, with 627 unique propositions and no POLICY PENDING disposition. All 62 tests, 627 cases, 627 oracles, 18 registry rows, and 31 conditional case mappings validate.

## Limitations

RC1 is a specification package only. It contains no BetterCP/M implementation, runner suite implementation, candidate campaign, certificate, or compatibility claim. Those remain deferred implementation/certification tasks.

## Conclusion

The BetterCP/M CP/M 2.2 Compatibility Standard 1.0-rc1 package is complete, reproducible from `SOURCE-MAP.tsv` and the manifest, hash-valid, path-consistent, synchronized, and internally consistent as a release-candidate artifact. No unexpected ledger-impacting issue was found.
