#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
report="$root/../Investigation 068 - CP-M 2.2 Final Engineering Gap Assessment.md"

test "$(grep -Ec '^## ([1-9]|1[0-5])\. ' "$report")" -eq 15
test "$(wc -l < "$root/ledger-entries.tsv" | tr -d ' ')" -eq 652
test "$(cut -f1 "$root/ledger-entries.tsv" | sort -u | wc -l | tr -d ' ')" -eq 622
test "$(tail -n +2 "$root/duplicate-ledger-audit.tsv" | wc -l | tr -d ' ')" -eq 30
test "$(tail -n +2 "$root/policy-pending-inventory.tsv" | wc -l | tr -d ' ')" -eq 50
test "$(tail -n +2 "$root/i060-gap-closure.tsv" | wc -l | tr -d ' ')" -eq 24
test "$(tail -n +2 "$root/final-readiness-matrix.tsv" | wc -l | tr -d ' ')" -eq 15
grep -q 'Overall determination: TARGETED FOLLOW-UP REQUIRED' "$report"
grep -q '^No new behavioral compatibility proposition was discovered' "$report"
echo 'I068 validation PASS'
