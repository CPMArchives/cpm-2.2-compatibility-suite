#!/bin/sh
set -eu
cd "$(dirname "$0")"
out=/private/tmp/i035-runs
stock=${1:-cpmsim}
fault=${2:-$PWD/emulator-src/cpmsim/cpmsim}
rm -rf "$out"
mkdir -p "$out"
for mode in cold ret fzero warm reset pending error
do
  mkdir -p "$out/$mode"
  cp images-before/drivea.dsk "$out/$mode/drivea.dsk"
  cp images-before/driveb.dsk "$out/$mode/driveb.dsk"
  emu=$stock
  test "$mode" = error && emu=$fault
  ./run-case035.exp "$mode" "$out/$mode" "$out/$mode/console.txt" "$emu"
done
