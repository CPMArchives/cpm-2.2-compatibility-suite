#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cases="$root/cases"
emu="$root/emulator-src/cpmsim/cpmsim"
mkdir -p "$cases"

run_case() {
  id=$1 mode=$2 response=$3
  dir="$cases/$id"
  mkdir -p "$dir"
  cp "$root/base066.dsk" "$dir/drivea.dsk"
  shasum -a 256 "$dir/drivea.dsk" > "$dir/before.sha256"
  "$root/run-case066.exp" "$mode" "$response" "$dir" "$dir/console.txt" "$emu"
  shasum -a 256 "$dir/drivea.dsk" > "$dir/after.sha256"
  cpmls -f ibm-3740 -D "$dir/drivea.dsk" > "$dir/directory.txt"
}

run_case T01 N ignore
run_case T02 A ignore
run_case T03 C ignore
run_case T07 U ignore
run_case T08 P ignore
run_case T09 P abort

for spec in 'T04 repeat' 'T05 ignore' 'T06 abort'; do
  set -- $spec
  id=$1 path=$2 dir="$cases/$1"
  mkdir -p "$dir"
  cp "$root/base066.dsk" "$dir/drivea.dsk"
  shasum -a 256 "$dir/drivea.dsk" > "$dir/before.sha256"
  if [ "$path" = repeat ]; then
    "$root/run-repeat066.exp" "$dir" "$dir/console.txt" "$emu"
  else
    "$root/run-recovery066.exp" "$path" "$dir" "$dir/console.txt" "$emu"
  fi
  shasum -a 256 "$dir/drivea.dsk" > "$dir/after.sha256"
  cpmls -f ibm-3740 -D "$dir/drivea.dsk" > "$dir/directory.txt"
done

for id in T01 T02 T03 T04 T05 T06 T07 T08 T09; do
  cpmcp -f ibm-3740 "$cases/$id/drivea.dsk" 0:DSKFILE.DAT "$cases/$id/dskfile.dat"
  shasum -a 256 "$cases/$id/dskfile.dat" > "$cases/$id/dskfile.sha256"
  cpmcp -f ibm-3740 "$cases/$id/drivea.dsk" 0:CLOSEME.DAT "$cases/$id/closeme.dat"
  shasum -a 256 "$cases/$id/closeme.dat" > "$cases/$id/closeme.sha256"
done
