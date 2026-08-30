; Make and write one record, deliberately omit Close, then terminate R/F/J.
        ORG 100H
        LD A,(0082H)
        LD (MODE),A
        LD HL,FNAME
        CP 'F'
        JR NZ,NOTF
        LD (HL),'F'
        JR NAMED
NOTF:   CP 'J'
        JR NZ,NAMED
        LD (HL),'J'
NAMED:  LD DE,DATA
        LD C,26
        CALL 5
        LD DE,FCB
        LD C,22
        CALL 5
        LD (MAKERC),A
        LD DE,FCB
        LD C,21
        CALL 5
        LD (WRITERC),A
        LD DE,MSG
        LD C,9
        CALL 5
        LD A,(MAKERC)
        CALL HEX
        LD A,(WRITERC)
        CALL HEX
        LD E,13
        CALL OUT
        LD E,10
        CALL OUT
        LD A,(MODE)
        CP 'F'
        JR Z,DOF0
        CP 'J'
        JP Z,0
        RET
DOF0:   LD C,0
        JP 5
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
OUT:    LD C,2
        JP 5
MSG:    DB 'FILE24 MAKE/WRITE RC=','$'
MODE:   DB 0
MAKERC: DB 0
WRITERC:DB 0
FCB:    DB 0
FNAME:  DB 'ROPEN24 '
        DB 'DAT',0,0,0,0
        DS 16
        DB 0,0,0,0
DATA:   DB 'I024-UNCLOSED-RECORD'
        DS 128-20,024H
        END
