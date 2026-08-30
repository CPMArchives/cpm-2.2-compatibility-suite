#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
case="$root/case"
mkdir -p "$case"
cp <cpmsim-root>/disks/drivea.dsk "$case/drivea.dsk"
cp <cpmsim-root>/disks/driveb.dsk "$case/driveb.dsk"
for n in BDOS41 BIOS41 ZERO41 VECTOR41 MOD41 DIRECT41; do
  cpmcp -f ibm-3740 "$case/drivea.dsk" "$root/$n.COM" "0:$n.COM"
done
cp "$case/drivea.dsk" "$root/images-before/drivea.dsk"
cp "$case/driveb.dsk" "$root/images-before/driveb.dsk"
sha256sum "$root"/images-before/*.dsk > "$root/transcripts/images-before.sha256"
console_tmp="$root/transcripts/console.$$.txt"
failure_tmp="$root/transcripts/failure.$$.txt"
"$root/run041.exp" "$case" "$console_tmp"
"$root/run-fail041.exp" "$case" "$failure_tmp"
mv "$console_tmp" "$root/transcripts/console.txt"
mv "$failure_tmp" "$root/transcripts/failure.txt"
cp "$case/drivea.dsk" "$root/images-after/drivea.dsk"
cp "$case/driveb.dsk" "$root/images-after/driveb.dsk"
sha256sum "$root"/images-after/*.dsk > "$root/transcripts/images-after.sha256"
