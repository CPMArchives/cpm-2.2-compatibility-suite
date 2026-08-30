; Function 0 termination from an application-owned stack; must not return.
        ORG 0100H
        LD DE,MSG
        LD C,9
        CALL 0005H
        LD SP,STACKTOP
        LD C,0
        CALL 0005H
        LD DE,BAD
        LD C,9
        CALL 0005H
        RET
MSG:    DB 'FN043 PRIVATE STACK FUNCTION 0$'
BAD:    DB 'FN043 UNEXPECTED RETURN$'
        DS 128
STACKTOP:
        END

