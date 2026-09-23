; SPDX-License-Identifier: GPL-2.0-or-later

; ********************************************************************************
; *                   CP/M 2.2 Conformance Suite -- DISKTEST                    *
; *                                                                              *
; * Exercises disk-system state, allocation exhaustion, block release, software *
; * write protection, reset behavior, and selected terminal mutation paths.     *
; * Destructive checks require an explicitly prepared replaceable scratch disk  *
; * before any disk I/O is attempted.                                            *
; ********************************************************************************

  ; Version 0.1.0-dev42

  ; Assemble with ZSM4 and Digital Research LINK using the 8080 subset.
  ; Run under CP/M 2.2 as:  DISKTEST /selector

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
  ;   dev38   ask for the prepared scratch drive; remove fixed D: use
  ;   dev40   implement the finalized exact command and group interface
  ;   dev41   append failed selectors and avoid a contradictory zero-fail summary
  ;

  ; Notes for modifiers:
  ;   The command tail is at 0080H/0081H in the usual CP/M form.
  ;   All messages passed to function 9 must end in a dollar sign.
  ;   Every exit is a warm start through location 0000H.
  ;   Destructive tests ask for a prepared scratch drive before any I/O.
  ;

  ; LINK establishes the CP/M transient load address at 0100h.
BDOS    EQU 0005H

; ================================================================================
; =                     Command Interface and Static Catalog                     =
; =                                                                              =
; = Parses exact selectors and presents help, catalog, group, result, profile,   =
; = safe, required, observation, allocation, protection, and individual test     =
; = views.                                                                       =
; ================================================================================

  ; Enter from CCP.  Copy and fold exactly one selector, rejecting any second
  ; token before dispatch.  This prevents abbreviations from selecting a test.

START:  LD SP,STACKTOP       ;do not depend on CCP stack
        LD A,(0080H)
        OR A
        JP Z,SHOWHELP
        CALL GETARG
        JP NZ,SHOWBAD
        LD DE,SH
        CALL ARGIS
        JP Z,SHOWHELP
        LD DE,SHELP
        CALL ARGIS
        JP Z,SHOWHELP
        LD DE,SLIST
        CALL ARGIS
        JP Z,SHOWLIST
        LD DE,SALL
        CALL ARGIS
        JP Z,SHOWALL
        LD DE,SSAFE
        CALL ARGIS
        JP Z,SHOWSAFE
        LD DE,SINFO
        CALL ARGIS
        JP Z,SHOWINFO
        LD DE,SVER
        CALL ARGIS
        JP Z,SHOWVERSION
        LD DE,SVERSION
        CALL ARGIS
        JP Z,SHOWVERSION
        LD DE,SGLIST
        CALL ARGIS
        JP Z,SHOWGROUPS
        LD DE,SGSTATE
        CALL ARGIS
        JP Z,RUNSTATE
        LD DE,SGALLOC
        CALL ARGIS
        JP Z,SHOWALLOC
        LD DE,SGPROTECT
        CALL ARGIS
        JP Z,RUNPROTECT
        LD DE,SGREQ
        CALL ARGIS
        JP Z,SHOWREQUIRED
        LD DE,SGOBS
        CALL ARGIS
        JP Z,SHOWOBSERVATION
        LD DE,SGMAN
        CALL ARGIS
        JP Z,RUNMANUAL
        LD DE,SFN13
        CALL ARGIS
        JP Z,RUNFN13
        LD DE,SFN28
        CALL ARGIS
        JP Z,RUNFN28
        LD DE,SFN29
        CALL ARGIS
        JP Z,RUNFN29
        LD DE,SHR
        CALL ARGIS
        JP Z,SHOWRESULTS
        LD DE,SHP
        CALL ARGIS
        JP Z,SHOWPROFILES
        CALL ITEMARG
        JP Z,RUNONE
        JP SHOWBAD

; -------------------------------------------------------------------------------
; Command Argument Parser
; -------------------------------------------------------------------------------

  ; Copy one case-insensitive token from the CCP command tail.

GETARG: XOR A                           ; parse command argument
        LD (ARGBUF),A
        LD A,(0080H)
        OR A
        RET Z
        LD B,A
        LD HL,0081H

PSKIP: LD A,(HL)                        ; pskip
        CP ' '
        JP NZ,PSTART
        INC HL
        DEC B
        JP NZ,PSKIP
        XOR A
        RET

PSTART:LD DE,ARGBUF                     ; pstart

PCOPY: LD A,B                           ; pcopy
        OR A
        JP Z,PDONE
        LD A,(HL)
        CP ' '
        JP Z,PTRAIL
        CP 'a'
        JP C,PSTORE
        CP 'z'+1
        JP NC,PSTORE
        SUB 20H

PSTORE:LD (DE),A                        ; pstore
        INC DE
        INC HL
        DEC B
        JP PCOPY

PTRAIL:INC HL                           ; ptrail
        DEC B

PTRLP: LD A,B                           ; ptrlp
        OR A
        JP Z,PDONE
        LD A,(HL)
        CP ' '
        JP NZ,PBAD
        INC HL
        DEC B
        JP PTRLP

PDONE: XOR A                            ; pdone
        LD (DE),A
        RET

PBAD:  OR 1                             ; pbad
        RET

ARGIS: LD HL,ARGBUF                     ; argis

PACMP: LD A,(DE)                        ; pacmp
        CP (HL)
        RET NZ
        OR A
        RET Z
        INC DE
        INC HL
        JP PACMP

; -------------------------------------------------------------------------------
; Numeric Selector
; -------------------------------------------------------------------------------

  ; Accept /NNNN and /NNNN:REPORT only.

ITEMARG:XOR A                           ; parse numeric item selector
        LD (REPORTMODE),A
        LD HL,ARGBUF
        LD A,(HL)
        CP '/'
        RET NZ
        INC HL
        LD B,4
        LD DE,0
        EX DE,HL
        LD (ITEMNO),HL
        EX DE,HL

PNUM:  LD A,(HL)                        ; pnum
        CP '0'
        JP C,PIBAD
        CP '9'+1
        JP NC,PIBAD
        SUB '0'
        LD C,A
        PUSH HL
        LD HL,(ITEMNO)
        ADD HL,HL
        PUSH HL
        ADD HL,HL
        ADD HL,HL
        POP DE
        ADD HL,DE
        LD E,C
        LD D,0
        ADD HL,DE
        LD (ITEMNO),HL
        POP HL
        INC HL
        DEC B
        JP NZ,PNUM
        LD A,(HL)
        OR A
        RET Z
        LD DE,SREPORT

PIRPT: LD A,(DE)                        ; pirpt
        CP (HL)
        JP NZ,PIBAD
        OR A
        JP Z,PIROK
        INC DE
        INC HL
        JP PIRPT

PIROK: LD A,1                           ; pirok
        LD (REPORTMODE),A
        XOR A
        RET

PIBAD: OR 1                             ; pibad
        RET

; -------------------------------------------------------------------------------
; Single-Item Selection
; -------------------------------------------------------------------------------

  ; Locate the selected ledger number and jump to its established handler.

RUNONE: LD HL,ITEMTAB                   ; run one catalog item
        LD B,20

RONEXT:LD E,(HL)                        ; ronext
        INC HL
        LD D,(HL)
        INC HL
        PUSH HL
        LD HL,(ITEMNO)
        LD A,H
        CP D
        JP NZ,ROMISS
        LD A,L
        CP E
        JP Z,ROFOUND

