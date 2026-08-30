#!/bin/sh
set -eu
base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

[ "$(awk 'NR>1 {n++} END {print n+0}' "$base/undocumented-behavior-inventory.tsv")" -eq 21 ]
grep -q 'MOD41 wrapper-count resultHL 01 0022' "$base/transcripts/i041/console.txt"
grep -q 'DIRECT41 private-BDOS-HL invalid-SELDSK-HL 0022 0000' "$base/transcripts/i041/failure.txt"
grep -q 'IN42 count=07 data=BATCH42' "$base/transcripts/i042/software.txt"
grep -q 'HELLO42 OK' "$base/transcripts/i042/software.txt"
grep -q '00 A5 5A 0022' "$base/transcripts/i043/main.txt"
grep -q 'MAXOK43 EXECUTED' "$base/transcripts/i043/main.txt"
grep -q 'BAD LOAD' "$base/transcripts/i043/main.txt"

for area in i041 i043; do
  cmp "$base/images/$area/images-before/drivea.dsk" "$base/images/$area/images-after/drivea.dsk"
  cmp "$base/images/$area/images-before/driveb.dsk" "$base/images/$area/images-after/driveb.dsk"
done

[ "$(grep -c BYTE-IDENTICAL "$base/rebuild-verification.txt")" -eq 11 ]
echo 'inventory rows: 21'
echo 'controlled tests: 7'
echo 'rebuilds byte-identical: 11'
echo 'I041/I043 image pairs unchanged: 4'
echo 'required transcript markers: present'
echo 'validation: PASS'
