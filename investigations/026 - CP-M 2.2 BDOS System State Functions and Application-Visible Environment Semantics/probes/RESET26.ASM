        ORG 100H
        LD SP,STACK
        LD C,13
        CALL 5
        LD E,1
        LD C,14
        CALL 5
        LD C,28
        CALL 5
        LD E,0
        LD C,14
        CALL 5
        LD HL,BEF
        CALL SNAP
        LD DE,0002H
        LD C,37
        CALL 5
        LD HL,AFTB
        CALL SNAP
        LD DE,0001H
        LD C,37
        CALL 5
        LD HL,AFTA
        CALL SNAP
        LD C,0
        JP 5
SNAP:   CALL PUTS
        LD C,25
        CALL 5
        CALL HEXB
        CALL SPACE
        LD C,24
        CALL 5
        CALL HEXW
        CALL SPACE
        LD C,29
        CALL 5
        CALL HEXW
        CALL SPACE
        LD C,27
        CALL 5
        CALL HEXW
        CALL SPACE
        LD C,31
        CALL 5
        CALL HEXW
        JP CRLF
BEF:    DB 'BEFORE ',0
AFTB:   DB 'RESETB ',0
AFTA:   DB 'RESETA ',0
        DS 128
STACK:
        INCLUDE "COMMON26.INC"
        END
