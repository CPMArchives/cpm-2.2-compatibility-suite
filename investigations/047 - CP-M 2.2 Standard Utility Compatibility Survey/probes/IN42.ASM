; Deterministic XSUB/Function-10 consumer for Investigation 042.
        ORG 0100H
        LD DE,BUF
        LD C,10
        CALL 0005H
        LD DE,MSG
        LD C,9
        CALL 0005H
        LD A,(BUF+1)
        CALL HEXB
        LD DE,DATA
        LD C,9
        CALL 0005H
        LD A,(BUF+1)
        LD B,A
        LD HL,BUF+2
LOOP:   LD A,B
        OR A
        JR Z,DONE
        LD E,(HL)
        PUSH HL
        PUSH BC
        LD C,2
        CALL 0005H
        POP BC
        POP HL
        INC HL
        DEC B
        JR LOOP
DONE:   LD E,13
        LD C,2
        CALL 0005H
        LD E,10
        LD C,2
        CALL 0005H
        RET
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
        JR C,NOUT
        ADD A,7
NOUT:   LD E,A
        LD C,2
        JP 0005H
MSG:    DB 'IN42 count=$'
DATA:   DB ' data=$'
BUF:    DB 20,0
        DS 22
        END

