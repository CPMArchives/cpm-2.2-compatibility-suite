; Resource exhaustion: Make then Write one record, report FCB and DMA.
        ORG 100H
        LD DE,DMA
        LD C,26
        CALL 5
        LD DE,FCB
        LD C,22
        CALL 5
        LD (MRC),A
        CP 0FFH
        JR Z,NOWRITE
        LD DE,FCB
        LD C,21
        CALL 5
        LD (WRC),A
NOWRITE:LD DE,MSG
        LD C,9
        CALL 5
        LD A,(MRC)
        CALL HEX
        LD A,(WRC)
        CALL HEX
        LD DE,FCB
        LD BC,36
        CALL DUMP0
        LD DE,DMA
        LD BC,16
        CALL DUMP
        RET
DUMP0:  LD A,(DE)
        PUSH BC
        PUSH DE
        CALL HEX
        POP DE
        POP BC
        INC DE
        DEC BC
        LD A,B
        OR C
        JR NZ,DUMP0
        RET
DUMP:   CALL DUMP0
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
MSG:    DB 'MAKE/WRITE RC/FCB/DMA=','$'
MRC:    DB 0EEH
WRC:    DB 0EEH
FCB:    DB 0,'NEW25   ','DAT',0,0,0,0
        DS 16
        DB 0,0,0,0
DMA:   DB 'I025-WRITE-DATA'
        DS 113,025H
        END
