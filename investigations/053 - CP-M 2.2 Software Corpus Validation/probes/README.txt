INVESTIGATION 053 PROBES AND EVIDENCE

This directory preserves the cross-category corpus validation evidence.

Files
- executed-corpus.tsv: compact 13-record execution matrix.
- validation-records.txt: required purpose/environment/procedure/observation/
  conclusion records.
- requirement-mapping.tsv: ledger-area and I052 regression mapping.
- corpus-coverage.txt: category, operation-class, and gap analysis.
- observed-output.txt: concise results and disk-state summary.
- images/: restored before and captured after disk images.
- images-sha256.txt: image hashes.
- transcripts/: raw or semantic output and generated evidence, grouped by category.
- validate-corpus.sh: structural, transcript, and image-relation audit.
- validation-audit.txt: captured validator output.
- SHA256SUMS: hashes for the preserved investigation artifacts.

Reproduction
The executions used isolated copies of the preserved I047-I051 fixtures and
their documented runners. The complete disposable working copies are not
archival inputs; the raw transcripts, result records, before/after images, and
hashes needed to audit the observations are preserved here. Restore the named
before image before each mutating case and follow the matching earlier
investigation runner/README. No manual application input is required.

Interpretation
A PASS means the stated observation occurred. For V053-12 and V053-13, the
acceptance observation is a precise unsupported-profile trap, not successful
operation of the hardware-specific application. V053-09 does not claim a
successful peer transfer.
