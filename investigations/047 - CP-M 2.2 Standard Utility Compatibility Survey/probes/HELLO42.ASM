        ORG     100H
        LXI     D,MSG
        MVI     C,9
        CALL    5
        RET
MSG:    DB      'HELLO42 OK$'
        END