ROMISS:POP HL                           ; romiss
        INC HL
        INC HL
        DEC B
        JP NZ,RONEXT
        JP SHOWBAD

ROFOUND:POP HL                          ; rofound
        LD E,(HL)
        INC HL
        LD D,(HL)
        EX DE,HL
        JP (HL)

; -------------------------------------------------------------------------------
; Display Commands and Groups
; -------------------------------------------------------------------------------

  ; common display exits.  strings are terminated by '$'.

SHOWHELP:LD DE,HELPMSG                  ; display command help
        CALL PRINT
        JP 0000H

SHOWINFO:LD DE,INFOMSG                  ; display suite information
        CALL PRINT
        JP 0000H

SHOWVERSION:LD DE,VERMSG                ; display suite version
        CALL PRINT
        JP 0000H

SHOWGROUPS:LD DE,GRPLIST                ; display functional groups
        CALL PRINT
        JP 0000H

SHOWRESULTS:LD DE,RESULTMSG             ; display result help
        CALL PRINT
        JP 0000H

SHOWPROFILES:LD DE,PROFILEMSG           ; display profile help
        CALL PRINT
        JP 0000H

SHOWLIST:LD DE,LISTPLACE                ; display catalog list
        CALL PRINT
        JP 0000H

SHOWALL:LD A,12                         ; run complete returning aggregate
        LD (DOFLAG),A
        LD DE,ALLMSG
        JP SCRATCH

SHOWSAFE:JP RUNSAFE                     ; run safe aggregate

SHOWALLOC:LD A,13                       ; run allocation group
        LD (DOFLAG),A
        LD DE,ALLOCMSG
        JP SCRATCH

SHOWREQUIRED:LD A,14                    ; showrequired
        LD (DOFLAG),A
        LD DE,REQMSG
        JP SCRATCH

SHOWOBSERVATION:LD A,15                 ; showobservation
        LD (DOFLAG),A
        LD DE,OBSMSG
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

SHOW0355:LD DE,MSG0355                  ; show0355
        JP SHOWSTATIC

SHOW0379:LD A,6                         ; show0379
        LD (DOFLAG),A
        LD DE,MSG0379
        JP SCRATCH

SHOW0380:LD A,7                         ; show0380
        LD (DOFLAG),A
        LD DE,MSG0380
        JP SCRATCH

SHOW0381:LD A,8                         ; show0381
        LD (DOFLAG),A
        LD DE,MSG0381
        JP SCRATCH

SHOW0382:LD A,9                         ; show0382
        LD (DOFLAG),A
        LD DE,MSG0382
        JP SCRATCH

SHOW0383:LD A,10                        ; show0383
        LD (DOFLAG),A
        LD DE,MSG0383
        JP SCRATCH

SHOW0384:LD A,11                        ; show0384
        LD (DOFLAG),A
        LD DE,MSG0384
        JP SCRATCH

SHOW0558:LD DE,MSG0558                  ; show0558

SHOWSTATIC:                             ; showstatic
        CALL PRINT
        LD A,(REPORTMODE)
        OR A
        JP Z,STATDONE
        LD DE,REPORTMSG
        CALL PRINT

STATDONE:                               ; statdone
        JP 0000H

SHOWBAD:LD DE,BADMSG                    ; showbad
        CALL PRINT
        JP 0000H

; ================================================================================
; =                       Prepared Scratch-Disk Selection                        =
; =                                                                              =
; = Obtains an operator-approved replaceable scratch drive and applies it to     =
; = immutable FCB templates before any destructive or allocation-sensitive I/O.  =
; ================================================================================
; -------------------------------------------------------------------------------
; Scratch Drive Gate
; -------------------------------------------------------------------------------

  ; SCRATCH - obtain a prepared scratch-drive letter before destructive I/O.
  ; Entry: DE addresses the selected procedure.  Q performs no disk I/O.

SCRATCH:EX DE,HL             ;8080-compatible save of procedure
        LD (PROCPTR),HL
        EX DE,HL

ASKSCR: LD DE,ASKMSG                    ; askscr
        CALL PRINT
        LD C,1               ;console input with echo
        CALL BDOS
        AND 5FH              ;accept lower case also
        CP 'Q'
        JP Z,QUITSCR
        CP 'B'               ;A: may hold the system; accept B: through P:
        JP C,ASKSCR
        CP 'P'+1
        JP NC,ASKSCR
        SUB 'A'              ;BDOS select code: A:=0 ... P:=15
        LD (SCRDRV),A
        INC A                ;FCB drive code: default=0, A:=1 ... P:=16
        LD (SCRFCB),A
        CALL SETFCBS
        JP DOPROC

QUITSCR:                                ; quitscr
        LD DE,BYPASSMSG
        CALL PRINT
        JP 0000H

; -------------------------------------------------------------------------------
; Scratch FCB Setup
; -------------------------------------------------------------------------------

  ; SETFCBS - apply the chosen drive to every immutable FCB template.
  ; Rename has a second drive byte at offset 16; CP/M requires that destination
  ; drive to match the source for this same-disk conformance probe.

SETFCBS:LD A,(SCRFCB)                   ; apply selected scratch drive
        LD (FCB0255),A
        LD (FCB0275),A
        LD (FCBREL),A
        LD (FCBNEW),A
        LD (FCBRONEW),A
        LD (FCBGUARD),A
        LD (FCBREN),A
        LD (FCBREN+16),A
        RET

DOPROC: LD A,(DOFLAG)                   ; doproc
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
        CP 14
        JP Z,RUNREQUIRED
        CP 15
        JP Z,RUNOBSERVATION
        LD HL,(PROCPTR)      ;8080-compatible reload through h,l
        EX DE,HL
        CALL PRINT
        JP 0000H

; ================================================================================
; =                         Allocation-Exhaustion Tests                          =
; =                                                                              =
; = Exercises empty-file creation, failed allocating writes, exact               =
; = sequential/random full-disk codes, block release, and diagnostic freed-block =
; = reuse on controlled media.                                                   =
; ================================================================================
; -------------------------------------------------------------------------------
; Item 0255 -- Empty File on Full Disk
; -------------------------------------------------------------------------------

  ; Test 0255 - Make an empty file when no data blocks remain.
  ;
  ; The chosen drive is named explicitly in the FCB; the caller's selected disk
  ; is not changed.  A successful Make consumes a directory entry but no block.
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

FAIL0255:LD HL,255                      ; fail0255
        CALL LOGFAIL
        LD DE,MSG25FAIL
        JP REPORT

; -------------------------------------------------------------------------------
; Item 0275 -- Allocating Write on Full Disk
; -------------------------------------------------------------------------------

  ; Test 0275 - an allocating write must fail when the scratch disk is full.
  ;
  ; BTFULL.DAT contains 128 records.  Try random record 128, then require
  ; the old size and the identifying bytes in record 127 to remain unchanged.
  ; Function 13 is essential after the operator replaces the scratch medium.

RUN0275:LD C,13              ;log in the newly mounted scratch disk
        CALL BDOS
        LD HL,FCB0275
        LD DE,WORKFCB
        CALL COPY36
        LD DE,WORKFCB
        LD C,15              ;open BTFULL.DAT on the chosen scratch drive
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

CHK275: LD A,(DE)                       ; chk275
        CP (HL)
        JP NZ,FAIL0275
        INC DE
        INC HL
        DEC B
        JP NZ,CHK275
        LD DE,PASS0275
        JP REPORT

FAIL0275:LD HL,275                      ; fail0275
        CALL LOGFAIL
        LD DE,MSG27FAIL
        JP REPORT

