; Immediate JMP 0000h termination.
        ORG 100H
        LD DE,MSG
        LD C,9
        CALL 5
        JP 0
MSG:    DB 'JUMP24 BEFORE J0',13,10,'$'
        END
