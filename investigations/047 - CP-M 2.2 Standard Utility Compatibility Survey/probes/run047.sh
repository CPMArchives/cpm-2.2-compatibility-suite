#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
case_dir="$root/case"
mkdir -p "$case_dir" "$root/images-after" "$root/transcripts"
cp "$root/images-before/drivea.dsk" "$case_dir/drivea.dsk"
cp "$root/images-before/driveb.dsk" "$case_dir/driveb.dsk"
"$root/run047.exp" "$case_dir" "$root/transcripts/utility-survey.txt"
cp "$case_dir/drivea.dsk" "$root/images-after/drivea.dsk"
cp "$case_dir/driveb.dsk" "$root/images-after/driveb.dsk"
shasum -a 256 "$root"/images-before/*.dsk > "$root/transcripts/images-before.sha256"
shasum -a 256 "$root"/images-after/*.dsk > "$root/transcripts/images-after.sha256"
cpmcp -f ibm-3740 -t "$case_dir/driveb.dsk" 0:COPY47.ASM "$root/transcripts/COPY47.ASM"
cpmcp -f ibm-3740 -t "$case_dir/driveb.dsk" 0:EDIT47.TXT "$root/transcripts/EDIT47.TXT"
cmp "$root/HELLO42.ASM" "$root/transcripts/COPY47.ASM"
