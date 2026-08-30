#!/bin/sh
set -eu
for n in CREATE30 GROW30 EXTENT30 FCB30 CLOSE30 OPEN30 FAIL30
do
 if [ "$n" = FCB30 ]; then body=RAND013.INC; else body=WRITE011.INC; fi
 sed '/ INCLUDE /r '"$body" "$n.ASM" | sed '/ INCLUDE /d' > "$n.build.asm"
 z80asm -fb -l -o"$n.COM" "$n.build.asm"
 mv "$n.build.lis" "$n.lis"
 rm -f "$n.build.asm"
done
