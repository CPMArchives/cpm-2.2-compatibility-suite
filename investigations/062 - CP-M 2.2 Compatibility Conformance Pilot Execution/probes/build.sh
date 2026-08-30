#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$root"
Z80ASM=${Z80ASM:-z80asm}
for name in VECTOR41 ZERO41 BASE61 STATE61 BIOS41 FN043; do
  "$Z80ASM" -fb -o"$name.rebuilt.COM" "$name.ASM" > "$name.rebuilt.lis"
  cmp "$name.COM" "$name.rebuilt.COM"
done
"$Z80ASM" -fb -oZRET43.rebuilt.COM ZERORET43.ASM > ZRET43.rebuilt.lis
cmp ZRET43.COM ZRET43.rebuilt.COM
sed '/INCLUDE "COMMON43.INC"/r COMMON43.INC' EDGE43.ASM |
  sed '/INCLUDE "COMMON43.INC"/d' > EDGE43.rebuilt.asm
"$Z80ASM" -fb -oEDGE43.rebuilt.COM EDGE43.rebuilt.asm > EDGE43.rebuilt.lis
cmp EDGE43.COM EDGE43.rebuilt.COM