ERR0275:LD DE,MSG27ERR                  ; err0275
        JP REPORT

  ; COPY36 - copy one complete CP/M 2.2 FCB.
  ; Entry: HL source, DE destination.  Exit: B=0.

COPY36: LD B,36                         ; copy36

CPY36L:LD A,(HL)                        ; cpy36l
        LD (DE),A
        INC HL
        INC DE
        DEC B
        JP NZ,CPY36L
        RET

; -------------------------------------------------------------------------------
; Item 0276 -- Exact Allocation-Full Results
; -------------------------------------------------------------------------------

  ; Test 0276 - exact allocation-full results from sequential and random write.
  ;
  ; Read record 127 first, then sequentially rewrite that identical record.  The
  ; next sequential write crosses the extent boundary and must return 02H.  A
  ; fresh FCB random write of record 128 must also return 02H.  Finally reopen
  ; the fixture and check its size and last-record marker.

RUN0276:LD C,13              ;forget any earlier view of replaced media
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

CHK276: LD A,(DE)                       ; chk276
        CP (HL)
        JP NZ,FAIL0276
        INC DE
        INC HL
        DEC B
        JP NZ,CHK276
        LD DE,PASS0276
        JP REPORT

FAIL0276:LD HL,276                      ; fail0276
        CALL LOGFAIL
        LD DE,MSG26FAIL
        JP REPORT

ERR0276:LD DE,MSG26ERR                  ; err0276
        JP REPORT

; -------------------------------------------------------------------------------
; Item 0292 -- Released Allocation Block
; -------------------------------------------------------------------------------

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
        LD HL,292
        CALL LOGFAIL
        LD DE,MSG92FAIL
        JP REPORT

BADREST:LD DE,MSG92ERR                  ; badrest
        JP REPORT

ERR0292:LD DE,MSG92MISS                 ; err0292
        JP REPORT

  ; RESTREL - recreate the one-record reservation file after item 0292.
  ; Exit: A=0 on complete restoration, A=FFH otherwise.

RESTREL:LD HL,FCBREL                    ; restrel
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

RESTBAD:LD A,0FFH                       ; restbad
        RET

; -------------------------------------------------------------------------------
; Item 0293 -- Freed-Block Reuse Observation
; -------------------------------------------------------------------------------

  ; Test 0293 - observe whether the allocator reuses the exact freed block.
  ;
  ; Both outcomes are conforming.  This fixture normally has only the released
  ; block available, but the ledger deliberately does not require allocation
  ; order on systems having more than one valid free block.

RUN0293:LD C,13                         ; observe freed-block reuse
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

OBS293D:LD DE,OBS293N                   ; obs293d
        JP REPORT

CLEAN293:LD HL,FCBNEW                   ; clean293
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

ERR293RST:LD DE,MSG93REST               ; err293rst
        JP REPORT

ERR293MISS:LD DE,MSG93MISS              ; err293miss
        JP REPORT

; ================================================================================
; =                     Software Write Protection and Reset                      =
; =                                                                              =
; = Temporarily places the scratch drive in the software read-only vector,       =
; = exercises Functions 28 and 29, and restores the caller's selected drive and  =
; = protection state.                                                            =
; ================================================================================
; -------------------------------------------------------------------------------
; Software Read-Only Setup
; -------------------------------------------------------------------------------

  ; SETPROT - select B: and place it in the software read-only vector.
  ; The former drive is saved so every probe can put the caller back where
  ; he started.  Function 13 also removes the temporary protection.

SETPROT:LD C,25                         ; install temporary software write protection
        CALL BDOS
        LD (OLDDRV),A
        LD E,1
        LD C,14
        CALL BDOS
        LD C,28
        CALL BDOS
        RET

GETRO:  LD C,29                         ; getro
        CALL BDOS
        LD A,L
        RET

RESETD: LD C,13                         ; resetd
        CALL BDOS
        LD A,(OLDDRV)
        LD E,A
        LD C,14
        CALL BDOS
        RET

; -------------------------------------------------------------------------------
; Functions 28/29 and Reset Behavior
; -------------------------------------------------------------------------------

  ; Tests 0373-0378 - Function 28/29 convention and reset behavior.
  ; B: is protected only in memory.  No directory or data record is changed.

RUN0373:CALL SETPROT                    ; run Function-28/29 test
        CALL GETRO
        AND 02H
        PUSH AF
        CALL RESETD
        POP AF
        LD DE,PASS0373
        JP NZ,REPORT
        LD HL,373
        CALL LOGFAIL
        LD DE,FAIL0373
        JP REPORT

RUN0374:CALL SETPROT                    ; run0374
        LD C,13
        CALL BDOS
        CALL GETRO
        AND 02H
        PUSH AF
        CALL RESETD
        POP AF
        LD DE,PASS0374
        JP Z,REPORT
        LD HL,374
        CALL LOGFAIL
        LD DE,FAIL0374
        JP REPORT

RUN0375:CALL SETPROT                    ; run0375
        CALL GETRO
        LD (LASTV),A
        CALL RESETD
        LD A,(LASTV)
        AND 02H
        LD DE,PASS0375
        JP NZ,REPORT
        LD HL,375
        CALL LOGFAIL
        LD DE,FAIL0375
        JP REPORT

RUN0376:CALL SETPROT                    ; run0376
        CALL GETRO
        AND 02H
        PUSH AF
        CALL RESETD
        POP AF
        LD DE,PASS0376
        JP NZ,REPORT
        LD HL,376
        CALL LOGFAIL
        LD DE,FAIL0376
        JP REPORT

RUN0377:CALL SETPROT                    ; run0377
        CALL GETRO
        AND 02H
        PUSH AF
        CALL RESETD
        POP AF
        LD DE,PASS0377
        JP NZ,REPORT
        LD HL,377
        CALL LOGFAIL
        LD DE,FAIL0377
        JP REPORT

RUN0378:CALL SETPROT                    ; run0378
        LD C,13
        CALL BDOS
        CALL GETRO
        AND 02H
        PUSH AF
        CALL RESETD
        POP AF
        LD DE,PASS0378
        JP Z,REPORT
        LD HL,378
        CALL LOGFAIL
        LD DE,FAIL0378

REPORT: LD A,(ALLMODE)                  ; report selected result
        OR A
        JP Z,REPNORM
        CALL PRINTROW         ;omit each row's individual summary in /ALL
        RET

REPNORM:CALL PRINT                      ; repnorm
        LD A,(REPORTMODE)
        OR A
        JP Z,REPDONE
        LD DE,REPORTMSG
        CALL PRINT

REPDONE:                                ; repdone
        JP 0000H

; ================================================================================
; =                      Protected Mutation Terminal Tests                       =
; =                                                                              =
; = Establishes a fresh protected scratch login for mutation requests expected   =
; = to enter the BDOS read-only error path and return to the CCP rather than to  =
; = DISKTEST.                                                                    =
; ================================================================================
; -------------------------------------------------------------------------------
; Protected Mutation Setup
; -------------------------------------------------------------------------------

  ; SELD/PROTD - establish a fresh scratch-disk login, then protect it.
  ; A conforming mutation request normally enters the BDOS R/O error path and
  ; returns to the CCP without returning here.  If it does return, report FAIL.

SELD:   LD C,25                         ; select fresh scratch disk
        CALL BDOS
        LD (OLDDRV),A
        LD C,13
        CALL BDOS
        LD A,(SCRDRV)
        LD E,A
        LD C,14
        CALL BDOS
        RET

