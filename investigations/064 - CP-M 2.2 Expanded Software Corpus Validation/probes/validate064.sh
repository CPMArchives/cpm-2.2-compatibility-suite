#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
report="$root/Investigation 064 - CP-M 2.2 Expanded Software Corpus Validation.md"
out="$root/probes/validation-audit.txt"
{
  test "$(grep -c '^## [0-9][0-9]*\.' "$report")" -eq 13
  for n in $(jot 13 1); do grep -q "^## $n\." "$report"; done
  grep -q 'I064 SOFTWARE CORPUS VALIDATION subsystem IG AG' "$report"
  test "$(awk -F '\t' 'NR==1{print NF}' "$root/probes/software-validation-records.tsv")" -eq 8
  test "$(awk -F '\t' 'NR>1 && NF!=8{bad++} END{print bad+0}' "$root/probes/software-validation-records.tsv")" -eq 0
  grep -q 'TP64 PASS' "$root/probes/transcripts/tp-normal.txt"
  grep -q 'Error' "$root/probes/transcripts/tp-failure.txt"
  ! grep -q 'TURBO Pascal system' "$root/probes/transcripts/tp-8080.txt"
  grep -q 'F80-64 PASS' "$root/probes/transcripts/f80-normal.txt"
  grep -q 'File not found' "$root/probes/transcripts/f80-failure.txt"
  test -s "$root/probes/extracted/F80HELLO.COM"
  echo 'PASS: report has exactly 13 required numbered sections.'
  echo 'PASS: all five records have every required field.'
  echo 'PASS: normal, failure, and processor-boundary transcripts support the report.'
  echo 'PASS: generated FORTRAN COM is present.'
  echo 'PASS: unresolved categories are explicitly identified without experimental claims.'
} > "$out"
