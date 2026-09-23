; SPDX-License-Identifier: GPL-2.0-or-later

; ********************************************************************************
; *                  CP/M 2.2 Conformance Suite -- ENTRYTST                    *
; *                                                                              *
; * Exercises the public state presented when the CCP transfers control to a    *
; * transient: page zero, default FCBs, command tail, DMA, entry stack, loaded  *
; * image, Function 40 behavior, and public BIOS structures. Private CCP or BDOS*
; * machinery is not inferred from those visible effects.                       *
; ********************************************************************************

  ; Version 0.1.0-dev17
  ; Intel 8080 subset; assembled by ZSM4 and linked by Digital Research LINK.

  ; PROGRAMMER'S NOTES
  ; ------------------
  ;
  ; ENTRYTST examines the machine exactly where the CCP hands it to a transient:
  ; page zero, default FCBs, command tail, DMA, entry stack, and loaded image.
  ; It does not infer private CCP or BDOS machinery from those public effects.
  ;
  ; ENTRYSP is saved before our private stack is installed.  The selected RET
  ; card restores it.  Function-zero and WBOOT cards deliberately do not return.
  ; These terminal cards are operator procedures and never run in a batch.
  ;
  ; An A5h byte at the end of the COM proves the loader reached the final byte.
  ; A5h paint at 0080h lets Search First prove the entry DMA: its 0..3 result is
  ; multiplied by 32 to select the changed slot, after FFh has been rejected.
  ;
  ; The Function 40 sandbox uses ENT40.$$$, writes random record two, and reads
  ; zero-filled holes back.  Returning roads restore DMA and delete the file.
  ; The direct-structure probe follows the public BIOS table, DPH, DPB, and
  ; SECTRAN pointer without writing disk data.
  ;
  ; Manual and profile rows remain UNTESTED until their recipe is performed.

  ; LINK establishes the CP/M transient load address at 0100h.  Do not use
  ; ORG 0100h in relocatable input: LINK would add a second 0100h displacement.
BDOS    EQU     0005H
NCASES  EQU     59

; ================================================================================
; =                   Command Interface and Catalog Selection                    =
; =                                                                              =
; = Parses exact selectors while preserving later command-tail operands needed   =
; = by entry-state cards, and selects safe, aggregate, group, range, filter, or  =
; = numeric views.                                                               =
; ================================================================================

START:  LD      HL,0                    ; enter ENTRYTST command dispatcher
        ; Save the CCP's entry stack before borrowing our own.
        ADD     HL,SP
        LD      (ENTRYSP),HL
        LD      SP,STACKTOP
        LD      HL,0
        PUSH    HL
        LD      A,(0080H)
        OR      A
        JP      Z,HELP
        CALL    GETARG
        JP      NZ,BADCOMMAND
        LD      DE,SH
        CALL    ARGIS
        JP      Z,HELP
        LD      DE,SHELP
        CALL    ARGIS
        JP      Z,HELP
        LD      DE,SLIST
        CALL    ARGIS
        JP      Z,LIST
        LD      DE,SSAFE
        CALL    ARGIS
        JP      Z,RUNSAFE
        LD      DE,SALL
        CALL    ARGIS
        JP      Z,RUNALL
        LD      DE,SINFO
        CALL    ARGIS
        JP      Z,INFO
        LD      DE,SVER
        CALL    ARGIS
        JP      Z,VERSION
        LD      DE,SVERSION
        CALL    ARGIS
        JP      Z,VERSION
        LD      DE,SGLIST
        CALL    ARGIS
        JP      Z,GROUPLIST
        LD      DE,SGENTRY
        CALL    ARGIS
        JP      Z,RUNENTRY
        LD      DE,SGTERM
        CALL    ARGIS
        JP      Z,RUNTERMINATION
        LD      DE,SGLOADER
        CALL    ARGIS
        JP      Z,RUNLOADER
        LD      DE,SGBIOS
        CALL    ARGIS
        JP      Z,RUNBIOS
        LD      DE,SGF40
        CALL    ARGIS
        JP      Z,RUNFUNCTION40
        LD      DE,SGDEV
        CALL    ARGIS
        JP      Z,RUNDEVICES
        LD      DE,SGREQ
        CALL    ARGIS
        JP      Z,RUNREQUIRED
        LD      DE,SGOBS
        CALL    ARGIS
        JP      Z,RUNOBSERVATION
        LD      DE,SGMAN
        CALL    ARGIS
        JP      Z,RUNMANUAL
        LD      DE,SHR
        CALL    ARGIS
        JP      Z,HRESULTS
        LD      DE,SHP
        CALL    ARGIS
        JP      Z,HPROFILES
        CALL    ITEMARG
        JP      Z,RUNONE

BADCOMMAND:                             ; report invalid command
        LD      DE,BADSEL
        CALL    PUTS
        RET

; -------------------------------------------------------------------------------
; Command Argument Parser
; -------------------------------------------------------------------------------

  ; Copy and fold the selector from the first token. Operand-sensitive entry
  ; tests deliberately retain later tokens in the command tail/default FCBs.

GETARG:XOR     A                        ; parse selector argument
        LD      (ARGBUF),A
        LD      A,(0080H)
        OR      A
        RET     Z
        LD      B,A
        LD      HL,0081H

PSKIP: LD      A,(HL)                   ; pskip
        CP      ' '
        JP      NZ,PSTART
        INC     HL
        DEC     B
        JP      NZ,PSKIP
        XOR     A
        RET

PSTART:LD      DE,ARGBUF                ; pstart

PCOPY: LD      A,B                      ; pcopy
        OR      A
        JP      Z,PDONE
        LD      A,(HL)
        CP      ' '
        JP      Z,PTRAIL
        CP      'a'
        JP      C,PSTORE
        CP      'z'+1
        JP      NC,PSTORE
        SUB     20H

PSTORE:LD      (DE),A                   ; pstore
        INC     DE
        INC     HL
        DEC     B
        JP      PCOPY
  ; Patch 2026-09-02: the old generic selector parser rejected any second token,
  ; making the documented /0012, /0014, /0015, and /0020 procedures impossible.
  ; Stop after the selector; the individual oracle reads its public entry state.

PTRAIL:                                 ; ptrail

PDONE: XOR     A                        ; pdone
        LD      (DE),A
        RET

ARGIS: LD      HL,ARGBUF                ; argis

PACMP: LD      A,(DE)                   ; pacmp
        CP      (HL)
        RET     NZ
        OR      A
        RET     Z
        INC     DE
        INC     HL
        JP      PACMP

; -------------------------------------------------------------------------------
; Numeric Selector
; -------------------------------------------------------------------------------

  ; Accept /NNNN and /NNNN:REPORT only.

ITEMARG:XOR    A                        ; parse numeric item selector
        LD      (REPORTMODE),A
        LD      HL,ARGBUF
        LD      A,(HL)
        CP      '/'
        RET     NZ
        INC     HL
        LD      B,4
        LD      DE,0
        EX      DE,HL
        LD      (ITEMNO),HL
        EX      DE,HL

PNUM:  LD      A,(HL)                   ; pnum
        CP      '0'
        JP      C,PIBAD
        CP      '9'+1
        JP      NC,PIBAD
        SUB     '0'
        LD      C,A
        PUSH    HL
        LD      HL,(ITEMNO)
        ADD     HL,HL
        PUSH    HL
        ADD     HL,HL
        ADD     HL,HL
        POP     DE
        ADD     HL,DE
        LD      E,C
        LD      D,0
        ADD     HL,DE
        LD      (ITEMNO),HL
        POP     HL
        INC     HL
        DEC     B
        JP      NZ,PNUM
        LD      A,(HL)
        OR      A
        RET     Z
        LD      DE,SREPORT

PIRPT: LD      A,(DE)                   ; pirpt
        CP      (HL)
        JP      NZ,PIBAD
        OR      A
        JP      Z,PIROK
        INC     DE
        INC     HL
        JP      PIRPT

PIROK: LD      A,1                      ; pirok
        LD      (REPORTMODE),A
        XOR     A
        RET

PIBAD: OR      1                        ; pibad
        RET

; -------------------------------------------------------------------------------
; Help and Information Commands
; -------------------------------------------------------------------------------

HELP:  LD      DE,HLPMSG                ; display command help
        CALL    PUTS
        RET

LIST:  LD      DE,LSTMSG                ; display catalog list
        CALL    PUTS
        RET

INFO:  LD      DE,INFMSG                ; display suite information
        CALL    PUTS
        RET

VERSION:LD     DE,VERMSG                ; display suite version
        CALL    PUTS
        RET

GROUPLIST:LD   DE,GRPLIST               ; display functional groups
        CALL    PUTS
        RET

HRESULTS:LD    DE,RESMSG                ; display result-class help
        CALL    PUTS
        RET

HPROFILES:LD   DE,PRFMSG                ; display profile help
        CALL    PUTS
        RET

; -------------------------------------------------------------------------------
; Aggregate and Group Runs
; -------------------------------------------------------------------------------

RUNSAFE:LD     A,3                      ; run safe aggregate
        JP      RUNSET

RUNALL: LD     A,4                      ; run complete aggregate
        JP      RUNSET

  ; Functional groups are a disjoint view of the 59-card deck.  RUNMODE 4 runs
  ; returning observations while leaving selected/manual procedures as rows.

