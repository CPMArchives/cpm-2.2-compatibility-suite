#!/bin/sh
set -eu
for n in CALL27 FUNC27 REG27 STACK27 PARAM27
do
  if grep -q 'INCLUDE "COMMON27.INC"' "$n.ASM"
  then
    sed '/INCLUDE "COMMON27.INC"/r COMMON27.INC' "$n.ASM" | sed '/INCLUDE "COMMON27.INC"/d' > "$n.build.asm"
    z80asm -fb -l -o"$n.COM" "$n.build.asm"
    mv "$n.build.lis" "$n.lis"
    rm -f "$n.build.asm"
  else
    z80asm -fb -l -o"$n.COM" "$n.ASM"
  fi
done

