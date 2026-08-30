#!/bin/sh
set -eu
cd "$(dirname "$0")"
asm=z80asm
for n in BIOS36 CON36 DISK36 ERROR36 VECTOR36
do
  "$asm" -fb -l -o"$n.COM" "$n.ASM"
  test -f "$n.lis" || test -f "$n.lst"
done