GROUPBEGIN:                             ; begin functional-group run
        LD      A,4
        LD      (RUNMODE),A
        CALL    BEGIN
        RET

RUNENTRY:                               ; run entry group
        CALL    GROUPBEGIN
        LD      HL,CASES
        LD      B,22
        CALL    RUNRANGE
        JP      SUMMARY

RUNTERMINATION:                         ; run termination group
        CALL    GROUPBEGIN
        LD      HL,CASES+198
        LD      B,6
        CALL    RUNRANGE
        JP      SUMMARY

RUNLOADER:                              ; run loader group
        CALL    GROUPBEGIN
        LD      HL,CASES+252
        LD      B,10
        CALL    RUNRANGE
        JP      SUMMARY

RUNFUNCTION40:                          ; run Function-40 group
        CALL    GROUPBEGIN
        LD      HL,CASES+378
        LD      B,4
        CALL    RUNRANGE
        JP      SUMMARY

RUNDEVICES:                             ; run device group
        CALL    GROUPBEGIN
        LD      HL,CASES+360
        LD      B,2
        CALL    RUNRANGE
        LD      HL,CASES+414
        LD      B,7
        CALL    RUNRANGE
        JP      SUMMARY

RUNBIOS:                                ; run BIOS group
        CALL    GROUPBEGIN
        LD      HL,CASES+342
        LD      B,2
        CALL    RUNRANGE
        LD      HL,CASES+477
        LD      B,6
        CALL    RUNRANGE
        JP      SUMMARY

; -------------------------------------------------------------------------------
; Range and Filter Selection
; -------------------------------------------------------------------------------

RUNRANGE:                               ; run catalog range

RGRLP:  PUSH    BC                      ; rgrlp
        PUSH    HL
        CALL    RUNENT
        POP     HL
        LD      DE,9
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RGRLP
        RET

RUNREQUIRED:                            ; run required cases
        XOR     A
        LD      (FILTERMODE),A
        JP      RUNFILTER

RUNOBSERVATION:                         ; run observations
        LD      A,1
        LD      (FILTERMODE),A
        JP      RUNFILTER

RUNMANUAL:                              ; run manual cases
        LD      A,2
        LD      (FILTERMODE),A

RUNFILTER:                              ; run filtered catalog
        LD      A,4
        LD      (RUNMODE),A
        CALL    BEGIN
        LD      HL,CASES
        LD      B,NCASES

RFLP:   PUSH    BC                      ; rflp
        PUSH    HL
        LD      DE,8
        ADD     HL,DE
        LD      C,(HL)
        LD      A,(FILTERMODE)
        OR      A
        JP      Z,RFREQ
        CP      1
        JP      Z,RFOBS
        LD      A,C
        CP      2
        JP      Z,RFPRINT
        CP      4
        JP      Z,RFPRINT
        CP      5
        JP      Z,RFPRINT
        JP      RFSKIP

RFREQ:  LD      A,C                     ; rfreq
        OR      A
        JP      Z,RFPRINT
        CP      2
        JP      Z,RFPRINT
        CP      4
        JP      NZ,RFSKIP
        JP      RFPRINT

RFOBS:  LD      A,C                     ; rfobs
        CP      1
        JP      NZ,RFSKIP

RFPRINT:POP     HL                      ; rfprint
        PUSH    HL
        CALL    RUNENT

RFSKIP: POP     HL                      ; rfskip
        LD      DE,9
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RFLP
        JP      SUMMARY

; -------------------------------------------------------------------------------
; Selected Case Set
; -------------------------------------------------------------------------------

RUNSET:LD      (RUNMODE),A              ; run selected case set
        CALL    BEGIN
        LD      HL,CASES
        LD      B,NCASES

RSLOOP:PUSH    BC                       ; rsloop
        PUSH    HL
        CALL    RUNENT
        POP     HL
        LD      DE,9
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RSLOOP
        JP      SUMMARY

; -------------------------------------------------------------------------------
; Single-Item Selection
; -------------------------------------------------------------------------------

RUNONE:XOR     A                        ; run one catalog item
        LD      (RUNMODE),A
        LD      HL,CASES
        LD      B,NCASES

ROLOOP:LD      E,(HL)                   ; roloop
        INC     HL
        LD      D,(HL)
        INC     HL
        PUSH    HL
        LD      HL,(ITEMNO)
        LD      A,H
        CP      D
        JP      NZ,RONEXT
        LD      A,L
        CP      E
        POP     HL
        JP      Z,ROFOUND
        JP      ROADV

RONEXT:POP     HL                       ; ronext

ROADV: LD      DE,7                     ; roadv
        ADD     HL,DE
        DEC     B
        JP      NZ,ROLOOP
        LD      DE,BADSEL
        CALL    PUTS
        RET

ROFOUND:DEC    HL                       ; rofound
        DEC     HL
        PUSH    HL
        CALL    BEGIN
        POP     HL
        CALL    RUNENT
        JP      SUMMARY

; ================================================================================
; =                   Case Execution and Result Classification                   =
; =                                                                              =
; = Dispatches the nine-byte card deck by class, separates required failures     =
; = from observations, and leaves terminal, manual, profile, and selected        =
; = procedures explicitly unrun.                                                 =
; ================================================================================
; -------------------------------------------------------------------------------
; Card Deck and Score Keeper
; -------------------------------------------------------------------------------

BEGIN: XOR     A                        ; begin case execution
        LD      (PASSCT),A
        LD      (FAILCT),A
        LD      (OBSCT),A
        LD      DE,HEADER
        JP      PUTS

  ; Entry: item, probe, observation, record, class.
  ; Class 0 REQUIRED, 1 NOT GUARANTEED, 2 separately-run REQUIRED,
  ; 3 separately-run PROFILE, 4 selected REQUIRED, 5 selected PROFILE, 6 OUTSIDE.

RUNENT:LD      E,(HL)                   ; execute catalog entry
        INC     HL
        LD      D,(HL)
        INC     HL
        EX      DE,HL
        LD      (CURITEM),HL
        EX      DE,HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        EX      DE,HL
        LD      (PROCPTR),HL
        EX      DE,HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        EX      DE,HL
        LD      (OBSPTR),HL
        EX      DE,HL
        INC     HL
        INC     HL
        LD      A,(HL)
        CP      6
        JP      Z,OOSROW
        CP      5
        JP      Z,SELPROF
        CP      4
        JP      Z,SELREQ
        CP      3
        JP      Z,PRFROW
        CP      2
        JP      Z,MANROW
        CP      1
        JP      NZ,RUNREQ
        LD      A,(RUNMODE)
        CP      3
        RET     Z
        LD      HL,(PROCPTR)
        CALL    CALLHL
        OR      A
        JP      NZ,OBSFAIL
  ; An observation is not a required-test pass. Count it only once.
        LD      A,(OBSCT)
        INC     A
        LD      (OBSCT),A
        LD      DE,SOBS
        JP      ROWOUT

OBSFAIL:LD     A,(FAILCT)               ; obsfail
        CALL    SAVEFAIL
        INC     A
        LD      (FAILCT),A
        LD      DE,SOBFAIL
        JP      ROWOUT

RUNREQ:LD      HL,(PROCPTR)             ; runreq
        CALL    CALLHL
        OR      A
        JP      NZ,ROWFAIL
        LD      A,(PASSCT)
        INC     A
        LD      (PASSCT),A
        LD      DE,SPASS
        JP      ROWOUT

ROWFAIL:LD     A,(FAILCT)               ; rowfail
        CALL    SAVEFAIL
        INC     A
        LD      (FAILCT),A
        LD      DE,SFAIL
        JP      ROWOUT

OOSROW:LD      HL,OOSOBS                ; oosrow
        LD      (OBSPTR),HL
        LD      DE,SOOS
        JP      ROWOUT

MANROW:LD      DE,SMAN                  ; manrow
        CALL    ROWOUT
        LD      A,(RUNMODE)
        OR      A
        RET     NZ
        JP      MANDETAIL

PRFROW:LD      DE,SPROF                 ; prfrow
        CALL    ROWOUT
        LD      A,(RUNMODE)
        OR      A
        RET     NZ
        JP      MANDETAIL

SELREQ:LD      A,(RUNMODE)              ; selreq
        OR      A
        JP      Z,RUNREQ
        LD      DE,SSEL
        JP      ROWOUT

SELPROF:LD     A,(RUNMODE)              ; selprof
        OR      A
        JP      NZ,SELPROW
        LD      HL,(PROCPTR)
        CALL    CALLHL
        OR      A
        JP      NZ,SELPRF
        LD      A,(PASSCT)
        INC     A
        LD      (PASSCT),A
        LD      DE,SPPASS
        JP      ROWOUT

SELPRF:LD      A,(FAILCT)               ; selprf
        CALL    SAVEFAIL
        INC     A
        LD      (FAILCT),A
        LD      DE,SPFAIL
        JP      ROWOUT

SELPROW:LD     DE,SPROF                 ; selprow
        JP      ROWOUT

