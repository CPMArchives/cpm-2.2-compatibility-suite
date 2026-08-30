#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
"$root/probes/validate062.sh" > "$root/probes/validation-audit.txt"
{
  echo "Ledger baseline"
  shasum -a 256 '<project-root>/compatibility/02 Compatibility Ledger - Investigation 061.txt'
  echo "Source images"
  shasum -a 256 '<local-home>/z80pack/cromemcosim/disks/library/cpm22.dsk' '<local-home>/z80pack/cromemcosim/disks/library/cdos258_8.dsk'
  echo "I059 conformance specification"
  shasum -a 256 '<project-root>/investigations/059 - CP-M 2.2 Compatibility Conformance Test Suite Design/probes/proposed-conformance-test-inventory.tsv' '<project-root>/investigations/059 - CP-M 2.2 Compatibility Conformance Test Suite Design/probes/result-record-schema.tsv' '<project-root>/investigations/059 - CP-M 2.2 Compatibility Conformance Test Suite Design/probes/pass-fail-rules.tsv' '<project-root>/investigations/059 - CP-M 2.2 Compatibility Conformance Test Suite Design/probes/ledger-test-traceability.tsv'
  echo "z80pack git 91fd28eb04e675c2127df88ed3f40675e15282e2"
} > "$root/hashes/source-inputs.sha256"
(
  cd "$root"
  find . -type f ! -path './hashes/SHA256SUMS' ! -path './hashes/protected-after.sha256' ! -path './hashes/protected-diff.txt' -print0 |
    sort -z | xargs -0 shasum -a 256 > hashes/SHA256SUMS
)

