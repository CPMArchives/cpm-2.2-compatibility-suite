#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$root"
rm -rf run-z80 run-8080 images-before images-after
mkdir -p run-z80 run-8080 images-before images-after transcripts
for d in run-z80 run-8080; do
  cp <cpmsim-root>/disks/drivea.dsk "$d/drivea.dsk"
  cp <cpmsim-root>/disks/driveb.dsk "$d/driveb.dsk"
  for f in CPU8080.COM CPUZ80.COM UNDOC63.COM TIMING63.COM; do
    cpmcp -f ibm-3740 "$d/drivea.dsk" "$f" "0:$f"
  done
  cp "$d/drivea.dsk" "images-before/$d-drivea.dsk"
  cp "$d/driveb.dsk" "images-before/$d-driveb.dsk"
done
./run-profile.exp "$root/run-z80" -z none STAT,CPU8080,CPUZ80 transcripts/z80-documented.txt
./run-profile.exp "$root/run-8080" -8 none STAT,CPU8080,CPUZ80 transcripts/8080-boundary.txt
./run-profile.exp "$root/run-z80" -z none UNDOC63 transcripts/z80-undocumented-enabled.txt
./run-profile.exp "$root/run-z80" -z -u UNDOC63 transcripts/z80-undocumented-trapped.txt
./run-profile.exp "$root/run-z80" -z -f,2 TIMING63 transcripts/timing-2mhz.txt
./run-profile.exp "$root/run-z80" -z -f,4 TIMING63 transcripts/timing-4mhz.txt
for d in run-z80 run-8080; do
  cp "$d/drivea.dsk" "images-after/$d-drivea.dsk"
  cp "$d/driveb.dsk" "images-after/$d-driveb.dsk"
done
