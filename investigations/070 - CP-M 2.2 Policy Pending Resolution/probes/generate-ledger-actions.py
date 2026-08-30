#!/usr/bin/env python3
import csv
import pathlib

root = pathlib.Path(__file__).parent
with (root / 'policy-resolution-matrix.tsv').open() as stream:
    rows = list(csv.DictReader(stream, delimiter='\t'))

mapping = {
    'REQUIRED': ('REQUIRED', 'direct baseline requirement'),
    'PROFILE REQUIRED': ('REQUIRED', 'rewrite as conditional named-profile requirement'),
    'OPTIONAL': ('NOT REQUIRED', 'state optional opt-in profile/extension applicability'),
    'NOT GUARANTEED': ('NOT GUARANTEED', 'replace exact assertion with permitted-variation wording where necessary'),
    'OUTSIDE SCOPE': ('NOT REQUIRED', 'state explicit exclusion from compatibility claim'),
}

with (root / 'recommended-ledger-actions.tsv').open('w', newline='') as stream:
    fields = ['id', 'title', 'I070 decision', 'recommended ledger disposition', 'required wording treatment', 'applicability/profile', 'evidence label']
    writer = csv.DictWriter(stream, fieldnames=fields, delimiter='\t')
    writer.writeheader()
    for row in rows:
        disposition, treatment = mapping[row['decision']]
        writer.writerow({
            'id': row['id'],
            'title': row['title'],
            'I070 decision': row['decision'],
            'recommended ledger disposition': disposition,
            'required wording treatment': treatment,
            'applicability/profile': row['applicability/profile'],
            'evidence label': 'I070 POLICY PENDING RESOLUTION subsystem IG AG',
        })

