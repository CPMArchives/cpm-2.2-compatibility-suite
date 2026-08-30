#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
case_dir="$root/case"
mkdir -p "$case_dir"
cp <cpmsim-root>/disks/drivea.dsk "$case_dir/drivea.dsk"
cp <cpmsim-root>/disks/driveb.dsk "$case_dir/driveb.dsk"
cpmcp -f ibm-3740 -t "$case_dir/driveb.dsk" "$root/HELLO42.ASM" 0:HELLO42.ASM
cpmcp -f ibm-3740 -t "$case_dir/drivea.dsk" "$root/RUN42.SUB" 0:RUN42.SUB
cpmcp -f ibm-3740 "$case_dir/drivea.dsk" "$root/IN42.COM" 0:IN42.COM
cp "$case_dir/drivea.dsk" "$root/images-before/drivea.dsk"
cp "$case_dir/driveb.dsk" "$root/images-before/driveb.dsk"
normal_tmp="$root/transcripts/software.$$.txt"
"$root/run042.exp" "$case_dir" "$normal_tmp"
mv "$normal_tmp" "$root/transcripts/software.txt"
for program in M80 L80 MAC RMAC Z80ASM SLRNK WM SDIR SID ZSID; do
  startup_tmp="$root/transcripts/startup-$program.$$.txt"
  "$root/run-startups042.exp" "$case_dir" "$startup_tmp" "$program"
  mv "$startup_tmp" "$root/transcripts/startup-$program.txt"
done
cp "$case_dir/drivea.dsk" "$root/images-after/drivea.dsk"
cp "$case_dir/driveb.dsk" "$root/images-after/driveb.dsk"
sha256sum "$root"/images-before/*.dsk > "$root/transcripts/images-before.sha256"
sha256sum "$root"/images-after/*.dsk > "$root/transcripts/images-after.sha256"
python3 "$root/scan_vectors.py" "$root/../reference/software" > "$root/transcripts/executable-patterns.tsv"
