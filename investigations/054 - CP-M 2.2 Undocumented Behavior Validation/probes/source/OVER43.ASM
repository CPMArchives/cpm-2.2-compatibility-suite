; DRI-specific overlap: damage CCP and original RET word, recover via WBOOT.
        ORG 0100H
        LD (ENTRYSP),SP
        LD HL,(0006H)
        LD DE,0806H
        OR A
        SBC HL,DE
        LD (CCPBASE),HL
        LD A,(HL)
        LD (OLDCCP),A
        LD SP,STACKTOP
        LD (HL),0A5H
        LD HL,(ENTRYSP)
        XOR A
        LD (HL),A
        INC HL
        LD (HL),A
        LD DE,MSG
        LD C,9
        CALL 0005H
        JP 0000H
MSG:    DB 'OVER43 CCP AND RET OVERWRITTEN; WBOOT$'
ENTRYSP: DW 0
CCPBASE: DW 0
OLDCCP: DB 0
        DS 160
STACKTOP:
        END

