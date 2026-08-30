;***************************************************************
;*                                                             *
;*       BetterCP/M disk conformance test, version dev35        *
;*                                                             *
;*       8080 instruction subset                                *
;*       re-baseline of proven dev19                            *
;*                                                             *
;***************************************************************
; Version 0.1.0-dev35
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
;   dev28   execute item 0275; preserve size and last record
;   dev29   execute item 0276; require exact full-disk codes
;   dev30   execute item 0292; release and reclaim one block
;   dev31   execute item 0293; observe exact block reuse
;   dev32   restore items 0355 and 0373 through 0378
;   dev33   complete catalog; add protected mutations and /ALL
;   dev34   use standard aggregate summary at end of /ALL
;   dev35   restore safe, function, group, and help selectors
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
        JP Z,TRYHELP
        CP 'I'
        JP Z,SHOWINFO
        CP 'L'
        JP Z,SHOWLIST
        CP 'A'
        JP Z,SHOWALL
        CP 'S'
        JP Z,SHOWSAFE
        CP 'F'
        JP Z,TRYFN
        CP 'G'
        JP Z,TRYGROUP
        JP SHOWBAD

; Optional selectors are decoded in place.  Full words are checked so a
; mistyped abbreviation cannot silently select the wrong collection.
TRYHELP:INC HL
        LD A,(HL)
        CP ':'
        JP NZ,SHOWHELP
        INC HL
        LD A,(HL)
        AND 5FH
        CP 'R'
        JP Z,SHOWRESULTS
        CP 'P'
        JP Z,SHOWPROFILES
        JP SHOWBAD
TRYFN:  INC HL
        LD A,(HL)
        AND 5FH
        CP 'N'
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        CP ':'
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        CP '1'
        JP Z,FN1
        CP '2'
        JP Z,FN2
        JP SHOWBAD
FN1:    INC HL
        LD A,(HL)
        CP '3'
        JP Z,RUNFN13
        JP SHOWBAD
FN2:    INC HL
        LD A,(HL)
        CP '8'
        JP Z,RUNFN28
        CP '9'
        JP Z,RUNFN29
        JP SHOWBAD
TRYGROUP:INC HL
        LD A,(HL)
        AND 5FH
        CP 'R'
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        AND 5FH
        CP 'O'
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        AND 5FH
        CP 'U'
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        AND 5FH
        CP 'P'
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        CP ':'
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        AND 5FH
        CP 'A'
        JP Z,SHOWALLOC
        CP 'P'
        JP Z,RUNPROTECT
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
        CP '3'
        JP Z,NUM3
        CP '5'
        JP Z,NUM5
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
NUM3:   INC HL
        LD A,(HL)
        CP '5'
        JP Z,NUM35
        CP '7'
        JP Z,NUM37
        CP '8'
        JP Z,NUM38
        JP SHOWBAD
NUM35:  INC HL
        LD A,(HL)
        CP '5'
        JP Z,SHOW0355
        JP SHOWBAD
NUM37:  INC HL
        LD A,(HL)
        CP '3'
        JP Z,RUN0373
        CP '4'
        JP Z,RUN0374
        CP '5'
        JP Z,RUN0375
        CP '6'
        JP Z,RUN0376
        CP '7'
        JP Z,RUN0377
        CP '8'
        JP Z,RUN0378
        CP '9'
        JP Z,SHOW0379
        JP SHOWBAD
NUM38:  INC HL
        LD A,(HL)
        CP '0'
        JP Z,SHOW0380
        CP '1'
        JP Z,SHOW0381
        CP '2'
        JP Z,SHOW0382
        CP '3'
        JP Z,SHOW0383
        CP '4'
        JP Z,SHOW0384
        JP SHOWBAD
NUM5:   INC HL
        LD A,(HL)
        CP '5'
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        CP '8'
        JP Z,SHOW0558
        JP SHOWBAD

; common display exits.  strings are terminated by '$'.
SHOWHELP:LD DE,HELPMSG
        CALL PRINT
        JP 0000H
SHOWINFO:LD DE,INFOMSG
        CALL PRINT
        JP 0000H
SHOWRESULTS:LD DE,RESULTMSG
        CALL PRINT
        JP 0000H
SHOWPROFILES:LD DE,PROFILEMSG
        CALL PRINT
        JP 0000H
SHOWLIST:LD DE,LISTPLACE
        CALL PRINT
        JP 0000H
SHOWALL:LD A,12
        LD (DOFLAG),A
        LD DE,ALLMSG
        JP SCRATCH
SHOWSAFE:JP RUNSAFE
SHOWALLOC:LD A,13
        LD (DOFLAG),A
        LD DE,ALLOCMSG
        JP SCRATCH
SHOW0255:LD A,1               ;continue dispatches executable test
        LD (DOFLAG),A
        LD DE,MSG0255
        JP SCRATCH
SHOW0275:LD A,2               ;continue dispatches allocation-full test
        LD (DOFLAG),A
        LD DE,MSG0275
        JP SCRATCH
