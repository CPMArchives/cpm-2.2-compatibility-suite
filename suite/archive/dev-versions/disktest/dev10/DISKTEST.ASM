; BetterCP/M executable conformance suite - DISKTEST skeleton
; Version 0.1.0-dev10
; Fresh Montezuma Micro bring-up build: /H and /INFO only.
; Intel 8080 instruction subset.

        ORG     0100H
BDOS    EQU     0005H

START:  LD      SP,STACKTOP
        LD      HL,0
        PUSH    HL              ; RET from a command returns through address 0

        LD      HL,0081H        ; CCP command tail
        LD      A,(0080H)
        OR      A
        JP      Z,SHOWHELP
        LD      B,A

SKIP:   LD      A,(HL)
        CP      ' '
        JP      NZ,GOTCHAR
        INC     HL
        DEC     B
        JP      NZ,SKIP
        JP      SHOWHELP

GOTCHAR:CP      '/'
        JP      NZ,SHOWBAD
        INC     HL
        LD      A,(HL)
        AND     5FH
        CP      'H'
        JP      Z,SHOWHELP
        CP      'I'
        JP      Z,SHOWINFO
        JP      SHOWBAD

SHOWHELP:
        LD      DE,HELPMSG
        CALL    PRINT
        RET

SHOWINFO:
        LD      DE,INFOMSG
        CALL    PRINT
        RET

SHOWBAD:
        LD      DE,BADMSG
        CALL    PRINT
        RET

PRINT:  LD      C,9
        CALL    BDOS
        RET

HELPMSG:DB 13,10,'DISKTEST 0.1.0-dev10 skeleton',13,10,13,10
        DB '  DISKTEST /H      Show this help',13,10
        DB '  DISKTEST /INFO   Show build information',13,10,13,10
        DB 'This bring-up build contains no disk tests.',13,10,'$'

INFOMSG:DB 13,10,'BetterCP/M DISKTEST 0.1.0-dev10 skeleton',13,10
        DB 'Implemented commands: /H and /INFO',13,10
        DB 'Disk-test cases implemented: 0',13,10,'$'

BADMSG: DB 13,10,'DISKTEST: use /H or /INFO.',13,10,'$'

        DS      64
STACKTOP:
        END
