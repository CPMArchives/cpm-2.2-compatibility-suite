; General logical failure matrix: missing Open/Close/Delete/Rename and duplicate Make.
        ORG 100H
        LD DE,DMA
        LD C,26
        CALL 5
        CALL FILLDMA
        LD DE,MISS
        LD C,15
        CALL 5
        LD DE,L_OPEN
        CALL SHOW
        LD DE,MISS
        LD C,16
        CALL 5
        LD DE,L_CLOSE
        CALL SHOW
        LD DE,MISS
        LD C,19
        CALL 5
        LD DE,L_DELETE
        CALL SHOW
        LD DE,RENFCB
        LD C,23
        CALL 5
        LD DE,L_RENAME
        CALL SHOWREN
        LD DE,DUPFCB
        LD C,22
        CALL 5
        LD DE,L_DUP
        CALL SHOWDUP
        RET
SHOW:   PUSH AF
        CALL PSTR
        POP AF
        CALL HEX
        LD DE,MISS
        JR SDUMP
SHOWREN:PUSH AF
        CALL PSTR
        POP AF
        CALL HEX
        LD DE,RENFCB
        JR SDUMP
SHOWDUP:PUSH AF
        CALL PSTR
        POP AF
        CALL HEX
        LD DE,DUPFCB
SDUMP:  LD BC,36
        CALL DUMP
        LD DE,DMA
        LD BC,16
        CALL DUMP
        RET
FILLDMA:LD HL,DMA
        LD B,128
FD0:    LD (HL),0AAH
        INC HL
        DJNZ FD0
        RET
PSTR:   LD C,9
        JP 5
DUMP:   LD A,(DE)
        PUSH BC
        PUSH DE
        CALL HEX
        POP DE
        POP BC
        INC DE
        DEC BC
        LD A,B
        OR C
        JR NZ,DUMP
        LD E,13
        CALL OUT
        LD E,10
        JP OUT
HEX:    PUSH AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL NIB
        POP AF
NIB:    AND 0FH
        ADD A,'0'
        CP '9'+1
        JR C,HOUT
        ADD A,7
HOUT:   LD E,A
OUT:    PUSH BC
        LD C,2
        CALL 5
        POP BC
        RET
L_OPEN: DB 'OPEN-MISSING RC/FCB/DMA=','$'
L_CLOSE:DB 'CLOSE-MISSING RC/FCB/DMA=','$'
L_DELETE:DB 'DELETE-MISSING RC/FCB/DMA=','$'
L_RENAME:DB 'RENAME-MISSING RC/FCB/DMA=','$'
L_DUP:  DB 'MAKE-DUPLICATE RC/FCB/DMA=','$'
MISS:   DB 0,'MISSING ','DAT',055H,066H,077H,088H
        DS 16,099H
        DB 0AAH,0BBH,0CCH,0DDH
RENFCB: DB 0,'MISSING ','DAT',0,0,0,0
        DB 0,'NEWNAME ','DAT',0,0,0,0
        DB 0,0,0,0
DUPFCB: DB 0,'ONE25   ','DAT',0,0,0,0
        DS 16
        DB 0,0,0,0
DMA:    DS 128
        END
