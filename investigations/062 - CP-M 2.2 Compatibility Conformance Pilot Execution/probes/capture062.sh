#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$root"
cpmls -f ibm-3740 -l images-after/dri-cpm22.dsk > dri-after-listing.txt
cpmls -f ibm-3740 -l images-after/cdos258.dsk > cdos-after-listing.txt
{
  wc -c SRC61.TXT extracted/dri-COPY62.TXT extracted/cdos-COPY62.TXT
  shasum -a 256 SRC61.TXT extracted/dri-COPY62.TXT extracted/cdos-COPY62.TXT
  cmp -n 53 SRC61.TXT extracted/dri-COPY62.TXT
  cmp SRC61.TXT extracted/cdos-COPY62.TXT
  echo "Payload comparisons passed."
} > payload-comparison.txt

