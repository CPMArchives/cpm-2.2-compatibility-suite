#!/bin/sh
set -eu
base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

[ "$(awk 'NR>1{n++} END{print n+0}' "$base/personality-requirement-map.tsv")" -eq 652 ]
[ "$(cut -f1 "$base/personality-requirement-map.tsv" | tail -n +2 | sort | uniq | wc -l | tr -d ' ')" -eq 622 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/personality-boundary-review.tsv")" -eq 17 ]
[ "$(awk -F '\t' 'NR>1 && ($3=="" || $4=="" || $5=="" || $6=="" || $7==""){n++} END{print n+0}' "$base/personality-requirement-map.tsv")" -eq 0 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/software-boundary-analysis.tsv")" -eq 8 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/validation-ownership.tsv")" -eq 12 ]

echo 'ledger proposition lines mapped: 652'
echo 'unique ledger identifiers represented: 622'
echo 'incomplete personality mappings: 0'
echo 'consolidated mappings: 17'
echo 'software boundary cases: 8'
echo 'validation ownership families: 12'
echo 'validation: PASS'
