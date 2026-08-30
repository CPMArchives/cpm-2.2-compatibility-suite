#!/bin/sh
set -eu
dest=${1:-cases/main}
mkdir -p "$dest"
cp base-images/drivea.dsk "$dest/drivea.dsk"
cp base-images/driveb.dsk "$dest/driveb.dsk"
cp base-images/drived.dsk "$dest/drived.dsk"
for n in DIR SAVE TYPE USER ERA REN
do cpmcp -f ibm-3740 "$dest/drivea.dsk" CONFLICT.COM "0:$n.COM"; done
cpmcp -f ibm-3740 "$dest/drivea.dsk" TEXT.TXT 0:TEXT.TXT
cpmcp -f ibm-3740 "$dest/drivea.dsk" EMPTY.DAT 0:EMPTY.DAT
cpmcp -f ibm-3740 "$dest/drivea.dsk" BINARY.SRC 0:BINARY.DAT
cpmcp -f ibm-3740 "$dest/drivea.dsk" USER0.TXT 0:SAME.TXT
cpmcp -f ibm-3740 "$dest/drivea.dsk" USER1.TXT 1:SAME.TXT
cpmcp -f ibm-3740 "$dest/drivea.dsk" TEXT.TXT 0:ONE.DEL
cpmcp -f ibm-3740 "$dest/drivea.dsk" TEXT.TXT 0:WILD1.DEL
cpmcp -f ibm-3740 "$dest/drivea.dsk" TEXT.TXT 0:WILD2.DEL
cpmcp -f ibm-3740 "$dest/drivea.dsk" TEXT.TXT 0:OLDFILE.DAT
cpmcp -f ibm-3740 "$dest/drivea.dsk" TEXT.TXT 0:SOURCE.DAT
cpmcp -f ibm-3740 "$dest/drivea.dsk" TEXT.TXT 0:EXISTS.DAT
cpmcp -f ibm-3740 "$dest/drivea.dsk" TEXT.TXT 0:ROFILE.DAT
cpmchmod -f ibm-3740 "$dest/drivea.dsk" 0:ROFILE.DAT +r
