#!/bin/sh
set -eu
cd "$(dirname "$0")"
asm=z80asm
"$asm" -fb -l -oBDOS37.COM BDOS37.ASM
sed '/INCLUDE "COMMON26.INC"/r COMMON26.INC' STATE37.ASM |
  sed '/INCLUDE "COMMON26.INC"/d' > STATE37.build.asm
"$asm" -fb -l -oSTATE37.COM STATE37.build.asm
mv STATE37.build.lis STATE37.lis
rm -f STATE37.build.asm
for n in REGISTER37 DMA37
do
  sed '/INCLUDE "COMMON27.INC"/r COMMON27.INC' "$n.ASM" |
    sed '/INCLUDE "COMMON27.INC"/d' > "$n.build.asm"
  "$asm" -fb -l -o"$n.COM" "$n.build.asm"
  mv "$n.build.lis" "$n.lis"
  rm -f "$n.build.asm"
done
"$asm" -fb -l -oERROR37.COM ERROR37.ASM

