        CSEG
        LXI     D,MESSAGE
        MVI     C,9
        CALL    5
        RET
MESSAGE:DB      'BIG48 OK$'
        DS      300
        END
