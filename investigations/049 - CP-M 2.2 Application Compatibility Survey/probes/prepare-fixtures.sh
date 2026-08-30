#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DISKS="$ROOT/work/disks/CPM"
SRC=<local-home>/z80pack/mosteksim/disks/CPM

cp "$SRC/CPM22v11-56K-SSSD.dsk" "$DISKS/system.dsk"
cp "$SRC/WordStar_VT52.dsk" "$DISKS/wordstar.dsk"
cp "$SRC/BASIC_Games.dsk" "$DISKS/games.dsk"

for name in spelstar.dct spelstar.ovr jhn jhn.bak ww13 ww13.add; do
    cpmrm -f ibm-3740 "$DISKS/wordstar.dsk" "0:$name"
done
