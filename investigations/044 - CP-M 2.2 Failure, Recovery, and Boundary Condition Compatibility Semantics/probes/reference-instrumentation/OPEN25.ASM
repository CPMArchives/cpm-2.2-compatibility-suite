; Missing, wrong-user, wildcard, and unavailable/invalid drive Open behavior.
; Argument N performs returning cases; C uses drive code 3; I uses drive 17.
        ORG 100H
        LD A,(0082H)
        CP 'C'
        JR Z,DRIVEC
        CP 'I'
        JR Z,DRIVEI
        LD DE,MISS
        LD C,15
        CALL 5
        LD DE,L_MISS
        CALL SHOW
        LD DE,USER1
        LD C,15
        CALL 5
        LD DE,L_USER
        CALL SHOW
        LD DE,WILD
        LD C,15
        CALL 5
        LD DE,L_WILD
        CALL SHOW
        RET
DRIVEC: LD DE,CFILE
        LD C,15
        CALL 5
        LD DE,L_RET
        CALL SHOW
        RET
DRIVEI: LD DE,IFILE
        LD C,15
        CALL 5
        LD DE,L_RET
        CALL SHOW
        RET
SHOW:   PUSH AF
        LD C,9
        CALL 5
        POP AF
        CALL HEX
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
OUT:    LD C,2
        JP 5
L_MISS: DB 'OPEN MISSING=','$'
L_USER: DB 'OPEN USER1-FILE FROM USER0=','$'
L_WILD: DB 'OPEN WILDCARD=','$'
L_RET:  DB 'UNEXPECTED NORMAL RETURN=','$'
MISS:   DB 0,'MISSING ','DAT',0,0,0,0
        DS 20
USER1:  DB 0,'USER1   ','DAT',0,0,0,0
        DS 20
WILD:   DB 0,'ONE?5   ','DAT',0,0,0,0
        DS 20
CFILE:  DB 3,'ONE25   ','DAT',0,0,0,0
        DS 20
IFILE:  DB 17,'ONE25   ','DAT',0,0,0,0
        DS 20
        END
