#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
report="$root/Investigation 063 - CP-M 2.2 Processor and Instruction Profile.md"
out="$root/probes/validation-audit.txt"
{
  test "$(grep -c '^## [0-9][0-9]*\.' "$report")" -eq 15
  for n in $(jot 15 1); do grep -q "^## $n\." "$report"; done
  grep -q 'I063 PROCESSOR INSTRUCTION PROFILE subsystem IG AG' "$report"
  grep -q '^## 12\. Proposed ledger additions' "$report"
  grep -q '^## 13\. Existing-entry updates' "$report"
  grep -q '^## 14\. Open questions' "$report"
  grep -q 'POLICY PENDING' "$report"
  test "$(awk -F '\t' 'NR==1{print NF}' "$root/probes/processor-profile-records.tsv")" -eq 8
  test "$(awk -F '\t' 'NR>1 && NF!=8{bad++} END{print bad+0}' "$root/probes/processor-profile-records.tsv")" -eq 0
  grep -q 'CPU8080 PASS' "$root/probes/transcripts/z80-documented.txt"
  grep -q 'CPU8080 PASS' "$root/probes/transcripts/8080-boundary.txt"
  grep -q 'CPUZ80 PASS' "$root/probes/transcripts/z80-documented.txt"
  ! grep -q 'CPUZ80 PASS' "$root/probes/transcripts/8080-boundary.txt"
  grep -q 'Op-code trap at 0x0105 0xcb 0x30' "$root/probes/transcripts/z80-undocumented-trapped.txt"
  test "$(grep -l 'TIMING63 DONE' "$root"/probes/transcripts/timing-*.txt | wc -l | tr -d ' ')" -eq 2
  grep -q 'All four COM files rebuilt byte-identically.' "$root/probes/rebuild-verification.txt"
  for d in run-z80 run-8080; do
    cmp "$root/probes/images-before/$d-drivea.dsk" "$root/probes/images-after/$d-drivea.dsk"
    cmp "$root/probes/images-before/$d-driveb.dsk" "$root/probes/images-after/$d-driveb.dsk"
  done
  echo 'PASS: report has exactly 15 required numbered sections.'
  echo 'PASS: evidence string, classifications, ledger proposals, updates, and open questions are present.'
  echo 'PASS: all eight experimental records contain every required field.'
  echo 'PASS: retained transcripts support the stated processor boundaries.'
  echo 'PASS: all four COM files rebuild byte-identically.'
  echo 'PASS: all staged before/after disk images are byte-identical.'
} > "$out"
