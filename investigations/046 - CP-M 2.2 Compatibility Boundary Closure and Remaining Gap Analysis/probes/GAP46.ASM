; Investigation 046 closure validation probe.
        ORG 100H
        LD HL,005CH
        LD DE,F1COPY
        LD BC,16
        LDIR
        LD HL,006CH
        LD DE,F2COPY
        LD BC,16
        LDIR
        LD A,(0080H)
        LD (TAILN),A
        LD C,A
        LD B,0
        LD HL,0081H
        LD DE,TAILCOPY
        LDIR

        LD E,1
        LD C,14
        CALL 5
        LD C,28
        CALL 5
        LD C,24
        CALL 5
        LD (LOGIN0),HL
        LD C,29
        CALL 5
        LD (RO0),HL
        LD DE,0002H
        LD C,37
        CALL 5
        LD (F37RET),HL
        LD C,24
        CALL 5
        LD (LOGIN1),HL
        LD C,29
        CALL 5
        LD (RO1),HL
        LD C,25
        CALL 5
        LD (DRIVE1),A

        LD C,38
        CALL 5
        LD (F38),HL
        LD C,39
        CALL 5
        LD (F39),HL
        LD C,41
        CALL 5
        LD (F41),HL

        LD C,13
        CALL 5
        LD DE,0080H
        LD C,26
        CALL 5

        LD DE,TITLE
        CALL PRINT
        LD DE,LF1
        CALL PRINT
        LD HL,F1COPY
        LD B,16
        CALL DUMP
        LD DE,LF2
        CALL PRINT
        LD HL,F2COPY
        LD B,16
        CALL DUMP
        LD DE,LTAIL
        CALL PRINT
        LD A,(TAILN)
        CALL HEX
        LD E,'/'
        CALL OUT
        LD A,(TAILN)
        LD B,A
        LD HL,TAILCOPY
TPR:    LD E,(HL)
        PUSH BC
        PUSH HL
        CALL OUT
        POP HL
        POP BC
        INC HL
        DJNZ TPR
        CALL CRLF
        LD DE,LVEC
        CALL PRINT
        LD HL,(LOGIN0)
        CALL HEXHL
        LD E,'/'
        CALL OUT
        LD HL,(RO0)
        CALL HEXHL
        LD E,'-'
        CALL OUT
        LD E,'>'
        CALL OUT
        LD HL,(LOGIN1)
        CALL HEXHL
        LD E,'/'
        CALL OUT
        LD HL,(RO1)
        CALL HEXHLCR
        LD DE,LF37
        CALL PRINT
        LD HL,(F37RET)
        CALL HEXHL
        LD A,(DRIVE1)
        CALL HEXCR
        LD DE,LRES
        CALL PRINT
        LD HL,(F38)
        CALL HEXHL
        LD HL,(F39)
        CALL HEXHL
        LD HL,(F41)
        CALL HEXHLCR
        LD DE,DONE
        CALL PRINT
        RET

DUMP:   LD A,(HL)
        PUSH BC
        PUSH HL
        CALL HEX
        POP HL
        POP BC
        INC HL
        DJNZ DUMP
        JP CRLF
HEXHLCR:
        PUSH HL
        LD A,H
        CALL HEX
        POP HL
        LD A,L
        JP HEXCR
HEXHL:  PUSH HL
        LD A,H
        CALL HEX
        POP HL
        LD A,L
        JP HEX
HEXCR:  CALL HEX
CRLF:   LD E,13
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
PRINT:  LD C,9
        JP 5

TITLE: DB 'GAP46 CLOSURE MATRIX',13,10,'$'
LF1:   DB 'FCB1[0..15]=','$'
LF2:   DB 'FCB2[0..15]=','$'
LTAIL: DB 'TAIL COUNT/TEXT=','$'
LVEC:  DB 'LOGIN/RO BEFORE->AFTER=','$'
LF37:  DB 'F37 RET/CURRENT DRIVE=','$'
LRES:  DB 'F38/F39/F41=','$'
DONE:  DB 'GAP46 COMPLETE',13,10,'$'
F1COPY: DS 16
F2COPY: DS 16
TAILN: DB 0
TAILCOPY: DS 127
LOGIN0: DW 0
RO0: DW 0
LOGIN1: DW 0
RO1: DW 0
F37RET: DW 0
DRIVE1: DB 0
F38: DW 0
F39: DW 0
F41: DW 0
        END
