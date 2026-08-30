#!/bin/sh
set -eu
cd "$(dirname "$0")"
asm=z80asm
for n in MEM34 ZERO34 LOAD34 STACK34 VECTOR34 LARGE34
do
  if grep -q 'INCLUDE "COMMON34.INC"' "$n.ASM"
  then
    sed '/INCLUDE "COMMON34.INC"/r COMMON34.INC' "$n.ASM" |
      sed '/INCLUDE "COMMON34.INC"/d' > "$n.build.asm"
    "$asm" -fb -l -o"$n.COM" "$n.build.asm"
    mv "$n.build.lis" "$n.lis"
    rm -f "$n.build.asm"
  else
    "$asm" -fb -l -o"$n.COM" "$n.ASM"
  fi
done
sed '/INCLUDE "COMMON34.INC"/r COMMON34.INC' OVERLAY34.ASM |
  sed '/INCLUDE "COMMON34.INC"/d' > OVR34.build.asm
"$asm" -fb -l -oOVR34.COM OVR34.build.asm
mv OVR34.build.lis OVR34.lis
rm -f OVR34.build.asm
cp LARGE34.COM LARGEOK.COM
cp LARGE34.COM TOOLARGE.COM
truncate -s 57984 LARGEOK.COM
truncate -s 58112 TOOLARGE.COM
