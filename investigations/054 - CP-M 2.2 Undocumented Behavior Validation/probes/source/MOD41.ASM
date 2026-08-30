; Investigation 041: reversible 0005h gateway interposition.
        ORG 0100H
        LD HL,0005H
        LD DE,SAVED
        LD BC,3
        LDIR
        LD HL,(0006H)
        LD (CHAIN+1),HL
        LD A,0C3H
        LD (0005H),A
        LD HL,WRAP
        LD (0006H),HL
        LD C,12
        CALL 0005H
        LD (RESULT),HL
        DI
        LD HL,SAVED
        LD DE,0005H
        LD BC,3
        LDIR
        EI
        LD DE,MSG
        LD C,9
        CALL 0005H
        LD A,(COUNT)
        CALL HEXB
        LD E,' '
        LD C,2
        CALL 0005H
        LD HL,(RESULT)
        LD A,H
        CALL HEXB
        LD HL,(RESULT)
        LD A,L
        CALL HEXB
        LD E,13
        LD C,2
        CALL 0005H
        LD E,10
        LD C,2
        CALL 0005H
        RET
WRAP:   PUSH AF
        LD A,(COUNT)
        INC A
        LD (COUNT),A
        POP AF
CHAIN:  JP 0000H
HEXB:   PUSH AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL NIB
        POP AF
NIB:    AND 0FH
        ADD A,'0'
        CP '9'+1
        JR C,OUT
        ADD A,7
OUT:    LD E,A
        LD C,2
        JP 0005H
MSG:    DB 'MOD41 wrapper-count resultHL $'
SAVED:  DS 3
RESULT: DW 0
COUNT:  DB 0
        END
