#!/bin/sh
set -eu

base=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
rows=$(awk 'NR > 1 { n++ } END { print n+0 }' "$base/executed-corpus.tsv")
[ "$rows" -eq 13 ]
bad=$(awk -F '\t' 'NR > 1 && $6 !~ /^PASS/ { n++ } END { print n+0 }' "$base/executed-corpus.tsv")
[ "$bad" -eq 0 ]

for stem in adventure communications hardware wumpus; do
    cmp "$base/images/$stem-before.dsk" "$base/images/$stem-after.dsk"
done
if cmp -s "$base/images/wordstar-before.dsk" "$base/images/wordstar-after.dsk"; then
    echo "wordstar image unexpectedly unchanged" >&2
    exit 1
fi

count=$(find "$base/transcripts" -type f | wc -l | tr -d ' ')
[ "$count" -ge 13 ]

echo "records: 13"
echo "non-PASS records: 0"
echo "unchanged image pairs: adventure communications hardware wumpus"
echo "expected changed image: wordstar"
echo "transcript/evidence files: $count"
echo "validation: PASS"
