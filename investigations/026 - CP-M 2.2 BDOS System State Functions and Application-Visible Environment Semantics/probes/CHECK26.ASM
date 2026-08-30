        ORG 100H
        LD HL,MSG
        CALL PUTS
        LD C,25
        CALL 5
        CALL HEXB
        CALL SPACE
        LD E,0FFH
        LD C,32
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
        CALL CRLF
        LD C,0
        JP 5
MSG:    DB 'CHECK26 cur user login ro ',0
        DS 128
STACK:
        INCLUDE "COMMON26.INC"
        END
