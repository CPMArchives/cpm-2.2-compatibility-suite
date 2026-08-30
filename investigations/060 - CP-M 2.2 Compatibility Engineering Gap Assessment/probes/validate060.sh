#!/bin/sh
set -eu
base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

[ "$(awk 'NR>1{n++} END{print n+0}' "$base/gap-assessment-matrix.tsv")" -eq 24 ]
[ "$(awk -F '\t' 'NR>1 && ($2=="" || $3=="" || $4=="" || $5=="" || $6=="" || $7=="" || $8==""){n++} END{print n+0}' "$base/gap-assessment-matrix.tsv")" -eq 0 ]
[ "$(awk -F '\t' 'NR>1 && $8!="RELEASE READY" && $8!="ADDITIONAL INVESTIGATION REQUIRED" && $8!="POLICY PENDING" && $8!="NOT REQUIRED"{n++} END{print n+0}' "$base/gap-assessment-matrix.tsv")" -eq 0 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/duplicate-ledger-audit.tsv")" -eq 30 ]
[ "$(awk -F '\t' 'NR>1 && $4 ~ /,/{n++} END{print n+0}' "$base/duplicate-ledger-audit.tsv")" -eq 0 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/policy-pending-inventory.tsv")" -eq 50 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/conformance-test-inventory.tsv")" -eq 62 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/recommended-investigations.tsv")" -eq 7 ]
[ "$(awk 'NR>1{n++} END{print n+0}' "$base/release-gates.tsv")" -eq 10 ]

echo 'gap areas assessed: 24'
echo 'incomplete gap records: 0'
echo 'duplicate identifier set: 30; conflicting dispositions: 0'
echo 'policy-pending proposition lines: 50'
echo 'conformance tests reviewed: 62'
echo 'recommended evidence campaigns: 7'
echo 'release gates: 10'
echo 'validation: PASS'
