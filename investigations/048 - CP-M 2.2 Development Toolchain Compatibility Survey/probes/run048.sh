#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
case_dir="$root/case"
mkdir -p "$case_dir" "$root/images-after" "$root/transcripts"
cp "$root/images-before/drivea.dsk" "$case_dir/drivea.dsk"
cp "$root/images-before/driveb.dsk" "$case_dir/driveb.dsk"
"$root/run048.exp" "$case_dir" "$root/transcripts/toolchain-survey.txt"
cp "$case_dir/drivea.dsk" "$root/images-after/drivea.dsk"
cp "$case_dir/driveb.dsk" "$root/images-after/driveb.dsk"
shasum -a 256 "$root"/images-before/*.dsk > "$root/transcripts/images-before.sha256"
shasum -a 256 "$root"/images-after/*.dsk > "$root/transcripts/images-after.sha256"
cpmls -f ibm-3740 -l "$case_dir/drivea.dsk" > "$root/transcripts/drivea-after.txt"
cpmls -f ibm-3740 -l "$case_dir/driveb.dsk" > "$root/transcripts/driveb-after.txt"
for name in ABS48.COM ABS48.HEX MACRO48.COM MACRO48.HEX DEV48.COM DEV48.SYM BIG48.COM BIG48.REL BATCH48.COM BATCH48.SYM MAIN48.REL MSG48.REL BAD48.REL BADOUT.COM BADOUT.SYM; do
  cpmcp -f ibm-3740 "$case_dir/driveb.dsk" "0:$name" "$root/transcripts/$name"
done
cmp "$root/transcripts/DEV48.COM" "$root/transcripts/BATCH48.COM"
if cpmls -f ibm-3740 "$case_dir/drivea.dsk" | tr ' ' '\n' | grep -q '\.\$\$\$$'; then
  echo "unexpected temporary file remains on A:" >&2
  exit 1
fi
