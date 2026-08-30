#!/bin/sh
set -eu
for n in LOAD28 MEM28 ENTRY28 RETURN28 CHECK28 ERROR28 MIN28
do
 if grep -q 'INCLUDE "COMMON28.INC"' "$n.ASM"
 then
  sed '/INCLUDE "COMMON28.INC"/r COMMON28.INC' "$n.ASM" | sed '/INCLUDE "COMMON28.INC"/d' > "$n.build.asm"
  z80asm -fb -l -o"$n.COM" "$n.build.asm"
  mv "$n.build.lis" "$n.lis"
  rm -f "$n.build.asm"
 else
  z80asm -fb -l -o"$n.COM" "$n.ASM"
 fi
done
