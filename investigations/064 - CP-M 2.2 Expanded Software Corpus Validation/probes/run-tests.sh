#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$root"
rm -rf cases images-before images-after transcripts extracted
mkdir -p cases images-before images-after transcripts extracted
for case in tp-normal tp-failure tp-8080 f80-normal f80-failure; do
  mkdir -p "cases/$case"
  cp <cpmsim-root>/disks/drivea.dsk "cases/$case/drivea.dsk"
  cp <cpmsim-root>/disks/driveb.dsk "cases/$case/driveb.dsk"
  for f in TURBO.COM TURBO.OVR TURBO.MSG F80.COM L80.COM M80.COM FORLIB.REL; do
    cpmcp -f ibm-3740 "cases/$case/driveb.dsk" "$root/../downloads/$f" "0:$f"
  done
  cpmcp -f ibm-3740 -t "cases/$case/driveb.dsk" HELLO.PAS 0:HELLO.PAS
  cpmcp -f ibm-3740 -t "cases/$case/driveb.dsk" BAD.PAS 0:BAD.PAS
  cpmcp -f ibm-3740 -t "cases/$case/driveb.dsk" HELLO.FOR 0:HELLO.FOR
  cp "cases/$case/drivea.dsk" "images-before/$case-drivea.dsk"
  cp "cases/$case/driveb.dsk" "images-before/$case-driveb.dsk"
done
./run064.exp "$root/cases/tp-normal" tp-normal "$root/transcripts/tp-normal.txt" -z
./run064.exp "$root/cases/tp-failure" tp-failure "$root/transcripts/tp-failure.txt" -z
./run064.exp "$root/cases/tp-8080" tp-8080 "$root/transcripts/tp-8080.txt" -8
./run064.exp "$root/cases/f80-normal" f80-normal "$root/transcripts/f80-normal.txt" -z
./run064.exp "$root/cases/f80-failure" f80-failure "$root/transcripts/f80-failure.txt" -z
for case in tp-normal tp-failure tp-8080 f80-normal f80-failure; do
  cp "cases/$case/drivea.dsk" "images-after/$case-drivea.dsk"
  cp "cases/$case/driveb.dsk" "images-after/$case-driveb.dsk"
done
cpmcp -f ibm-3740 "cases/f80-normal/driveb.dsk" 0:HELLO.COM extracted/F80HELLO.COM
