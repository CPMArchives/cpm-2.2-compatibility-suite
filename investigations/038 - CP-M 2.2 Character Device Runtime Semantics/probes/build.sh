#!/bin/sh
set -eu
cd "$(dirname "$0")"
asm=z80asm
for n in CHAR38 STATUS38 IOBYTE38 BLOCK38 ERROR38
do
  "$asm" -fb -l -o"$n.COM" "$n.ASM"
done

