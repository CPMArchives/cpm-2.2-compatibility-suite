        ORG 100H
        LD (OLDSP),SP
        LD SP,STKTOP
        LD HL,BAN
        CALL PUTS
        LD B,64
SLOOP:  LD HL,0
        ADD HL,SP
        LD (PRE),HL
        PUSH BC
        LD C,12
        CALL 5
        POP BC
        LD HL,0
        ADD HL,SP
        LD (POST),HL
        LD HL,(PRE)
        LD DE,(POST)
        OR A
        SBC HL,DE
        JR NZ,BAD
        DJNZ SLOOP
        LD HL,OK
        JR OUT
BAD:    LD HL,FAIL
OUT:    CALL PUTS
        LD HL,(PRE)
        CALL HEXW
        CALL SPACE
        LD HL,(POST)
        CALL HEXW
        CALL SPACE
        LD A,(GUARD0)
        CALL HEXB
        CALL SPACE
        LD A,(GUARD1)
        CALL HEXB
        CALL CRLF
        LD SP,(OLDSP)
        JP EXIT
BAN:    DB 'STACK27 64 repeated calls',13,10,0
OK:     DB 'OK pre post guards ',0
FAIL:   DB 'FAIL pre post guards ',0
OLDSP:  DW 0
PRE:    DW 0
POST:   DW 0
GUARD0: DB 0A5H
        DS 126,05AH
STKTOP:
GUARD1: DB 03CH
        INCLUDE "COMMON27.INC"
        END
