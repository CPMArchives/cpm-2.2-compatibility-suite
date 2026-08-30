#!/usr/bin/env python3
import collections
import csv
import pathlib
import re

ledger_path = pathlib.Path('<project-root>/compatibility/02 Compatibility Ledger - Investigation 069.txt')
matrix_path = pathlib.Path(__file__).with_name('policy-resolution-matrix.tsv')
text = ledger_path.read_text()
matches = list(re.finditer(r'(?m)^(\d{4})\.\s+(.+)$', text))
pending = {}
for i, match in enumerate(matches):
    block = text[match.start():matches[i + 1].start() if i + 1 < len(matches) else len(text)]
    if re.search(r'(?m)^\s*Disposition:\s*POLICY PENDING\s*$', block):
        pending[match.group(1)] = match.group(2).strip()

with matrix_path.open() as stream:
    rows = list(csv.DictReader(stream, delimiter='\t'))
ids = [row['id'] for row in rows]
decisions = collections.Counter(row['decision'] for row in rows)
allowed = {'REQUIRED', 'PROFILE REQUIRED', 'OPTIONAL', 'NOT GUARANTEED', 'OUTSIDE SCOPE'}

errors = []
if len(rows) != 49:
    errors.append(f'expected 49 rows, found {len(rows)}')
if len(set(ids)) != len(ids):
    errors.append('duplicate matrix identifiers')
if set(ids) != set(pending):
    errors.append(f'identifier mismatch missing={sorted(set(pending)-set(ids))} extra={sorted(set(ids)-set(pending))}')
if set(decisions) - allowed:
    errors.append(f'unknown decisions={sorted(set(decisions)-allowed)}')
for row in rows:
    if row['current'] != 'POLICY PENDING':
        errors.append(f"{row['id']} current status is not POLICY PENDING")
    if not all(row[field].strip() for field in ('origin', 'evidence reviewed', 'decision', 'rationale', 'conformance impact')):
        errors.append(f"{row['id']} has an empty required field")

print(f'ledger_pending={len(pending)}')
print(f'matrix_rows={len(rows)} unique_ids={len(set(ids))}')
for name in sorted(allowed):
    print(f'{name}={decisions[name]}')
print('identifier_coverage=' + ('PASS' if set(ids) == set(pending) else 'FAIL'))
print('field_validation=' + ('PASS' if not errors else 'FAIL'))
if errors:
    for error in errors:
        print('ERROR ' + error)
    raise SystemExit(1)
print('I070 policy matrix validation PASS')

