#!/bin/sh
set -eu
cd "$(dirname "$0")"
for n in READERR33 WRITEERR33 DIRERR33 RECOVER33 CCPERR33
do
 sed '/ INCLUDE /r PHYS033.INC' "$n.ASM" | sed '/ INCLUDE /d' > "$n.build.asm"
 z80asm -fb -l -o"$n.COM" "$n.build.asm"
 mv "$n.build.lis" "$n.lis"
 rm -f "$n.build.asm"
done
