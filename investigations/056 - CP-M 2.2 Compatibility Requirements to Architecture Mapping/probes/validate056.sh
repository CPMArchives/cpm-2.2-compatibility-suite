#!/bin/sh
set -eu
base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

[ "$(awk 'NR>1{n++} END{print n+0}' "$base/requirement-responsibility-map.tsv")" -eq 652 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/regression-test-inventory.tsv")" -eq 62 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/architecture-mapping-review.tsv")" -eq 15 ]
[ "$(awk -F '\t' 'NR>1 && ($3=="" || $4=="" || $5=="" || $6=="" || $7==""){n++} END{print n+0}' "$base/requirement-responsibility-map.tsv")" -eq 0 ]
[ "$(awk -F '\t' 'NR>1 && $4=="Unresolved cross-layer ownership"{n++} END{print n+0}' "$base/requirement-responsibility-map.tsv")" -eq 0 ]
[ "$(cut -f1 "$base/requirement-responsibility-map.tsv" | tail -n +2 | sort | uniq | wc -l | tr -d ' ')" -eq 622 ]

echo 'ledger proposition lines mapped: 652'
echo 'unique ledger identifiers represented: 622'
echo 'unassigned responsibility mappings: 0'
echo 'mappings missing evidence/test/classification: 0'
echo 'regression tests referenced: 62 inventory entries'
echo 'consolidated mappings: 15'
echo 'validation: PASS'
