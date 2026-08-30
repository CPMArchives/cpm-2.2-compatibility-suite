#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
report="$root/../Investigation 062 - CP-M 2.2 Compatibility Conformance Pilot Execution.md"
records="$root/conformance-pilot-records.tsv"

test -f "$report"
test "$(grep -c '^## [0-9][0-9]*\.' "$report")" -eq 14
for n in $(jot 14 1); do grep -q "^## $n\." "$report"; done
grep -q 'I062 CONFORMANCE PILOT VALIDATION subsystem IG AG' "$report"

awk -F '\t' 'NR==1{if(NF!=15) exit 1; next} NF==0{next} {if(NF!=15) exit 1; n++; r[$7]++} END{if(n!=18 || r["PASS"]!=9 || r["FAIL"]!=2 || r["BLOCKED"]!=7) exit 1}' "$records"
grep -q 'Illegal system call 29H at 013EH' "$root/transcripts/cdos258-pilot.txt"
grep -q 'STATE61 VER DRIVE USER LOGIN RO F41 ENTRYSP RET 0022 00 00 0001 0000 0000' "$root/transcripts/dri-pilot.txt"
grep -q '00 C3' "$root/transcripts/dri-pilot.txt"
grep -q '0F 79' "$root/transcripts/cdos258-pilot.txt"
grep -qi 'copy62' "$root/dri-after-listing.txt"
grep -qi 'copy62' "$root/cdos-after-listing.txt"
cmp -n 53 "$root/SRC61.TXT" "$root/extracted/dri-COPY62.TXT"
cmp "$root/SRC61.TXT" "$root/extracted/cdos-COPY62.TXT"
"$root/build.sh"
echo "I062 validation passed: 18 records; 9 PASS, 2 FAIL, 7 BLOCKED"
