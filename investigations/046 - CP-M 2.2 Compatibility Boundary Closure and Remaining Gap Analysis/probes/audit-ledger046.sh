#!/bin/sh
set -eu
ledger=${1:?ledger path required}
tmp=${TMPDIR:-/tmp}/i046-ledger-numbers.$$
expected=${TMPDIR:-/tmp}/i046-ledger-expected.$$
unique=${TMPDIR:-/tmp}/i046-ledger-unique.$$
trap 'rm -f "$tmp" "$expected" "$unique"' EXIT
grep -E '^[0-9]{4}\.' "$ledger" | sed 's/\..*//' | sort > "$tmp"
printf 'entry-lines: '
wc -l < "$tmp"
printf 'unique-numbers: '
sort -u "$tmp" | wc -l
printf 'duplicate-numbers:\n'
uniq -d "$tmp"
printf 'missing-0001-through-0622:\n'
seq -f '%04g' 1 622 > "$expected"
sort -u "$tmp" > "$unique"
comm -23 "$expected" "$unique"
printf 'dispositions:\n'
grep 'Disposition:' "$ledger" | sed 's/.*Disposition:[[:space:]]*//' | sort | uniq -c
printf 'policy-pending-entries:\n'
awk '/^[0-9][0-9][0-9][0-9]?\./{entry=$0} /Disposition: POLICY PENDING/{print entry}' "$ledger"
