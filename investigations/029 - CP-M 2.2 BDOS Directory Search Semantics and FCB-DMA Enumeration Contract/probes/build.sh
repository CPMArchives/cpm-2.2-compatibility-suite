#!/bin/sh
set -eu
for n in SEARCH29 MATCH29 DMA29 STATE29 USER29 ERROR29
do
 if grep -q 'INCLUDE "COMMON29.INC"' "$n.ASM"
 then
  sed '/INCLUDE "COMMON29.INC"/r COMMON29.INC' "$n.ASM" | sed '/INCLUDE "COMMON29.INC"/d' > "$n.build.asm"
  z80asm -fb -l -o"$n.COM" "$n.build.asm"
  mv "$n.build.lis" "$n.lis"
  rm -f "$n.build.asm"
 else
  z80asm -fb -l -o"$n.COM" "$n.ASM"
 fi
done

