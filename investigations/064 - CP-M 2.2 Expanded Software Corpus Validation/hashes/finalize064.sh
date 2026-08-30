#!/bin/sh
set -eu
stage=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$stage"
shasum -a 256 \
  <project-root>/investigations/I064_CPM_2_2_Expanded_Software_Corpus_Validation_Prompt.txt \
  <project-root>/compatibility/'02 Compatibility Ledger - Investigation 063.txt' \
  cpmsim \
  <cpmsim-root>/disks/drivea.dsk \
  <cpmsim-root>/disks/driveb.dsk > hashes/source-inputs.sha256
find . -type f ! -path './hashes/SHA256SUMS' ! -path './hashes/protected-after.sha256' ! -path './hashes/protected-diff.txt' -print0 |
  sort -z | xargs -0 shasum -a 256 > hashes/SHA256SUMS
