; Short host file. CP/M stores/loads one full record; print the last byte of
; that loaded record to expose fixture padding without claiming it universal.
        ORG 0100H
        LD DE,MSG
        LD C,9
        CALL 5
        LD A,(017FH)
        CALL HEX
        LD E,13
        LD C,2
        CALL 5
        LD E,10
        LD C,2
        CALL 5
        RET
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
        LD C,2
        JP 5
MSG:   DB 'PART22 byte at 017F=$'
        END
