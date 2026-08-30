; Sequential EOF, unopened read, and random logical failures.
        ORG 100H
        LD DE,DMA
        LD C,26
        CALL 5
        LD DE,EMPTY
        LD C,15
        CALL 5
        CALL FILL
        LD DE,EMPTY
        LD C,20
        CALL 5
        LD DE,L_EOF
        CALL SHOWE
        CALL FILL
        LD DE,UNOPEN
        LD C,20
        CALL 5
        LD DE,L_UNOPEN
        CALL SHOWU
        LD DE,ONE
        LD C,15
        CALL 5
        LD A,1
        LD (ONE+33),A
        XOR A
        LD (ONE+34),A
        LD (ONE+35),A
        CALL FILL
        LD DE,ONE
        LD C,33
        CALL 5
        LD DE,L_R1
        CALL SHOWO
        LD A,128
        LD (ONE+33),A
        XOR A
        LD (ONE+34),A
        LD (ONE+35),A
        CALL FILL
        LD DE,ONE
        LD C,33
        CALL 5
        LD DE,L_R128
        CALL SHOWO
        XOR A
        LD (ONE+33),A
        LD (ONE+34),A
        LD A,4
        LD (ONE+35),A
        CALL FILL
        LD DE,ONE
        LD C,33
        CALL 5
        LD DE,L_RBAD
        CALL SHOWO
        RET
SHOWE:  LD HL,EMPTY
        JR SHOW
SHOWU:  LD HL,UNOPEN
        JR SHOW
SHOWO:  LD HL,ONE
SHOW:   PUSH HL
        PUSH AF
        LD C,9
        CALL 5
        POP AF
        CALL HEX
        POP DE
        LD BC,36
        CALL DUMP0
        LD DE,DMA
        LD BC,16
        CALL DUMP
        RET
FILL:   LD HL,DMA
        LD B,128
F0:     LD (HL),0A5H
        INC HL
        DJNZ F0
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
L_EOF:  DB 'SEQ-EMPTY-EOF RC/FCB/DMA=','$'
L_UNOPEN:DB 'SEQ-UNOPENED RC/FCB/DMA=','$'
L_R1:   DB 'RANDOM-REC1 RC/FCB/DMA=','$'
L_R128: DB 'RANDOM-REC128 RC/FCB/DMA=','$'
L_RBAD: DB 'RANDOM-INVALID RC/FCB/DMA=','$'
EMPTY:  DB 0,'EMPTY25 ','DAT',0,0,0,0
        DS 20
UNOPEN: DB 0,'ONE25   ','DAT',0,0,0,0
        DS 20
ONE:    DB 0,'ONE25   ','DAT',0,0,0,0
        DS 20
DMA:    DS 128
        END
