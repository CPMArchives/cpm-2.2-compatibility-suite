#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$root"
asm=${Z80ASM:-z80asm}
"$asm" -8 -fb -lCPU8080.lis -oCPU8080.COM CPU8080.ASM
for n in CPUZ80 UNDOC63 TIMING63; do
  "$asm" -fb -l"$n.lis" -o"$n.COM" "$n.ASM"
done
