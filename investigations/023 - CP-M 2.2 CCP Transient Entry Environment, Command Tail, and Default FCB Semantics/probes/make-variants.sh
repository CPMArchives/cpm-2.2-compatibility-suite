#!/bin/sh
set -eu

# BIG23 is the identical executable padded to exactly twenty CP/M records.
# The differing loader Open result makes residual/default-FCB RC behavior
# observable without changing the probe code.
cp ENTRY23.COM BIG23.COM
truncate -s 2560 BIG23.COM
