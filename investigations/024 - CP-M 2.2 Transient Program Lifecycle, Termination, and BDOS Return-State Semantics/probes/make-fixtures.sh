#!/bin/sh
set -eu
dest=${1:-images-fixture-recreated}
mkdir -p "$dest"
cp images-base/drivea.dsk "$dest/drivea.dsk"
cp images-base/driveb.dsk "$dest/driveb.dsk"
for disk in a b
do
  for user in 0 1
  do
    for name in TERM24 BDOS024 JUMP24 STATE24 FILE24 CHECK24 BAD24 BADSP24
    do
      cpmcp -f ibm-3740 "$dest/drive$disk.dsk" "$name.COM" "$user:$name.COM"
    done
    cpmcp -f ibm-3740 "$dest/drive$disk.dsk" CONSOLE24.COM "$user:CONS24.COM"
    cpmcp -f ibm-3740 "$dest/drive$disk.dsk" \
      '<project-root>/investigations/023 - CP-M 2.2 CCP Transient Entry Environment, Command Tail, and Default FCB Semantics/probes/ENTRY23.COM' \
      "$user:OBS24.COM"
  done
done

