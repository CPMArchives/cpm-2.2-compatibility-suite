#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$root"

mkdir -p extracted listings
cpmcp -f ibm-3740 images-after/dri-cpm22-cromemco.dsk 0:COPY61.TXT extracted/dri-COPY61.TXT
cpmcp -f ibm-3740 images-after/cromemco-cdos258.dsk 0:COPY61.TXT extracted/cdos258-COPY61.TXT
cpmls -f ibm-3740 -l images-after/dri-cpm22-cromemco.dsk > listings/dri-after-long.txt
cpmls -f ibm-3740 -l images-after/cromemco-cdos258.dsk > listings/cdos258-after-long.txt
cpmls -f ibm-3740 -D images-after/dri-cpm22-cromemco.dsk > listings/dri-after-directory.txt
cpmls -f ibm-3740 -D images-after/cromemco-cdos258.dsk > listings/cdos258-after-directory.txt

{
  wc -c SRC61.TXT extracted/dri-COPY61.TXT extracted/cdos258-COPY61.TXT
  shasum -a 256 SRC61.TXT extracted/dri-COPY61.TXT extracted/cdos258-COPY61.TXT
  cmp -n 53 SRC61.TXT extracted/dri-COPY61.TXT
  cmp SRC61.TXT extracted/cdos258-COPY61.TXT
  echo "First 53 bytes match on both; CDOS exact file matches source."
} > payload-comparison.txt