SHOW0276:LD A,3               ;continue dispatches exact-code test
        LD (DOFLAG),A
        LD DE,MSG0276
        JP SCRATCH
SHOW0292:LD A,4               ;continue dispatches release test
        LD (DOFLAG),A
        LD DE,MSG0292
        JP SCRATCH
SHOW0293:LD A,5               ;continue dispatches reuse observation
        LD (DOFLAG),A
        LD DE,MSG0293
        JP SCRATCH
SHOW0355:LD DE,MSG0355
        CALL PRINT
        JP 0000H
SHOW0379:LD A,6
        LD (DOFLAG),A
        LD DE,MSG0379
        JP SCRATCH
SHOW0380:LD A,7
        LD (DOFLAG),A
        LD DE,MSG0380
        JP SCRATCH
SHOW0381:LD A,8
        LD (DOFLAG),A
        LD DE,MSG0381
        JP SCRATCH
SHOW0382:LD A,9
        LD (DOFLAG),A
        LD DE,MSG0382
        JP SCRATCH
SHOW0383:LD A,10
        LD (DOFLAG),A
        LD DE,MSG0383
        JP SCRATCH
SHOW0384:LD A,11
        LD (DOFLAG),A
        LD DE,MSG0384
        JP SCRATCH
SHOW0558:LD DE,MSG0558
        CALL PRINT
        JP 0000H
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
        CP 1
        JP Z,RUN0255
        CP 2
        JP Z,RUN0275
        CP 3
        JP Z,RUN0276
        CP 4
        JP Z,RUN0292
        CP 5
        JP Z,RUN0293
        CP 6
        JP Z,RUN0379
        CP 7
        JP Z,RUN0380
        CP 8
        JP Z,RUN0381
        CP 9
        JP Z,RUN0382
        CP 10
        JP Z,RUN0383
        CP 11
        JP Z,RUN0384
        CP 12
        JP Z,RUNALL
        CP 13
        JP Z,RUNALLOC
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
        JP REPORT
FAIL0255:LD DE,MSG25FAIL
        JP REPORT

; Test 0275 - an allocating write must fail when D: has no free blocks.
;
; BTFULL.DAT contains 128 records.  Try random record 128, then require
; the old size and the identifying bytes in record 127 to remain unchanged.
; Function 13 is essential after the operator replaces the D: image.
RUN0275:LD C,13              ;log in the newly mounted scratch disk
        CALL BDOS
        LD HL,FCB0275
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,15              ;open D:BTFULL.DAT
        CALL BDOS
        CP 0FFH
        JP Z,ERR0275
        LD DE,DMABUF
        LD C,26
        CALL BDOS
        LD A,128             ;first record beyond the fixture file
        LD (WORKFCB+33),A
        XOR A
        LD (WORKFCB+34),A
        LD (WORKFCB+35),A
        LD DE,WORKFCB
        LD C,34              ;random write with zero fill
        CALL BDOS
        OR A
        JP Z,FAIL0275        ;success means allocation was wrongly possible
        LD DE,WORKFCB
        LD C,35              ;failed growth must not change logical size
        CALL BDOS
        LD A,(WORKFCB+33)
        CP 128
        JP NZ,FAIL0275
        LD A,(WORKFCB+34)
        OR A
        JP NZ,FAIL0275
        LD A,(WORKFCB+35)
        OR A
        JP NZ,FAIL0275
        LD HL,FCB0275        ;reopen from an unmodified FCB
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,15
        CALL BDOS
        CP 0FFH
        JP Z,FAIL0275
        LD A,127             ;verify the old last record remains readable
        LD (WORKFCB+33),A
        XOR A
        LD (WORKFCB+34),A
        LD (WORKFCB+35),A
        LD DE,WORKFCB
        LD C,33
        CALL BDOS
        OR A
        JP NZ,FAIL0275
        LD HL,DMABUF
        LD DE,LASTMARK
        LD B,8
CHK275: LD A,(DE)
        CP (HL)
        JP NZ,FAIL0275
        INC DE
        INC HL
        DEC B
        JP NZ,CHK275
        LD DE,PASS0275
        JP REPORT
FAIL0275:LD DE,MSG27FAIL
        JP REPORT
ERR0275:LD DE,MSG27ERR
        JP REPORT

; COPY36 - copy one complete CP/M 2.2 FCB.
; Entry: HL source, DE destination.  Exit: B=0.
COPY36: LD B,36
CPY36L:LD A,(HL)
        LD (DE),A
        INC HL
        INC DE
        DEC B
        JP NZ,CPY36L
        RET

