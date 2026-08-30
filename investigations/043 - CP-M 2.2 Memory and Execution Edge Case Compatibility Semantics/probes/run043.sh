#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
case_dir="$root/case"
mkdir -p "$case_dir"
cp <cpmsim-root>/disks/drivea.dsk "$case_dir/drivea.dsk"
cp <cpmsim-root>/disks/driveb.dsk "$case_dir/driveb.dsk"
cpmrm -f ibm-3740 "$case_dir/drivea.dsk" '0:*.*'
for name in EDGE43 ZRET43 FN043 OVER43 MAXOK43 MAXBAD43; do
  cpmcp -f ibm-3740 "$case_dir/drivea.dsk" "$root/$name.COM" "0:$name.COM"
done
cp "$case_dir/drivea.dsk" "$root/images-before/drivea.dsk"
cp "$case_dir/driveb.dsk" "$root/images-before/driveb.dsk"
run_tmp="$root/transcripts/main.$$.txt"
"$root/run043.exp" "$case_dir" "$run_tmp"
mv "$run_tmp" "$root/transcripts/main.txt"
cp "$case_dir/drivea.dsk" "$root/images-after/drivea.dsk"
cp "$case_dir/driveb.dsk" "$root/images-after/driveb.dsk"
sha256sum "$root"/images-before/*.dsk > "$root/transcripts/images-before.sha256"
sha256sum "$root"/images-after/*.dsk > "$root/transcripts/images-after.sha256"