ROWOUT:PUSH    DE                       ; rowout
        CALL    PUTITEM
        LD      DE,TWO
        CALL    PUTS
        POP     DE
        CALL    PUTS
        LD      HL,(OBSPTR)
        EX      DE,HL
        CALL    PUTS
        LD      DE,CRLF
        JP      PUTS

CALLHL:JP      (HL)                     ; call probe through HL

; ================================================================================
; =                             Operator Procedures                              =
; =                                                                              =
; = Prints the complete recipe for selected manual and terminal cards whose      =
; = behavior occurs before loading or after the transient surrenders control.    =
; ================================================================================
; -------------------------------------------------------------------------------
; Operator's Clipboard
; -------------------------------------------------------------------------------

  ; Numeric selection of a manual row prints the complete operator procedure.
  ; Aggregate runs retain one compact row per item.
  ; THE OPERATOR'S CLIPBOARD -- selected manual cards print the full recipe.

MANDETAIL:LD   HL,MANTAB                ; print manual procedure
        LD      B,10

MDLOOP:LD      E,(HL)                   ; mdloop
        INC     HL
        LD      D,(HL)
        INC     HL
        PUSH    HL
        LD      HL,(CURITEM)
        LD      A,H
        CP      D
        JP      NZ,MDNEXT
        LD      A,L
        CP      E
        POP     HL
        JP      Z,MDFOUND
        INC     HL
        INC     HL
        DEC     B
        JP      NZ,MDLOOP
        RET

MDNEXT:POP     HL                       ; mdnext
        INC     HL
        INC     HL
        DEC     B
        JP      NZ,MDLOOP
        RET

MDFOUND:LD     E,(HL)                   ; mdfound
        INC     HL
        LD      D,(HL)
        CALL    PUTS
        LD      HL,(CURITEM)
        LD      DE,26
        CALL    CMPEQ
        OR      A
        JP      Z,MDTERM26
        LD      HL,(CURITEM)
        LD      DE,27
        CALL    CMPEQ
        OR      A
        JP      Z,MDTERM27
        LD      HL,(CURITEM)
        LD      DE,595
        CALL    CMPEQ
        OR      A
        JP      Z,MDTERM95
        RET

MDTERM26:LD    DE,MDGO26                ; mdterm26
        CALL    MDPAUSE
        LD      C,0
        CALL    BDOS
        LD      DE,MDFAIL26
        JP      PUTS

MDTERM27:LD    DE,MDGO27                ; mdterm27
        CALL    MDPAUSE
        LD      HL,(ENTRYSP)
        LD      SP,HL
        RET

MDTERM95:LD    DE,MDGO95                ; mdterm95
        CALL    MDPAUSE
        JP      0000H

MDPAUSE:CALL   PUTS                     ; mdpause
        LD      C,1
        CALL    BDOS
        LD      DE,CRLF
        JP      PUTS

PUTCHARS:LD    E,(HL)                   ; putchars
        INC     HL
        PUSH    HL
        PUSH    BC
        LD      C,2
        CALL    BDOS
        POP     BC
        POP     HL
        DEC     B
        JP      NZ,PUTCHARS
        RET

; ================================================================================
; =                        Entry Furniture and Page Zero                         =
; =                                                                              =
; = Examines public entry stack, page-zero vectors, default FCBs, command tail,  =
; = and other CCP-supplied transient state without consulting private workspace. =
; ================================================================================
; -------------------------------------------------------------------------------
; Entry and Page-Zero Probes
; -------------------------------------------------------------------------------

  ; --- Entry and page-zero probes -----------------------------------------

P0001: LD      HL,START                 ; probe catalog item 1
        LD      DE,0100H
        JP      CMPEQ

P0003: JP      P0001                    ; probe catalog item 3

P0005: LD      A,(0000H)                ; probe catalog item 5
        CP      0C3H
        JP      RETCMP

P0006: LD      HL,0003H                 ; probe catalog item 6
        LD      DE,0003H
        JP      CMPEQ

P0008: LD      A,(0005H)                ; probe catalog item 8
        CP      0C3H
        JP      RETCMP

P0009: CALL    P0005                    ; probe catalog item 9
        OR      A
        RET     NZ
        JP      P0008

P0011: LD      HL,005CH                 ; probe catalog item 11
        LD      DE,005CH
        JP      CMPEQ

P0012: LD      HL,006CH                 ; probe catalog item 12
        LD      DE,FCB12
        LD      B,12
        JP      CMPMEM

P0014: LD      HL,006CH                 ; probe catalog item 14
        LD      DE,FCB14
        LD      B,12
        JP      CMPMEM

P0015: LD      HL,006CH                 ; probe catalog item 15
        LD      DE,FCB15
        LD      B,12
        JP      CMPMEM

P0017: LD      A,(0080H)                ; probe catalog item 17
        CP      128
        JP      NC,FAILRET
        XOR     A
        RET

P0018: LD      A,(0080H)                ; probe catalog item 18
        OR      A
        JP      Z,FAILRET
        LD      A,(0081H)
        CP      ' '
        JP      RETCMP

P0020: LD      A,(0080H)                ; probe catalog item 20
        LD      B,A
        LD      HL,0081H

P20LP: LD      A,(HL)                   ; p20lp
        CP      'a'
        JP      C,P20NEXT
        CP      'z'+1
        JP      C,FAILRET

P20NEXT:INC    HL                       ; p20next
        DEC     B
        JP      NZ,P20LP
        XOR     A
        RET

; ================================================================================
; =                        Entry DMA and Loader Witnesses                        =
; =                                                                              =
; = Uses Search First to prove the entry DMA at 0080H and an A5H end-of-image    =
; = witness to show that the loader reached the complete COM image below the     =
; = BDOS ceiling.                                                                =
; ================================================================================
; -------------------------------------------------------------------------------
; Painted DMA Trick
; -------------------------------------------------------------------------------

P0021: LD      A,(0080H)                ; probe catalog item 21
        LD      L,A
        LD      H,0
        LD      DE,0081H
        ADD     HL,DE
        LD      A,(HL)
        LD      HL,DIAGTAIL
        LD      (OBSPTR),HL
        LD      DE,9
        ADD     HL,DE
        CALL    HEXMEM
        XOR     A
        RET

  ; Search First observes that the entry DMA remains 0080h.
  ; THE PAINTED-DMA TRICK -- convert Search First's 0..3 result to DMA+32*A.

P0023: LD      HL,0080H                 ; probe catalog item 23
        LD      B,128
        LD      A,0A5H
        CALL    FILL
        LD      DE,WILDFCB
        LD      C,17
        CALL    BDOS
        CP      0FFH
        JP      Z,FAILRET
        LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      DE,0080H
        ADD     HL,DE
        LD      A,(HL)
        CP      0A5H
        JP      Z,FAILRET
        XOR     A
        RET

P0024: JP      P0023                    ; probe catalog item 24

; -------------------------------------------------------------------------------
; Load-Limit Witness
; -------------------------------------------------------------------------------

P0537: LD      C,12                     ; probe catalog item 537
        CALL    BDOS
        CP      22H
        JP      RETCMP
  ; LOAD-LIMIT WITNESS -- the complete image must lie below the BDOS ceiling.

P0589: LD      HL,(0006H)               ; probe catalog item 589
        LD      DE,ENDPROG
        LD      A,H
        CP      D
        JP      C,FAILRET
        JP      NZ,PASSRET
        LD      A,L
        CP      E
        JP      C,FAILRET

PASSRET:XOR    A                        ; return probe success
        RET

  ; Public vector and disk-parameter probes are read-only.

P0598: JP      P0005                    ; probe catalog item 598

P0599: LD      C,31                     ; probe catalog item 599
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,FAILRET
        XOR     A
        RET

  ; IOBYTE probes restore the entry value. Toggling only bit zero also proves
  ; that the other assignment fields can be preserved.
  ; BORROWED IOBYTE -- toggle one bit and restore the entry value.

P0608: LD      A,(0003H)                ; probe catalog item 608
        LD      B,A
        XOR     1
        LD      (0003H),A
        LD      C,A
        LD      A,(0003H)
        CP      C
        PUSH    AF
        LD      A,B
        LD      (0003H),A
        POP     AF
        JP      RETCMP

P0609: JP      P0608                    ; probe catalog item 609

P0610: LD      A,(0003H)                ; probe catalog item 610
        LD      B,A
        XOR     1
        LD      (0003H),A
        XOR     B
        LD      C,A
        LD      A,B
        LD      (0003H),A
        LD      A,C
        CP      1
        JP      RETCMP

P0613: JP      P0599                    ; probe catalog item 613

; ================================================================================
; =                    Function 40 and Public BIOS Structures                    =
; =                                                                              =
; = Uses a reserved Function-40 sandbox with full cleanup, then follows the      =
; = public BIOS jump table, DPH, DPB, and SECTRAN pointer without writing disk   =
; = data.                                                                        =
; ================================================================================
; -------------------------------------------------------------------------------
; Function 40 Sandbox
; -------------------------------------------------------------------------------

  ; Function 40 uses a reserved scratch file. Cleanup restores DMA 0080h and
  ; deletes the file on every returning path.

P0602: JP      P40COMMON                ; probe catalog item 602

P0603: JP      P40COMMON                ; probe catalog item 603

P0605: JP      P40COMMON                ; probe catalog item 605
  ; THE FUNCTION 40 SANDBOX -- all exits restore DMA and remove ENT40.$$$.

