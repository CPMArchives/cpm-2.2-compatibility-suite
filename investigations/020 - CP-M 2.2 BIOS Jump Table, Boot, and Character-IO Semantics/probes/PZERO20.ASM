; Snapshot page zero immediately after the WBOOT20 warm restart.
        ORG 0100H
        LD DE,MSG
        LD C,9
        CALL 5
        LD HL,0
        LD B,8
LOOP:   LD A,(HL)
        INC HL
        PUSH HL
        PUSH BC
        CALL HEX
        LD E,' '
        LD C,2
        CALL 5
        POP BC
        POP HL
        DJNZ LOOP
        LD E,13
        LD C,2
        CALL 5
        LD E,10
        LD C,2
        CALL 5
        RET
HEX:    PUSH AF
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
        JP 5
MSG:    DB 'PZERO20 AFTER WBOOT PZ00-07: $'
        END
