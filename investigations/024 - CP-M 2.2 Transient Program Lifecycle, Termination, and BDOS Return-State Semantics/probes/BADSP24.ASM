; A corrupted RET stack is not validated: this safe case routes RET to 0000h.
        ORG 100H
        LD DE,MSG
        LD C,9
        CALL 5
        LD SP,WORD0
        RET
WORD0:  DW 0
MSG:    DB 'BADSP24 RET WORD 0000',13,10,'$'
        END