PROTD:  LD C,28                         ; protect scratch disk
        CALL BDOS
        RET

TERMFAIL:CALL RESETD                    ; termfail
        LD DE,TERMFMSG
        CALL PRINT
        JP 0000H

TERMERR:CALL RESETD                     ; termerr
        LD DE,TERMEMSG
        CALL PRINT
        JP 0000H

; -------------------------------------------------------------------------------
; Terminal Mutation Cards
; -------------------------------------------------------------------------------

  ; Tests 0379-0384 deliberately request a mutation on the protected scratch disk.
  ; The expected result is the standard BDOS R/O diagnostic followed by CCP.

RUN0379:CALL SELD                       ; run0379
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

RUN0380:CALL SELD                       ; run0380
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

RUN0381:CALL SELD                       ; run0381
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

RUN0382:CALL SELD                       ; run0382
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

RUN0383:CALL SELD                       ; run0383
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

RUN0384:CALL SELD                       ; run0384
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

; ================================================================================
; =                     Aggregate and Functional-Group Runs                      =
; =                                                                              =
; = Runs returning checks through a shared batch/report path while listing       =
; = nonreturning protected-mutation cards without invoking them inside an        =
; = aggregate.                                                                   =
; ================================================================================
; -------------------------------------------------------------------------------
; Returning Aggregate
; -------------------------------------------------------------------------------

  ; /ALL runs every check which returns control to DISKTEST.  The six protected
  ; mutation cases are necessarily separate: successful rejection warm-starts
  ; CP/M and therefore cannot return to an in-process batch driver.

RUNALL: LD A,1                          ; run returning aggregate
        LD (ALLMODE),A
        CALL CLEARFAIL
        LD DE,ALLHEAD
        CALL PRINT
        CALL PRINTHEADER
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
        LD DE,MANROWS
        CALL PRINT
        LD DE,OUTROWS
        CALL PRINT
        XOR A
        LD (ALLMODE),A
        LD DE,ALLDONE
        CALL PRINTAGGSUM
        CALL PRINTFAILS
        JP 0000H

  ; Returning subsets use the same batch flag as /ALL.  REPORT then prints one
  ; compact row and returns here; individual selectors retain their own summary.

RUNSAFE:LD A,1                          ; run safe subset
        LD (ALLMODE),A
        CALL CLEARFAIL
        LD DE,SAFEHEAD
        CALL PRINT
        CALL PRINTHEADER
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
        CALL PRINTAGGSUM
        CALL PRINTFAILS
        JP 0000H

RUNFN13:LD A,1                          ; runfn13
        LD (ALLMODE),A
        CALL CLEARFAIL
        LD DE,FN13HEAD
        CALL PRINT
        CALL PRINTHEADER
        CALL RUN0155
        CALL RUN0374
        CALL RUN0378
        XOR A
        LD (ALLMODE),A
        LD DE,FN13DONE
        CALL PRINTAGGSUM
        CALL PRINTFAILS
        JP 0000H

RUNFN28:LD A,1                          ; runfn28
        LD (ALLMODE),A
        CALL CLEARFAIL
        LD DE,FN28HEAD
        CALL PRINT
        CALL PRINTHEADER
        CALL RUN0373
        CALL RUN0374
        CALL RUN0377
        XOR A
        LD (ALLMODE),A
        LD DE,FN28DONE
        CALL PRINTAGGSUM
        CALL PRINTFAILS
        JP 0000H

RUNFN29:LD A,1                          ; runfn29
        LD (ALLMODE),A
        CALL CLEARFAIL
        LD DE,FN29HEAD
        CALL PRINT
        CALL PRINTHEADER
        CALL RUN0375
        CALL RUN0376
        XOR A
        LD (ALLMODE),A
        LD DE,FN29DONE
        CALL PRINTAGGSUM
        CALL PRINTFAILS
        JP 0000H

RUNALLOC:LD A,1                         ; runalloc
        LD (ALLMODE),A
        CALL CLEARFAIL
        LD DE,ALLOCHEAD
        CALL PRINT
        CALL PRINTHEADER
        CALL RUN0255
        CALL RUN0275
        CALL RUN0276
        CALL RUN0292
        CALL RUN0293
        LD DE,OUTROWS
        CALL PRINT
        XOR A
        LD (ALLMODE),A
        LD DE,ALLOCDONE
        CALL PRINTAGGSUM
        CALL PRINTFAILS
        JP 0000H

RUNPROTECT:LD A,1                       ; runprotect
        LD (ALLMODE),A
        CALL CLEARFAIL
        LD DE,PROTHEAD
        CALL PRINT
        CALL PRINTHEADER
        CALL RUN0373
        CALL RUN0374
        CALL RUN0375
        CALL RUN0376
        CALL RUN0377
        CALL RUN0378
        LD DE,MANROWS
        CALL PRINT
        XOR A
        LD (ALLMODE),A
        LD DE,PROTDONE
        CALL PRINTAGGSUM
        CALL PRINTFAILS
        JP 0000H

; -------------------------------------------------------------------------------
; Required Selector
; -------------------------------------------------------------------------------

  ; The universal REQUIRED selector runs every returning REQUIRED row and lists
  ; the six terminal rows without invoking them.  Allocation tests share the
  ; same prepared-scratch gate as /ALL and /GROUP:ALLOC.

RUNREQUIRED:                            ; run required subset
        LD A,1
        LD (ALLMODE),A
        CALL CLEARFAIL
        LD DE,REQHEAD
        CALL PRINT
        CALL PRINTHEADER
        CALL RUN0155
        CALL RUN0255
        CALL RUN0275
        CALL RUN0276
        CALL RUN0292
        CALL RUN0373
        CALL RUN0374
        CALL RUN0375
        CALL RUN0376
        CALL RUN0377
        CALL RUN0378
        LD DE,MANROWS
        CALL PRINT
        XOR A
        LD (ALLMODE),A
        LD DE,REQDONE
        CALL PRINTAGGSUM
        CALL PRINTFAILS
        JP 0000H

RUNOBSERVATION:                         ; run observations
        LD A,1
        LD (ALLMODE),A
        LD DE,OBSHEAD
        CALL PRINT
        CALL PRINTHEADER
        CALL RUN0293
        XOR A
        LD (ALLMODE),A
        LD DE,OBSDONE
        CALL PRINT
        JP 0000H

RUNMANUAL:                              ; list manual terminal cases
        LD DE,MANHEAD
        CALL PRINT
        LD DE,MANROWS
        CALL PRINT
        LD DE,MANDONE
        CALL PRINT
        JP 0000H

RUNSTATE:                               ; runstate
        LD A,1
        LD (ALLMODE),A
        CALL CLEARFAIL
        LD DE,STATEHEAD
        CALL PRINT
        CALL PRINTHEADER
        CALL RUN0155
        XOR A
        LD (ALLMODE),A
        LD DE,STATEDONE
        CALL PRINTAGGSUM
        CALL PRINTFAILS
        JP 0000H

; ================================================================================
; =                           Disk-State Preservation                            =
; =                                                                              =
; = Tests that Function 13 preserves the current user number while restoring the =
; = original user and selected drive before leaving the transient.               =
; ================================================================================
; -------------------------------------------------------------------------------
; Function 13 User Preservation
; -------------------------------------------------------------------------------

  ; Test 0155 - Function 13 preserves current user number.
  ;
  ; On entry: normal CP/M transient-program state.
  ; On exit:  original user and selected disk restored; warm boot follows.
  ; Uses:     A,B,C,E.  No disk records are read or written.
  ;
  ; Choose a user different from the caller, reset the disk system, then
  ; ask Function 32 which user remains selected.  This catches systems
  ; which incorrectly fold a user reset into Function 13.

