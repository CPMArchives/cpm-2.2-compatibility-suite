; Entry/return-state probe used after all three termination paths.
        ORG 0100H
        LD (SPSAVE),SP
        LD DE,MSG
        LD C,9
        CALL 5
        LD A,(0004H)
        CALL HEX
        LD DE,ULAB
        LD C,9
        CALL 5
        LD E,0FFH
        LD C,32
        CALL 5
        CALL HEX
        LD DE,SPLAB
        LD C,9
        CALL 5
        LD HL,(SPSAVE)
        CALL HEXW
        LD E,' '
        CALL PUTC
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
        CALL HEXW
        LD DE,TAIL
        LD C,9
        CALL 5
        LD A,(0080H)
        CALL HEX
        CALL CRLF
        RET
HEXW:  PUSH HL
        LD A,H
        CALL HEX
        POP HL
        LD A,L
HEX:   PUSH AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL NIB
        POP AF
NIB:   AND 0FH
        ADD A,'0'
        CP '9'+1
        JR C,OUT
        ADD A,7
OUT:   LD E,A
PUTC:  PUSH BC
        PUSH DE
        PUSH HL
        LD C,2
        CALL 5
        POP HL
        POP DE
        POP BC
        RET
CRLF:  LD E,13
        CALL PUTC
        LD E,10
        JP PUTC
MSG:   DB 'STATE22 PZ4=$'
ULAB:  DB ' USER=$'
SPLAB: DB ' SP/RET=$'
TAIL:  DB ' TAILCOUNT=$'
SPSAVE:DW 0
        DS 96
STACKTOP:
        END