P40COMMON:LD   HL,F40INIT               ; p40common
        LD      DE,F40FCB
        LD      B,36
        CALL    COPYMEM
        LD      DE,F40FCB
        LD      C,19
        CALL    BDOS
        LD      DE,F40FCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        JP      Z,P40FAIL
        LD      HL,F40DMA
        LD      B,128
        LD      A,0A5H
        CALL    FILL
        LD      DE,F40DMA
        LD      C,26
        CALL    BDOS
        LD      A,2
        LD      (F40FCB+33),A
        XOR     A
        LD      (F40FCB+34),A
        LD      (F40FCB+35),A
        LD      DE,F40FCB
        LD      C,40
        CALL    BDOS
        OR      A
        JP      NZ,P40FAIL
        XOR     A
        LD      (F40FCB+33),A
        LD      DE,F40FCB
        LD      C,33
        CALL    BDOS
        OR      A
        JP      NZ,P40FAIL
        LD      HL,F40DMA
        LD      B,128

P40ZERO:LD     A,(HL)                   ; p40zero
        OR      A
        JP      NZ,P40FAIL
        INC     HL
        DEC     B
        JP      NZ,P40ZERO
        LD      A,1
        LD      (F40FCB+33),A
        LD      DE,F40FCB
        LD      C,33
        CALL    BDOS
        OR      A
        JP      NZ,P40FAIL
        LD      HL,F40DMA
        LD      B,128

P40ZER2:LD     A,(HL)                   ; p40zer2
        OR      A
        JP      NZ,P40FAIL
        INC     HL
        DEC     B
        JP      NZ,P40ZER2
        CALL    P40CLEAN
        XOR     A
        RET

P40FAIL:CALL   P40CLEAN                 ; p40fail
        JP      FAILRET

P40CLEAN:LD    DE,0080H                 ; p40clean
        LD      C,26
        CALL    BDOS
        LD      DE,F40FCB
        LD      C,19
        JP      BDOS

P0614: LD      C,31                     ; probe catalog item 614
        CALL    BDOS
        LD      DE,2
        ADD     HL,DE
        LD      C,(HL)
        INC     HL
        LD      A,1

P14SH: DEC     C                        ; p14sh
        JP      M,P14MASK
        ADD     A,A
        JP      P14SH

P14MASK:DEC    A                        ; p14mask
        CP      (HL)
        JP      NZ,FAILRET
        INC     HL
        INC     HL
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,FAILRET
        INC     HL
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,FAILRET
        XOR     A
        RET

P0615: JP      P0617                    ; probe catalog item 615

; -------------------------------------------------------------------------------
; Public BIOS Structure Walk
; -------------------------------------------------------------------------------

  ; Act as a conforming direct-structure caller. Locate SELDSK and SECTRAN from
  ; the public BIOS jump table, select the already-current disk, follow the DPH
  ; to its DPB, compare that pointer with BDOS Function 31, validate core DPB
  ; fields, and exercise the active translation pointer. No disk data is changed.

P0617: LD      C,25                     ; probe catalog item 617
        CALL    BDOS
        LD      C,A
        LD      HL,(0001H)
        LD      DE,24
        ADD     HL,DE
        LD      E,0
        CALL    CALLHL
        LD      A,H
        OR      L
        JP      Z,FAILRET
        LD      (DPHPTR),HL
        LD      DE,10
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      (DPBPTR),HL
        LD      C,31
        CALL    BDOS
        EX      DE,HL
        LD      HL,(DPBPTR)
        CALL    CMPEQ
        OR      A
        RET     NZ
        LD      HL,(DPBPTR)
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,FAILRET
        INC     HL
        LD      A,(HL)
        CP      8
        JP      NC,FAILRET
        INC     HL
        LD      A,(HL)
        OR      A
        JP      Z,FAILRET
        INC     HL
        INC     HL
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,FAILRET
        INC     HL
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,FAILRET
        LD      HL,(0001H)
        LD      DE,45
        ADD     HL,DE
        LD      (BIOPTR),HL
        LD      HL,(DPHPTR)
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      BC,0
        LD      HL,(BIOPTR)
        CALL    CALLHL
        XOR     A
        RET

; ================================================================================
; =                 Diagnostic Observations and Test Instruments                 =
; =                                                                              =
; = Records deliberately unspecified residue as observations and provides common =
; = comparison, memory, fill, numeric, and diagnostic helpers for the probe      =
; = deck.                                                                        =
; ================================================================================
; -------------------------------------------------------------------------------
; Diagnostic Observations
; -------------------------------------------------------------------------------

  ; --- Diagnostic observations -------------------------------------------

P0032: LD      HL,O0032                 ; probe catalog item 32
        LD      (OBSPTR),HL
        XOR     A
        RET

P0033: LD      HL,O0033                 ; probe catalog item 33
        LD      (OBSPTR),HL
        XOR     A
        RET

P0511: LD      HL,O0511                 ; probe catalog item 511
        LD      (OBSPTR),HL
        XOR     A
        RET

P0533: LD      HL,O0533                 ; probe catalog item 533
        LD      (OBSPTR),HL
        XOR     A
        RET

P0539: LD      HL,DIAGSP                ; probe catalog item 539
        LD      (OBSPTR),HL
        LD      DE,3
        ADD     HL,DE
        LD      A,(ENTRYSP+1)
        CALL    HEXMEM
        LD      A,(ENTRYSP)
        CALL    HEXMEM
        XOR     A
        RET

; -------------------------------------------------------------------------------
; Test Instruments
; -------------------------------------------------------------------------------

CMPEQ: LD      A,H                      ; compare values
        CP      D
        JP      NZ,FAILRET
        LD      A,L
        CP      E

RETCMP:JP      NZ,FAILRET               ; retcmp

PASS0: XOR     A                        ; pass0
        RET

CMPMEM:LD     A,(DE)                    ; compare memory regions
        CP      (HL)
        JP      NZ,FAILRET
        INC     DE
        INC     HL
        DEC     B
        JP      NZ,CMPMEM
        XOR     A
        RET

COPYMEM:LD    A,(HL)                    ; copy memory region
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,COPYMEM
        RET

FAILRET:LD     A,1                      ; return probe failure
        RET

FILL:  LD      (HL),A                   ; fill diagnostic buffer
        INC     HL
        DEC     B
        JP      NZ,FILL
        RET

HEXMEM:PUSH    AF                       ; hexmem
        RRCA
        RRCA
        RRCA
        RRCA
        AND     0FH
        CALL    NIBMEM
        POP     AF
        AND     0FH

NIBMEM:CP      10                       ; nibmem
        JP      C,NMDIG
        ADD     A,'A'-10
        JP      NMHAVE

NMDIG: ADD     A,'0'                    ; nmdig

NMHAVE:LD      (HL),A                   ; nmhave
        INC     HL
        RET

; ================================================================================
; =                         Reporting and Numeric Output                         =
; =                                                                              =
; = Prints aggregate counts, failed-item lists, item numbers, and supporting     =
; = diagnostics after the selected run completes.                                =
; ================================================================================
; -------------------------------------------------------------------------------
; Summary and Failure List
; -------------------------------------------------------------------------------

SUMMARY:LD     DE,SUM1                  ; print run summary
        CALL    PUTS
        LD      A,(PASSCT)
        CALL    PUTNUM
        LD      DE,SUM2
        CALL    PUTS
        LD      A,(FAILCT)
        CALL    PUTNUM
        LD      DE,SUM3
        CALL    PUTS
        LD      A,(OBSCT)
        CALL    PUTNUM
        LD      DE,SUM4
        CALL    PUTS
        CALL    PRINTFAILS
        LD      A,(REPORTMODE)
        OR      A
        RET     Z
        LD      DE,REPORTMSG
        JP      PUTS

SAVEFAIL:                               ; savefail
        PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL
        LD      A,(FAILCT)
        ADD     A,A
        LD      E,A
        LD      D,0
        LD      HL,FAILITEMS
        ADD     HL,DE
        LD      C,L
        LD      B,H
        LD      HL,(CURITEM)
        LD      A,L
        LD      (BC),A
        INC     BC
        LD      A,H
        LD      (BC),A
        POP     HL
        POP     DE
        POP     BC
        POP     AF
        RET

PRINTFAILS:                             ; print failed-item list
        LD      A,(FAILCT)
        OR      A
        RET     Z
        LD      DE,FAILMSG
        CALL    PUTS
  ; Console output may change BC. Fetch the count AFTER printing the heading.
        LD      A,(FAILCT)
        LD      B,A
        LD      HL,FAILITEMS

PFLP:  PUSH    BC                       ; pflp
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        PUSH    HL
        EX      DE,HL
        LD      (CURITEM),HL
        CALL    PUTITEM
        LD      DE,FSPACE
        CALL    PUTS
        POP     HL
        POP     BC
        DEC     B
        JP      NZ,PFLP
        LD      DE,CRLF
        JP      PUTS

; -------------------------------------------------------------------------------
; Numeric Output Helpers
; -------------------------------------------------------------------------------

PUTITEM:LD     HL,(CURITEM)             ; print catalog item number
        LD      DE,1000
        LD      B,0

