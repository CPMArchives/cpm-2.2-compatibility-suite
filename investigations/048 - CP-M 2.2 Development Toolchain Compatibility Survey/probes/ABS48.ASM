        ORG     100H
        LXI     D,MESSAGE
        MVI     C,9
        CALL    5
        RET
MESSAGE:DB      'ABS48 OK$'
        END
