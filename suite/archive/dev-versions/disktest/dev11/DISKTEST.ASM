; BetterCP/M DISKTEST
; Version 0.1.0-dev11
; Incremental rebuild: /H, /INFO, and ledger item 0155 only.
; Intel 8080 instruction subset.
        ORG 0100H
BDOS    EQU 0005H

START:  LD SP,STACKTOP
        LD HL,0
        PUSH HL
        LD HL,0081H
        LD A,(0080H)
        OR A
        JP Z,SHOWHELP
        LD B,A
SKIP:   LD A,(HL)
        CP ' '
        JP NZ,GOTCHAR
        INC HL
        DEC B
        JP NZ,SKIP
        JP SHOWHELP
GOTCHAR:CP '/'
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        CP '0'
        JP Z,TRY0155
        AND 5FH
        CP 'H'
        JP Z,SHOWHELP
        CP 'I'
        JP Z,SHOWINFO
        JP SHOWBAD

TRY0155:INC HL
        LD A,(HL)
        CP '1'
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        CP '5'
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        CP '5'
        JP NZ,SHOWBAD
        JP RUN0155

SHOWHELP:LD DE,HELPMSG
        CALL PRINT
        RET
SHOWINFO:LD DE,INFOMSG
        CALL PRINT
        RET
SHOWBAD:LD DE,BADMSG
        CALL PRINT
        RET

; 0155: Function 13 must preserve the current user number. Save caller state,
; select a deliberately nonzero user, reset, observe, then restore caller state.
RUN0155:LD C,25
        CALL BDOS
        LD (OLDDRV),A
        LD E,0FFH
        LD C,32
        CALL BDOS
        LD (OLDUSR),A
        LD E,1
        CP 1
        JP NZ,SETTEST
        LD E,2
SETTEST:LD A,E
        LD (TESTUSR),A
        LD C,32
        CALL BDOS
        LD C,13
        CALL BDOS
        LD E,0FFH
        LD C,32
        CALL BDOS
        LD (GOTUSR),A
        LD A,(OLDUSR)
        LD E,A
        LD C,32
        CALL BDOS
        LD A,(OLDDRV)
        LD E,A
        LD C,14
        CALL BDOS
        LD A,(TESTUSR)
        LD B,A
        LD A,(GOTUSR)
        CP B
        JP NZ,FAIL0155
        LD DE,PASSMSG
        CALL PRINT
        RET
FAIL0155:LD DE,FAILMSG
        CALL PRINT
        RET

PRINT:  LD C,9
        CALL BDOS
        RET

HELPMSG:DB 13,10,'DISKTEST 0.1.0-dev11',13,10,13,10
        DB '  DISKTEST /0155   Test Function 13 user preservation',13,10
        DB '  DISKTEST /H      Show this help',13,10
        DB '  DISKTEST /INFO   Show build information',13,10,13,10
        DB 'This incremental build contains one disk test.',13,10,'$'
INFOMSG:DB 13,10,'BetterCP/M DISKTEST 0.1.0-dev11',13,10
        DB 'Implemented commands: /0155, /H, and /INFO',13,10
        DB 'Disk-test cases implemented: 1',13,10
        DB 'Ledger coverage: 0155',13,10,'$'
PASSMSG:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0155  PASS      REQUIRED      Function 13 preserved user number',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
FAILMSG:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0155  FAIL      REQUIRED      Function 13 changed user number',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'
BADMSG: DB 13,10,'DISKTEST: use /0155, /H, or /INFO.',13,10,'$'
OLDDRV: DB 0
OLDUSR: DB 0
TESTUSR:DB 0
GOTUSR: DB 0
        DS 64
STACKTOP:
        END
