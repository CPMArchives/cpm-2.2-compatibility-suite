#!/bin/sh
set -eu
cd "$(dirname "$0")"
asm=z80asm
for n in IOBYTE39 DEVICE39 STAT39 SWITCH39 BDOS39 BIOS39
do
  "$asm" -fb -l -o"$n.COM" "$n.ASM"
done

