; Investigation 039: set CON=CRT encoding and warm restart.
        ORG 0100H
        LD E,01H
        LD C,8
        CALL 0005H
        LD DE,MSG
        LD C,9
        CALL 0005H
        LD C,0
        JP 0005H
MSG:    DB 'SWITCH39 SET IOBYTE 01 THEN WBOOT',13,10,'$'
        END