PI1:   OR      A                        ; pi1
        CALL    SUBHLDE
        JP      C,PI1D
        INC     B
        JP      PI1

PI1D:  ADD     HL,DE                    ; pi1d
        LD      A,B
        PUSH    HL
        CALL    PUTDIG
        POP     HL
        LD      DE,100
        LD      B,0

PI2:   OR      A                        ; pi2
        CALL    SUBHLDE
        JP      C,PI2D
        INC     B
        JP      PI2

PI2D:  ADD     HL,DE                    ; pi2d
        LD      A,B
        PUSH    HL
        CALL    PUTDIG
        POP     HL
        LD      DE,10
        LD      B,0

PI3:   OR      A                        ; pi3
        CALL    SUBHLDE
        JP      C,PI3D
        INC     B
        JP      PI3

PI3D:  ADD     HL,DE                    ; pi3d
        LD      A,B
        PUSH    HL
        CALL    PUTDIG
        POP     HL
        LD      A,L
        JP      PUTDIG

SUBHLDE:LD     A,L                      ; subhlde
        SUB     E
        LD      L,A
        LD      A,H
        SBC     A,D
        LD      H,A
        RET

PUTNUM:CP      10                       ; print decimal number
        JP      C,PUTDIG
        LD      B,0

PN1:   SUB     10                       ; pn1
        INC     B
        CP      10
        JP      NC,PN1
        PUSH    AF
        LD      A,B
        CALL    PUTDIG
        POP     AF

PUTDIG:ADD     A,'0'                    ; putdig
        LD      E,A
        LD      C,2
        JP      BDOS

PUTS:  LD      C,9                      ; print $-terminated string
        JP      BDOS

; ================================================================================
; =                    Conformance Catalog and Manual Tables                     =
; =                                                                              =
; = Defines the nine-byte card deck, manual procedures, command/help text,       =
; = requirement and observation records, group tables, and result markers.       =
; ================================================================================
; -------------------------------------------------------------------------------
; Case Deck
; -------------------------------------------------------------------------------

CASES:                                  ; entry conformance case catalog
        DW 1,P0001,O0001,R0001
        DB 0
        DW 3,P0003,O0003,R0003
        DB 0
        DW 5,P0005,O0005,R0005
        DB 0
        DW 6,P0006,O0006,R0006
        DB 0
        DW 8,P0008,O0008,R0008
        DB 0
        DW 9,P0009,O0009,R0009
        DB 0
        DW 11,P0011,O0011,R0011
        DB 0
        DW 12,P0012,O0012,R0012
        DB 5
        DW 14,P0014,O0014,R0014
        DB 4
        DW 15,P0015,O0015,R0015
        DB 4
        DW 17,P0017,O0017,R0017
        DB 0
        DW 18,P0018,O0018,R0018
        DB 0
        DW 20,P0020,O0020,R0020
        DB 4
        DW 21,P0021,O0021,R0021
        DB 1
        DW 23,P0023,O0023,R0023
        DB 0
        DW 24,P0024,O0024,R0024
        DB 0
        DW 26,P0001,O0026,R0026
        DB 2
        DW 27,P0001,O0027,R0027
        DB 2
        DW 29,P0001,OOSOBS,R0029
        DB 6
        DW 30,P0001,OOSOBS,R0030
        DB 6
        DW 32,P0032,O0032,R0032
        DB 1
        DW 33,P0033,O0033,R0033
        DB 1
        DW 509,P0001,O0509,R0509
        DB 2
        DW 511,P0511,O0511,R0511
        DB 1
        DW 533,P0533,O0533,R0533
        DB 1
        DW 535,P0001,OOSOBS,R0535
        DB 6
        DW 537,P0537,O0537,R0537
        DB 0
        DW 539,P0539,O0539,R0539
        DB 1
        DW 588,P0001,OOSOBS,R0588
        DB 6
        DW 589,P0589,O0589,R0589
        DB 0
        DW 590,P0001,O0590,R0590
        DB 2
        DW 591,P0001,O0591,R0591
        DB 1
        DW 592,P0001,O0592,R0592
        DB 1
        DW 593,P0001,O0593,R0593
        DB 2
        DW 594,P0001,O0594,R0594
        DB 1
        DW 595,P0001,O0595,R0595
        DB 2
        DW 596,P0001,O0596,R0596
        DB 1
        DW 597,P0001,O0597,R0597
        DB 1
        DW 598,P0598,O0598,R0598
        DB 0
        DW 599,P0599,O0599,R0599
        DB 0
        DW 600,P0001,O0600,R0600
        DB 2
        DW 601,P0001,O0601,R0601
        DB 1
        DW 602,P0602,O0602,R0602
        DB 0
        DW 603,P0603,O0603,R0603
        DB 0
        DW 604,P0001,O0604,R0604
        DB 1
        DW 605,P0605,O0605,R0605
        DB 0
        DW 606,P0001,O0606,R0606
        DB 2
        DW 607,P0001,O0607,R0607
        DB 2
        DW 608,P0608,O0608,R0608
        DB 0
        DW 609,P0609,O0609,R0609
        DB 0
        DW 610,P0610,O0610,R0610
        DB 0
        DW 611,P0001,O0611,R0611
        DB 1
        DW 612,P0001,O0612,R0612
        DB 2
        DW 613,P0613,O0613,R0613
        DB 0
        DW 614,P0614,O0614,R0614
        DB 0
        DW 615,P0615,O0615,R0615
        DB 0
        DW 616,P0001,O0616,R0616
        DB 1
        DW 617,P0617,O0617,R0617
        DB 0
        DW 619,P0001,O0619,R0619
        DB 1

; -------------------------------------------------------------------------------
; Manual Procedure Table
; -------------------------------------------------------------------------------

MANTAB:DW 26,MD0026                     ; manual procedure table
        DW 27,MD0027
        DW 509,MD0509
        DW 590,MD0590
        DW 593,MD0593
        DW 595,MD0595
        DW 600,MD0600
        DW 606,MD0606
        DW 607,MD0607
        DW 612,MD0612

BADSEL:DB 13,10,'ENTRYTST: unknown selector. Use ENTRYTST /HELP.',13,10 ; badsel
        DB 'Use ENTRYTST /GROUP:LIST for available groups.',13,10,'$'

HLPMSG:DB 13,10,'ENTRYTST 0.1.0-dev17',13,10,13,10 ; hlpmsg
        DB '  ENTRYTST /NNNN[:REPORT]     Run, explain, or report one item',13,10
        DB '  ENTRYTST /ALL               Run checks and report all items',13,10
        DB '  ENTRYTST /SAFE              Run automated REQUIRED items',13,10
        DB '  ENTRYTST /LIST              List ledger items by useful group',13,10
        DB '  ENTRYTST /GROUP:LIST        List all available groupings',13,10
        DB '  ENTRYTST /GROUP:name        Run a tool-specific group',13,10
        DB '                              (run /GROUP:LIST for available groups)',13,10
        DB '  ENTRYTST /H, /HELP          Show concise command help',13,10
        DB '  ENTRYTST /INFO              Show build information',13,10
        DB '  ENTRYTST /VER, /VERSION     Show name and version',13,10,'$'

RESMSG:DB 13,10,'ENTRYTST result terminology',13,10,13,10 ; resmsg
        DB 'STATUS: P=Pass F=Fail -=Not-run O=Observed.',13,10
        DB 'PASS=completed and matched; FAIL=completed and mismatched.',13,10
        DB 'CLASS: R=Required N=Not-guaranteed S=Out-of-scope X=Profile.',13,10
        DB 'PROFILE=required only when its named profile is claimed.',13,10
        DB 'OUT SCOPE=ENTRYTST cannot execute or judge the item.',13,10
        DB 'OBSERVED gives evidence or the command still required.',13,10,'$'

PRFMSG:DB 13,10,'ENTRYTST named profiles',13,10,13,10 ; prfmsg
        DB 'DRI-CCP: strict DRI default-FCB parsing behavior (0012).',13,10
        DB 'A PROFILE row applies only when that named behavior is claimed.',13,10
        DB 'Run the numbered item for prerequisites and expected behavior.',13,10
        DB 'For expendable-media procedures, first run SCRATCH /BLANK.',13,10,'$'

INFMSG:DB 13,10,'ENTRYTST 0.1.0-dev17',13,10 ; infmsg
        DB 'Implemented: all 59 assigned rows',13,10
        DB 'Required: 38 (10 manual, 3 selected); diagnostics: 16',13,10
        DB 'Profile: 1 selected; outside scope: 4',13,10
        DB 'Catalog rows represented: 59 of 59; remaining 0',13,10,'$'

VERMSG:DB 13,10,'ENTRYTST 0.1.0-dev17',13,10,'$' ; vermsg
GRPLIST:DB 13,10,'ENTRYTST GROUPS',13,10,13,10 ; grplist
        DB 'FUNCTIONAL',13,10
        DB '  ENTRY       22  Entry image, page zero, FCBs, tail, and DMA',13,10
        DB '  TERMINATION  6  Termination, readiness, and entry stack',13,10
        DB '  LOADER      10  Loader ceiling, BOOT, WBOOT, and residual state',13,10
        DB '  BIOS         8  BIOS vectors, DPH/DPB, and directory layout',13,10
        DB '  FUNCTION40   4  BDOS Function 40 zero-fill behavior',13,10
        DB '  DEVICES      9  Raw devices, IOBYTE, and STAT assignment',13,10
        DB 13,10,'UNIVERSAL',13,10
        DB '  REQUIRED    38  REQUIRED items; thirteen list-only procedures',13,10
        DB '  OBSERVATION 16  NOT GUARANTEED observations',13,10
        DB '  MANUAL      14  Manual, selected, and profile rows (lists only)',13,10,'$'

