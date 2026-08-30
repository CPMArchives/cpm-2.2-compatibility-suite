#!/bin/sh
set -eu
cd "$(dirname "$0")"
out=/private/tmp/i036-runs
stock=cpmsim
fault="$PWD/emulator-src/cpmsim/cpmsim"
rm -rf "$out"
mkdir -p "$out/core" "$out/error"
for mode in core error
do
  cp images-before/drivea.dsk "$out/$mode/drivea.dsk"
  cp images-before/driveb.dsk "$out/$mode/driveb.dsk"
done
./run036.exp "$out/core" "$out/core/console.txt" "$stock" core
./run036.exp "$out/error" "$out/error/console.txt" "$fault" error