RUN0155:LD C,25                         ; test Function-13 user preservation
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

SETTEST:LD A,E                          ; settest
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

FAIL0155:LD HL,155                      ; fail0155
        CALL LOGFAIL
        LD DE,FAILMSG
        JP REPORT

CLEARFAIL:                              ; clearfail
        XOR A
        LD (FAILCT),A
        RET

; ================================================================================
; =                    Aggregate Reporting and Numeric Output                    =
; =                                                                              =
; = Prints truthful aggregate summaries, failed selector lists, zero-padded item =
; = numbers, and the common result table used by batch and selected runs.        =
; ================================================================================
; -------------------------------------------------------------------------------
; Aggregate Summary
; -------------------------------------------------------------------------------

  ; DE addresses the normal zero-failure summary.  On a failing aggregate use a
  ; truthful generic summary; PRINTFAILS immediately supplies the exact countable
  ; selectors, so no stale hard-coded pass count can contradict the rows.

PRINTAGGSUM:                            ; print aggregate summary
        LD A,(FAILCT)
        OR A
        JP Z,PRINT
        LD DE,AGGFAILED
        JP PRINT

  ; HL is the failed ledger number. Individual selectors already end beside
  ; their row; aggregate runs retain the number for the final scroll-safe line.

LOGFAIL:                                ; logfail
        LD A,(ALLMODE)
        OR A
        RET Z
        PUSH BC
        PUSH DE
        PUSH HL
        LD A,(FAILCT)
        ADD A,A
        LD E,A
        LD D,0
        LD HL,FAILITEMS
        ADD HL,DE
        LD C,L
        LD B,H
        POP HL
        LD A,L
        LD (BC),A
        INC BC
        LD A,H
        LD (BC),A
        LD HL,FAILCT
        LD A,(HL)
        INC A
        LD (HL),A
        POP DE
        POP BC
        RET

PRINTFAILS:                             ; print failed selectors
        LD A,(FAILCT)
        OR A
        RET Z
        LD DE,FAILTAIL
        CALL PRINT
  ; Console output may change BC. Fetch the count AFTER printing the heading.
        LD      A,(FAILCT)
        LD      B,A
        LD HL,FAILITEMS

PFLP:  PUSH BC                          ; pflp
        LD E,(HL)
        INC HL
        LD D,(HL)
        INC HL
        PUSH HL
        EX DE,HL
        CALL PUT4
        LD E,' '
        LD C,2
        CALL BDOS
        POP HL
        POP BC
        DEC B
        JP NZ,PFLP
        LD DE,CRLF
        JP PRINT

  ; Print the zero-padded four-digit value in HL.

PUT4:  LD DE,1000                       ; put4
        CALL PDIG
        LD DE,100
        CALL PDIG
        LD DE,10
        CALL PDIG
        LD A,L
        ADD A,'0'
        LD E,A
        LD C,2
        JP BDOS

PDIG:  LD B,'0'                         ; pdig

PDLP:  OR A                             ; pdlp
        CALL SUBHLDE
        JP C,PDDONE
        INC B
        JP PDLP

PDDONE:ADD HL,DE                        ; pddone
        LD E,B
        LD C,2
        JP BDOS

SUBHLDE:                                ; subhlde
        LD A,L
        SUB E
        LD L,A
        LD A,H
        SBC A,D
        LD H,A
        RET

; -------------------------------------------------------------------------------
; Console Output
; -------------------------------------------------------------------------------

  ; PRINT - send a '$'-terminated string to the console.
  ; Entry: DE addresses text.  Exit: registers are whatever BDOS leaves.
  ; Keep CALL/RET here: this is the sequence proved by dev19 on Montezuma.

PRINT:  LD C,9                          ; print $-terminated string
        CALL BDOS
        RET

PRINTHEADER:                            ; print result-table heading
        LD DE,TABLEHEAD
        CALL PRINT
        RET

; -------------------------------------------------------------------------------
; Result Row Formatting
; -------------------------------------------------------------------------------

  ; PRINTROW - individual result strings contain their own table furniture for
  ; selected runs.  Aggregate runs skip those first three lines and emit only
  ; the result row beneath the single common heading printed by the caller.

PRINTROW:EX DE,HL                       ; print result row
        LD B,3

PROWSK:LD A,(HL)                        ; prowsk
        CP '$'
        RET Z
        INC HL
        CP 10
        JP NZ,PROWSK
        DEC B
        JP NZ,PROWSK

PROWLP:LD A,(HL)                        ; prowlp
        CP '$'
        RET Z
        INC HL
        PUSH HL
        PUSH AF
        LD E,A
        LD C,2
        CALL BDOS
        POP AF
        POP HL
        CP 10
        JP NZ,PROWLP
        RET

; ================================================================================
; =                   Messages, Catalog Rows, and Result Text                    =
; =                                                                              =
; = Defines command help, group headings, aggregate summaries, result rows,      =
; = pending terminal cards, and individual test explanations.                    =
; ================================================================================
; -------------------------------------------------------------------------------
; Messages and Result Rows
; -------------------------------------------------------------------------------

HELPMSG:DB 13,10,'DISKTEST 0.1.0-dev42',13,10,13,10 ; helpmsg
        DB '  DISKTEST /NNNN[:REPORT]     Run, explain, or report one item',13,10
        DB '  DISKTEST /ALL               Run returning checks; list others',13,10
        DB '  DISKTEST /SAFE              Run non-destructive returning checks',13,10
        DB '  DISKTEST /LIST              List ledger items by useful group',13,10
        DB '  DISKTEST /GROUP:LIST        List all available groupings',13,10
        DB '  DISKTEST /GROUP:name        Run a tool-specific group',13,10
        DB '                               (run /GROUP:LIST for available groups)',13,10
        DB '  DISKTEST /H, /HELP          Show concise command help',13,10
        DB '  DISKTEST /INFO              Show build information',13,10
        DB '  DISKTEST /VER, /VERSION     Show name and version',13,10,'$'

LISTPLACE:DB 13,10,'CLASS: R=Required N=Not-guaranteed S=Out-of-scope',13,10 ; listplace
        DB 13,10,'STATE (1)',13,10
        DB '  0155 R Function 13 user-number preservation',13,10
        DB 13,10,'ALLOC (7)',13,10
        DB '  0255 R Data-full empty Make',13,10
        DB '  0275 R Allocation-full failure',13,10
        DB '  0276 R Exact write failure codes',13,10
        DB '  0292 R Allocation release',13,10
        DB '  0293 N Exact freed-block reuse',13,10
        DB '  0355 S Physical allocation versus virtual size',13,10
        DB '  0558 S Allocation order across lifecycles',13,10
        DB 13,10,'PROTECT (12)',13,10
        DB '  0373 R Function 28 convention',13,10
        DB '  0374 R Function 28 transience',13,10
        DB '  0375 R Function 29 convention',13,10
        DB '  0376 R Read-only vector mapping',13,10
        DB '  0377 R Function 28 vector effect',13,10
        DB '  0378 R Reset clears software protection',13,10
        DB '  0379 R Protected-disk Make',13,10
        DB '  0380 R Protected sequential write',13,10
        DB '  0381 R Protected random write',13,10
        DB '  0382 R Protected-disk Delete',13,10
        DB '  0383 R Protected-disk Rename',13,10
        DB '  0384 R Protection before mutation',13,10
        DB 13,10,'TOTAL: 20 ITEMS',13,10,'$'