LSTMSG:DB 13,10,'CLASS: R=Required N=Not-guaranteed S=Out-of-scope X=Profile',13,10 ; lstmsg
        DB 13,10,'ENTRY (22)',13,10
        DB '  0001 R .COM load origin',13,10
        DB '  0003 R TPA lower boundary',13,10
        DB '  0005 R Warm-start gateway at 0000h',13,10
        DB '  0006 R IOBYTE location',13,10
        DB '  0008 R BDOS gateway at 0005h',13,10
        DB '  0009 R Reserved restart/interrupt region roles',13,10
        DB '  0011 R First default FCB location',13,10
        DB '  0012 X Second default FCB at 006Ch',13,10
        DB '  0014 R Default FCB wildcard expansion',13,10
        DB '  0015 R Default FCB case and padding',13,10
        DB '  0017 R Command-tail count location',13,10
        DB '  0018 R Command-tail character location',13,10
        DB '  0020 R Uppercase command-tail representation',13,10
        DB '  0021 N NUL after counted command tail',13,10
        DB '  0023 R Default DMA address',13,10
        DB '  0024 R Command-tail/default-DMA overlap',13,10
        DB '  0026 R Program termination through BDOS function 0',13,10
        DB '  0027 R RET termination',13,10
        DB '  0029 S Exact entry SP',13,10
        DB '  0030 S Exact entry return address',13,10
        DB '  0032 N Z80 extended-register entry state',13,10
        DB '  0033 N Entry flags and interrupt state',13,10
        DB 13,10,'TERMINATION (6)',13,10
        DB '  0509 R Transient termination mechanisms',13,10
        DB '  0511 N Termination does not implicitly close application FCBs',13,10
        DB '  0533 N BDOS reentrancy',13,10
        DB '  0535 S Handoff preparation ordering',13,10
        DB '  0537 R Immediate BDOS readiness',13,10
        DB '  0539 N Transient stack preparation',13,10
        DB 13,10,'LOADER (10)',13,10
        DB '  0588 S Exact recovery internals are not part of the contract',13,10
        DB '  0589 R Loader ceiling and overlay TPA are distinct',13,10
        DB '  0590 R CCP overlay invalidates ordinary RET assumptions',13,10
        DB '  0591 N System ownership is an application obligation',13,10
        DB '  0592 N Entry-stack storage may occupy overlayable memory',13,10
        DB '  0593 R Cold BOOT public postcondition',13,10
        DB '  0594 N Cold BOOT does not promise blanket memory clearing',13,10
        DB '  0595 R WBOOT command-environment reconstruction',13,10
        DB '  0596 N Residual state across WBOOT',13,10
        DB '  0597 N Console-pending state across WBOOT',13,10
        DB 13,10,'BIOS (8)',13,10
        DB '  0598 R BIOS vector is a public runtime ABI',13,10
        DB '  0599 R DPH structures are compatibility-visible',13,10
        DB '  0613 R Parameterized disk-structure coherence',13,10
        DB '  0614 R DPB-dependent directory allocation-map width',13,10
        DB '  0615 R Logical directory placement',13,10
        DB '  0616 N Raw-format universality',13,10
        DB '  0617 R Direct-structure caller responsibility',13,10
        DB '  0619 N Private BDOS target is not an application gateway',13,10
        DB 13,10,'FUNCTION40 (4)',13,10
        DB '  0602 R Function 40 selector and input',13,10
        DB '  0603 R Function 40 allocation-block zero fill',13,10
        DB '  0604 N Function 40 is not universal sparse-hole materialization',13,10
        DB '  0605 R Function 40 result family',13,10
        DB 13,10,'DEVICES (9)',13,10
        DB '  0600 R Direct BIOS calls expose raw device behavior',13,10
        DB '  0601 N BIOS implementation details remain profile-specific',13,10
        DB '  0606 R BIOS character services are raw device interfaces',13,10
        DB '  0607 R Character devices remain distinct runtime paths',13,10
        DB '  0608 R IOBYTE reassignment is runtime visible',13,10
        DB '  0609 R IOBYTE access coherence',13,10
        DB '  0610 R Field-preserving assignment changes',13,10
        DB '  0611 N IOBYTE assignment does not validate device presence',13,10
        DB '  0612 R STAT device-assignment semantics',13,10
        DB 13,10,'TOTAL: 59 ITEMS',13,10,'$'

HEADER: DB 13,10,'STATUS: P=Pass F=Fail -=Not-run O=Observed',13,10 ; header
        DB 'CLASS:  R=Required N=Not-guaranteed S=Out-of-scope X=Profile',13,10,13,10
        DB 'ITEM  S  C  OBSERVED',13,10
        DB '----  -  -  ----------------------------------------------------------',13,10,'$'

SPASS: DB 'P  R  $'                     ; spass
SFAIL: DB 'F  R  $'                     ; sfail
SOBS:  DB 'O  N  $'                     ; sobs
SOBFAIL:DB 'F  N  $'                    ; sobfail
SOOS:  DB '-  S  $'                     ; soos
SMAN:  DB '-  R  $'                     ; sman
SPROF: DB '-  X  $'                     ; sprof
SSEL:  DB '-  R  $'                     ; ssel
SPPASS:DB 'P  X  $'                     ; sppass
SPFAIL:DB 'F  X  $'                     ; spfail
OOSOBS:DB 'Outside executable scope$'   ; oosobs
TWO:   DB '  $'                         ; two
CRLF:  DB 13,10,'$'                     ; crlf
SUM1:  DB 13,10,'Summary: $'            ; sum1
SUM2:  DB ' pass, $'                    ; sum2
SUM3:  DB ' fail, 0 error, $'           ; sum3
SUM4:  DB ' observations',13,10,'$'     ; sum4
FAILMSG:DB 'Failed items: $'            ; failmsg
FSPACE:DB ' $'                          ; fspace
REPORTMSG:DB 'Report: the selected row shows its class and returning evidence.',13,10 ; reportmsg
        DB 'Manual rows above include the complete operator procedure.',13,10,'$'

DIAGTAIL:DB 'Tail-end=00; not guaranteed$'
DIAGSP:DB 'SP=0000; not guaranteed$'

MD0012:DB 13,10,'PROCEDURE: run ENTRYTST /0012 SECOND.BIN',13,10 ; md0012
        DB 'EXPECTED: FCB2 at 006Ch has drive 0 and SECOND.BIN.',13,10
        DB 'Compare the actual 8.3 field printed below.',13,10,'$'

MDACT12:DB 'ACTUAL FCB2 name.type: $'   ; mdact12
MD0014:DB 13,10,'PROCEDURE: copy program as WILD.COM, then run:',13,10 ; md0014
        DB 'WILD A:AB???.*',13,10
        DB 'EXPECTED: FCB1 drive=1, name AB???   , type ???.',13,10
        DB 'Inspect bytes 005Ch-0067h with a debugger.',13,10,'$'

MD0015:DB 13,10,'PROCEDURE: copy program as LOWER.COM, then run:',13,10 ; md0015
        DB 'LOWER mixed.txt',13,10
        DB 'EXPECTED: FCB1 name MIXED   , type TXT, space padded.',13,10,'$'

MD0020:DB 13,10,'PROCEDURE: copy program as TAIL.COM, then run:',13,10 ; md0020
        DB 'TAIL mixed Case',13,10
        DB 'EXPECTED (DRI CCP): tail at 0081h is uppercase.',13,10
        DB 'Record clones that preserve lowercase as incompatible.',13,10,'$'

MD0026:DB 13,10,'This calls BDOS C=0.',13,10 ; md0026
        DB 'SUCCESS: control returns to the CCP with a usable prompt.',13,10
        DB 'ENTRYTST cannot print a result after it terminates.',13,10,'$'

MDGO26:DB 'Press Enter to run the test: $' ; mdgo26
MDFAIL26:DB 'FAIL: BDOS C=0 returned to ENTRYTST.',13,10,'$' ; mdfail26
MD0027:DB 13,10,'This restores the original entry stack and executes RET.',13,10 ; md0027
        DB 'SUCCESS: control returns to the CCP with a usable prompt.',13,10
        DB 'ENTRYTST cannot print a result after it terminates.',13,10,'$'

MDGO27:DB 'Press Enter to run the test: $' ; mdgo27
MD0509:DB 13,10,'Run these three commands and follow each prompt:',13,10 ; md0509
        DB '  ENTRYTST /0026   (BDOS Function 0)',13,10
        DB '  ENTRYTST /0027   (entry RET)',13,10
        DB '  ENTRYTST /0595   (JMP 0000h / WBOOT)',13,10
        DB 'SUCCESS: every command returns a usable CCP prompt.',13,10
        DB 'FAIL: any command hangs, crashes, or leaves no usable prompt.',13,10,'$'

