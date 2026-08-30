        ORG 0100H
        LD DE,MSG
        LD C,9
        CALL 0005H
        RET
MSG:    DB 'MAXOK43 EXECUTED$'
        END

