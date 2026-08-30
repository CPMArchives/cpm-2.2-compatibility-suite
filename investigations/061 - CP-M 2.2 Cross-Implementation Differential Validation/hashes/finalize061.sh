#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
probe="$root/probes"

"$probe/validate061.sh" > "$probe/validation-audit.txt"
{
  echo "Ledger baseline"
  shasum -a 256 '<project-root>/compatibility/02 Compatibility Ledger - Investigation 059.txt'
  echo "Source images"
  shasum -a 256 \
    '<local-home>/z80pack/cromemcosim/disks/library/cpm22.dsk' \
    '<local-home>/z80pack/cromemcosim/disks/library/cdos258_8.dsk' \
    '<local-home>/z80pack/cromemcosim/disks/library/cdos236_8.dsk'
  echo "Documentation"
  shasum -a 256 \
    '<reference-archive>/CPM_2_0_Interface_Guide.pdf' \
    '<reference-archive>/CPM_2.2_Alteration_Guide_1979.pdf'
  echo "Simulator metadata"
  printf '%s\n' 'z80pack git 91fd28eb04e675c2127df88ed3f40675e15282e2'
  shasum -a 256 '<local-home>/z80pack/cromemcosim/README'
} > "$root/hashes/source-inputs.sha256"

(
  cd "$root"
  find . -type f \
    ! -path './hashes/SHA256SUMS' \
    ! -path './hashes/protected-after.sha256' \
    ! -path './hashes/protected-diff.txt' \
    -print0 | sort -z | xargs -0 shasum -a 256 > hashes/SHA256SUMS
)
