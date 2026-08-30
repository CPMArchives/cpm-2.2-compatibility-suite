#!/bin/zsh
set -e
here=${0:A:h}
base="$here/images-before/drivea.dsk"
emulator="$here/emulator-src/cpmsim/cpmsim"
rundir=/private/tmp/inv015-runs
rm -rf "$rundir"
mkdir -p "$rundir"
for mode in N A B C D E F G H I J; do
  mkdir -p "$rundir/$mode"
  cp "$base" "$rundir/$mode/drivea.dsk"
  shasum -a 256 "$rundir/$mode/drivea.dsk" > "$rundir/$mode/before.sha256"
  "$here/run-phys015-case.exp" "$mode" "$rundir/$mode" \
    "$rundir/$mode/console.txt" "$emulator"
  shasum -a 256 "$rundir/$mode/drivea.dsk" > "$rundir/$mode/after.sha256"
  cpmls -f ibm-3740 -D "$rundir/$mode/drivea.dsk" > "$rundir/$mode/directory.txt"
done
