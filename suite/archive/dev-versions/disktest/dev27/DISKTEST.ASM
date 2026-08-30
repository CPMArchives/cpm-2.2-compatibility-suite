;***************************************************************
;*                                                             *
;*       BetterCP/M disk conformance test, version dev27        *
;*                                                             *
;*       8080 instruction subset                                *
;*       re-baseline of proven dev19                            *
;*                                                             *
;***************************************************************
; Version 0.1.0-dev27
;
; Assemble with Z80ASM using the 8080 instruction subset.
; Run under CP/M 2.2 as:  DISKTEST /selector
;
; Revision history:
;   dev19   six-item bring-up version proved on Montezuma CP/M
;   dev24   restored dev19 code; comments revised, no code change
;   dev25   add operator gate for procedures requiring scratch D:
;   dev26   execute item 0255 after operator consent
;   dev27   reset disk system before logging replaced D: media
;
; Notes for modifiers:
;   The command tail is at 0080H/0081H in the usual CP/M form.
;   All messages passed to function 9 must end in a dollar sign.
;   Every exit is a warm start through location 0000H.
;   Tests using drive D: must obtain operator consent before I/O.
;
        ORG 0100H
BDOS    EQU 0005H

; enter from ccp.  establish private stack and scan command tail.
START:  LD SP,STACKTOP       ;do not depend on ccp stack
        LD HL,0081H
        LD A,(0080H)         ;command length
        OR A
        JP Z,SHOWHELP
        LD B,A
SKIP:   LD A,(HL)            ;skip leading blanks
        CP ' '
        JP NZ,GOTCHAR
        INC HL
        DEC B
        JP NZ,SKIP
        JP SHOWHELP
GOTCHAR:CP '/'               ;all selectors begin with slash
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        CP '0'
        JP Z,TRYNUM
        AND 5FH
        CP 'H'
        JP Z,SHOWHELP
        CP 'I'
        JP Z,SHOWINFO
        CP 'L'
        JP Z,SHOWLIST
        JP SHOWBAD

; Decode four-digit ledger selector.  This is intentionally written
; as a short decision tree; it is easy to patch with DDT and does not
; require a table search in the first bring-up versions.
TRYNUM: INC HL
        LD A,(HL)
        CP '1'
        JP Z,NUM1
        CP '2'
        JP Z,NUM2
        JP SHOWBAD
NUM1:   INC HL
        LD A,(HL)
        CP '5'
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        CP '5'
        JP NZ,SHOWBAD
        JP RUN0155
NUM2:   INC HL
        LD A,(HL)
        CP '5'
        JP Z,NUM25
        CP '7'
        JP Z,NUM27
        CP '9'
        JP Z,NUM29
        JP SHOWBAD
NUM25:  INC HL
        LD A,(HL)
        CP '5'
        JP Z,SHOW0255
        JP SHOWBAD
NUM27:  INC HL
        LD A,(HL)
        CP '5'
        JP Z,SHOW0275
        CP '6'
        JP Z,SHOW0276
        JP SHOWBAD
NUM29:  INC HL
        LD A,(HL)
        CP '2'
        JP Z,SHOW0292
        CP '3'
        JP Z,SHOW0293
        JP SHOWBAD

; common display exits.  strings are terminated by '$'.
SHOWHELP:LD DE,HELPMSG
        CALL PRINT
        JP 0000H
SHOWINFO:LD DE,INFOMSG
        CALL PRINT
        JP 0000H
SHOWLIST:LD DE,LISTPLACE
        CALL PRINT
        JP 0000H
SHOW0255:LD A,1               ;continue dispatches executable test
        LD (DOFLAG),A
        LD DE,MSG0255
        JP SCRATCH
SHOW0275:LD DE,MSG0275
        JP SCRPROC
SHOW0276:LD DE,MSG0276
        JP SCRPROC
SHOW0292:LD DE,MSG0292
        JP SCRPROC
SHOW0293:LD DE,MSG0293
        JP SCRPROC
SHOWBAD:LD DE,BADMSG
        CALL PRINT
        JP 0000H

