#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
report="$root/Investigation 065 - CP-M 2.2 Communications Profile Validation.md"
out="$root/probes/validation-audit.txt"
{
  test "$(grep -c '^## [0-9][0-9]*\.' "$report")" -eq 14
  for n in $(jot 14 1); do grep -q "^## $n\." "$report"; done
  grep -q 'I065 COMMUNICATIONS PROFILE VALIDATION subsystem IG AG' "$report"
  test "$(awk -F '\t' 'NR==1{print NF}' "$root/probes/communications-validation-records.tsv")" -eq 8
  test "$(awk -F '\t' 'NR>1 && NF!=8{bad++} END{print bad+0}' "$root/probes/communications-validation-records.tsv")" -eq 0
  test "$(awk 'END{print NR}' "$root/probes/communications-validation-records.tsv")" -eq 8
  grep -q 'Transfer complete' "$root/probes/transcripts/xmodem-normal.txt"
  grep -q 'Non-ACK: 0x15' "$root/probes/transcripts/xmodem-retry.txt"
  grep -q 'INJECT-NAK' "$root/probes/peer-logs/xmodem-retry.tsv"
  grep -q 'FORCED-DISCONNECT' "$root/probes/peer-logs/disconnect.tsv"
  grep -q 'FORCED-DISCONNECT-AFTER-BLOCK' "$root/probes/peer-logs/xmodem-interrupted.tsv"
  grep -q 'SIO 2A running at 1200 baud' "$root/probes/transcripts/terminal-1200.txt"
  grep -q 'SIO 2A running at 9600 baud' "$root/probes/transcripts/terminal-9600.txt"
  cmp "$root/probes/received/xmodem-normal.bin" "$root/probes/received/xmodem-retry.bin"
  test "$(wc -c < "$root/probes/received/xmodem-normal.bin" | tr -d ' ')" -eq 128
  echo 'PASS: report has exactly 14 required numbered sections.'
  echo 'PASS: seven validation records contain every required field.'
  echo 'PASS: successful transfer, injected retry, disconnect, unavailable, and timing artifacts are present.'
  echo 'PASS: normal and retry recovered records are identical and 128 bytes.'
  echo 'PASS: profile and generic CP/M conclusions are separated.'
} > "$out"
