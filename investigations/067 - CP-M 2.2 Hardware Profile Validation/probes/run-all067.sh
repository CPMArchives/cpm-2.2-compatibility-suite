#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Machine-profile portable controls.
for spec in 'cromemco cromemco' 'imsai imsai'; do
  set -- $spec
  name=$1 kind=$2 p="$root/profiles/$1"
  rm -f "$p/disks/drivea.dsk"
  cp "$p/disks/library/cpm22.dsk" "$p/disks/drivea.dsk"
  cpmcp -f ibm-3740 "$p/disks/drivea.dsk" "$root/BASE051.COM" 0:BASE051.COM
  shasum -a 256 "$p/disks/drivea.dsk" > "$root/records/$name-before.sha256"
  "$root/run-machine067.exp" "$p" "$kind" BASE051 "$root/transcripts/$name-base051.txt"
  shasum -a 256 "$p/disks/drivea.dsk" > "$root/records/$name-after.sha256"
done

# Processor-profile controls from a fresh generic CP/M image.
for cpu in z80 i8080; do
  d="$root/profiles/cpu-$cpu"
  rm -rf "$d"
  mkdir -p "$d"
  cp <cpmsim-root>/disks/drivea.dsk "$d/drivea.dsk"
  cp <cpmsim-root>/disks/driveb.dsk "$d/driveb.dsk"
  cpmcp -f ibm-3740 "$d/drivea.dsk" "$root/CPU8080.COM" 0:CPU8080.COM
  cpmcp -f ibm-3740 "$d/drivea.dsk" "$root/CPUZ80.COM" 0:CPUZ80.COM
done
"$root/run-cpu067.exp" "$root/profiles/cpu-z80" -z CPU8080 "$root/transcripts/z80-cpu8080.txt"
"$root/run-cpu067.exp" "$root/profiles/cpu-z80" -z CPUZ80 "$root/transcripts/z80-cpuz80.txt"
"$root/run-cpu067.exp" "$root/profiles/cpu-i8080" -8 CPU8080 "$root/transcripts/8080-cpu8080.txt"
"$root/run-cpu067.exp" "$root/profiles/cpu-i8080" -8 CPUZ80 "$root/transcripts/8080-cpuz80-mismatch.txt"
