; Out-of-range BDOS function 41: record return and terminate normally.
        ORG 100H
        LD C,41
        CALL 5
        LD (RC),A
        LD DE,MSG
        LD C,9
        CALL 5
        LD A,(RC)
        CALL HEX
        LD E,13
        CALL OUT
        LD E,10
        CALL OUT
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
        JR C,HOUT
        ADD A,7
HOUT:   LD E,A
OUT:    LD C,2
        JP 5
MSG:    DB 'BAD24 F41 RETURN=','$'
RC:     DB 0FFH
        END
