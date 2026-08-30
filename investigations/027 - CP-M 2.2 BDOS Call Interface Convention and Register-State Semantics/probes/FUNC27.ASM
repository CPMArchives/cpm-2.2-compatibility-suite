        ORG 100H
        LD SP,STACK
        LD HL,BAN
        CALL PUTS
        LD HL,FUNCS
        LD B,7
LOOP:   LD C,(HL)
        INC HL
        PUSH HL
        PUSH BC
        LD E,0A5H
        CALL 5
        LD (RESHL),HL
        LD (RESA),A
        LD A,B
        LD (RESB),A
        POP BC
        POP HL
        PUSH HL
        PUSH BC
        LD A,C
        CALL HEXB
        CALL SPACE
        LD HL,(RESHL)
        CALL HEXW
        CALL SPACE
        LD A,(RESA)
        CALL HEXB
        CALL SPACE
        LD A,(RESB)
        CALL HEXB
        CALL CRLF
        POP BC
        POP HL
        DJNZ LOOP
        JP EXIT
BAN:    DB 'FUNC27 fn HL A B',13,10,0
FUNCS:  DB 12,38,39,41,42,127,255
RESHL:  DW 0
RESA:   DB 0
RESB:   DB 0
        DS 128
STACK:
        INCLUDE "COMMON27.INC"
        END

