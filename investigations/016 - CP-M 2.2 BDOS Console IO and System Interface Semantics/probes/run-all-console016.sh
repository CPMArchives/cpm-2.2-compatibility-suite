#!/bin/zsh
set -e
here=${0:A:h}
rundir=/private/tmp/inv016-runs
rm -rf "$rundir"
mkdir -p "$rundir"
for case in OUT DIOE DIO6 DIOS DIOF DIOO IN BUF SYS SCROLL BLOCKQ BLOCK1C BLOCK10C; do
  mkdir -p "$rundir/$case"
  cp "$here/images-before/drivea.dsk" "$rundir/$case/drivea.dsk"
  cp "$here/images-before/driveb.dsk" "$rundir/$case/driveb.dsk"
  shasum -a 256 "$rundir/$case/drivea.dsk" "$rundir/$case/driveb.dsk" > "$rundir/$case/before.sha256"
  "$here/run-console016-case.exp" "$case" "$rundir/$case" "$rundir/$case/console.txt"
  shasum -a 256 "$rundir/$case/drivea.dsk" "$rundir/$case/driveb.dsk" > "$rundir/$case/after.sha256"
  cpmls -f ibm-3740 -D "$rundir/$case/drivea.dsk" > "$rundir/$case/directory-a.txt"
  cpmls -f ibm-3740 -D "$rundir/$case/driveb.dsk" > "$rundir/$case/directory-b.txt"
done
