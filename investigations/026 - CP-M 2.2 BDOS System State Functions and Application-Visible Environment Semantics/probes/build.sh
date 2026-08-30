#!/bin/sh
set -eu
for n in STATE26 DPB26 RESET26 PROTECT26 TERMSTATE26 CHECK26
do
  if grep -q 'INCLUDE "COMMON26.INC"' "$n.ASM"
  then
    sed '/INCLUDE "COMMON26.INC"/r COMMON26.INC' "$n.ASM" | sed '/INCLUDE "COMMON26.INC"/d' > "$n.build.asm"
    z80asm -fb -l -o"$n.COM" "$n.build.asm"
    mv "$n.build.lis" "$n.lis"
    rm -f "$n.build.asm"
  else
    z80asm -fb -l -o"$n.COM" "$n.ASM"
  fi
done