MD0590:DB 13,10,'This destructive test needs a restorable emulator snapshot',13,10 ; md0590
        DB 'and an overlay helper that overwrites the resident CCP.',13,10
        DB 'After overwrite, execute entry RET.',13,10
        DB 'SUCCESS: RET is not treated as a safe return to erased CCP.',13,10
        DB 'UNAVAILABLE: no snapshot or overlay helper is installed.',13,10,'$'

MD0593:DB 13,10,'1. Reset or power-cycle the CP/M machine.',13,10 ; md0593
        DB '2. Wait for CP/M to finish a true cold boot.',13,10
        DB 'SUCCESS: drive A is current, an A> prompt appears, and DIR works.',13,10
        DB 'FAIL: boot hangs, another drive is current, or commands fail.',13,10
        DB 'ENTRYTST cannot continue across the reset.',13,10,'$'

MD0595:DB 13,10,'This jumps through 0000h to invoke WBOOT.',13,10 ; md0595
        DB 'SUCCESS: CP/M reconstructs a usable CCP prompt.',13,10
        DB 'ENTRYTST cannot print a result after WBOOT.',13,10,'$'

MDGO95:DB 'Press Enter to run the test: $' ; mdgo95
MD0600:DB 13,10,'PREREQUISITE: documented BIOS disk profile and scratch disk.',13,10 ; md0600
        DB 'Prepare the expendable disk first with SCRATCH /BLANK.',13,10
        DB '1. Record sector size, numbering, translation, and error codes.',13,10
        DB '2. Run ENTRYTST /0617 to validate public DPH/DPB access.',13,10
        DB '3. Use the profile monitor to read one known scratch sector.',13,10
        DB 'SUCCESS: raw bytes and status match the documented BIOS profile.',13,10
        DB 'Restore the original scratch image after the test.',13,10,'$'

MD0602:DB 13,10,'SETUP: use a disposable file on a restorable scratch disk.',13,10 ; md0602
        DB 'Prepare the expendable disk first with SCRATCH /BLANK.',13,10
        DB 'ACTION: call BDOS C=40 with DE pointing to its random FCB.',13,10
        DB 'EXPECTED: selector 40 consumes the FCB address in DE.',13,10,'$'

MD0603:DB 13,10,'SETUP: make a short file on a restorable scratch disk.',13,10 ; md0603
        DB 'Prepare the expendable disk first with SCRATCH /BLANK.',13,10
        DB 'ACTION: random-write with zero fill beyond current EOF.',13,10
        DB 'EXPECTED: newly allocated intervening records read as zero.',13,10,'$'

MD0605:DB 13,10,'ACTION: run Function 40 on valid and exhausted media.',13,10 ; md0605
        DB 'EXPECTED: result is in the documented success/error family;',13,10
        DB 'record the exact code for the selected disk profile.',13,10,'$'

MD0606:DB 13,10,'PREREQUISITE: observable console, reader, punch, and list.',13,10 ; md0606
        DB 'Send byte 41h through each documented BIOS output entry.',13,10
        DB 'Supply byte 42h to each documented BIOS input entry.',13,10
        DB 'SUCCESS: exactly A is output and exactly B is returned;',13,10
        DB 'no TAB expansion, echo, or BDOS formatting is added.',13,10
        DB 'UNAVAILABLE: required character devices cannot be observed.',13,10,'$'

MD0607:DB 13,10,'PREREQUISITE: separately observable device routes.',13,10 ; md0607
        DB 'Route console, reader, punch, and list to distinct endpoints.',13,10
        DB 'Send a different identifying byte through each BIOS path.',13,10
        DB 'SUCCESS: every byte appears only at its assigned endpoint.',13,10
        DB 'Restore all original routes after the test.',13,10
        DB 'UNAVAILABLE: the profile exposes no distinct endpoints.',13,10,'$'

MD0612:DB 13,10,'This test requires STAT.COM and an alternate device.',13,10 ; md0612
        DB '1. Run: STAT DEV:',13,10
        DB '2. Record the current assignment and IOBYTE value.',13,10
        DB '3. Use STAT to select a documented alternate assignment.',13,10
        DB '4. Run: STAT DEV:',13,10
        DB 'SUCCESS: STAT shows the new route; only its IOBYTE field changed.',13,10
        DB 'Restore the original assignment. UNAVAILABLE if STAT is absent.',13,10,'$'

MD0614:DB 13,10,'SETUP: obtain the selected disk DPB and a scratch directory.',13,10 ; md0614
        DB 'Prepare the expendable disk first with SCRATCH /BLANK.',13,10
        DB 'ACTION: compare DSM with directory allocation entry width.',13,10
        DB 'EXPECTED: DSM below 256 uses 8-bit entries; otherwise 16-bit.',13,10,'$'

MD0615:DB 13,10,'ACTION: use BIOS SELDSK/SETTRK/SETSEC/SETDMA/READ on a',13,10 ; md0615
        DB 'restorable disk, translating logical sectors with SECTRAN.',13,10
        DB 'Prepare the expendable disk first with SCRATCH /BLANK.',13,10
        DB 'EXPECTED: computed directory sectors contain valid entries.',13,10,'$'

; -------------------------------------------------------------------------------
; Observation Records
; -------------------------------------------------------------------------------

O0001: DB 'Program began at 0100h$'     ; observation record for item 1
O0003: DB 'TPA lower boundary is 0100h$' ; observation record for item 3
O0005: DB 'JMP at 0000h is warm start$' ; observation record for item 5
O0006: DB 'IOBYTE resides at 0003h$'    ; observation record for item 6
O0008: DB 'JMP at 0005h is BDOS gateway$' ; observation record for item 8
O0009: DB 'Page-zero gateway roles present$' ; observation record for item 9
O0011: DB 'First default FCB is at 005Ch$' ; observation record for item 11
O0012: DB 'DRI-CCP: Run: ENTRYTST /0012 SECOND.BIN$' ; observation record for item 12
O0014: DB 'Use /0014 A:AB*.C?M$'        ; observation record for item 14
O0015: DB 'Use /0015 mixed.txt$'        ; observation record for item 15
O0017: DB 'Tail count read from 0080h$' ; observation record for item 17
O0018: DB 'Tail text begins at 0081h$'  ; observation record for item 18
O0020: DB 'Use /0020 mixed Case; tail must uppercase$'
O0021: DB 'Tail-end byte observed$'     ; observation record for item 21
O0023: DB 'Entry DMA was 0080h$'        ; observation record for item 23
O0024: DB 'Tail and default DMA overlap$' ; observation record for item 24
O0026: DB 'Run ENTRYTST /0026 manually$' ; observation record for item 26
O0027: DB 'Run ENTRYTST /0027 manually$' ; observation record for item 27
O0032: DB 'Extended registers unspecified$' ; observation record for item 32
O0033: DB 'Flags/interrupt unspecified$' ; observation record for item 33
O0509: DB 'Run ENTRYTST /0509 manually$' ; observation record for item 509
O0511: DB 'Open FCBs need explicit close$' ; observation record for item 511
O0533: DB 'BDOS is not reentrant$'      ; observation record for item 533
O0537: DB 'BDOS ready at transient entry$' ; observation record for item 537
O0539: DB 'Entry stack recorded$'       ; observation record for item 539
O0589: DB 'BDOS ceiling lies above program$' ; observation record for item 589
O0590: DB 'Run ENTRYTST /0590 manually$' ; observation record for item 590
O0591: DB 'Application owns constraints$' ; observation record for item 591
O0592: DB 'Entry stack may be overlayable$' ; observation record for item 592
O0593: DB 'Run ENTRYTST /0593 manually$' ; observation record for item 593
O0594: DB 'BOOT need not clear all memory$' ; observation record for item 594
O0595: DB 'Run ENTRYTST /0595 manually$' ; observation record for item 595
O0596: DB 'Residual WBOOT state varies$' ; observation record for item 596
O0597: DB 'Post-WBOOT console state varies$' ; observation record for item 597
O0598: DB 'WBOOT vector present at 0000h$' ; observation record for item 598
O0599: DB 'Function 31 returned a DPB$' ; observation record for item 599
O0600: DB 'Run ENTRYTST /0600 manually$' ; observation record for item 600
O0601: DB 'BIOS internals vary by profile$' ; observation record for item 601
O0602: DB 'Function 40 consumed scratch FCB$' ; observation record for item 602
O0603: DB 'Intervening records were zero$' ; observation record for item 603
O0604: DB 'Sparse-hole behavior varies$' ; observation record for item 604
O0605: DB 'Function 40 returned success$' ; observation record for item 605
O0606: DB 'Run ENTRYTST /0606 manually$' ; observation record for item 606
O0607: DB 'Run ENTRYTST /0607 manually$' ; observation record for item 607
O0608: DB 'IOBYTE reassignment was visible$' ; observation record for item 608
O0609: DB 'IOBYTE read/write was coherent$' ; observation record for item 609
O0610: DB 'Other IOBYTE fields preserved$' ; observation record for item 610
O0611: DB 'Assignment need not prove I/O$' ; observation record for item 611
O0612: DB 'Run ENTRYTST /0612 manually$' ; observation record for item 612
O0613: DB 'Disk parameter block available$' ; observation record for item 613
O0614: DB 'DPB block mask/limits coherent$' ; observation record for item 614
O0615: DB 'Logical disk structures followed$' ; observation record for item 615
O0616: DB 'Raw disk format is nonportable$' ; observation record for item 616
O0617: DB 'Active DPH/DPB contract followed$' ; observation record for item 617
O0619: DB 'Private BDOS is not a gateway$' ; observation record for item 619

