        ORG 0100H
        LD DE,MSG
        LD C,9
        CALL 5
        LD C,0
        JP 5
MSG:   DB 13,10,'F0TERM22 terminating by BDOS Function 0',13,10,'$'
        END