; SCRATCH - obtain consent before displaying a destructive D: procedure.
; Entry: DE addresses the selected procedure.  Bypass performs no disk I/O.
SCRPROC:XOR A                ;continue displays procedure only
        LD (DOFLAG),A
SCRATCH:EX DE,HL             ;8080-compatible save of procedure
        LD (PROCPTR),HL
        EX DE,HL
ASKSCR: LD DE,ASKMSG
        CALL PRINT
        LD C,1               ;console input with echo
        CALL BDOS
        AND 5FH              ;accept lower case also
        CP 'C'
        JP Z,DOPROC
        CP 'B'
        JP NZ,ASKSCR
        LD DE,BYPASSMSG
        CALL PRINT
        JP 0000H
DOPROC: LD A,(DOFLAG)
        OR A
        JP NZ,RUN0255
        LD HL,(PROCPTR)      ;8080-compatible reload through h,l
        EX DE,HL
        CALL PRINT
        JP 0000H

; Test 0255 - Make an empty file when no data blocks remain.
;
; D: is named explicitly in the FCB; the caller's selected disk is not
; changed.  A successful Make consumes a directory entry but no data block.
; Delete the entry before reporting so a repeat begins from the same fixture.
RUN0255:LD C,13              ;discard stale allocation vectors after swap
        CALL BDOS
        LD DE,FCB0255
        LD C,22              ;make file
        CALL BDOS
        CP 0FFH
        JP Z,FAIL0255
        LD DE,FCB0255
        LD C,19              ;remove temporary empty file
        CALL BDOS
        LD DE,PASS0255
        CALL PRINT
        JP 0000H
FAIL0255:LD DE,MSG25FAIL
        CALL PRINT
        JP 0000H

; Test 0155 - Function 13 preserves current user number.
;
; On entry: normal CP/M transient-program state.
; On exit:  original user and selected disk restored; warm boot follows.
; Uses:     A,B,C,E.  No disk records are read or written.
;
; Choose a user different from the caller, reset the disk system, then
; ask Function 32 which user remains selected.  This catches systems
; which incorrectly fold a user reset into Function 13.
RUN0155:LD C,25
        CALL BDOS
        LD (OLDDRV),A        ;save selected disk
        LD E,0FFH
        LD C,32
        CALL BDOS
        LD (OLDUSR),A        ;save user number
        LD E,1
        CP 1
        JP NZ,SETTEST
        LD E,2               ;avoid testing current user 1
SETTEST:LD A,E
        LD (TESTUSR),A
        LD C,32
        CALL BDOS
        LD C,13
        CALL BDOS
        LD E,0FFH
        LD C,32
        CALL BDOS
        LD (GOTUSR),A        ;user following disk reset
        LD A,(OLDUSR)
        LD E,A
        LD C,32
        CALL BDOS
        LD A,(OLDDRV)        ;restore selected disk
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
        JP 0000H
FAIL0155:LD DE,FAILMSG
        CALL PRINT
        JP 0000H

; PRINT - send a '$'-terminated string to the console.
; Entry: DE addresses text.  Exit: registers are whatever BDOS leaves.
; Keep CALL/RET here: this is the sequence proved by dev19 on Montezuma.
PRINT:  LD C,9
        CALL BDOS
        RET

HELPMSG:DB 13,10,'DISKTEST 0.1.0-dev27',13,10,13,10
        DB '  DISKTEST /NNNN   Run or explain one ledger item',13,10
        DB '  DISKTEST /LIST   List implemented ledger items',13,10
        DB '  DISKTEST /H      Show this help',13,10
        DB '  DISKTEST /INFO   Show build information',13,10,13,10
        DB 'Automated: 0155, 0255. Other items print controlled procedures.',13,10,'$'
LISTPLACE:DB 13,10,'0155  REQUIRED  Function 13 user-number preservation',13,10
        DB '0255  REQUIRED  Data-full empty Make',13,10
        DB '0275  REQUIRED  Allocation-full failure',13,10
        DB '0276  REQUIRED  Exact write failure codes',13,10
        DB '0292  REQUIRED  Allocation release',13,10
        DB '0293  NOT GUAR. Exact freed-block reuse',13,10,'$'
