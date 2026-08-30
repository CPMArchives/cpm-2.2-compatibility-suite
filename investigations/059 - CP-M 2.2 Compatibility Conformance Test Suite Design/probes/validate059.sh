#!/bin/sh
set -eu
base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

[ "$(awk 'NR>1{n++} END{print n+0}' "$base/proposed-conformance-test-inventory.tsv")" -eq 62 ]
[ "$(cut -f1 "$base/proposed-conformance-test-inventory.tsv" | tail -n +2 | sort | uniq | wc -l | tr -d ' ')" -eq 62 ]
[ "$(awk -F '\t' 'NR>1{for(i=2;i<=11;i++) if($i==""){bad++}} END{print bad+0}' "$base/proposed-conformance-test-inventory.tsv")" -eq 0 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/ledger-test-traceability.tsv")" -eq 652 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/conformance-levels.tsv")" -eq 5 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/pass-fail-rules.tsv")" -eq 5 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/result-record-schema.tsv")" -eq 15 ]

awk -F '\t' '
  NR==FNR { if (NR>1) known[$1]=1; next }
  FNR>1 { split($7,a,","); for(i in a) if(!(a[i] in known)) bad++ }
  END { exit(bad!=0) }
' "$base/proposed-conformance-test-inventory.tsv" "$base/ledger-test-traceability.tsv"

echo 'conformance tests: 62'
echo 'duplicate test identifiers: 0'
echo 'incomplete test definitions: 0'
echo 'ledger proposition lines mapped: 652'
echo 'unknown primary-test references: 0'
echo 'conformance levels: 5'
echo 'validation: PASS'