; Test 0276 - exact allocation-full results from sequential and random write.
;
; Read record 127 first, then sequentially rewrite that identical record.  The
; next sequential write crosses the extent boundary and must return 02H.  A
; fresh FCB random write of record 128 must also return 02H.  Finally reopen
; the fixture and check its size and last-record marker.
RUN0276:LD C,13              ;forget any earlier view of replaced D:
        CALL BDOS
        LD HL,FCB0275
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,15
        CALL BDOS
        CP 0FFH
        JP Z,ERR0276
        LD DE,DMABUF
        LD C,26
        CALL BDOS
        LD A,127
        LD (WORKFCB+33),A
        XOR A
        LD (WORKFCB+34),A
        LD (WORKFCB+35),A
        LD DE,WORKFCB
        LD C,33              ;save the exact last record as write data
        CALL BDOS
        OR A
        JP NZ,FAIL0276
        LD HL,FCB0275
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,15
        CALL BDOS
        CP 0FFH
        JP Z,FAIL0276
        LD A,127
        LD (WORKFCB+32),A    ;sequential current-record field
        LD DE,WORKFCB
        LD C,21
        CALL BDOS            ;rewrite record 127 without changing it
        OR A
        JP NZ,FAIL0276
        LD DE,WORKFCB
        LD C,21
        CALL BDOS            ;first allocating sequential write
        CP 2
        JP NZ,FAIL0276
        LD HL,FCB0275
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,15
        CALL BDOS
        CP 0FFH
        JP Z,FAIL0276
        LD A,128
        LD (WORKFCB+33),A
        XOR A
        LD (WORKFCB+34),A
        LD (WORKFCB+35),A
        LD DE,WORKFCB
        LD C,34
        CALL BDOS            ;first allocating random write
        CP 2
        JP NZ,FAIL0276
        LD DE,WORKFCB
        LD C,35
        CALL BDOS
        LD A,(WORKFCB+33)
        CP 128
        JP NZ,FAIL0276
        LD A,(WORKFCB+34)
        OR A
        JP NZ,FAIL0276
        LD A,(WORKFCB+35)
        OR A
        JP NZ,FAIL0276
        LD HL,FCB0275
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,15
        CALL BDOS
        CP 0FFH
        JP Z,FAIL0276
        LD A,127
        LD (WORKFCB+33),A
        XOR A
        LD (WORKFCB+34),A
        LD (WORKFCB+35),A
        LD DE,WORKFCB
        LD C,33
        CALL BDOS
        OR A
        JP NZ,FAIL0276
        LD HL,DMABUF
        LD DE,LASTMARK
        LD B,8
CHK276: LD A,(DE)
        CP (HL)
        JP NZ,FAIL0276
        INC DE
        INC HL
        DEC B
        JP NZ,CHK276
        LD DE,PASS0276
        JP REPORT
FAIL0276:LD DE,MSG26FAIL
        JP REPORT
ERR0276:LD DE,MSG26ERR
        JP REPORT

; Test 0292 - deleting an allocated file releases its allocation block.
;
; The fixture is full and reserves one block in BTREL.DAT.  Remove that file,
; allocate one record to BTNEW.TST, then remove the probe and rebuild BTREL.
; Thus a passing run leaves the scratch disk full and ready for another run.
RUN0292:LD C,13              ;log in the newly mounted scratch disk
        CALL BDOS
        LD DE,RELBUF
        LD C,26
        CALL BDOS
        LD HL,FCBREL
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,19              ;release the reserved allocation block
        CALL BDOS
        CP 0FFH
        JP Z,ERR0292
        LD HL,FCBNEW
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,22
        CALL BDOS
        CP 0FFH
        JP Z,CLEAN292
        LD DE,WORKFCB
        LD C,21              ;must allocate the newly released block
        CALL BDOS
        OR A
        JP NZ,CLEAN292
        LD DE,WORKFCB
        LD C,16
        CALL BDOS
        CP 0FFH
        JP Z,CLEAN292
        LD HL,FCBNEW
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,19              ;remove the successful probe file
        CALL BDOS
        CP 0FFH
        JP Z,BADREST
        CALL RESTREL
        OR A
        JP NZ,BADREST
        LD DE,PASS0292
        JP REPORT
CLEAN292:LD HL,FCBNEW        ;best-effort removal after a failed probe
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,19
        CALL BDOS
        CALL RESTREL
        OR A
        JP NZ,BADREST
        LD DE,MSG92FAIL
        JP REPORT
BADREST:LD DE,MSG92ERR
        JP REPORT
ERR0292:LD DE,MSG92MISS
        JP REPORT

; RESTREL - recreate the one-record reservation file after item 0292.
; Exit: A=0 on complete restoration, A=FFH otherwise.
RESTREL:LD HL,FCBREL
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,22
        CALL BDOS
        CP 0FFH
        RET Z
        LD DE,WORKFCB
        LD C,21
        CALL BDOS
        OR A
        JP NZ,RESTBAD
        LD DE,WORKFCB
        LD C,16
        CALL BDOS
        CP 0FFH
        RET Z
        XOR A
        RET
RESTBAD:LD A,0FFH
        RET

