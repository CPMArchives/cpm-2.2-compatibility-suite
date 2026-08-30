#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
before="$root/images-before"
after="$root/images-after"
tmp="$root/work"
mkdir -p "$before" "$after" "$tmp"
rm -f "$before"/*.dsk "$after"/*.dsk "$tmp"/*

python3 "$root/make-empty040.py" ibm-3740 "$before/empty-ibm3740.dsk"
cp <cpmsim-root>/disks/drivea.dsk "$before/normal-ibm3740.dsk"

python3 "$root/make-empty040.py" ibm-3740 "$before/nearly-full-ibm3740.dsk"
dd if=/dev/zero of="$tmp/FILLER.BIN" bs=128 count=1870 2>/dev/null
cpmcp -f ibm-3740 "$before/nearly-full-ibm3740.dsk" "$tmp/FILLER.BIN" 0:FILLER.BIN

cp "$before/normal-ibm3740.dsk" "$tmp/damage-source.dsk"
python3 "$root/analyze040.py" damage ibm-3740 "$tmp/damage-source.dsk" "$before/damaged-ibm3740.dsk" > "$root/transcripts/damage-action.txt"

python3 "$root/make-empty040.py" z80pack-hd "$before/empty-z80pack-hd.dsk"
printf 'different geometry\r\n' > "$tmp/GEOM.TXT"

python3 "$root/analyze040.py" inspect ibm-3740 \
  "$before/empty-ibm3740.dsk" "$before/normal-ibm3740.dsk" \
  "$before/nearly-full-ibm3740.dsk" "$before/damaged-ibm3740.dsk" \
  > "$root/transcripts/raw-structure.jsonl"
python3 "$root/analyze040.py" inspect z80pack-hd \
  "$before/empty-z80pack-hd.dsk" > "$root/transcripts/alternate-geometry.jsonl"

for image in "$before"/*.dsk; do cp "$image" "$after/$(basename "$image")"; done
for image in "$before"/*ibm3740.dsk; do
  name=$(basename "$image")
  { echo "== $name =="; cpmls -f ibm-3740 -T raw "$image"; } \
    >> "$root/transcripts/cpmls.txt" 2>&1 || true
  { echo "== $name =="; fsck.cpm -f ibm-3740 -n "$image"; } \
    >> "$root/transcripts/fsck.txt" 2>&1 || true
done
{ echo '== empty-z80pack-hd.dsk =='; cpmls -f z80pack-hd -T raw "$before/empty-z80pack-hd.dsk"; } \
  >> "$root/transcripts/cpmls.txt" 2>&1
{ echo '== empty-z80pack-hd.dsk =='; fsck.cpm -f z80pack-hd -n "$before/empty-z80pack-hd.dsk"; } \
  >> "$root/transcripts/fsck.txt" 2>&1 || true

sha256sum "$before"/*.dsk > "$root/transcripts/images-before.sha256"
sha256sum "$after"/*.dsk > "$root/transcripts/images-after.sha256"
