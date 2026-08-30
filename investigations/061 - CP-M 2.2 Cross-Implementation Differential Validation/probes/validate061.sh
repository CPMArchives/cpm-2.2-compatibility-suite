#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
report="$root/../Investigation 061 - CP-M 2.2 Cross-Implementation Differential Validation.md"

test -f "$report"
test "$(grep -c '^## [0-9][0-9]*\.' "$report")" -eq 14
for n in $(jot 14 1); do grep -q "^## $n\." "$report"; done
grep -q 'I061 DIFFERENTIAL VALIDATION COMPATIBILITY subsystem IG AG' "$report"
grep -q '^D61-11' "$root/differential-records.tsv"
grep -q 'STATE61 VER DRIVE USER LOGIN RO F41 ENTRYSP RET 0022 00 00 0001 0000 0000' "$root/transcripts/dri-cpm22-cromemco.txt"
grep -q 'Illegal system call 29H at 013EH' "$root/transcripts/cromemco-cdos258.txt"
grep -q 'BASE61 VER DRIVE USER LOGIN RO ENTRYSP RET 0022 00 00 0001 0000 EBA9 EB5F' "$root/transcripts/dri-base61.txt"
grep -q 'BASE61 VER DRIVE USER LOGIN RO ENTRYSP RET 0022 00 00 0022 0000 F8AA D048' "$root/transcripts/cdos-base61.txt"
grep -q 'ZERO41 fn12-HL 0084' "$root/transcripts/cromemco-cdos236.txt"
grep -qi 'copy61' "$root/listings/dri-after-long.txt"
grep -qi 'copy61' "$root/listings/cdos258-after-long.txt"
cmp -n 53 "$root/SRC61.TXT" "$root/extracted/dri-COPY61.TXT"
cmp "$root/SRC61.TXT" "$root/extracted/cdos258-COPY61.TXT"
"$root/build.sh"
echo "I061 validation passed"