; Test 0293 - observe whether the allocator reuses the exact freed block.
;
; Both outcomes are conforming.  This fixture normally has only the released
; block available, but the ledger deliberately does not require allocation
; order on systems having more than one valid free block.
RUN0293:LD C,13
        CALL BDOS
        LD DE,RELBUF
        LD C,26
        CALL BDOS
        LD HL,FCBREL
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,15              ;capture BTREL.DAT allocation entry zero
        CALL BDOS
        CP 0FFH
        JP Z,ERR293MISS
        LD A,(WORKFCB+16)
        OR A
        JP Z,ERR293MISS
        LD (OLDBLK),A
        LD HL,FCBREL
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,19
        CALL BDOS
        CP 0FFH
        JP Z,ERR293MISS
        LD HL,FCBNEW
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,22
        CALL BDOS
        CP 0FFH
        JP Z,CLEAN293
        LD DE,WORKFCB
        LD C,21
        CALL BDOS
        OR A
        JP NZ,CLEAN293
        LD DE,WORKFCB
        LD C,16
        CALL BDOS
        CP 0FFH
        JP Z,CLEAN293
        LD HL,FCBNEW
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,15
        CALL BDOS
        CP 0FFH
        JP Z,CLEAN293
        LD A,(WORKFCB+16)
        OR A
        JP Z,CLEAN293
        LD (NEWBLK),A
        LD HL,FCBNEW
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,19
        CALL BDOS
        CP 0FFH
        JP Z,ERR293RST
        CALL RESTREL
        OR A
        JP NZ,ERR293RST
        LD A,(OLDBLK)
        LD B,A
        LD A,(NEWBLK)
        CP B
        JP NZ,OBS293D
        LD DE,OBS293S
        JP REPORT
OBS293D:LD DE,OBS293N
        JP REPORT
CLEAN293:LD HL,FCBNEW
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,19
        CALL BDOS
        CALL RESTREL
        OR A
        JP NZ,ERR293RST
        LD DE,MSG93ERR
        JP REPORT
ERR293RST:LD DE,MSG93REST
        JP REPORT
ERR293MISS:LD DE,MSG93MISS
        JP REPORT

; SETPROT - select B: and place it in the software read-only vector.
; The former drive is saved so every probe can put the caller back where
; he started.  Function 13 also removes the temporary protection.
SETPROT:LD C,25
        CALL BDOS
        LD (OLDDRV),A
        LD E,1
        LD C,14
        CALL BDOS
        LD C,28
        CALL BDOS
        RET
GETRO:  LD C,29
        CALL BDOS
        LD A,L
        RET
RESETD: LD C,13
        CALL BDOS
        LD A,(OLDDRV)
        LD E,A
        LD C,14
        CALL BDOS
        RET

; Tests 0373-0378 - Function 28/29 convention and reset behavior.
; B: is protected only in memory.  No directory or data record is changed.
RUN0373:CALL SETPROT
        CALL GETRO
        AND 02H
        PUSH AF
        CALL RESETD
        POP AF
        LD DE,PASS0373
        JP NZ,REPORT
        LD DE,FAIL0373
        JP REPORT
RUN0374:CALL SETPROT
        LD C,13
        CALL BDOS
        CALL GETRO
        AND 02H
        PUSH AF
        CALL RESETD
        POP AF
        LD DE,PASS0374
        JP Z,REPORT
        LD DE,FAIL0374
        JP REPORT
RUN0375:CALL SETPROT
        CALL GETRO
        LD (LASTV),A
        CALL RESETD
        LD A,(LASTV)
        AND 02H
        LD DE,PASS0375
        JP NZ,REPORT
        LD DE,FAIL0375
        JP REPORT
RUN0376:CALL SETPROT
        CALL GETRO
        AND 02H
        PUSH AF
        CALL RESETD
        POP AF
        LD DE,PASS0376
        JP NZ,REPORT
        LD DE,FAIL0376
        JP REPORT
RUN0377:CALL SETPROT
        CALL GETRO
        AND 02H
        PUSH AF
        CALL RESETD
        POP AF
        LD DE,PASS0377
        JP NZ,REPORT
        LD DE,FAIL0377
        JP REPORT
RUN0378:CALL SETPROT
        LD C,13
        CALL BDOS
        CALL GETRO
        AND 02H
        PUSH AF
        CALL RESETD
        POP AF
        LD DE,PASS0378
        JP Z,REPORT
        LD DE,FAIL0378
REPORT: LD A,(ALLMODE)
        OR A
        JP Z,REPNORM
        CALL PRINTROW         ;omit each row's individual summary in /ALL
        RET
REPNORM:CALL PRINT
        JP 0000H

; SELD/PROTD - establish a fresh D: login, then apply software protection.
; A conforming mutation request normally enters the BDOS R/O error path and
; returns to the CCP without returning here.  If it does return, report FAIL.
SELD:   LD C,25
        CALL BDOS
        LD (OLDDRV),A
        LD C,13
        CALL BDOS
        LD E,3
        LD C,14
        CALL BDOS
        RET
PROTD:  LD C,28
        CALL BDOS
        RET
