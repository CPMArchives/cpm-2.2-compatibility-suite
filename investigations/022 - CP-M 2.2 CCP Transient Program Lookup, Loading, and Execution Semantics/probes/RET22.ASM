        ORG 0100H
        LD DE,MSG
        LD C,9
        CALL 5
        RET
MSG:   DB 13,10,'RET22 terminating by RET',13,10,'$'
        END
