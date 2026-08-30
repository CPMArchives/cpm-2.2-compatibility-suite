#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$root"
Z80ASM=${Z80ASM:-z80asm}
for name in EDGE43; do
  sed '/INCLUDE "COMMON43.INC"/r COMMON43.INC' "$name.ASM" |
    sed '/INCLUDE "COMMON43.INC"/d' > "$name.build.asm"
  "$Z80ASM" -fb -o"$name.COM" "$name.build.asm" > "$name.lis"
  mv "$name.build.asm" "$name.expanded.asm"
done
for name in FN043 OVER43 LARGE43; do
  "$Z80ASM" -fb -o"$name.COM" "$name.ASM" > "$name.lis"
done
"$Z80ASM" -fb -oZRET43.COM ZERORET43.ASM > ZERORET43.lis
cp LARGE43.COM MAXOK43.COM
cp LARGE43.COM MAXBAD43.COM
truncate -s 57984 MAXOK43.COM
truncate -s 58112 MAXBAD43.COM