TERMFAIL:CALL RESETD
        LD DE,TERMFMSG
        CALL PRINT
        JP 0000H
TERMERR:CALL RESETD
        LD DE,TERMEMSG
        CALL PRINT
        JP 0000H

; Tests 0379-0384 deliberately request a mutation on protected D:.
; The expected result is the standard BDOS R/O diagnostic followed by CCP.
RUN0379:CALL SELD
        CALL PROTD
        LD DE,PEND0379
        CALL PRINT
        LD HL,FCBRONEW
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,22
        CALL BDOS
        JP TERMFAIL
RUN0380:CALL SELD
        LD DE,DMABUF
        LD C,26
        CALL BDOS
        LD HL,FCB0275
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,15
        CALL BDOS
        CP 0FFH
        JP Z,TERMERR
        CALL PROTD
        LD DE,PEND0380
        CALL PRINT
        LD DE,WORKFCB
        LD C,21
        CALL BDOS
        JP TERMFAIL
RUN0381:CALL SELD
        LD DE,DMABUF
        LD C,26
        CALL BDOS
        LD HL,FCB0275
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,15
        CALL BDOS
        CP 0FFH
        JP Z,TERMERR
        XOR A
        LD (WORKFCB+33),A
        LD (WORKFCB+34),A
        LD (WORKFCB+35),A
        CALL PROTD
        LD DE,PEND0381
        CALL PRINT
        LD DE,WORKFCB
        LD C,34
        CALL BDOS
        JP TERMFAIL
RUN0382:CALL SELD
        CALL PROTD
        LD DE,PEND0382
        CALL PRINT
        LD HL,FCBREL
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,19
        CALL BDOS
        JP TERMFAIL
RUN0383:CALL SELD
        CALL PROTD
        LD DE,PEND0383
        CALL PRINT
        LD HL,FCBREN
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,23
        CALL BDOS
        JP TERMFAIL
RUN0384:CALL SELD
        CALL PROTD
        LD DE,PEND0384
        CALL PRINT
        LD HL,FCBGUARD
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,22
        CALL BDOS
        JP TERMFAIL

; /ALL runs every check which returns control to DISKTEST.  The six protected
; mutation cases are necessarily separate: successful rejection warm-starts
; CP/M and therefore cannot return to an in-process batch driver.
RUNALL: LD A,1
        LD (ALLMODE),A
        LD DE,ALLHEAD
        CALL PRINT
        CALL RUN0155
        CALL RUN0255
        CALL RUN0275
        CALL RUN0276
        CALL RUN0292
        CALL RUN0293
        CALL RUN0373
        CALL RUN0374
        CALL RUN0375
        CALL RUN0376
        CALL RUN0377
        CALL RUN0378
        XOR A
        LD (ALLMODE),A
        LD DE,ALLDONE
        CALL PRINT
        JP 0000H

; Returning subsets use the same batch flag as /ALL.  REPORT then prints one
; compact row and returns here; individual selectors retain their own summary.
RUNSAFE:LD A,1
        LD (ALLMODE),A
        LD DE,SAFEHEAD
        CALL PRINT
        CALL RUN0155
        CALL RUN0373
        CALL RUN0374
        CALL RUN0375
        CALL RUN0376
        CALL RUN0377
        CALL RUN0378
        XOR A
        LD (ALLMODE),A
        LD DE,SAFEDONE
        CALL PRINT
        JP 0000H
RUNFN13:LD A,1
        LD (ALLMODE),A
        LD DE,FN13HEAD
        CALL PRINT
        CALL RUN0155
        CALL RUN0374
        CALL RUN0378
        XOR A
        LD (ALLMODE),A
        LD DE,FN13DONE
        CALL PRINT
        JP 0000H
RUNFN28:LD A,1
        LD (ALLMODE),A
        LD DE,FN28HEAD
        CALL PRINT
        CALL RUN0373
        CALL RUN0374
        CALL RUN0377
        XOR A
        LD (ALLMODE),A
        LD DE,FN28DONE
        CALL PRINT
        JP 0000H
RUNFN29:LD A,1
        LD (ALLMODE),A
        LD DE,FN29HEAD
        CALL PRINT
        CALL RUN0375
        CALL RUN0376
        XOR A
        LD (ALLMODE),A
        LD DE,FN29DONE
        CALL PRINT
        JP 0000H
RUNALLOC:LD A,1
        LD (ALLMODE),A
        LD DE,ALLOCHEAD
        CALL PRINT
        CALL RUN0255
        CALL RUN0275
        CALL RUN0276
        CALL RUN0292
        CALL RUN0293
        XOR A
        LD (ALLMODE),A
        LD DE,ALLOCDONE
        CALL PRINT
        JP 0000H
RUNPROTECT:LD A,1
        LD (ALLMODE),A
        LD DE,PROTHEAD
        CALL PRINT
        CALL RUN0373
        CALL RUN0374
        CALL RUN0375
        CALL RUN0376
        CALL RUN0377
        CALL RUN0378
        XOR A
        LD (ALLMODE),A
        LD DE,PROTDONE
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
        JP REPORT
