        PUBLIC  MSGOUT
        CSEG
MSGOUT: LXI     D,MESSAGE
        MVI     C,9
        CALL    5
        RET
MESSAGE:DB      'TOOL48 OK$'
        END
