        ORG 100H
        LD SP,STACK
        LD C,13
        CALL 5
        LD HL,L0
        CALL SHOW
        LD C,28
        CALL 5
        LD HL,L28
        CALL SHOW
        LD C,40
        LD DE,FCB
        CALL 5
        PUSH HL
        LD HL,L40
        CALL PUTS
        POP HL
        CALL HEXW
        CALL SPACE
        LD C,29
        CALL 5
        CALL HEXW
        CALL CRLF
        LD DE,0001H
        LD C,37
        CALL 5
        LD HL,LR
        CALL SHOW
        LD C,0
        JP 5
SHOW:   CALL PUTS
        LD C,29
        CALL 5
        CALL HEXW
        JP CRLF
L0:     DB 'RO initial ',0
L28:    DB 'RO after F28 ',0
L40:    DB 'F40 result/ro ',0
LR:     DB 'RO after F37 ',0
FCB:    DB 0,'NOFILE  DAT',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DS 128
STACK:
        INCLUDE "COMMON26.INC"
        END