FAIL0155:LD DE,FAILMSG
        JP REPORT

; PRINT - send a '$'-terminated string to the console.
; Entry: DE addresses text.  Exit: registers are whatever BDOS leaves.
; Keep CALL/RET here: this is the sequence proved by dev19 on Montezuma.
PRINT:  LD C,9
        CALL BDOS
        RET

; PRINTROW - print the heading, rule, and result row, stopping after line 3.
; This keeps /ALL to one final authoritative Summary line.
PRINTROW:EX DE,HL
        LD B,4               ;blank, heading, rule, result
PROWLP:LD A,(HL)
        CP '$'
        RET Z
        INC HL
        PUSH HL
        PUSH BC
        PUSH AF
        LD E,A
        LD C,2
        CALL BDOS
        POP AF
        POP BC
        POP HL
        CP 10
        JP NZ,PROWLP
        DEC B
        JP NZ,PROWLP
        RET

HELPMSG:DB 13,10,'DISKTEST 0.1.0-dev35',13,10,13,10
        DB '  DISKTEST /NNNN   Run or explain one ledger item',13,10
        DB '  DISKTEST /SAFE   Run non-destructive returning checks',13,10
        DB '  DISKTEST /ALL    Run all returning checks and observations',13,10
        DB '  DISKTEST /FN:n   Run returning checks for BDOS function n',13,10
        DB '  DISKTEST /GROUP:ALLOC|PROTECT   Run one group',13,10
        DB '  DISKTEST /LIST   List implemented ledger items',13,10
        DB '  DISKTEST /H      Show this help',13,10
        DB '  DISKTEST /H:RESULTS or /H:PROFILES   Topic help',13,10
        DB '  DISKTEST /INFO   Show build information',13,10,13,10
        DB 'Automated: 0155, 0255, 0275, 0276, 0292.',13,10
        DB 'Automated: 0373, 0374, 0375, 0376, 0377, 0378.',13,10
        DB 'Observed: 0293 (not guaranteed).',13,10,'$'
LISTPLACE:DB 13,10,'0155  REQUIRED  Function 13 user-number preservation',13,10
        DB '0255  REQUIRED  Data-full empty Make',13,10
        DB '0275  REQUIRED  Allocation-full failure',13,10
        DB '0276  REQUIRED  Exact write failure codes',13,10
        DB '0292  REQUIRED  Allocation release',13,10
        DB '0293  NOT GUAR. Exact freed-block reuse',13,10
        DB '0355  OUT SCOPE Physical allocation versus virtual size',13,10
        DB '0373  REQUIRED  Function 28 convention',13,10
        DB '0374  REQUIRED  Function 28 transience',13,10
        DB '0375  REQUIRED  Function 29 convention',13,10
        DB '0376  REQUIRED  Read-only vector mapping',13,10
        DB '0377  REQUIRED  Function 28 vector effect',13,10
        DB '0378  REQUIRED  Reset clears software protection',13,10
        DB '0379  REQUIRED  Protected-disk Make',13,10
        DB '0380  REQUIRED  Protected sequential write',13,10
        DB '0381  REQUIRED  Protected random write',13,10
        DB '0382  REQUIRED  Protected-disk Delete',13,10
        DB '0383  REQUIRED  Protected-disk Rename',13,10
        DB '0384  REQUIRED  Protection before mutation',13,10
        DB '0558  OUT SCOPE Allocation order across lifecycles',13,10,'$'
INFOMSG:DB 13,10,'BetterCP/M DISKTEST 0.1.0-dev35',13,10
        DB 'Commands: /NNNN /SAFE /ALL /FN /GROUP /LIST /H /INFO',13,10
        DB 'Ledger items represented: 20; remaining: 0',13,10
        DB 'Returning checks/observations: 12; terminal checks: 6',13,10
        DB 'Required: 17; not guaranteed: 1; outside scope: 2',13,10
        DB 'Ledger coverage: 20 of 20',13,10,'$'
ALLMSG:DB 13,10,'/ALL requires the supplied scratch disk in D:.',13,10,'$'
ALLHEAD:DB 13,10,'DISKTEST /ALL - returning checks and observations',13,10,'$'
ALLDONE:DB 13,10,'Summary: 11 pass, 0 fail, 0 error, 1 observation',13,10
        DB 'Run terminal rows 0379-0384 separately.',13,10,'$'
RESULTMSG:DB 13,10,'DISKTEST result terminology',13,10,13,10
        DB 'STATUS: PASS matched; FAIL mismatched; UNTESTED did not run.',13,10
        DB 'CLASS: REQUIRED affects baseline; NOT GUAR. is informational.',13,10
        DB 'OUT SCOPE means DISKTEST cannot execute or judge the item.',13,10
        DB 'OBSERVED records evidence or the next command required.',13,10
        DB 'A Summary counts completed rows; terminal rows run separately.',13,10,'$'