INFOMSG:DB 13,10,'DISKTEST 0.1.0-dev42',13,10 ; infomsg
        DB 'Ledger items represented: 20; remaining: 0',13,10
        DB 'Returning checks/observations: 12; terminal checks: 6',13,10
        DB 'Required: 17; not guaranteed: 1; outside scope: 2',13,10
        DB 'Ledger coverage: 20 of 20',13,10,'$'

VERMSG:DB 13,10,'DISKTEST 0.1.0-dev42',13,10,'$' ; vermsg
GRPLIST:DB 13,10,'DISKTEST GROUPS',13,10,13,10 ; grplist
        DB 'FUNCTIONAL',13,10
        DB '  STATE       1  Disk-reset user-state preservation',13,10
        DB '  ALLOC       7  Full-disk allocation and release',13,10
        DB '  PROTECT    12  Read-only vectors and protected mutation',13,10
        DB 13,10,'UNIVERSAL',13,10
        DB '  REQUIRED   17  REQUIRED items; six are listed manual rows',13,10
        DB '  OBSERVATION 1  NOT GUARANTEED allocation observation',13,10
        DB '  MANUAL      6  Terminal protected-mutation rows (lists only)',13,10
        DB 13,10,'ORTHOGONAL',13,10
        DB '  /FN:13, /FN:28, /FN:29  Returning checks by BDOS function',13,10,'$'

ALLMSG:DB 13,10,'/ALL requires a prepared scratch disk.',13,10,'$' ; allmsg
ALLHEAD:DB 13,10,'DISKTEST /ALL - returning checks and observations',13,10,'$' ; allhead
ALLDONE:DB 13,10,'Summary: 11 pass, 0 fail, 0 error, 1 observation',13,10 ; alldone
        DB 'Six manual and two out-of-scope rows were not run.',13,10,'$'

FAILTAIL:DB 'Failed items: $'           ; failtail
AGGFAILED:DB 13,10,'Summary: one or more disk oracles failed; see selectors below',13,10,'$'
CRLF:DB 13,10,'$'                       ; crlf
RESULTMSG:DB 13,10,'DISKTEST result terminology',13,10,13,10 ; resultmsg
        DB 'STATUS: P=Pass F=Fail -=Not-run O=Observed.',13,10
        DB 'CLASS: R=Required N=Not-guaranteed S=Out-of-scope.',13,10
        DB 'OUT SCOPE means DISKTEST cannot execute or judge the item.',13,10
        DB 'OBSERVED records evidence or the next command required.',13,10
        DB 'A Summary counts completed rows; terminal rows run separately.',13,10,'$'

PROFILEMSG:DB 13,10,'DISKTEST fixtures and equipment',13,10,13,10 ; profilemsg
        DB 'No named compatibility profiles are defined.',13,10
        DB 'Allocation checks use the prepared disk selected at the prompt.',13,10
        DB 'Never select a disk containing unique files.',13,10
        DB 'Rows 0379-0384 intentionally return through the BDOS R/O path.',13,10,'$'

SAFEHEAD:DB 13,10,'DISKTEST /SAFE - non-destructive returning checks',13,10,'$' ; safehead
SAFEDONE:DB 13,10,'Summary: 7 pass, 0 fail, 0 error, 0 observations',13,10,'$' ; safedone
FN13HEAD:DB 13,10,'DISKTEST /FN:13 - Function 13 checks',13,10,'$' ; fn13head
FN13DONE:DB 13,10,'Summary: 3 pass, 0 fail, 0 error, 0 observations',13,10,'$' ; fn13done
FN28HEAD:DB 13,10,'DISKTEST /FN:28 - returning Function 28 checks',13,10,'$' ; fn28head
FN28DONE:DB 13,10,'Summary: 3 pass, 0 fail, 0 error, 0 observations',13,10 ; fn28done
        DB 'Run terminal rows 0379-0384 separately.',13,10,'$'

FN29HEAD:DB 13,10,'DISKTEST /FN:29 - Function 29 checks',13,10,'$' ; fn29head
FN29DONE:DB 13,10,'Summary: 2 pass, 0 fail, 0 error, 0 observations',13,10,'$' ; fn29done
ALLOCMSG:DB 13,10,'Allocation group requires a prepared scratch disk.',13,10,'$' ; allocmsg
ALLOCHEAD:DB 13,10,'DISKTEST /GROUP:ALLOC - allocation checks',13,10,'$' ; allochead
ALLOCDONE:DB 13,10,'Summary: 4 pass, 0 fail, 0 error, 1 observation',13,10 ; allocdone
        DB 'Rows 0355 and 0558 are outside executable scope.',13,10,'$'

PROTHEAD:DB 13,10,'DISKTEST /GROUP:PROTECT - returning protection checks',13,10,'$' ; prothead
PROTDONE:DB 13,10,'Summary: 6 pass, 0 fail, 0 error, 0 observations',13,10 ; protdone
        DB 'Six terminal rows were listed but not run.',13,10,'$'

REQMSG: DB 13,10,'REQUIRED allocation checks need a prepared scratch disk.',13,10,'$' ; reqmsg
REQHEAD:DB 13,10,'DISKTEST /GROUP:REQUIRED - required checks',13,10,'$' ; reqhead
REQDONE:DB 13,10,'Summary: 11 pass, 0 fail, 0 error, 0 observations',13,10 ; reqdone
        DB 'Six terminal REQUIRED rows were listed but not run.',13,10,'$'

OBSMSG: DB 13,10,'The allocation observation needs a prepared scratch disk.',13,10,'$' ; obsmsg
OBSHEAD:DB 13,10,'DISKTEST /GROUP:OBSERVATION - diagnostic checks',13,10,'$' ; obshead
OBSDONE:DB 13,10,'Summary: 0 pass, 0 fail, 0 error, 1 observation',13,10,'$' ; obsdone
MANHEAD:DB 13,10,'STATUS: P=Pass F=Fail -=Not-run O=Observed',13,10 ; manhead
        DB 'CLASS:  R=Required N=Not-guaranteed S=Out-of-scope',13,10,13,10
        DB 'ITEM  S  C  OBSERVED',13,10
        DB '----  -  -  ----------------------------------------------------------',13,10,'$'

MANDONE:DB 13,10,'Summary: 0 pass, 0 fail, 0 error, 0 observations',13,10 ; mandone
        DB 'Run each listed item separately on prepared scratch media.',13,10,'$'

STATEHEAD:DB 13,10,'DISKTEST /GROUP:STATE - disk reset state',13,10,'$' ; statehead
STATEDONE:DB 13,10,'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$' ; statedone
MANROWS:DB '0379  -  R  Run DISKTEST /0379 on prepared scratch media',13,10 ; manrows
        DB '0380  -  R  Run DISKTEST /0380 on prepared scratch media',13,10
        DB '0381  -  R  Run DISKTEST /0381 on prepared scratch media',13,10
        DB '0382  -  R  Run DISKTEST /0382 on prepared scratch media',13,10
        DB '0383  -  R  Run DISKTEST /0383 on prepared scratch media',13,10
        DB '0384  -  R  Run DISKTEST /0384 on prepared scratch media',13,10,'$'

OUTROWS:DB '0355  -  S  Physical allocation is outside portable scope',13,10 ; outrows
        DB '0558  -  S  Allocation order is outside portable scope',13,10,'$'

