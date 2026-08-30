#!/bin/sh
set -eu

base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

entries=$(awk -F '\t' 'NR>1 {n++} END {print n+0}' "$base/ledger-test-coverage.tsv")
missing=$(awk -F '\t' 'NR>1 && $7=="" {n++} END {print n+0}' "$base/ledger-test-coverage.tsv")
tests=$(awk -F '\t' 'NR>1 {n++} END {print n+0}' "$base/regression-test-inventory.tsv")
bad=$(awk -F '\t' 'NR>1 && NF!=7 {n++} END {print n+0}' "$base/regression-test-inventory.tsv")
dups=$(awk -F '\t' 'NR>1 {n[$1]++} END {for(k in n) if(n[k]>1)d++; print d+0}' "$base/regression-test-inventory.tsv")

test "$entries" -eq 652
test "$missing" -eq 0
test "$tests" -eq 62
test "$bad" -eq 0
test "$dups" -eq 0

printf 'ledger_entries=%s\nmissing_primary_tests=%s\ninventory_tests=%s\nbad_field_rows=%s\nduplicate_test_ids=%s\nPASS\n' \
  "$entries" "$missing" "$tests" "$bad" "$dups"