PROFILEMSG:DB 13,10,'DISKTEST fixtures and equipment',13,10,13,10
        DB 'No named compatibility profiles are defined.',13,10
        DB 'B: holds DISKTEST; allocation checks use restorable D:.',13,10
        DB 'Never substitute a disk containing unique files for D:.',13,10
        DB 'Rows 0379-0384 intentionally return through the BDOS R/O path.',13,10,'$'
SAFEHEAD:DB 13,10,'DISKTEST /SAFE - non-destructive returning checks',13,10,'$'
SAFEDONE:DB 13,10,'Summary: 7 pass, 0 fail, 0 error, 0 observations',13,10,'$'
FN13HEAD:DB 13,10,'DISKTEST /FN:13 - Function 13 checks',13,10,'$'
FN13DONE:DB 13,10,'Summary: 3 pass, 0 fail, 0 error, 0 observations',13,10,'$'
FN28HEAD:DB 13,10,'DISKTEST /FN:28 - returning Function 28 checks',13,10,'$'
FN28DONE:DB 13,10,'Summary: 3 pass, 0 fail, 0 error, 0 observations',13,10
        DB 'Run terminal rows 0379-0384 separately.',13,10,'$'
FN29HEAD:DB 13,10,'DISKTEST /FN:29 - Function 29 checks',13,10,'$'
FN29DONE:DB 13,10,'Summary: 2 pass, 0 fail, 0 error, 0 observations',13,10,'$'
ALLOCMSG:DB 13,10,'Allocation group requires the supplied D: disk.',13,10,'$'
ALLOCHEAD:DB 13,10,'DISKTEST /GROUP:ALLOC - allocation checks',13,10,'$'
ALLOCDONE:DB 13,10,'Summary: 4 pass, 0 fail, 0 error, 1 observation',13,10
        DB 'Rows 0355 and 0558 are outside executable scope.',13,10,'$'
PROTHEAD:DB 13,10,'DISKTEST /GROUP:PROTECT - returning protection checks',13,10,'$'
PROTDONE:DB 13,10,'Summary: 6 pass, 0 fail, 0 error, 0 observations',13,10
        DB 'Run terminal rows 0379-0384 separately.',13,10,'$'
PASSMSG:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0155  PASS      REQUIRED      Function 13 preserved user number',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
FAILMSG:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0155  FAIL      REQUIRED      Function 13 changed user number',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

; The following entries require a replaceable D: image.  All five execute
; after consent.  Item 0293 records an observation, not a pass or failure.
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
PASS0275:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0275  PASS      REQUIRED      Growth failed; old file intact',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
MSG27FAIL:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0275  FAIL      REQUIRED      Growth succeeded or changed file',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'
MSG27ERR:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0275  ERROR     REQUIRED      D:BTFULL.DAT could not be opened',13,10
        DB 'Summary: 0 pass, 0 fail, 1 error, 0 observations',13,10,'$'
PASS0276:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0276  PASS      REQUIRED      Sequential=02h, random=02h',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
MSG26FAIL:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0276  FAIL      REQUIRED      Wrong code or fixture changed',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'
MSG26ERR:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0276  ERROR     REQUIRED      D:BTFULL.DAT could not be opened',13,10
        DB 'Summary: 0 pass, 0 fail, 1 error, 0 observations',13,10,'$'
PASS0292:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0292  PASS      REQUIRED      Released block was reusable',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
MSG92FAIL:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0292  FAIL      REQUIRED      Released block was unavailable',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'
MSG92ERR:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0292  ERROR     REQUIRED      Scratch fixture not restored',13,10
        DB 'Summary: 0 pass, 0 fail, 1 error, 0 observations',13,10,'$'
MSG92MISS:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0292  ERROR     REQUIRED      D:BTREL.DAT was not found',13,10
        DB 'Summary: 0 pass, 0 fail, 1 error, 0 observations',13,10,'$'
OBS293S:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0293  OBSERVED  NOT GUAR.     Same freed block was reused',13,10
        DB 'Summary: 0 pass, 0 fail, 0 error, 1 observation',13,10,'$'
OBS293N:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0293  OBSERVED  NOT GUAR.     Different free block was used',13,10
        DB 'Summary: 0 pass, 0 fail, 0 error, 1 observation',13,10,'$'
MSG93ERR:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0293  ERROR     NOT GUAR.     Reuse probe could not complete',13,10
        DB 'Summary: 0 pass, 0 fail, 1 error, 0 observations',13,10,'$'
MSG93REST:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0293  ERROR     NOT GUAR.     Scratch fixture not restored',13,10
        DB 'Summary: 0 pass, 0 fail, 1 error, 0 observations',13,10,'$'
MSG93MISS:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0293  ERROR     NOT GUAR.     D:BTREL.DAT was not usable',13,10
        DB 'Summary: 0 pass, 0 fail, 1 error, 0 observations',13,10,'$'