INFOMSG:DB 13,10,'BetterCP/M DISKTEST 0.1.0-dev27',13,10
        DB 'Implemented commands: /NNNN, /LIST, /H, and /INFO',13,10
        DB 'Ledger items represented: 6',13,10
        DB 'Automated: 2; controlled procedures: 4',13,10
        DB 'Required: 5; not guaranteed: 1',13,10
        DB 'Ledger coverage: 0155, 0255, 0275, 0276, 0292, 0293',13,10,'$'
PASSMSG:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0155  PASS      REQUIRED      Function 13 preserved user number',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
FAILMSG:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0155  FAIL      REQUIRED      Function 13 changed user number',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

; The following entries require a replaceable D: image.  Test 0255 runs
; after consent; the remaining four still display controlled procedures.
; The common gate asks C=continue/B=bypass before any possible disk access.
; Never substitute a disk containing unique files.
ASKMSG: DB 13,10,'Scratch disk required in D:.',13,10
        DB 'Press C to continue, B to bypass: $'
BYPASSMSG:DB 13,10,'BYPASSED: D: was not accessed.',13,10,'$'
PASS0255:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0255  PASS      REQUIRED      Empty Make succeeded on data-full D:',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
MSG25FAIL:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0255  FAIL      REQUIRED      Empty Make failed on data-full D:',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'
MSG0255:DB 13,10,'0255  UNTESTED  REQUIRED      Data-full empty Make',13,10
        DB 'SETUP: mount the supplied restorable full disk as D:.',13,10
        DB 'ACTION: make D:EMPTY.TST without writing a data record.',13,10
        DB 'EXPECTED: Make succeeds; an empty file needs no data block.',13,10
        DB 'FAIL: Make reports data-full before a record is written.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
MSG0275:DB 13,10,'0275  UNTESTED  REQUIRED      Allocation-full failure',13,10
        DB 'SETUP: mount the supplied restorable full disk as D:.',13,10
        DB 'ACTION: append one record to D:BTFULL.DAT.',13,10
        DB 'EXPECTED: allocating write fails; existing data remains intact.',13,10
        DB 'FAIL: write succeeds or corrupts an existing record.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
MSG0276:DB 13,10,'0276  UNTESTED  REQUIRED      Exact write failure codes',13,10
        DB 'SETUP: mount the supplied restorable full disk as D:.',13,10
        DB 'ACTION: attempt sequential and random allocating writes.',13,10
        DB 'EXPECTED: each returns its documented nonzero failure code.',13,10
        DB 'FAIL: either returns success or an undocumented success alias.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
MSG0292:DB 13,10,'0292  UNTESTED  REQUIRED      Allocation release',13,10
        DB 'SETUP: use a fresh copy of the supplied restorable D: disk.',13,10
        DB 'ACTION: delete an allocated file, then allocate equal space.',13,10
        DB 'EXPECTED: new allocation succeeds using released capacity.',13,10
        DB 'FAIL: released capacity remains unavailable.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
MSG0293:DB 13,10,'0293  UNTESTED  NOT GUAR.     Exact freed-block reuse',13,10
        DB 'Observe the allocation block reused after delete and Make.',13,10
        DB 'Any valid free block is acceptable; exact order is not fixed.',13,10
        DB 'This observation has no baseline conformance effect.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
; Working storage.  The private stack prevents a failed probe from relying
; on the depth or contents of the CCP stack.  Sixty-four bytes is ample for
; this nonrecursive version; increase it if nested test helpers are added.
BADMSG: DB 13,10,'DISKTEST: unknown selector. Use DISKTEST /H.',13,10,'$'
OLDDRV: DB 0
OLDUSR: DB 0
TESTUSR:DB 0
GOTUSR: DB 0
DOFLAG: DB 0
PROCPTR:DW 0
; Explicit D: FCB for EMPTY.TST.  Remaining fields begin at zero.
FCB0255:DB 4,'EMPTY   ','TST'
        DS 24
        DS 64
STACKTOP:
        END
