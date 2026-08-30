#!/bin/sh
set -eu
cd "$(dirname "$0")"
asm=z80asm
for n in COLD35 STATE35
do
  sed '/INCLUDE "OBS35.INC"/r OBS35.INC' "$n.ASM" |
    sed '/INCLUDE "OBS35.INC"/d' |
    sed '/INCLUDE "COMMON35.INC"/r COMMON35.INC' |
    sed '/INCLUDE "COMMON35.INC"/d' > "$n.build.asm"
  "$asm" -fb -l -o"$n.COM" "$n.build.asm"
  mv "$n.build.lis" "$n.lis"
  rm -f "$n.build.asm"
done
for n in WARM35 RET35 FZERO35
do
  sed '/INCLUDE "MUTATE35.INC"/r MUTATE35.INC' "$n.ASM" |
    sed '/INCLUDE "MUTATE35.INC"/d' > "$n.build.asm"
  "$asm" -fb -l -o"$n.COM" "$n.build.asm"
  mv "$n.build.lis" "$n.lis"
  rm -f "$n.build.asm"
done
for n in RESET35
do
  sed '/INCLUDE "COMMON35.INC"/r COMMON35.INC' "$n.ASM" |
    sed '/INCLUDE "COMMON35.INC"/d' > "$n.build.asm"
  "$asm" -fb -l -o"$n.COM" "$n.build.asm"
  mv "$n.build.lis" "$n.lis"
  rm -f "$n.build.asm"
done
for n in BOOT35 PEND35
do
  "$asm" -fb -l -o"$n.COM" "$n.ASM"
done
sed '/ INCLUDE /r PHYS035.INC' RECOVER35.ASM | sed '/ INCLUDE /d' > RECOVER35.build.asm
"$asm" -fb -l -oRECOVER35.COM RECOVER35.build.asm
mv RECOVER35.build.lis RECOVER35.lis
rm -f RECOVER35.build.asm

