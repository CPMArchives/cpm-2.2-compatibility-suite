        ORG 100H
        LD SP,STACK
        LD HL,BAN
        CALL PUTS
        LD E,0
        LD C,14
        CALL 5
        LD HL,LA
        CALL PUTS
        CALL PTRS
        LD E,1
        LD C,14
        CALL 5
        LD HL,LB
        CALL PUTS
        CALL PTRS
        LD HL,LX
        CALL PUTS
        LD C,39
        LD DE,1234H
        CALL 5
        CALL HEXW
        CALL SPACE
        LD C,41
        LD DE,5678H
        CALL 5
        CALL HEXW
        CALL CRLF
        LD C,0
        JP 5
PTRS:   LD C,27
        CALL 5
        CALL HEXW
        CALL SPACE
        LD C,31
        CALL 5
        PUSH HL
        CALL HEXW
        CALL SPACE
        POP HL
        LD B,15
PLOOP:  LD A,(HL)
        INC HL
        CALL HEXB
        DJNZ PLOOP
        JP CRLF
BAN:    DB 'DPB26 drive alv dpb bytes',13,10,0
LA:     DB 'A ',0
LB:     DB 'B ',0
LX:     DB 'F39/F41 ',0
        DS 128
STACK:
        INCLUDE "COMMON26.INC"
        END
