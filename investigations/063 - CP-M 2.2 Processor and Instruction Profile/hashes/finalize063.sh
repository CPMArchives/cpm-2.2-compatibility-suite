#!/bin/sh
set -eu
stage=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$stage"
mkdir -p hashes
shasum -a 256 \
  <project-root>/investigations/I063_CPM_2_2_Processor_and_Instruction_Profile_Prompt.txt \
  <project-root>/compatibility/'02 Compatibility Ledger - Investigation 062.txt' \
  <reference-archive>/cpm2-plm/OS2CCP.ASM \
  <reference-archive>/cpm2-plm/OS3BDOS.ASM \
  cpmsim \
  <cpmsim-root>/disks/drivea.dsk > hashes/source-inputs.sha256
find . -type f ! -path './hashes/SHA256SUMS' ! -path './hashes/protected-after.sha256' ! -path './hashes/protected-diff.txt' -print0 |
  sort -z |
  xargs -0 shasum -a 256 > hashes/SHA256SUMS
