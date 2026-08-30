#!/bin/sh
set -eu
for name in TERM24 BDOS024 JUMP24 STATE24 FILE24 CHECK24 CONSOLE24 BAD24 BADSP24
do
    z80asm -fb -l -o"$name.COM" "$name.ASM"
done

