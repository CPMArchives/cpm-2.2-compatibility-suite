#!/bin/sh
set -eu
for name in FILEERR25 OPEN25 WRITE25 READ25 SEARCH25 FCB25 DISK25
do
    z80asm -fb -l -o"$name.COM" "$name.ASM"
done

