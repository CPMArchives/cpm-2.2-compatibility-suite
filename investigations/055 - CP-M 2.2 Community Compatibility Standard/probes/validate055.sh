#!/bin/sh
set -eu
base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

[ "$(awk 'NR>1{n++} END{print n+0}' "$base/ledger-test-traceability.tsv")" -eq 652 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/regression-test-inventory.tsv")" -eq 62 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/undocumented-behavior-inventory.tsv")" -eq 21 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/community-standard-review.tsv")" -eq 20 ]

for pair in 'REQUIRED 445' 'NOT_GUARANTEED 109' 'POLICY_PENDING 50' 'NOT_REQUIRED 48'; do
  key=${pair% *}; expected=${pair#* }
  label=$(printf '%s' "$key" | tr '_' ' ')
  actual=$(awk -F '\t' -v d="$label" 'NR>1 && $4==d{n++} END{print n+0}' "$base/ledger-test-traceability.tsv")
  [ "$actual" -eq "$expected" ]
done

[ "$(awk -F '\t' 'NR>1 && $7==""{n++} END{print n+0}' "$base/ledger-test-traceability.tsv")" -eq 0 ]
[ "$(cut -f1 "$base/regression-test-inventory.tsv" | tail -n +2 | sort | uniq -d | wc -l | tr -d ' ')" -eq 0 ]

echo 'ledger propositions: 652'
echo 'dispositions: REQUIRED 445; NOT GUARANTEED 109; POLICY PENDING 50; NOT REQUIRED 48'
echo 'mapped propositions without primary test: 0'
echo 'regression tests: 62; duplicate identifiers: 0'
echo 'standard conclusions: 20'
echo 'undocumented behaviors reviewed: 21'
echo 'validation: PASS'
