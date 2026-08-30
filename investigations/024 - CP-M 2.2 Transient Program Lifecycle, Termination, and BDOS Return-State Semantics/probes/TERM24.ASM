; Immediate RET termination.
        ORG 100H
        LD DE,MSG
        LD C,9
        CALL 5
        RET
MSG:    DB 'TERM24 BEFORE RET',13,10,'$'
        END
