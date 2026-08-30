        ORG 100H
        LD SP,STACK
        LD HL,BAN
        CALL PUTS
        LD HL,USERS
        LD B,4
ULOOP:  LD E,(HL)
        INC HL
        PUSH HL
        PUSH BC
        PUSH DE
        LD A,E
        CALL HEXB
        CALL SPACE
        POP DE
        LD C,32
        CALL 5
        LD E,0FFH
        LD C,32
        CALL 5
        CALL HEXB
        CALL CRLF
        POP BC
        POP HL
        DJNZ ULOOP
        LD E,0
        LD C,32
        CALL 5
        LD HL,LFCB
        CALL PUTS
        LD DE,BADFCB
        LD C,15
        CALL 5
        CALL HEXB
        CALL CRLF
        JP EXIT
BAN:    DB 'PARAM27 set/query user',13,10,0
LFCB:   DB 'malformed/unactivated Open ',0
USERS:  DB 0,31,32,254
BADFCB: DB 0,'BAD?    ???',0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
        DS 128
STACK:
        INCLUDE "COMMON27.INC"
        END
