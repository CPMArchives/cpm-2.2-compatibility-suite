#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$root"
Z80ASM=${Z80ASM:-z80asm}
for name in VECTOR41 ZERO41 BDOS41 BIOS41 STATE61 BASE61; do
  "$Z80ASM" -fb -o"$name.rebuilt.COM" "$name.ASM" > "$name.rebuilt.lis"
  cmp "$name.COM" "$name.rebuilt.COM"
done
sed '/INCLUDE "COMMON43.INC"/r COMMON43.INC' EDGE43.ASM |
  sed '/INCLUDE "COMMON43.INC"/d' > EDGE43.rebuilt.asm
"$Z80ASM" -fb -oEDGE43.rebuilt.COM EDGE43.rebuilt.asm > EDGE43.rebuilt.lis
cmp EDGE43.COM EDGE43.rebuilt.COM

