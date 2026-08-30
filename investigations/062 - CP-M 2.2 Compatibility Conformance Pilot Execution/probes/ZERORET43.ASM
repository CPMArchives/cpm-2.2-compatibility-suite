; Replace the active stack with a synthetic return word 0000h, then RET.
        ORG 0100H
        LD DE,MSG
        LD C,9
        CALL 0005H
        LD SP,ZWORD
        RET
MSG:    DB 'ZERORET43 RET TO 0000H$'
ZWORD:  DW 0000H
        END