MSG0355:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0355  UNTESTED  OUT SCOPE     Physical allocation is not portable',13,10
        DB 'DISKTEST cannot assign a portable PASS or FAIL to this item.',13,10
        DB 'Summary: 0 pass, 0 fail, 0 error, 0 observations',13,10,'$'
PASS0373:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0373  PASS      REQUIRED      Function 28 protected current disk',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
FAIL0373:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0373  FAIL      REQUIRED      Function 28 did not protect disk',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'
PASS0374:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0374  PASS      REQUIRED      Protection ended after disk reset',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
FAIL0374:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0374  FAIL      REQUIRED      Protection survived disk reset',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'
PASS0375:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0375  PASS      REQUIRED      Function 29 returned R/O vector',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
FAIL0375:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0375  FAIL      REQUIRED      Function 29 omitted protected disk',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'
PASS0376:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0376  PASS      REQUIRED      Vector bit 1 represented drive B',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
FAIL0376:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0376  FAIL      REQUIRED      Drive B did not map to vector bit 1',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'
PASS0377:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0377  PASS      REQUIRED      Function 28 set drive-B vector bit',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
FAIL0377:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0377  FAIL      REQUIRED      Function 28 left vector bit clear',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'
PASS0378:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0378  PASS      REQUIRED      Function 13 cleared R/O vector',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
FAIL0378:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0378  FAIL      REQUIRED      Function 13 left R/O vector set',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'
MSG0379:DB 13,10,'0379  TERMINAL  REQUIRED      Protected-disk Make',13,10,'$'
MSG0380:DB 13,10,'0380  TERMINAL  REQUIRED      Protected sequential write',13,10,'$'
MSG0381:DB 13,10,'0381  TERMINAL  REQUIRED      Protected random write',13,10,'$'
MSG0382:DB 13,10,'0382  TERMINAL  REQUIRED      Protected-disk Delete',13,10,'$'
MSG0383:DB 13,10,'0383  TERMINAL  REQUIRED      Protected-disk Rename',13,10,'$'
MSG0384:DB 13,10,'0384  TERMINAL  REQUIRED      Protection before mutation',13,10,'$'
PEND0379:DB 13,10,'0379: requesting Make on protected D:.',13,10
        DB 'EXPECTED: BDOS R/O rejection, then a usable CCP prompt.',13,10,'$'
PEND0380:DB 13,10,'0380: requesting sequential write on protected D:.',13,10
        DB 'EXPECTED: BDOS R/O rejection, then a usable CCP prompt.',13,10,'$'
PEND0381:DB 13,10,'0381: requesting random write on protected D:.',13,10
        DB 'EXPECTED: BDOS R/O rejection, then a usable CCP prompt.',13,10,'$'
PEND0382:DB 13,10,'0382: requesting Delete on protected D:.',13,10
        DB 'EXPECTED: BDOS R/O rejection, then a usable CCP prompt.',13,10,'$'
PEND0383:DB 13,10,'0383: requesting Rename on protected D:.',13,10
        DB 'EXPECTED: BDOS R/O rejection, then a usable CCP prompt.',13,10,'$'
PEND0384:DB 13,10,'0384: requesting mutation after protecting D:.',13,10
        DB 'EXPECTED: BDOS R/O rejection before any disk change.',13,10,'$'
TERMFMSG:DB 13,10,'FAIL: protected mutation returned without R/O rejection.',13,10,'$'
TERMEMSG:DB 13,10,'ERROR: the protected-disk fixture could not be opened.',13,10,'$'
MSG0558:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0558  UNTESTED  OUT SCOPE     Allocation order is not portable',13,10
        DB 'DISKTEST cannot assign a portable PASS or FAIL to this item.',13,10
        DB 'Summary: 0 pass, 0 fail, 0 error, 0 observations',13,10,'$'
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
LASTV:  DB 0
OLDBLK: DB 0
NEWBLK: DB 0
ALLMODE:DB 0
DOFLAG: DB 0
PROCPTR:DW 0
; Explicit D: FCB for EMPTY.TST.  Remaining fields begin at zero.
FCB0255:DB 4,'EMPTY   ','TST'
        DS 24,0
; Immutable template and working FCB for D:BTFULL.DAT.
FCB0275:DB 4,'BTFULL  ','DAT'
        DS 24,0
FCBREL: DB 4,'BTREL   ','DAT'
        DS 24,0
FCBNEW: DB 4,'BTNEW   ','TST'
        DS 24,0
FCBRONEW:DB 4,'ROTEST  ','TST'
        DS 24,0
FCBGUARD:DB 4,'ROGUARD ','TST'
        DS 24,0
FCBREN: DB 4,'BTREL   ','DAT',0,0,0,0
        DB 0,'BTREN   ','DAT'
        DS 8,0
WORKFCB:DS 36
LASTMARK:DB 'FULL-127'
DMABUF: DS 128
RELBUF: DS 128,0
        DS 64
STACKTOP:
        END
