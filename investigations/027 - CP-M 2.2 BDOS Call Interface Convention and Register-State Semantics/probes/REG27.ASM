        ORG 100H
        LD SP,STACK
        LD HL,BAN
        CALL PUTS
        LD HL,FUNCS
        LD B,4
RLOOP:  LD C,(HL)
        INC HL
        PUSH HL
        PUSH BC
        LD DE,1234H
        LD IX,5678H
        LD IY,9ABCH
        LD HL,0D55DH
        PUSH HL
        POP AF
        CALL 5
        LD (OBC),BC
        LD (ODE),DE
        LD (OHL),HL
        LD (OIX),IX
        LD (OIY),IY
        PUSH AF
        POP HL
        LD (OAF),HL
        POP BC
        POP HL
        PUSH HL
        PUSH BC
        LD A,C
        CALL HEXB
        LD DE,OAF
        LD B,6
PWORD:  PUSH DE
        CALL SPACE
        POP DE
        LD A,(DE)
        INC DE
        LD L,A
        LD A,(DE)
        INC DE
        LD H,A
        PUSH DE
        CALL HEXW
        POP DE
        DJNZ PWORD
        CALL CRLF
        POP BC
        POP HL
        DJNZ RLOOP
        JP EXIT
BAN:    DB 'REG27 fn AF BC DE HL IX IY',13,10,0
FUNCS:  DB 12,25,26,41
OAF: DW 0
OBC: DW 0
ODE: DW 0
OHL: DW 0
OIX: DW 0
OIY: DW 0
        DS 128
STACK:
        INCLUDE "COMMON27.INC"
        END
