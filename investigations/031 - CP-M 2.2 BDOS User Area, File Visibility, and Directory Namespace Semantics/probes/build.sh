#!/bin/sh
set -eu
for n in USER31 VIS31 OPEN31 SEARCH31 CREATE31 RENAME31 DELETE31
do
 sed '/ INCLUDE /r DELREN012.INC' "$n.ASM" | sed '/ INCLUDE /d' > "$n.build.asm"
 z80asm -fb -l -o"$n.COM" "$n.build.asm"
 mv "$n.build.lis" "$n.lis"
 rm -f "$n.build.asm"
done
