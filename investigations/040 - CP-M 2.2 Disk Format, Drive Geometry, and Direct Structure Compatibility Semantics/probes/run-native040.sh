#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
for case in bdos bios; do
  dir="$root/native-$case"
  mkdir -p "$dir"
  cp <cpmsim-root>/disks/drivea.dsk "$dir/drivea.dsk"
  cp <cpmsim-root>/disks/driveb.dsk "$dir/driveb.dsk"
done
cpmcp -f ibm-3740 "$root/native-bdos/drivea.dsk" "$root/DPB040.COM" 0:DPB040.COM
cpmcp -f ibm-3740 "$root/native-bios/drivea.dsk" "$root/BIOS040.COM" 0:BIOS040.COM
sha256sum "$root"/native-*/*.dsk > "$root/transcripts/native-before.sha256"
"$root/run-native040.exp" "$root/native-bdos" "$root/transcripts/native-bdos-stat.txt"
"$root/run-bios040.exp" "$root/native-bios" "$root/transcripts/native-bios.txt" || true
sha256sum "$root"/native-*/*.dsk > "$root/transcripts/native-after.sha256"
