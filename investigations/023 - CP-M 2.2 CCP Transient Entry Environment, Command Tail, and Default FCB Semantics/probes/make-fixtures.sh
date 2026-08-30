#!/bin/sh
set -eu

# Recreate disposable Investigation 023 fixture images from preserved bases.
# Run from probes/. The destination directory must already exist.
dest=${1:-images-fixture-recreated}
mkdir -p "$dest"
cp images-base/drivea.dsk "$dest/drivea.dsk"
cp images-base/driveb.dsk "$dest/driveb.dsk"

cpmcp -f ibm-3740 "$dest/drivea.dsk" ENTRY23.COM 0:ENTRY23.COM
cpmcp -f ibm-3740 "$dest/drivea.dsk" ENTRY23.COM 0:T.COM
cpmcp -f ibm-3740 "$dest/drivea.dsk" BIG23.COM 0:BIG23.COM
cpmcp -f ibm-3740 "$dest/drivea.dsk" DMACHK.DAT 0:DMACHK.DAT
cpmcp -f ibm-3740 "$dest/drivea.dsk" ENTRY23.COM 1:ENTRY23.COM
cpmcp -f ibm-3740 "$dest/drivea.dsk" DMACHK.DAT 1:DMACHK.DAT

cpmcp -f ibm-3740 "$dest/driveb.dsk" ENTRY23.COM 0:ENTRY23.COM
cpmcp -f ibm-3740 "$dest/driveb.dsk" DMACHK.DAT 0:DMACHK.DAT
cpmcp -f ibm-3740 "$dest/driveb.dsk" ENTRY23.COM 1:ENTRY23.COM
cpmcp -f ibm-3740 "$dest/driveb.dsk" DMACHK.DAT 1:DMACHK.DAT

