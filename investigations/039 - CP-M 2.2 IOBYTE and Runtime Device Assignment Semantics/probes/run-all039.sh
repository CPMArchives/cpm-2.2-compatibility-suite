#!/bin/sh
set -eu
cd "$(dirname "$0")"
out=/private/tmp/i039-runs
rm -rf "$out"
mkdir -p "$out"
cp images-before/drivea.dsk "$out/drivea.dsk"
cp images-before/driveb.dsk "$out/driveb.dsk"
./run039.exp "$out" "$out/console.txt"

