; Establish BDOS read-only drive state, then attempt Delete.
        ORG 100H
        LD C,28
        CALL 5
        LD DE,FCB
        LD C,19
        CALL 5
        LD (RC),A
        LD DE,MSG
        LD C,9
        CALL 5
        RET
MSG:    DB 'DISK25 UNEXPECTED RETURN',13,10,'$'
RC:     DB 0
FCB:    DB 0,'ONE25   ','DAT',0,0,0,0
        DS 20
        END
