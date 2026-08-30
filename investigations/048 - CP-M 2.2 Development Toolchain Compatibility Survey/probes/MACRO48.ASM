EMIT    MACRO   VALUE
        DB      VALUE
        ENDM
        ORG     100H
        LXI     D,MESSAGE
        MVI     C,9
        CALL    5
        RET
MESSAGE:EMIT    'MACRO48 OK$'
        END