; -------------------------------------------------------------------------------
; Catalog Records
; -------------------------------------------------------------------------------

R0001: DB 'MEM-001-P0001 OR-0001$'      ; catalog record for item 1
R0003: DB 'MEM-001-P0003 OR-0003$'      ; catalog record for item 3
R0005: DB 'MEM-001-P0005 OR-0005$'      ; catalog record for item 5
R0006: DB 'MEM-005-P0006 OR-0006$'      ; catalog record for item 6
R0008: DB 'MEM-001-P0008 OR-0008$'      ; catalog record for item 8
R0009: DB 'MEM-005-P0009 OR-0009$'      ; catalog record for item 9
R0011: DB 'MEM-001-P0011 OR-0011$'      ; catalog record for item 11
R0012: DB 'MEM-005-P0012 OR-0012$'      ; catalog record for item 12
R0014: DB 'MEM-001-P0014 OR-0014$'      ; catalog record for item 14
R0015: DB 'MEM-005-P0015 OR-0015$'      ; catalog record for item 15
R0017: DB 'MEM-001-P0017 OR-0017$'      ; catalog record for item 17
R0018: DB 'MEM-005-P0018 OR-0018$'      ; catalog record for item 18
R0020: DB 'MEM-001-P0020 OR-0020$'      ; catalog record for item 20
R0021: DB 'MEM-005-P0021 OR-0021$'      ; catalog record for item 21
R0023: DB 'MEM-001-P0023 OR-0023$'      ; catalog record for item 23
R0024: DB 'MEM-005-P0024 OR-0024$'      ; catalog record for item 24
R0026: DB 'MEM-001-P0026 OR-0026$'      ; catalog record for item 26
R0027: DB 'MEM-005-P0027 OR-0027$'      ; catalog record for item 27
R0029: DB 'MEM-001-P0029 OR-0029$'      ; catalog record for item 29
R0030: DB 'MEM-005-P0030 OR-0030$'      ; catalog record for item 30
R0032: DB 'MEM-001-P0032 OR-0032$'      ; catalog record for item 32
R0033: DB 'MEM-005-P0033 OR-0033$'      ; catalog record for item 33
R0509: DB 'MEM-005-P0509 OR-0509$'      ; catalog record for item 509
R0511: DB 'MEM-005-P0511 OR-0511$'      ; catalog record for item 511
R0533: DB 'MEM-004-P0533 OR-0533$'      ; catalog record for item 533
R0535: DB 'MEM-004-P0535 OR-0535$'      ; catalog record for item 535
R0537: DB 'MEM-004-P0537 OR-0537$'      ; catalog record for item 537
R0539: DB 'MEM-004-P0539 OR-0539$'      ; catalog record for item 539
R0588: DB 'MEM-002-P0588 OR-0588$'      ; catalog record for item 588
R0589: DB 'MEM-002-P0589 OR-0589$'      ; catalog record for item 589
R0590: DB 'MEM-002-P0590 OR-0590$'      ; catalog record for item 590
R0591: DB 'MEM-002-P0591 OR-0591$'      ; catalog record for item 591
R0592: DB 'MEM-002-P0592 OR-0592$'      ; catalog record for item 592
R0593: DB 'MEM-004-P0593 OR-0593$'      ; catalog record for item 593
R0594: DB 'MEM-002-P0594 OR-0594$'      ; catalog record for item 594
R0595: DB 'MEM-004-P0595 OR-0595$'      ; catalog record for item 595
R0596: DB 'MEM-002-P0596 OR-0596$'      ; catalog record for item 596
R0597: DB 'MEM-004-P0597 OR-0597$'      ; catalog record for item 597
R0598: DB 'MEM-002-P0598 OR-0598$'      ; catalog record for item 598
R0599: DB 'MEM-004-P0599 OR-0599$'      ; catalog record for item 599
R0600: DB 'MEM-002-P0600 OR-0600$'      ; catalog record for item 600
R0601: DB 'MEM-004-P0601 OR-0601$'      ; catalog record for item 601
R0602: DB 'MEM-002-P0602 OR-0602$'      ; catalog record for item 602
R0603: DB 'MEM-004-P0603 OR-0603$'      ; catalog record for item 603
R0604: DB 'MEM-002-P0604 OR-0604$'      ; catalog record for item 604
R0605: DB 'MEM-004-P0605 OR-0605$'      ; catalog record for item 605
R0606: DB 'MEM-002-P0606 OR-0606$'      ; catalog record for item 606
R0607: DB 'MEM-004-P0607 OR-0607$'      ; catalog record for item 607
R0608: DB 'MEM-002-P0608 OR-0608$'      ; catalog record for item 608
R0609: DB 'MEM-004-P0609 OR-0609$'      ; catalog record for item 609
R0610: DB 'MEM-005-P0610 OR-0610$'      ; catalog record for item 610
R0611: DB 'MEM-002-P0611 OR-0611$'      ; catalog record for item 611
R0612: DB 'MEM-004-P0612 OR-0612$'      ; catalog record for item 612
R0613: DB 'MEM-005-P0613 OR-0613$'      ; catalog record for item 613
R0614: DB 'MEM-002-P0614 OR-0614$'      ; catalog record for item 614
R0615: DB 'MEM-004-P0615 OR-0615$'      ; catalog record for item 615
R0616: DB 'MEM-005-P0616 OR-0616$'      ; catalog record for item 616
R0617: DB 'MEM-002-P0617 OR-0617$'      ; catalog record for item 617
R0619: DB 'MEM-006-P0619 OR-0619$'      ; catalog record for item 619

SH:     DB '/H',0                       ; sh
SHELP:  DB '/HELP',0                    ; shelp
SLIST:  DB '/LIST',0                    ; slist
SSAFE:  DB '/SAFE',0                    ; ssafe
SALL:   DB '/ALL',0                     ; sall
SINFO:  DB '/INFO',0                    ; sinfo
SVER:   DB '/VER',0                     ; sver
SVERSION:DB '/VERSION',0                ; sversion
SGLIST: DB '/GROUP:LIST',0              ; sglist
SGENTRY:DB '/GROUP:ENTRY',0             ; sgentry
SGTERM: DB '/GROUP:TERMINATION',0       ; sgterm
SGLOADER:DB '/GROUP:LOADER',0           ; sgloader
SGBIOS: DB '/GROUP:BIOS',0              ; sgbios
SGF40:  DB '/GROUP:FUNCTION40',0        ; sgf40
SGDEV:  DB '/GROUP:DEVICES',0           ; sgdev
SGREQ:  DB '/GROUP:REQUIRED',0          ; sgreq
SGOBS:  DB '/GROUP:OBSERVATION',0       ; sgobs
SGMAN:  DB '/GROUP:MANUAL',0            ; sgman
SHR:    DB '/H:RESULTS',0               ; shr
SHP:    DB '/H:PROFILES',0              ; shp
SREPORT:DB ':REPORT',0                  ; sreport

; ================================================================================
; =                          Fixtures and Runner State                           =
; =                                                                              =
; = Defines FCB fixtures, Function-40 state, current catalog pointers, counters, =
; = saved entry stack, public-structure pointers, private stack, and image-end   =
; = witness.                                                                     =
; ================================================================================
; -------------------------------------------------------------------------------
; Fixtures and Runner State
; -------------------------------------------------------------------------------

WILDFCB:DB 0,'ENTRYTST','COM',0,0,0,0   ; wildcard FCB fixture
        DS 20

FCB12:  DB 0,'SECOND  ','BIN'           ; fcb12
FCB14:  DB 1,'AB??????','C?M'           ; fcb14
FCB15:  DB 0,'MIXED   ','TXT'           ; fcb15
F40INIT:DB 0,'ENT40   ','$$$',0,0,0,0   ; f40init
        DS 20

F40FCB: DS 36                           ; Function-40 scratch FCB
F40DMA: DS 128                          ; Function-40 DMA buffer
ITEMNO:DW 0                             ; itemno
REPORTMODE:DB 0                         ; reportmode
FILTERMODE:DB 0                         ; filtermode
ARGBUF: DS 40                           ; argbuf
CURITEM:DW 0                            ; curitem
PROCPTR:DW 0                            ; procptr
OBSPTR:DW 0                             ; obsptr
PASSCT:DB 0                             ; passct
FAILCT:DB 0                             ; failct
OBSCT: DB 0                             ; obsct
FAILITEMS:DS 118                        ; failitems
RUNMODE:DB 0                            ; runmode
ENTRYSP:DW 0                            ; saved CCP entry stack
DPHPTR:DW 0                             ; dphptr
DPBPTR:DW 0                             ; dpbptr
BIOPTR: DW 0                            ; bioptr
        DS 128

STACKTOP:                               ; top of private test stack

ENDPROG:                                ; end of transient image
        END     START
