; Normal edge matrix: entry state, private stack, self-modification, TPA top.
        ORG 0100H
        LD (ENTRYSP),SP
        LD HL,0
        ADD HL,SP
        LD E,(HL)
        INC HL
        LD D,(HL)
        LD (RETWORD),DE

        LD HL,(0006H)
        DEC HL
        LD (TPALAST),HL
        LD A,(HL)
        LD (TOPOLD),A
        LD (HL),0A5H
        LD A,(HL)
        LD (TOPTEST),A
        LD A,(TOPOLD)
        LD (HL),A

        LD A,05AH
        LD (PATCH+1),A
        CALL PATCH
        LD (PATCHRES),A
        XOR A
        LD (PATCH+1),A

        LD SP,LOCALTOP
        LD (PRESP),SP
        LD C,12
        CALL 0005H
        LD (VERSION),HL
        LD (POSTSP),SP

        LD HL,MSG
        CALL PUTS
        LD HL,(ENTRYSP)
        CALL HEXW
        CALL SPACE
        LD HL,(RETWORD)
        CALL HEXW
        CALL SPACE
        LD HL,(PRESP)
        CALL HEXW
        CALL SPACE
        LD HL,(POSTSP)
        CALL HEXW
        CALL SPACE
        LD HL,(TPALAST)
        CALL HEXW
        CALL SPACE
        LD A,(TOPOLD)
        CALL HEXB
        CALL SPACE
        LD A,(TOPTEST)
        CALL HEXB
        CALL SPACE
        LD A,(PATCHRES)
        CALL HEXB
        CALL SPACE
        LD HL,(VERSION)
        CALL HEXW
        CALL CRLF
        LD C,0
        JP 0005H

PATCH:  LD A,00H
        RET
MSG:    DB 'EDGE43 ENTRYSP RET PRIVATE_PRE/POST TPA_LAST OLD/TEST PATCH VER ',0
ENTRYSP: DW 0
RETWORD: DW 0
PRESP:   DW 0
POSTSP:  DW 0
TPALAST: DW 0
VERSION: DW 0
TOPOLD:  DB 0
TOPTEST: DB 0
PATCHRES: DB 0
        DS 256
LOCALTOP:
        INCLUDE "COMMON43.INC"
        END

