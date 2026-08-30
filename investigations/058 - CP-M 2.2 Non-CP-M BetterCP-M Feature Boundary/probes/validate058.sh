#!/bin/sh
set -eu
base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

[ "$(awk 'NR>1{n++} END{print n+0}' "$base/extension-constraint-map.tsv")" -eq 652 ]
[ "$(cut -f1 "$base/extension-constraint-map.tsv" | tail -n +2 | sort | uniq | wc -l | tr -d ' ')" -eq 622 ]
[ "$(awk -F '\t' 'NR>1 && ($3=="" || $4=="" || $5=="" || $6=="" || $7==""){n++} END{print n+0}' "$base/extension-constraint-map.tsv")" -eq 0 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/extension-boundary-classifications.tsv")" -eq 26 ]
[ "$(awk -F '\t' 'NR>1 && ($2=="" || $3=="" || $4=="" || $5=="" || $6=="" || $7==""){n++} END{print n+0}' "$base/extension-boundary-classifications.tsv")" -eq 0 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/risk-preservation-matrix.tsv")" -eq 9 ]

echo 'ledger proposition lines constrained: 652'
echo 'unique ledger identifiers represented: 622'
echo 'incomplete extension constraints: 0'
echo 'feature-category classifications: 26'
echo 'incomplete feature classifications: 0'
echo 'risk surfaces: 9'
echo 'validation: PASS'
