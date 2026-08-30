        ORG 0100H
        LD DE,MSG
        LD C,9
        CALL 5
        JP 0000H
MSG:   DB 13,10,'J0TERM22 terminating by JMP 0000h',13,10,'$'
        END
