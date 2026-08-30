#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ledger="$root/02 Compatibility Ledger - Investigation 069.txt"

entries=$(grep -Ec '^[0-9]{4}\. ' "$ledger")
unique=$(grep -E '^[0-9]{4}\. ' "$ledger" | cut -c1-4 | sort -u | wc -l | tr -d ' ')
duplicates=$(grep -E '^[0-9]{4}\. ' "$ledger" | cut -c1-4 | sort | uniq -d | wc -l | tr -d ' ')
test "$entries" -eq 627
test "$unique" -eq 627
test "$duplicates" -eq 0

ids=$(grep -E '^[0-9]{4}\. ' "$ledger" | cut -c1-4)
expected=$(jot -w '%04d' 627 1)
test "$ids" = "$expected"

test "$(grep -Ec '^011 - CP/M 2\.2 BDOS Sequential Write and File Creation Semantics$' "$ledger")" -eq 1
for id in 0623 0624 0625 0626 0627; do grep -q "^$id\. " "$ledger"; done
grep -q '^0523\. Function 37 state-effect profile scope$' "$ledger"
grep -q '^069 - CP/M 2.2 Compatibility Ledger Integrity Resolution$' "$ledger"
test "$(grep -Ec '^  I[0-9]{3} -' "$ledger")" -eq 69

for f in "$root/probes/missing-identifier-report.txt" "$root/probes/duplicate-identifier-report.txt"; do
  test ! -s "$f"
done

echo 'I069 ledger validation PASS'
