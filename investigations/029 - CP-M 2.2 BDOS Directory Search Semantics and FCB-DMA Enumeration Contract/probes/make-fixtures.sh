#!/bin/sh
set -eu
dest=${1:-cases/recreated}
mkdir -p "$dest"
cp images-before/drivea.dsk "$dest/drivea.dsk"
cp images-before/driveb.dsk "$dest/driveb.dsk"
for n in SEARCH29 MATCH29 DMA29 STATE29 USER29 ERROR29
do
 cpmcp -f ibm-3740 "$dest/driveb.dsk" "$n.COM" "0:$n.COM"
done
for spec in 'MATCH29.COM:ALPHA.TXT' 'DMA29.COM:BETA.TXT' 'STATE29.COM:DELTA.TXT' 'USER29.COM:EPSILON.TXT'
do
 src=${spec%%:*}; dst=${spec##*:}; cpmcp -f ibm-3740 "$dest/drivea.dsk" "$src" "0:$dst"
done
cpmcp -f ibm-3740 "$dest/drivea.dsk" USER29.COM 1:UONE.TXT
cpmcp -f ibm-3740 "$dest/driveb.dsk" MATCH29.COM 0:BRAVO.TXT
cpmcp -f ibm-3740 "$dest/driveb.dsk" DMA29.COM 0:BETA.TXT
cpmcp -f ibm-3740 "$dest/driveb.dsk" USER29.COM 1:UONE.TXT
cp ERROR29.COM BIGMULTI.DAT
truncate -s 16640 BIGMULTI.DAT
cpmcp -f ibm-3740 "$dest/driveb.dsk" BIGMULTI.DAT 0:BIGMULTI.DAT

