#!/bin/sh
set -eu
Z80ASM=${Z80ASM:-z80asm}
for n in BDOS41 BIOS41 ZERO41 VECTOR41 MOD41 DIRECT41; do
  "$Z80ASM" -fb -o"$n.COM" "$n.ASM" > "$n.lis"
done
