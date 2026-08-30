; Immediate BDOS Function 0 termination.
        ORG 100H
        LD DE,MSG
        LD C,9
        CALL 5
        LD C,0
        JP 5
MSG:    DB 'BDOS024 BEFORE F0',13,10,'$'
        END