REPORTMSG:DB 'Report: result, class, and returning evidence are shown above.',13,10 ; reportmsg
        DB 'Scratch cards also verify fixture integrity and restoration.',13,10,'$'

TABLEHEAD:DB 13,10,'STATUS: P=Pass F=Fail -=Not-run O=Observed',13,10 ; tablehead
        DB 'CLASS:  R=Required N=Not-guaranteed S=Out-of-scope',13,10,13,10
        DB 'ITEM  S  C  OBSERVED',13,10
        DB '----  -  -  ----------------------------------------------------------',13,10,'$'

PASSMSG:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; passmsg
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0155  P  R  Function 13 preserved user number',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'

FAILMSG:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; failmsg
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0155  F  R  Function 13 changed user number',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

  ; The following entries require a replaceable prepared scratch disk.  They run
  ; after consent.  Item 0293 records an observation, not a pass or failure.
  ; The common gate records the chosen drive before any possible disk access.
  ; Never substitute a disk containing unique files.

ASKMSG: DB 13,10,'This test requires a prepared scratch disk.',13,10 ; askmsg
        DB 'To prepare one, quit now, then run SCRATCH /DISK.',13,10
        DB 'Enter its configured drive letter, or Q to quit (B-P or Q): $'

BYPASSMSG:DB 13,10,'QUIT: no scratch disk was accessed.',13,10,'$' ; bypassmsg
PASS0255:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; pass0255
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0255  P  R  Empty Make succeeded on full disk',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'

MSG25FAIL:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; msg25fail
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0255  F  R  Empty Make failed on full disk',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

PASS0275:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; pass0275
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0275  P  R  Growth failed; old file intact',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'

MSG27FAIL:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; msg27fail
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0275  F  R  Growth succeeded or changed file',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

MSG27ERR:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; msg27err
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0275  F  R  BTFULL.DAT could not be opened',13,10
        DB 'Summary: 0 pass, 0 fail, 1 error, 0 observations',13,10,'$'

PASS0276:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; pass0276
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0276  P  R  Sequential=02h, random=02h',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'

MSG26FAIL:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; msg26fail
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0276  F  R  Wrong code or fixture changed',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

MSG26ERR:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; msg26err
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0276  F  R  BTFULL.DAT could not be opened',13,10
        DB 'Summary: 0 pass, 0 fail, 1 error, 0 observations',13,10,'$'

PASS0292:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; pass0292
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0292  P  R  Released block was reusable',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'

MSG92FAIL:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; msg92fail
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0292  F  R  Released block was unavailable',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

MSG92ERR:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; msg92err
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0292  F  R  Scratch fixture not restored',13,10
        DB 'Summary: 0 pass, 0 fail, 1 error, 0 observations',13,10,'$'

MSG92MISS:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; msg92miss
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0292  F  R  BTREL.DAT was not found',13,10
        DB 'Summary: 0 pass, 0 fail, 1 error, 0 observations',13,10,'$'

OBS293S:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; obs293s
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0293  O  N  Same freed block was reused',13,10
        DB 'Summary: 0 pass, 0 fail, 0 error, 1 observation',13,10,'$'

OBS293N:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; obs293n
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0293  O  N  Different free block was used',13,10
        DB 'Summary: 0 pass, 0 fail, 0 error, 1 observation',13,10,'$'

MSG93ERR:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; msg93err
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0293  F  N  Reuse probe could not complete',13,10
        DB 'Summary: 0 pass, 0 fail, 1 error, 0 observations',13,10,'$'

MSG93REST:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; msg93rest
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0293  F  N  Scratch fixture not restored',13,10
        DB 'Summary: 0 pass, 0 fail, 1 error, 0 observations',13,10,'$'

MSG93MISS:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; msg93miss
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0293  F  N  BTREL.DAT was not usable',13,10
        DB 'Summary: 0 pass, 0 fail, 1 error, 0 observations',13,10,'$'

MSG0355:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; msg0355
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0355  -  S  Physical allocation is not portable',13,10
        DB 'DISKTEST cannot assign a portable PASS or FAIL to this item.',13,10
        DB 'Summary: 0 pass, 0 fail, 0 error, 0 observations',13,10,'$'

PASS0373:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; pass0373
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0373  P  R  Function 28 protected current disk',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'

FAIL0373:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; fail0373
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0373  F  R  Function 28 did not protect disk',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

PASS0374:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; pass0374
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0374  P  R  Protection ended after disk reset',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'

FAIL0374:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; fail0374
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0374  F  R  Protection survived disk reset',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

PASS0375:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; pass0375
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0375  P  R  Function 29 returned R/O vector',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'

FAIL0375:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; fail0375
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0375  F  R  Function 29 omitted protected disk',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

PASS0376:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; pass0376
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0376  P  R  Vector bit 1 represented drive B',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'

FAIL0376:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; fail0376
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0376  F  R  Drive B did not map to vector bit 1',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

PASS0377:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; pass0377
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0377  P  R  Function 28 set drive-B vector bit',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'

FAIL0377:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; fail0377
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0377  F  R  Function 28 left vector bit clear',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

PASS0378:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; pass0378
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0378  P  R  Function 13 cleared R/O vector',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'

FAIL0378:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; fail0378
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0378  F  R  Function 13 left R/O vector set',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

MSG0379:DB 13,10,'0379  -  R  Protected-disk Make',13,10,'$' ; msg0379
MSG0380:DB 13,10,'0380  -  R  Protected sequential write',13,10,'$' ; msg0380
MSG0381:DB 13,10,'0381  -  R  Protected random write',13,10,'$' ; msg0381
MSG0382:DB 13,10,'0382  -  R  Protected-disk Delete',13,10,'$' ; msg0382
MSG0383:DB 13,10,'0383  -  R  Protected-disk Rename',13,10,'$' ; msg0383
MSG0384:DB 13,10,'0384  -  R  Protection before mutation',13,10,'$' ; msg0384
PEND0379:DB 13,10,'0379: requesting Make on protected scratch disk.',13,10 ; pend0379
        DB 'EXPECTED: BDOS R/O rejection, then a usable CCP prompt.',13,10,'$'

PEND0380:DB 13,10,'0380: requesting sequential write on protected scratch disk.',13,10 ; pend0380
        DB 'EXPECTED: BDOS R/O rejection, then a usable CCP prompt.',13,10,'$'

PEND0381:DB 13,10,'0381: requesting random write on protected scratch disk.',13,10 ; pend0381
        DB 'EXPECTED: BDOS R/O rejection, then a usable CCP prompt.',13,10,'$'

PEND0382:DB 13,10,'0382: requesting Delete on protected scratch disk.',13,10 ; pend0382
        DB 'EXPECTED: BDOS R/O rejection, then a usable CCP prompt.',13,10,'$'

PEND0383:DB 13,10,'0383: requesting Rename on protected scratch disk.',13,10 ; pend0383
        DB 'EXPECTED: BDOS R/O rejection, then a usable CCP prompt.',13,10,'$'

PEND0384:DB 13,10,'0384: requesting mutation after protecting scratch disk.',13,10 ; pend0384
        DB 'EXPECTED: BDOS R/O rejection before any disk change.',13,10,'$'

TERMFMSG:DB 13,10,'FAIL: protected mutation returned without R/O rejection.',13,10,'$' ; termfmsg
TERMEMSG:DB 13,10,'ERROR: the protected-disk fixture could not be opened.',13,10,'$' ; termemsg
MSG0558:DB 13,10,'ITEM  S  C  OBSERVED',13,10 ; msg0558
        DB '----  -  -  ----------------------------------------------------------',13,10
        DB '0558  -  S  Allocation order is not portable',13,10
        DB 'DISKTEST cannot assign a portable PASS or FAIL to this item.',13,10
        DB 'Summary: 0 pass, 0 fail, 0 error, 0 observations',13,10,'$'

MSG0255:DB 13,10,'0255  -  R  Data-full empty Make',13,10 ; msg0255
        DB 'SETUP: mount a prepared restorable full scratch disk.',13,10
        DB 'ACTION: make EMPTY.TST without writing a data record.',13,10
        DB 'EXPECTED: Make succeeds; an empty file needs no data block.',13,10
        DB 'FAIL: Make reports data-full before a record is written.',13,10
        DB 'RESTORE: prepare the scratch disk again if needed.',13,10,'$'

MSG0275:DB 13,10,'0275  -  R  Allocation-full failure',13,10 ; msg0275
        DB 'SETUP: mount a prepared restorable full scratch disk.',13,10
        DB 'ACTION: append one record to BTFULL.DAT.',13,10
        DB 'EXPECTED: allocating write fails; existing data remains intact.',13,10
        DB 'FAIL: write succeeds or corrupts an existing record.',13,10
        DB 'RESTORE: prepare the scratch disk again if needed.',13,10,'$'

MSG0276:DB 13,10,'0276  -  R  Exact write failure codes',13,10 ; msg0276
        DB 'SETUP: mount a prepared restorable full scratch disk.',13,10
        DB 'ACTION: attempt sequential and random allocating writes.',13,10
        DB 'EXPECTED: each returns its documented nonzero failure code.',13,10
        DB 'FAIL: either returns success or an undocumented success alias.',13,10
        DB 'RESTORE: prepare the scratch disk again if needed.',13,10,'$'

MSG0292:DB 13,10,'0292  -  R  Allocation release',13,10 ; msg0292
        DB 'SETUP: use a freshly prepared scratch disk.',13,10
        DB 'ACTION: delete an allocated file, then allocate equal space.',13,10
        DB 'EXPECTED: new allocation succeeds using released capacity.',13,10
        DB 'FAIL: released capacity remains unavailable.',13,10
        DB 'RESTORE: prepare the scratch disk again if needed.',13,10,'$'

MSG0293:DB 13,10,'0293  -  N  Exact freed-block reuse',13,10 ; msg0293
        DB 'Observe the allocation block reused after delete and Make.',13,10
        DB 'Any valid free block is acceptable; exact order is not fixed.',13,10
        DB 'This observation has no baseline conformance effect.',13,10
        DB 'RESTORE: prepare the scratch disk again if needed.',13,10,'$'

SH:     DB '/H',0                       ; sh
SHELP:  DB '/HELP',0                    ; shelp
SLIST:  DB '/LIST',0                    ; slist
SALL:   DB '/ALL',0                     ; sall
SSAFE:  DB '/SAFE',0                    ; ssafe
SINFO:  DB '/INFO',0                    ; sinfo
SVER:   DB '/VER',0                     ; sver
SVERSION:DB '/VERSION',0                ; sversion
SGLIST: DB '/GROUP:LIST',0              ; sglist
SGSTATE:DB '/GROUP:STATE',0             ; sgstate
SGALLOC:DB '/GROUP:ALLOC',0             ; sgalloc
SGPROTECT:DB '/GROUP:PROTECT',0         ; sgprotect
SGREQ:  DB '/GROUP:REQUIRED',0          ; sgreq
SGOBS:  DB '/GROUP:OBSERVATION',0       ; sgobs
SGMAN:  DB '/GROUP:MANUAL',0            ; sgman
SFN13:  DB '/FN:13',0                   ; sfn13
SFN28:  DB '/FN:28',0                   ; sfn28
SFN29:  DB '/FN:29',0                   ; sfn29
SHR:    DB '/H:RESULTS',0               ; shr
SHP:    DB '/H:PROFILES',0              ; shp
SREPORT:DB ':REPORT',0                  ; sreport

ITEMTAB:DW 155,RUN0155                  ; itemtab
        DW 255,SHOW0255
        DW 275,SHOW0275
        DW 276,SHOW0276
        DW 292,SHOW0292
        DW 293,SHOW0293
        DW 355,SHOW0355
        DW 373,RUN0373
        DW 374,RUN0374
        DW 375,RUN0375
        DW 376,RUN0376
        DW 377,RUN0377
        DW 378,RUN0378
        DW 379,SHOW0379
        DW 380,SHOW0380
        DW 381,SHOW0381
        DW 382,SHOW0382
        DW 383,SHOW0383
        DW 384,SHOW0384
        DW 558,SHOW0558
  ; Working storage.  The private stack prevents a failed probe from relying
  ; on the depth or contents of the CCP stack.  Sixty-four bytes is ample for
  ; this nonrecursive version; increase it if nested test helpers are added.

BADMSG: DB 13,10,'DISKTEST: unknown selector. Use DISKTEST /HELP.',13,10 ; badmsg
        DB 'Use DISKTEST /GROUP:LIST for available groups.',13,10,'$'

ITEMNO: DW 0                            ; itemno
REPORTMODE:DB 0                         ; reportmode
ARGBUF: DS 40                           ; argbuf
OLDDRV: DB 0                            ; olddrv
OLDUSR: DB 0                            ; oldusr
TESTUSR:DB 0                            ; testusr
GOTUSR: DB 0                            ; gotusr
LASTV:  DB 0                            ; lastv
OLDBLK: DB 0                            ; oldblk
NEWBLK: DB 0                            ; newblk
ALLMODE:DB 0                            ; allmode
DOFLAG: DB 0                            ; doflag
FAILCT: DB 0                            ; failct
FAILITEMS:DS 24                         ; failitems
PROCPTR:DW 0                            ; procptr
SCRDRV: DB 0                ;BDOS drive number, A:=0 through P:=15
SCRFCB: DB 0                ;FCB drive number, A:=1 through P:=16
  ; Drive byte is filled from SCRFCB after the operator selects the disk.

FCB0255:DB 0,'EMPTY   ','TST'           ; fcb0255
        DS 24
  ; Immutable template and working FCB for scratch-drive BTFULL.DAT.

FCB0275:DB 0,'BTFULL  ','DAT'           ; fcb0275
        DS 24

FCBREL: DB 0,'BTREL   ','DAT'           ; fcbrel
        DS 24

FCBNEW: DB 0,'BTNEW   ','TST'           ; fcbnew
        DS 24

FCBRONEW:DB 0,'ROTEST  ','TST'          ; fcbronew
        DS 24

FCBGUARD:DB 0,'ROGUARD ','TST'          ; fcbguard
        DS 24

FCBREN: DB 0,'BTREL   ','DAT',0,0,0,0   ; fcbren
        DB 0,'BTREN   ','DAT'
        DS 8

WORKFCB:DS 36                           ; workfcb
LASTMARK:DB 'FULL-127'                  ; lastmark
DMABUF: DS 128                          ; dmabuf
RELBUF: DS 128                          ; relbuf
        DS 64

; ================================================================================
; =                        Working State and Scratch FCBs                        =
; =                                                                              =
; = Defines the private stack, selected scratch drive, batch state, failed-item  =
; = storage, immutable FCB templates, and working file-control blocks.           =
; ================================================================================
; -------------------------------------------------------------------------------
; Working Storage
; -------------------------------------------------------------------------------

STACKTOP:                               ; top of private test stack
        END
