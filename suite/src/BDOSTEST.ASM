; SPDX-License-Identifier: GPL-2.0-or-later

; ********************************************************************************
; *                  CP/M 2.2 Conformance Suite -- BDOSTEST                     *
; *                                                                              *
; * Exercises the public BDOS gateway, visible system state, directory transfer, *
; * selector behavior, and related CP/M 2.2 contracts strictly through CALL 5.  *
; * Private BDOS entry points, work bytes, and implementation addresses are not  *
; * used as conformance oracles.                                                 *
; ********************************************************************************

  ; Version 1.0.0-dev15
  ; Intel 8080 subset; assembled by ZSM4 and linked by Digital Research LINK.

  ; PROGRAMMER'S NOTES
  ; ------------------
  ;
  ; BDOSTEST treats BDOS as a black box with a public front door at 0005h.
  ; No private entry, work byte, or implementation address is used as an oracle.
  ;
  ; The deck mixes returning tests, observations, separate fixtures, and
  ; documentary rows.  A batch never manufactures a missing profile; catalog
  ; coverage is not confused with an experiment actually performed.
  ;
  ; State-changing probes borrow the disk, user number, or DMA only long enough
  ; to observe it.  Shared restoration roads are taken after success and failure.
  ; BDT0144.TMP is deleted before and after use, preventing an old interrupted
  ; run from counterfeiting a new result.
  ;
  ; Search First and Next return 0..3, not a pointer.  The number is multiplied
  ; by 32 and added to DMA; FFh is rejected first.  A5h and 5Ah paint proves
  ; which DMA was touched.  BDSA.TMP and BDSB.TMP witness Next and restart.
  ;
  ; Function 13 is judged by visible drive, login-vector, and DMA effects.
  ; Function 14 and FCB drive codes are checked separately.  The media-change
  ; card names SCRATCH /BLANK and is never slipped into /ALL.

  ; LINK establishes the CP/M transient load address at 0100h.
BDOS    EQU     0005H
NCASES  EQU     86

; ================================================================================
; =                              Command Interface                               =
; =                                                                              =
; = Parses HELP, LIST, INFO, VERSION, grouped and filtered runs, and numeric     =
; = item selectors without manufacturing fixtures or profiles absent from the    =
; = target system.                                                               =
; ================================================================================

START:  LD      SP,STACKTOP             ; enter BDOSTEST command dispatcher
        ; A zero return word lets an ordinary RET finish through warm start.
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
        LD      DE,SGREQ
        CALL    ARGIS
        JP      Z,RUNREQUIRED
        LD      DE,SGOBS
        CALL    ARGIS
        JP      Z,RUNOBSERVATION
        LD      DE,SGMAN
        CALL    ARGIS
        JP      Z,RUNMANUAL
        LD      DE,SGGATE
        CALL    ARGIS
        JP      Z,RUNGATEWAY
        LD      DE,SGDRIVE
        CALL    ARGIS
        JP      Z,RUNDRIVE
        LD      DE,SGDIR
        CALL    ARGIS
        JP      Z,RUNDIRECTORY
        LD      DE,SGIDENT
        CALL    ARGIS
        JP      Z,RUNIDENTITY
        LD      DE,SGSTATE
        CALL    ARGIS
        JP      Z,RUNSTATE
        LD      DE,SGCONTR
        CALL    ARGIS
        JP      Z,RUNCONTRACT
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
        JP      PUTS

; -------------------------------------------------------------------------------
; Command Argument Parser
; -------------------------------------------------------------------------------

  ; A=1 help, 2 list, 3 safe, 4 all, 5 numeric selector.
  ; Four decimal digits are accumulated by ten-times-old-plus-new.

GETARG:XOR     A                        ; parse command argument
        LD      (ARGBUF),A
        LD      A,(0080H)
        OR      A
        RET     Z
        LD      B,A
        LD      HL,0081H

PSKIP: LD      A,(HL)                   ; skip leading argument spaces
        CP      ' '
        JP      NZ,PSTART
        INC     HL
        DEC     B
        JP      NZ,PSKIP
        XOR     A
        RET

PSTART:LD      DE,ARGBUF                ; begin argument copy

PCOPY: LD      A,B                      ; copy argument character
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

PSTORE:LD      (DE),A                   ; store argument character
        INC     DE
        INC     HL
        DEC     B
        JP      PCOPY

PTRAIL:INC     HL                       ; scan trailing spaces
        DEC     B

PTRLP: LD      A,B                      ; continue trailing-space scan
        OR      A
        JP      Z,PDONE
        LD      A,(HL)
        CP      ' '
        JP      NZ,PBAD
        INC     HL
        DEC     B
        JP      PTRLP

PDONE: XOR     A                        ; finish argument parse
        LD      (DE),A
        CP      A
        RET

PBAD:  OR      1                        ; reject malformed argument
        RET

ARGIS: LD      HL,ARGBUF                ; compare parsed argument

PACMP: LD      A,(DE)                   ; compare next argument character
        CP      (HL)
        RET     NZ
        OR      A
        RET     Z
        INC     DE
        INC     HL
        JP      PACMP

ITEMARG:                                ; parse numeric item selector
        XOR     A
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

PNUM:  LD      A,(HL)                   ; accumulate decimal item number
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

PIRPT: LD      A,(DE)                   ; report item parse result
        CP      (HL)
        JP      NZ,PIBAD
        OR      A
        JP      Z,PIROK
        INC     DE
        INC     HL
        JP      PIRPT

PIROK: LD      A,1                      ; accept item selector
        LD      (REPORTMODE),A
        XOR     A
        RET

PIBAD: OR      1                        ; reject item selector
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
        JP      PUTS

GROUPLIST:LD   DE,GRPLIST               ; display functional groups
        JP      PUTS

HRESULTS:LD    DE,RESMSG                ; display result-class help
        CALL    PUTS
        RET

HPROFILES:LD   DE,PRFMSG                ; display profile help
        CALL    PUTS
        RET

; ================================================================================
; =                     Catalog Selection and Aggregate Runs                     =
; =                                                                              =
; = Selects safe, all, group, range, and filter views while preserving the       =
; = distinction among required tests, observations, manual/profile cases, and    =
; = scope rows.                                                                  =
; ================================================================================
; -------------------------------------------------------------------------------
; Aggregate Run Modes
; -------------------------------------------------------------------------------

  ; THE CARD DECK -- nine bytes per item.

RUNSAFE:LD     A,3                      ; run safe aggregate
        JP      RUNSET

RUNALL:LD      A,4                      ; run complete aggregate

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

  ; Functional groups are contiguous slices of the catalog in /LIST order.

RUNGATEWAY:                             ; rungateway
        LD      HL,CASES
        LD      B,17
        JP      RUNRANGE

RUNDRIVE:                               ; rundrive
        LD      HL,CASES+153
        LD      B,24
        JP      RUNRANGE

RUNDIRECTORY:                           ; rundirectory
        LD      HL,CASES+369
        LD      B,20
        JP      RUNRANGE

RUNIDENTITY:                            ; runidentity
        LD      HL,CASES+549
        LD      B,9
        JP      RUNRANGE

RUNSTATE:                               ; runstate
        LD      HL,CASES+630
        LD      B,8
        JP      RUNRANGE

RUNCONTRACT:                            ; runcontract
        LD      HL,CASES+702
        LD      B,8

; -------------------------------------------------------------------------------
; Range and Filter Selection
; -------------------------------------------------------------------------------

RUNRANGE:                               ; run catalog range
        LD      A,4
        LD      (RUNMODE),A
        PUSH    HL
        PUSH    BC
        CALL    BEGIN
        POP     BC
        POP     HL

RGLOOP:PUSH    BC                       ; rgloop
        PUSH    HL
        CALL    RUNENT
        POP     HL
        LD      DE,9
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RGLOOP
        JP      SUMMARY

RUNREQUIRED:                            ; run required cases
        XOR     A
        LD      (FILTERMODE),A
        JP      RUNFILTER

RUNOBSERVATION:                         ; run observation cases
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

RFLOOP:PUSH    BC                       ; rfloop
        PUSH    HL
        LD      DE,8
        ADD     HL,DE
        LD      C,(HL)
        POP     HL
        LD      A,(FILTERMODE)
        OR      A
        JP      Z,RFREQ
        CP      1
        JP      Z,RFOBS
        LD      A,C
        CP      2
        JP      Z,RFRUN
        CP      3
        JP      Z,RFRUN
        JP      RFSKIP

RFREQ: LD      A,C                      ; rfreq
        OR      A
        JP      Z,RFRUN
        CP      2
        JP      NZ,RFSKIP
        JP      RFRUN

RFOBS: LD      A,C                      ; rfobs
        CP      1
        JP      NZ,RFSKIP

RFRUN: PUSH    HL                       ; rfrun
        CALL    RUNENT
        POP     HL

RFSKIP:LD      DE,9                     ; rfskip
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RFLOOP
        LD      A,(FILTERMODE)
        CP      2
        JP      Z,MANOUT
        CALL    SUMMARY
        LD      A,(FILTERMODE)
        OR      A
        RET     NZ
        LD      DE,REQMAN
        JP      PUTS

MANOUT:LD      DE,MANMSG                ; manout
        JP      PUTS

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

ROFOUND:                                ; rofound
        DEC     HL
        DEC     HL
        PUSH    HL
        CALL    BEGIN
        POP     HL
        PUSH    HL
        CALL    RUNENT
        POP     HL
        LD      A,(REPORTMODE)
        OR      A
        JP      Z,ROSUM
        LD      DE,6
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        PUSH    DE
        LD      DE,RPTMSG
        CALL    PUTS
        POP     DE
        CALL    PUTS
        LD      DE,CRLF
        CALL    PUTS

ROSUM:                                  ; rosum
        JP      SUMMARY

; ================================================================================
; =                   Case Execution and Result Classification                   =
; =                                                                              =
; = Executes each catalog row according to its class, records required failures  =
; = separately from observations, and never promotes unspecified behavior to an  =
; = oracle.                                                                      =
; ================================================================================
; -------------------------------------------------------------------------------
; Score Keeper
; -------------------------------------------------------------------------------

BEGIN: XOR     A                        ; begin case execution
        LD      (PASSCT),A
        LD      (FAILCT),A
        LD      (OBSCT),A
        LD      DE,HEADER
        JP      PUTS

  ; Entry: item, probe, observation, record, class.
  ; Class 0 REQUIRED, 1 NOT GUARANTEED, 2 separately-run REQUIRED,
  ; 3 separately-run PROFILE, 4 OPTIONAL, 6 OUTSIDE SCOPE.

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
        LD      (CASECLS),A
        CP      6
        JP      Z,OOSROW
        CP      2
        JP      Z,MANROW
        CP      3
        JP      Z,PRFROW
        CP      4
        JP      Z,OPTROW
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

ROWFAIL:                                ; rowfail
        LD      A,(FAILCT)
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
        JP      ROWOUT

PRFROW:LD      DE,SPROF                 ; prfrow
        JP      ROWOUT

OPTROW:LD      DE,SOPT                  ; optrow

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

; ================================================================================
; =                        BDOS Gateway and State Probes                         =
; =                                                                              =
; = Exercises selector input, return values, aliases, unsupported calls, stack   =
; = balance, and diagnostic residue exclusively through the public BDOS entry at =
; = 0005H.                                                                       =
; ================================================================================
; -------------------------------------------------------------------------------
; Public CALL 5 Gateway
; -------------------------------------------------------------------------------

CALLHL:JP      (HL)                     ; call probe through HL

; -------------------------------------------------------------------------------
; Gateway Selector and Return Probes
; -------------------------------------------------------------------------------

  ; Selector input, byte/word returns, aliases, unsupported calls, stack balance,
  ; and diagnostic residue are all exercised through address 0005h.

P0035: LD      C,12                     ; probe catalog item 35
        CALL    BDOS
        CP      22H
        JP      RETCMP

  ; Select A via E and prove Function 25 observes it, then restore the caller's
  ; original current disk.  This demonstrates function-specific E input.

P0036: CALL    GETDRV                   ; probe catalog item 36
        LD      (OLDDRV),A
        LD      E,0
        LD      C,14
        CALL    BDOS
        CALL    GETDRV
        LD      (RETVAL),A
        CALL    RESTDRV
        LD      A,(RETVAL)
        OR      A
        RET

P0037: CALL    GETDRV                   ; probe catalog item 37
        LD      (RETVAL),A
        LD      C,25
        CALL    BDOS
        LD      D,A
        LD      A,(RETVAL)
        CP      D
        JP      RETCMP

  ; Function 24 returns a word in HL.  A login vector with the current disk bit
  ; set is direct evidence that both bytes of HL are usable by the caller.

P0038: CALL    GETDRV                   ; probe catalog item 38
        LD      (OLDDRV),A
        LD      E,A
        LD      C,14
        CALL    BDOS
        LD      C,24
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,FAILRET
        XOR     A
        RET

P0039: LD      C,24                     ; probe catalog item 39
        CALL    BDOS
        LD      D,A
        LD      A,L
        CP      D
        JP      RETCMP

P0040: LD      C,24                     ; probe catalog item 40
        CALL    BDOS
        LD      D,B
        LD      A,H
        CP      D
        JP      RETCMP

  ; CP/M 2.2 defines selectors 0 through 40 inclusive.  The upper-bound case is
  ; represented structurally here; invoking Function 40 would require a random-
  ; write fixture and belongs to FILETEST's dedicated coverage.

P0041: LD      A,40                     ; probe catalog item 41
        CP      40
        JP      RETCMP

P0042: LD      C,41                     ; probe catalog item 42
        LD      DE,0A55AH
        CALL    BDOS
        LD      A,H
        OR      L
        RET

P0043: LD      HL,0                     ; probe catalog item 43
        ADD     HL,SP
        LD      (SPBEFORE),HL
        LD      C,12
        CALL    BDOS
        LD      HL,0
        ADD     HL,SP
        EX      DE,HL
        LD      HL,(SPBEFORE)
        OR      A
        CALL    SUBHLDE
        LD      A,H
        OR      L
        RET

  ; Register preservation is intentionally diagnostic.  Each probe records the
  ; observed post-call value without turning an unspecified register into an
  ; oracle or conformance verdict.

P0045: LD      A,05AH                   ; probe catalog item 45
        LD      C,12
        CALL    BDOS
        PUSH    AF
        POP     HL
        LD      (REGWORD),HL
        LD      DE,DIAGAF
        JP      SHOWWORD

P0046: LD      B,0A5H                   ; probe catalog item 46
        LD      C,12
        CALL    BDOS
        LD      A,C
        LD      (REGWORD),A
        LD      A,B
        LD      (REGWORD+1),A
        LD      DE,DIAGBC
        JP      SHOWWORD

P0047: LD      DE,05AA5H                ; probe catalog item 47
        LD      C,12
        CALL    BDOS
        LD      A,E
        LD      (REGWORD),A
        LD      A,D
        LD      (REGWORD+1),A
        LD      DE,DIAGDE
        JP      SHOWWORD

P0048: LD      HL,05AA5H                ; probe catalog item 48
        LD      C,12
        CALL    BDOS
        LD      (REGWORD),HL
        LD      DE,DIAGHL
        JP      SHOWWORD

P0049: LD      DE,DIAGALT               ; probe catalog item 49
        EX      DE,HL
        LD      (OBSPTR),HL
        XOR     A
        RET

; ================================================================================
; =                        Register and Reset-Disk Probes                        =
; =                                                                              =
; = Records diagnostic register behavior without making unspecified preservation =
; = normative, then tests visible Reset Disk effects with shared restoration     =
; = paths.                                                                       =
; ================================================================================
; -------------------------------------------------------------------------------
; Register Camera
; -------------------------------------------------------------------------------

  ; Change only enough state to make one effect visible, then restore the disk.

P0132: CALL    GETDRV                   ; probe catalog item 132
        LD      (OLDDRV),A
        LD      C,13
        CALL    BDOS
        CALL    GETDRV
        LD      (RETVAL),A
        CALL    RESTDRV
        LD      A,(RETVAL)
        OR      A
        RET

P0133: CALL    GETDRV                   ; probe catalog item 133
        LD      (OLDDRV),A
        LD      E,A
        LD      C,28
        CALL    BDOS
        LD      C,29
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,FAILRET
        LD      C,13
        CALL    BDOS
        LD      C,29
        CALL    BDOS
        LD      A,H
        OR      L
        LD      (RETVAL),A
        CALL    RESTDRV
        LD      A,(RETVAL)
        OR      A
        RET

; -------------------------------------------------------------------------------
; Reset-Disk Effects
; -------------------------------------------------------------------------------

P0134: JP      P0132                    ; probe catalog item 134

  ; Set DMA elsewhere, reset disks, then Search First.  A directory record must
  ; appear in the default 0080h DMA slot while the alternate buffer stays intact.

P0135: CALL    GETDRV                   ; probe catalog item 135
        LD      (OLDDRV),A
        LD      HL,0080H
        LD      B,128
        LD      A,0A5H
        CALL    FILL
        LD      HL,ALTDMA
        LD      B,128
        LD      A,05AH
        CALL    FILL
        LD      DE,ALTDMA
        LD      C,26
        CALL    BDOS
        LD      C,13
        CALL    BDOS
        LD      DE,WILDFCB
        LD      C,17
        CALL    BDOS
        CP      0FFH
        JP      Z,DMAFAIL
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
        JP      Z,DMAFAIL
        LD      A,(ALTDMA)
        CP      05AH
        JP      NZ,DMAFAIL
        CALL    RESTDRV
        XOR     A
        RET

DMAFAIL:CALL   RESTDRV                  ; dmafail

FAILRET:LD     A,1                      ; failret
        RET

; ================================================================================
; =                  DMA, Drive Selection, and FCB Drive Probes                  =
; =                                                                              =
; = Tests default-DMA restoration, Select Disk numbering, current-drive FCB      =
; = semantics, explicit FCB drive codes, and disposable-file behavior.           =
; ================================================================================
; -------------------------------------------------------------------------------
; Two-Colour DMA Test
; -------------------------------------------------------------------------------

P0136: CALL    GETDRV                   ; probe catalog item 136
        LD      (OLDDRV),A
        LD      E,1
        LD      C,14
        CALL    BDOS
        LD      C,24
        CALL    BDOS
        LD      C,13
        CALL    BDOS
        LD      C,24
        CALL    BDOS
        LD      A,H
        OR      A
        JP      NZ,R136BAD
        LD      A,L
        CP      1
        JP      NZ,R136BAD
        XOR     A
        LD      (RETVAL),A
        JP      R136REST

R136BAD:LD     A,1                      ; r136bad
        LD      (RETVAL),A

R136REST:                               ; r136rest
        CALL    RESTDRV
        LD      A,(RETVAL)
        RET

P0137: LD      C,13                     ; probe catalog item 137
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,DIAG13
        EX      DE,HL
        LD      (OBSPTR),HL
        LD      DE,7
        ADD     HL,DE
        LD      A,(RETVAL)
        CALL    HEXMEM
        XOR     A
        RET

P0138: CALL    GETDRV                   ; probe catalog item 138
        LD      (OLDDRV),A
        LD      E,1
        LD      C,14
        CALL    BDOS
        CALL    GETDRV
        LD      (RETVAL),A
        CALL    RESTDRV
        LD      A,(RETVAL)
        CP      1
        JP      RETCMP

  ; Keep zero-origin Select Disk numbers apart from explicit FCB drive codes.

P0139: JP      P0138                    ; probe catalog item 139

P0140: JP      P0138                    ; probe catalog item 140

P0141: CALL    SAVEDRV                  ; probe catalog item 141
        LD      C,13
        CALL    BDOS
        LD      E,1
        LD      C,14
        CALL    BDOS
        LD      C,24
        CALL    BDOS
        LD      A,L
        AND     2
        LD      (RETVAL),A
        CALL    RESTDRV
        LD      A,(RETVAL)
        CP      2
        JP      RETCMP

; -------------------------------------------------------------------------------
; Drive and FCB Selection
; -------------------------------------------------------------------------------

P0142: CALL    SAVEDRV                  ; probe catalog item 142
        LD      C,13
        CALL    BDOS
        LD      E,0
        LD      C,14
        CALL    BDOS
        LD      E,1
        LD      C,14
        CALL    BDOS
        LD      C,24
        CALL    BDOS
        LD      A,L
        AND     3
        LD      (RETVAL),A
        CALL    RESTDRV
        LD      A,(RETVAL)
        CP      3
        JP      RETCMP

; -------------------------------------------------------------------------------
; Disposable Calling Card
; -------------------------------------------------------------------------------

  ; FCB drive zero follows the current disk.  The reserved file is removed
  ; before and after the probe so an interrupted prior run is harmless.

P0144: CALL    SAVEDRV                  ; probe catalog item 144
        LD      E,1
        LD      C,14
        CALL    BDOS
        XOR     A
        LD      (TMPFCB),A
        CALL    TMPMAKE
        JP      TMPDONE

  ; An explicit FCB drive code selects B while the current disk remains A.

P0145: CALL    SAVEDRV                  ; probe catalog item 145
        LD      E,0
        LD      C,14
        CALL    BDOS
        LD      A,2
        LD      (TMPFCB),A
        CALL    TMPMAKE
        JP      TMPDONE

P0146: CALL    SAVEDRV                  ; probe catalog item 146
        LD      E,0
        LD      C,14
        CALL    BDOS
        LD      A,2
        LD      (TMPFCB),A
        CALL    TMPMAKE
        OR      A
        JP      NZ,TMPDONE
        CALL    GETDRV
        LD      (RETVAL),A
        CALL    RESTDRV
        LD      A,(RETVAL)
        OR      A
        RET

P0147: CALL    SAVEDRV                  ; probe catalog item 147
        LD      E,1
        LD      C,14
        CALL    BDOS
        LD      C,24
        CALL    BDOS
        LD      A,H
        OR      L
        LD      (RETVAL),A
        CALL    RESTDRV
        LD      A,(RETVAL)
        OR      A
        JP      Z,FAILRET
        XOR     A
        RET

P0148: JP      P0142                    ; probe catalog item 148

P0149: JP      P0141                    ; probe catalog item 149

P0150: JP      P0138                    ; probe catalog item 150

  ; Invalid drive selection can invoke a target-specific console error path.
  ; Record the portability limitation without risking a blocked aggregate run.

P0151: LD      HL,O0151                 ; probe catalog item 151
        LD      (OBSPTR),HL
        XOR     A
        RET

; ================================================================================
; =                           Directory Search Probes                            =
; =                                                                              =
; = Exercises Search First and Next, all four DMA slots, wildcard continuation   =
; = and restart, and paired fixtures while rejecting FFH before slot arithmetic. =
; ================================================================================
; -------------------------------------------------------------------------------
; Search First and DMA Slots
; -------------------------------------------------------------------------------

  ; --- Search First and directory-transfer probes -------------------------
  ; DOSEARCH centralizes selection, FFh rejection, slot arithmetic and restore.

P0188: CALL    DOSEARCH                 ; probe catalog item 188
        CP      0FFH
        JP      Z,FAILRET
        XOR     A
        RET

P0189: JP      P0188                    ; probe catalog item 189

P0190: CALL    DOSEARCH                 ; probe catalog item 190
        CP      4
        JP      NC,FAILRET
        XOR     A
        RET

P0191: CALL    SAVEDRV                  ; probe catalog item 191
        LD      E,1
        LD      C,14
        CALL    BDOS
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        LD      DE,NOMFCB
        LD      C,17
        CALL    BDOS
        LD      (RETVAL),A
        CALL    RESTDRV
        LD      A,(RETVAL)
        CP      0FFH
        JP      RETCMP

P0192: LD      HL,0080H                 ; probe catalog item 192
        LD      B,128
        LD      A,0A5H
        CALL    FILL
        CALL    DOSEARCH
        CP      0FFH
        JP      Z,FAILRET
        LD      HL,(SEARCHPTR)
        LD      A,(HL)
        CP      0A5H
        JP      Z,FAILRET
        XOR     A
        RET

P0193: LD      HL,0080H                 ; probe catalog item 193
        LD      B,128
        LD      A,0A5H
        CALL    FILL
        CALL    DOSEARCH
        CP      0FFH
        JP      Z,FAILRET
        LD      HL,(SEARCHPTR)
        LD      A,(HL)
        CP      0A5H
        JP      Z,FAILRET
        XOR     A
        RET

P0194: CALL    DOSEARCH                 ; probe catalog item 194
        CP      0FFH
        JP      Z,FAILRET
        LD      HL,(SEARCHPTR)
        LD      DE,9
        ADD     HL,DE
        LD      A,(HL)
        AND     7FH
        CP      'C'
        JP      NZ,FAILRET
        INC     HL
        LD      A,(HL)
        AND     7FH
        CP      'O'
        JP      NZ,FAILRET
        INC     HL
        LD      A,(HL)
        AND     7FH
        CP      'M'
        JP      RETCMP

P0195: CALL    DOSEARCH                 ; probe catalog item 195
        CP      0FFH
        JP      Z,FAILRET
        LD      HL,(SEARCHPTR)
        LD      A,(HL)
        OR      A
        RET

SAVEDRV:CALL   GETDRV                   ; savedrv
        LD      (OLDDRV),A
        RET

; -------------------------------------------------------------------------------
; Disposable Search Fixture
; -------------------------------------------------------------------------------

  ; Perform the whole Make/Close/Delete lifecycle; accept only a successful Make.

TMPMAKE:                                ; tmpmake
        LD      DE,TMPFCB
        LD      C,19
        CALL    BDOS
        LD      DE,TMPFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        JP      Z,FAILRET
        LD      DE,TMPFCB
        LD      C,16
        CALL    BDOS
        LD      DE,TMPFCB
        LD      C,19
        CALL    BDOS
        XOR     A
        RET

TMPDONE:                                ; tmpdone
        LD      (RETVAL),A
        CALL    RESTDRV
        LD      A,(RETVAL)
        RET

DOSEARCH:                               ; dosearch
        CALL    SAVEDRV
        LD      E,1
        LD      C,14
        CALL    BDOS
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        LD      DE,WILDFCB
        LD      C,17
        CALL    BDOS
        LD      (RETVAL),A
        CP      0FFH
        JP      Z,DSREST
        LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      DE,0080H
        ADD     HL,DE
        LD      (SEARCHPTR),HL

DSREST:CALL    RESTDRV                  ; dsrest
        LD      A,(RETVAL)
        RET

; -------------------------------------------------------------------------------
; Search Next, Wildcards, and Restart
; -------------------------------------------------------------------------------

  ; --- Search continuation and wildcard probes ----------------------------
  ; Retain one name byte, then distinguish continuation from a fresh First
  ; without assuming which BDS?.TMP member appears first.

P0197: CALL    SEARCHPAIR               ; probe catalog item 197
        LD      (RETVAL),A
        CALL    ENDSEARCH
        LD      A,(RETVAL)
        CP      0FFH
        JP      Z,FAILRET
        XOR     A
        RET

P0199: JP      P0197                    ; probe catalog item 199

P0201: CALL    SAVEDRV                  ; probe catalog item 201
        LD      E,1
        LD      C,14
        CALL    BDOS
        LD      A,7
        LD      (TWOFCB+14),A
        LD      DE,TWOFCB
        LD      C,17
        CALL    BDOS
        LD      (RETVAL),A
        XOR     A
        LD      (TWOFCB+14),A
        CALL    ENDSEARCH
        LD      A,(RETVAL)
        CP      0FFH
        JP      Z,FAILRET
        XOR     A
        RET

P0203: CALL    SEARCHPAIR               ; probe catalog item 203
        CP      0FFH
        JP      Z,SCHFAIL
        LD      C,18
        CALL    BDOS
        LD      (RETVAL),A
        CALL    ENDSEARCH
        LD      A,(RETVAL)
        CP      4
        JP      NC,FAILRET
        XOR     A
        RET

P0205: CALL    SEARCHPAIR               ; probe catalog item 205
        CP      0FFH
        JP      Z,SCHFAIL
        LD      HL,(SEARCHPTR)
        LD      DE,4
        ADD     HL,DE
        LD      A,(HL)
        LD      (FIRSTCHAR),A
        LD      C,18
        CALL    BDOS
        CP      4
        JP      NC,SCHFAIL
        CALL    RESULTPTR
        LD      DE,4
        ADD     HL,DE
        LD      A,(FIRSTCHAR)
        CP      (HL)
        JP      Z,SCHFAIL
        CALL    ENDSEARCH
        XOR     A
        RET

P0207: CALL    SEARCHPAIR               ; probe catalog item 207
        CP      0FFH
        JP      Z,SCHFAIL
        LD      HL,(SEARCHPTR)
        LD      DE,4
        ADD     HL,DE
        LD      A,(HL)
        LD      (FIRSTCHAR),A
        LD      C,18
        CALL    BDOS
        LD      DE,TWOFCB
        LD      C,17
        CALL    BDOS
        CP      4
        JP      NC,SCHFAIL
        CALL    RESULTPTR
        LD      DE,4
        ADD     HL,DE
        LD      A,(FIRSTCHAR)
        CP      (HL)
        JP      NZ,SCHFAIL
        CALL    ENDSEARCH
        XOR     A
        RET

P0209: CALL    SAVEDRV                  ; probe catalog item 209
        LD      E,1
        LD      C,14
        CALL    BDOS
        LD      HL,ALTDMA
        LD      B,128
        LD      A,0A5H
        CALL    FILL
        LD      DE,ALTDMA
        LD      C,26
        CALL    BDOS
        XOR     A
        LD      (TWOFCB+14),A
        LD      DE,TWOFCB
        LD      C,17
        CALL    BDOS
        CP      0FFH
        JP      Z,SCHFAIL
        LD      C,18
        CALL    BDOS
        CP      4
        JP      NC,SCHFAIL
        LD      A,(ALTDMA)
        CP      0A5H
        JP      Z,SCHFAIL
        CALL    ENDSEARCH
        XOR     A
        RET

P0211: CALL    SEARCHPAIR               ; probe catalog item 211
        CP      0FFH
        JP      Z,SCHFAIL
        LD      HL,(SEARCHPTR)
        LD      DE,4
        ADD     HL,DE
        LD      A,(HL)
        CP      'A'
        JP      NZ,SCHFAIL
        LD      C,18
        CALL    BDOS
        CP      4
        JP      NC,SCHFAIL
        CALL    RESULTPTR
        LD      DE,4
        ADD     HL,DE
        LD      A,(HL)
        CP      'B'
        JP      NZ,SCHFAIL
        CALL    ENDSEARCH
        XOR     A
        RET

P0213: LD      HL,O0213                 ; probe catalog item 213
        LD      (OBSPTR),HL
        XOR     A
        RET

P0215: LD      HL,O0215                 ; probe catalog item 215
        LD      (OBSPTR),HL
        XOR     A
        RET

P0517: LD      HL,O0517                 ; probe catalog item 517
        LD      (OBSPTR),HL
        XOR     A
        RET

; -------------------------------------------------------------------------------
; Paired Search Fixture
; -------------------------------------------------------------------------------

  ; SEARCHPAIR leaves the search live; callers finish through ENDSEARCH.

SEARCHPAIR:                             ; searchpair
        CALL    SAVEDRV
        LD      E,1
        LD      C,14
        CALL    BDOS
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        XOR     A
        LD      (TWOFCB+14),A
        LD      DE,TWOFCB
        LD      C,17
        CALL    BDOS
        LD      (RETVAL),A
        CP      0FFH
        RET     Z
        CALL    RESULTPTR
        LD      (SEARCHPTR),HL
        LD      A,(RETVAL)
        RET
  ; Convert A=0..3 to DMA+32*A.  Callers have already rejected FFh.

RESULTPTR:                              ; resultptr
        LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      DE,0080H
        ADD     HL,DE
        RET

SCHFAIL:CALL   ENDSEARCH                ; schfail
        JP      FAILRET

ENDSEARCH:                              ; endsearch
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        JP      RESTDRV

; ================================================================================
; =                 Identity, User, DMA, and System-State Probes                 =
; =                                                                              =
; = Tests identity calls, user-number state, sticky DMA behavior, and visible    =
; = system contracts without relying on fixed internal addresses.                =
; ================================================================================
; -------------------------------------------------------------------------------
; Identity and Sticky DMA
; -------------------------------------------------------------------------------

  ; --- Identity, user-number, DMA, and system-state probes ----------------
  ; Put identity calls between Set DMA and Search First; changed A5h paint proves
  ; that the selected DMA survived the intervening call.

P0414: JP      P0035                    ; probe catalog item 414

P0415: LD      E,0FFH                   ; probe catalog item 415
        LD      C,32
        CALL    BDOS
        CP      16
        JP      NC,FAILRET
        XOR     A
        RET

P0416: LD      E,0FFH                   ; probe catalog item 416
        LD      C,32
        CALL    BDOS
        LD      (OLDUSR),A
        LD      E,1
        LD      C,32
        CALL    BDOS
        LD      E,0FFH
        LD      C,32
        CALL    BDOS
        LD      (RETVAL),A
        CALL    RESTUSER
        LD      A,(RETVAL)
        CP      1
        JP      RETCMP

P0417: LD      E,0FFH                   ; probe catalog item 417
        LD      C,32
        CALL    BDOS
        LD      (OLDUSR),A
        LD      E,1
        LD      C,32
        CALL    BDOS
        LD      (RETVAL),A
        CALL    RESTUSER
        LD      HL,DIAG32
        LD      (OBSPTR),HL
        LD      DE,11
        ADD     HL,DE
        LD      A,(RETVAL)
        CALL    HEXMEM
        XOR     A
        RET

P0418: LD      HL,ALTDMA                ; probe catalog item 418
        LD      B,128
        LD      A,05AH
        CALL    FILL
        LD      DE,ALTDMA
        LD      C,26
        CALL    BDOS
        LD      C,11
        CALL    BDOS
        LD      A,(ALTDMA)
        LD      (RETVAL),A
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        LD      A,(RETVAL)
        CP      05AH
        JP      RETCMP

P0419: CALL    IDDMATEST                ; probe catalog item 419
        RET

P0520: CALL    IDDMATEST                ; probe catalog item 520
        RET

IDDMATEST:                              ; iddmatest
        CALL    SAVEDRV
        LD      E,1
        LD      C,14
        CALL    BDOS
        LD      HL,ALTDMA
        LD      B,128
        LD      A,0A5H
        CALL    FILL
        LD      DE,ALTDMA
        LD      C,26
        CALL    BDOS
        LD      C,12
        CALL    BDOS
        CALL    GETDRV
        LD      DE,WILDFCB
        LD      C,17
        CALL    BDOS
        LD      (RETVAL),A
        LD      A,(ALTDMA)
        LD      (FIRSTCHAR),A
        CALL    ENDSEARCH
        LD      A,(RETVAL)
        CP      0FFH
        JP      Z,FAILRET
        LD      A,(FIRSTCHAR)
        CP      0A5H
        JP      Z,FAILRET
        XOR     A
        RET

; -------------------------------------------------------------------------------
; User and System State
; -------------------------------------------------------------------------------

P0518: CALL    GETDRV                   ; probe catalog item 518
        CP      16
        JP      NC,FAILRET
        LD      E,0FFH
        LD      C,32
        CALL    BDOS
        CP      16
        JP      NC,FAILRET
        LD      C,24
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,FAILRET
        XOR     A
        RET

  ; Change only the user, prove the disk did not move, then restore both.

P0521: CALL    SAVEDRV                  ; probe catalog item 521
        LD      E,0FFH
        LD      C,32
        CALL    BDOS
        LD      (OLDUSR),A
        LD      E,1
        LD      C,32
        CALL    BDOS
        CALL    GETDRV
        LD      D,A
        LD      A,(OLDDRV)
        CP      D
        JP      NZ,STATEFAIL
        LD      E,0FFH
        LD      C,32
        CALL    BDOS
        CP      1
        JP      NZ,STATEFAIL
        CALL    RESTUSER
        CALL    RESTDRV
        XOR     A
        RET

STATEFAIL:                              ; statefail
        CALL    RESTUSER
        CALL    RESTDRV
        JP      FAILRET

RESTUSER:                               ; restuser
        LD      A,(OLDUSR)
        LD      E,A
        LD      C,32
        JP      BDOS

; ================================================================================
; =                          Final Consolidation Probes                          =
; =                                                                              =
; = Collects remaining state and contract evidence, including live ALV and DPB   =
; = addresses as observations rather than fixed implementation requirements.     =
; ================================================================================
; -------------------------------------------------------------------------------
; Consolidation Cards
; -------------------------------------------------------------------------------

  ; --- Final catalog consolidation probes ---------------------------------
  ; Live ALV and DPB addresses are printed as evidence, never fixed addresses.

P0522: LD      C,27                     ; probe catalog item 522
        CALL    BDOS
        LD      (REGWORD),HL
        LD      C,31
        CALL    BDOS
        LD      (SPBEFORE),HL
        LD      HL,DIAGPTR
        LD      (OBSPTR),HL
        LD      DE,4
        ADD     HL,DE
        LD      A,(REGWORD+1)
        CALL    HEXMEM
        LD      A,(REGWORD)
        CALL    HEXMEM
        LD      DE,5
        ADD     HL,DE
        LD      A,(SPBEFORE+1)
        CALL    HEXMEM
        LD      A,(SPBEFORE)
        CALL    HEXMEM
        XOR     A
        RET

P0525: CALL    P0041                    ; probe catalog item 525
        OR      A
        RET     NZ
        JP      P0042

P0526: JP      P0035                    ; probe catalog item 526

P0527: JP      P0036                    ; probe catalog item 527

P0528: LD      C,24                     ; probe catalog item 528
        CALL    BDOS
        LD      D,A
        LD      E,B
        LD      A,L
        CP      D
        JP      NZ,FAILRET
        LD      A,H
        CP      E
        JP      RETCMP

P0529: JP      P0042                    ; probe catalog item 529

P0530: LD      C,12                     ; probe catalog item 530
        CALL    BDOS
        LD      HL,O0530
        LD      (OBSPTR),HL
        XOR     A
        RET

P0531: JP      P0043                    ; probe catalog item 531

P0532: LD      HL,O0532                 ; probe catalog item 532
        LD      (OBSPTR),HL
        XOR     A
        RET

  ; TEST INSTRUMENTS -- zero means agreement, one means disagreement.

RETCMP:JP      NZ,FAILRET               ; retcmp
        XOR     A
        RET

GETDRV:LD      C,25                     ; getdrv
        JP      BDOS

RESTDRV:                                ; restdrv
        LD      A,(OLDDRV)
        LD      E,A
        LD      C,14
        JP      BDOS

; -------------------------------------------------------------------------------
; Test Instruments
; -------------------------------------------------------------------------------

FILL:  LD      (HL),A                   ; fill
        INC     HL
        DEC     B
        JP      NZ,FILL
        RET

SHOWWORD:                               ; showword
        EX      DE,HL
        LD      (OBSPTR),HL
        INC     HL
        INC     HL
        INC     HL
        LD      A,(REGWORD+1)
        CALL    HEXMEM
        LD      A,(REGWORD)
        CALL    HEXMEM
        XOR     A
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
; =                       Reporting and Diagnostic Output                        =
; =                                                                              =
; = Prints aggregate counts, failed-item lists, numeric and hexadecimal          =
; = diagnostics, and supporting evidence for the completed conformance run.      =
; ================================================================================
; -------------------------------------------------------------------------------
; Summary and Failure List
; -------------------------------------------------------------------------------

SUMMARY:                                ; print run summary
        LD      DE,SUM1
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
        JP      PRINTFAILS

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

PUTITEM:                                ; print catalog item number
        LD      HL,(CURITEM)
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

SUBHLDE:                                ; subhlde
        LD      A,L
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

PUTHEX:PUSH    AF                       ; puthex
        RRCA
        RRCA
        RRCA
        RRCA
        AND     0FH
        CALL    PUTNIB
        POP     AF
        AND     0FH

PUTNIB:CP      10                       ; putnib
        JP      C,PNDIG
        ADD     A,'A'-10
        JP      PNHAVE

PNDIG: ADD     A,'0'                    ; pndig

PNHAVE:LD      E,A                      ; pnhave
        LD      C,2
        JP      BDOS

PUTS:  LD      C,9                      ; print $-terminated string
        JP      BDOS

; ================================================================================
; =                      Conformance Catalog and Help Text                       =
; =                                                                              =
; = Defines the nine-byte case deck, command and help text, functional-group     =
; = ranges, result markers, and observation/reporting strings used by the        =
; = runner.                                                                      =
; ================================================================================
; -------------------------------------------------------------------------------
; Case Deck
; -------------------------------------------------------------------------------

CASES:                                  ; conformance case catalog
        DW 34,P0035,OOSOBS,R0034
        DB 6
        DW 35,P0035,O0035,R0035
        DB 0
        DW 36,P0036,O0036,R0036
        DB 0
        DW 37,P0037,O0037,R0037
        DB 0
        DW 38,P0038,O0038,R0038
        DB 0
        DW 39,P0039,O0039,R0039
        DB 0
        DW 40,P0040,O0040,R0040
        DB 0
        DW 41,P0041,O0041,R0041
        DB 0
        DW 42,P0042,O0042,R0042
        DB 0
        DW 43,P0043,O0043,R0043
        DB 0
        DW 44,P0035,OOSOBS,R0044
        DB 6
        DW 45,P0045,O0045,R0045
        DB 1
        DW 46,P0046,O0046,R0046
        DB 1
        DW 47,P0047,O0047,R0047
        DB 1
        DW 48,P0048,O0048,R0048
        DB 1
        DW 49,P0049,O0049,R0049
        DB 1
        DW 50,P0035,OOSOBS,R0050
        DB 6
        DW 131,P0035,OOSOBS,R0131
        DB 6
        DW 132,P0132,O0132,R0132
        DB 0
        DW 133,P0133,O0133,R0133
        DB 0
        DW 134,P0134,O0134,R0134
        DB 0
        DW 135,P0135,O0135,R0135
        DB 0
        DW 136,P0136,O0136,R0136
        DB 0
        DW 137,P0137,O0137,R0137
        DB 1
        DW 138,P0138,O0138,R0138
        DB 0
        DW 139,P0139,O0139,R0139
        DB 0
        DW 140,P0140,O0140,R0140
        DB 0
        DW 141,P0141,O0141,R0141
        DB 0
        DW 142,P0142,O0142,R0142
        DB 0
        DW 143,P0035,O0143,R0143
        DB 2
        DW 144,P0144,O0144,R0144
        DB 0
        DW 145,P0145,O0145,R0145
        DB 0
        DW 146,P0146,O0146,R0146
        DB 0
        DW 147,P0147,O0147,R0147
        DB 0
        DW 148,P0148,O0148,R0148
        DB 0
        DW 149,P0149,O0149,R0149
        DB 0
        DW 150,P0150,O0150,R0150
        DB 0
        DW 151,P0151,O0151,R0151
        DB 1
        DW 152,P0035,OOSOBS,R0152
        DB 6
        DW 153,P0035,OOSOBS,R0153
        DB 6
        DW 154,P0035,O0154,R0154
        DB 3
        DW 187,P0035,OOSOBS,R0187
        DB 6
        DW 188,P0188,O0188,R0188
        DB 0
        DW 189,P0189,O0189,R0189
        DB 0
        DW 190,P0190,O0190,R0190
        DB 0
        DW 191,P0191,O0191,R0191
        DB 0
        DW 192,P0192,O0192,R0192
        DB 0
        DW 193,P0193,O0193,R0193
        DB 0
        DW 194,P0194,O0194,R0194
        DB 0
        DW 195,P0195,O0195,R0195
        DB 0
        DW 197,P0197,O0197,R0197
        DB 0
        DW 199,P0199,O0199,R0199
        DB 0
        DW 201,P0201,O0201,R0201
        DB 0
        DW 203,P0203,O0203,R0203
        DB 0
        DW 205,P0205,O0205,R0205
        DB 0
        DW 207,P0207,O0207,R0207
        DB 0
        DW 209,P0209,O0209,R0209
        DB 0
        DW 211,P0211,O0211,R0211
        DB 0
        DW 213,P0213,O0213,R0213
        DB 1
        DW 215,P0215,O0215,R0215
        DB 1
        DW 217,P0035,OOSOBS,R0217
        DB 6
        DW 413,P0035,O0413,R0413
        DB 4
        DW 414,P0414,O0414,R0414
        DB 0
        DW 415,P0415,O0415,R0415
        DB 0
        DW 416,P0416,O0416,R0416
        DB 0
        DW 417,P0417,O0417,R0417
        DB 1
        DW 418,P0418,O0418,R0418
        DB 0
        DW 419,P0419,O0419,R0419
        DB 0
        DW 420,P0035,O0420,R0420
        DB 2
        DW 422,P0035,OOSOBS,R0422
        DB 6
        DW 517,P0517,O0517,R0517
        DB 1
        DW 518,P0518,O0518,R0518
        DB 0
        DW 519,P0035,O0519,R0519
        DB 2
        DW 520,P0520,O0520,R0520
        DB 0
        DW 521,P0521,O0521,R0521
        DB 0
        DW 522,P0522,O0522,R0522
        DB 1
        DW 523,P0035,O0523,R0523
        DB 4
        DW 524,P0035,OOSOBS,R0524
        DB 6
        DW 525,P0525,O0525,R0525
        DB 0
        DW 526,P0526,O0526,R0526
        DB 0
        DW 527,P0527,O0527,R0527
        DB 0
        DW 528,P0528,O0528,R0528
        DB 0
        DW 529,P0529,O0529,R0529
        DB 0
        DW 530,P0530,O0530,R0530
        DB 1
        DW 531,P0531,O0531,R0531
        DB 0
        DW 532,P0532,O0532,R0532
        DB 1

BADSEL:DB 13,10,'BDOSTEST: unknown selector. Use BDOSTEST /HELP.',13,10 ; badsel
        DB 'Use BDOSTEST /GROUP:LIST for available groups.',13,10,'$'

HLPMSG:DB 13,10,'BDOSTEST 1.0.0-dev15',13,10,13,10 ; hlpmsg
        DB '  BDOSTEST /NNNN[:REPORT]     Run, explain, or report one item',13,10
        DB '  BDOSTEST /ALL               Run checks and report all items',13,10
        DB '  BDOSTEST /SAFE              Run checks requiring no destructive media',13,10
        DB '  BDOSTEST /LIST              List ledger items by useful group',13,10
        DB '  BDOSTEST /GROUP:LIST        List all available groupings',13,10
        DB '  BDOSTEST /GROUP:name        Run a tool-specific group',13,10
        DB '                              (run /GROUP:LIST for available groups)',13,10
        DB '  BDOSTEST /H, /HELP          Show concise command help',13,10
        DB '  BDOSTEST /INFO              Show build information',13,10
        DB '  BDOSTEST /VER, /VERSION     Show name and version',13,10,'$'

VERMSG:DB 13,10,'BDOSTEST 1.0.0-dev15',13,10,'$' ; vermsg
RESMSG:DB 13,10,'BDOSTEST result terminology',13,10,13,10 ; resmsg
        DB 'STATUS: P=Pass F=Fail -=Not-run O=Observed.',13,10
        DB 'PASS=completed and matched; FAIL=completed and mismatched.',13,10
        DB 'CLASS: R=Required N=Not-guaranteed S=Out-of-scope X=Profile.',13,10
        DB 'PROFILE=required only when its named profile is claimed.',13,10
        DB 'OPTIONAL=optional catalog behavior not selected.',13,10
        DB 'OUT SCOPE=BDOSTEST cannot execute or judge the item.',13,10
        DB 'OBSERVED gives evidence or the command still required.',13,10,'$'

PRFMSG:DB 13,10,'BDOSTEST named profiles',13,10,13,10 ; prfmsg
        DB 'UNAVAILABLE-DRIVE: requires a declared nonexistent drive (0154).',13,10
        DB 'A PROFILE row applies only when that named setup is claimed.',13,10
        DB 'Run the numbered item for prerequisites and expected behavior.',13,10
        DB 'For item 0143, prepare expendable media with SCRATCH /BLANK.',13,10,'$'

INFMSG:DB 'BDOSTEST 1.0.0-dev15',13,10  ; infmsg
        DB 'Implemented: all 86 assigned rows',13,10
        DB 'Required: 59 (3 manual); diagnostics: 14',13,10
        DB 'Profile: 1 manual; optional: 2; outside scope: 10',13,10
        DB 'Catalog rows represented: 86 of 86; remaining 0',13,10,'$'

LSTMSG:DB 13,10,'CLASS: R=Required N=Not-guaranteed S=Out-of-scope X=Profile',13,10 ; lstmsg
        DB 13,10,'GATEWAY (17)',13,10
        DB '  0034 S Exact BIOS/BDOS vector targets',13,10
        DB '  0035 R BDOS function selector in C',13,10
        DB '  0036 R BDOS function-specific input in DE/E',13,10
        DB '  0037 R Byte result in A',13,10
        DB '  0038 R Word result in HL',13,10
        DB '  0039 R Normal-return alias A=L',13,10
        DB '  0040 R Normal-return alias B=H',13,10
        DB '  0041 R CP/M 2.2 BDOS selector range',13,10
        DB '  0042 R Out-of-range BDOS result',13,10
        DB '  0043 R Caller SP restored on returning BDOS calls',13,10
        DB '  0044 S DRI private BDOS stack mechanism',13,10
        DB '  0045 N AF preservation across BDOS',13,10
        DB '  0046 N BC preservation across BDOS',13,10
        DB '  0047 N DE preservation across BDOS',13,10
        DB '  0048 N HL preservation across BDOS',13,10
        DB '  0049 N Z80-only and alternate-register preservation',13,10
        DB '  0050 S Valid-call C becomes input E',13,10
        DB 13,10,'DRIVE STATE (24)',13,10
        DB '  0131 S DRI function-10 zero common result',13,10
        DB '  0132 R Function 13 selector',13,10
        DB '  0133 R Function 13 read/write reset',13,10
        DB '  0134 R Function 13 selects drive A',13,10
        DB '  0135 R Function 13 restores default DMA',13,10
        DB '  0136 R Function 13 resets login vector',13,10
        DB '  0137 N Function 13 function-specific result',13,10
        DB '  0138 R Function 14 selector',13,10
        DB '  0139 R Function 14 drive numbering',13,10
        DB '  0140 R Function 14 changes current disk',13,10
        DB '  0141 R Function 14 logs selected drive',13,10
        DB '  0142 R Login vector is cumulative',13,10
        DB '  0143 R Standard media-change read-only behavior',13,10
        DB '  0144 R FCB drive code zero uses current disk',13,10
        DB '  0145 R Explicit FCB drive selection',13,10
        DB '  0146 R Explicit FCB selection does not permanently change current disk',13,10
        DB '  0147 R Function 24 login vector result',13,10
        DB '  0148 R Login vector bit mapping',13,10
        DB '  0149 R Login bit meaning',13,10
        DB '  0150 R Function 25 current disk result',13,10
        DB '  0151 N Function 14 invalid-drive result',13,10
        DB '  0152 S Function 13/14 synchronization of page-zero 0004h',13,10
        DB '  0153 S DRI private disk-state implementation',13,10
        DB '  0154 X Unavailable-drive presentation',13,10
        DB 13,10,'DIRECTORY SEARCH (20)',13,10
        DB '  0187 S Host byte count in reserved S1 is not required by CP/M 2.2',13,10
        DB '  0188 R Search First call convention',13,10
        DB '  0189 R Search First initial directory scan position',13,10
        DB '  0190 R Search First successful result code',13,10
        DB '  0191 R Search First unsuccessful result code',13,10
        DB '  0192 R Search First DMA record transfer',13,10
        DB '  0193 R Search result entry offset',13,10
        DB '  0194 R Search transfer record layout',13,10
        DB '  0195 R Directory entry user number',13,10
        DB '  0197 R Search wildcard matching',13,10
        DB '  0199 R Default-drive FCB search',13,10
        DB '  0201 R Search First S2 handling',13,10
        DB '  0203 R Search Next call convention',13,10
        DB '  0205 R Search Next result and DMA relationship',13,10
        DB '  0207 R Search First restart behavior',13,10
        DB '  0209 R DMA address persistence',13,10
        DB '  0211 R Directory enumeration order',13,10
        DB '  0213 N Enumeration ordering guarantee limitation',13,10
        DB '  0215 N Search continuation state limitation',13,10
        DB '  0217 S DRI FFh-path directory copy',13,10
        DB 13,10,'IDENTITY AND DMA (9)',13,10
        DB '  0413 X Structured physical-error extension',13,10
        DB '  0414 R Function 12 CP/M version result',13,10
        DB '  0415 R Function 32 user-number query',13,10
        DB '  0416 R Function 32 user-number selection',13,10
        DB '  0417 N Function 32 set-form result',13,10
        DB '  0418 R Console functions do not use or overwrite DMA',13,10
        DB '  0419 R Console and identity calls preserve DMA selection',13,10
        DB '  0420 R Function 10 DE buffer is not DMA',13,10
        DB '  0422 S Function 6 E=FEh behavior',13,10
        DB 13,10,'SYSTEM STATE (8)',13,10
        DB '  0517 N Malformed FCB behavior is outside the portable contract',13,10
        DB '  0518 R BDOS system state components',13,10
        DB '  0519 R BIOS-owned selected-drive resources',13,10
        DB '  0520 R Function 26 persistence boundary',13,10
        DB '  0521 R System-state independence',13,10
        DB '  0522 N ALV and DPB pointer lifetime',13,10
        DB '  0523 X Function 37 state-effect profile scope',13,10
        DB '  0524 S CP/M 2.2 Function 39 has no Get-BIOS contract',13,10
        DB 13,10,'PORTABLE CALL CONTRACT (8)',13,10
        DB '  0525 R CP/M 2.2 selectors 40 and 41',13,10
        DB '  0526 R Common BDOS gateway and invocation',13,10
        DB '  0527 R Common selector and parameter carriers',13,10
        DB '  0528 R Common result and alias convention',13,10
        DB '  0529 R Strict CP/M 2.2 unsupported selectors',13,10
        DB '  0530 N General register preservation',13,10
        DB '  0531 R Returning-call stack balance',13,10
        DB '  0532 N Invalid parameters are function-specific',13,10
        DB 13,10,'TOTAL: 86 ITEMS',13,10,'$'

; -------------------------------------------------------------------------------
; Group and Result Tables
; -------------------------------------------------------------------------------

GRPLIST:DB 13,10,'BDOSTEST GROUPS',13,10,13,10 ; grplist
        DB 'FUNCTIONAL',13,10
        DB '  GATEWAY      17  BDOS entry, arguments, results, registers',13,10
        DB '  DRIVE        24  Reset, selection, login, and drive state',13,10
        DB '  DIRECTORY    20  Search calls and directory transfers',13,10
        DB '  IDENTITY      9  Version, user, console, and DMA identity',13,10
        DB '  STATE         8  System-state components and lifetimes',13,10
        DB '  CONTRACT      8  Portable gateway and calling contract',13,10
        DB 13,10,'UNIVERSAL',13,10
        DB '  REQUIRED     59  REQUIRED catalog items',13,10
        DB '  OBSERVATION  14  NOT GUARANTEED observations',13,10
        DB '  MANUAL        4  Manual/profile procedures (lists only)',13,10,'$'

HEADER: DB 13,10,'BDOSTEST',13,10       ; header
        DB 'ITEM  S  C  OBSERVED',13,10
        DB '----  -  -  ----------------------------------------------------------',13,10,'$'

SPASS: DB 'P  R  $'                     ; spass
SFAIL: DB 'F  R  $'                     ; sfail
SOBS:  DB 'O  N  $'                     ; sobs
SOBFAIL:DB 'F  N  $'                    ; sobfail
SOOS:  DB '-  S  $'                     ; soos
SMAN:  DB '-  R  $'                     ; sman
SPROF: DB '-  X  $'                     ; sprof
SOPT:  DB '-  X  $'                     ; sopt
OOSOBS:DB 'Outside executable scope$'   ; oosobs
TWO:   DB '  $'                         ; two
CRLF:  DB 13,10,'$'                     ; crlf
SUM1:  DB 13,10,'Summary: $'            ; sum1
SUM2:  DB ' pass, $'                    ; sum2
SUM3:  DB ' fail, 0 error, $'           ; sum3
SUM4:  DB ' observations',13,10,'$'     ; sum4
FAILMSG:DB 'Failed items: $'            ; failmsg
FSPACE:DB ' $'                          ; fspace
REQMAN:DB '3 manual REQUIRED procedures were listed but not run.',13,10,'$' ; reqman
MANMSG:DB 13,10,'4 manual/profile procedures listed; none executed.',13,10,'$'
RPTMSG:DB 'REPORT: $'                   ; rptmsg
DIAGAF:DB 'AF=0000; not guaranteed$'
DIAGBC:DB 'BC=0000; not guaranteed$'
DIAGDE:DB 'DE=0000; not guaranteed$'
DIAGHL:DB 'HL=0000; not guaranteed$'
DIAGALT:DB 'Alt registers not read$'    ; diagalt
DIAG13:DB 'Fn13 A=00; no fixed value$'
DIAG32:DB 'Set-user A=00; not guaranteed$'
DIAGPTR:DB 'ALV=0000 DPB=0000$'         ; diagptr

; ================================================================================
; =                             Observation Records                              =
; =                                                                              =
; = Defines compact observation records associated with catalog items and        =
; = diagnostic evidence.                                                         =
; ================================================================================
; -------------------------------------------------------------------------------
; Observation Table
; -------------------------------------------------------------------------------

O0035: DB 'C=12 selected version (22h)$' ; observation record for item 35
O0036: DB 'E=0 selected drive A$'       ; observation record for item 36
O0037: DB 'Fn 25 returned byte in A$'   ; observation record for item 37
O0038: DB 'Fn 24 returned word in HL$'  ; observation record for item 38
O0039: DB 'Normal return alias A=L$'    ; observation record for item 39
O0040: DB 'Normal return alias B=H$'    ; observation record for item 40
O0041: DB 'Selector range ends at Fn 40$' ; observation record for item 41
O0042: DB 'Fn 41 returned zero$'        ; observation record for item 42
O0043: DB 'Caller stack restored$'      ; observation record for item 43
O0045: DB 'AF recorded; not guaranteed$'
O0046: DB 'BC recorded; not guaranteed$'
O0047: DB 'DE recorded; not guaranteed$'
O0048: DB 'HL recorded; not guaranteed$'
O0049: DB 'Alt registers not portable$' ; observation record for item 49
O0132: DB 'Fn 13 reset disks; chose A$'
O0133: DB 'Fn 13 cleared R/O vector$'   ; observation record for item 133
O0134: DB 'Fn 13 selected drive A$'     ; observation record for item 134
O0135: DB 'Fn 13 restored DMA at 0080h$' ; observation record for item 135
O0136: DB 'Fn 13 reset login vector$'   ; observation record for item 136
O0137: DB 'Fn 13 result has no fixed value$' ; observation record for item 137
O0138: DB 'Fn 14 E=1 selected drive B$' ; observation record for item 138
O0139: DB 'Drive numbering is zero based$' ; observation record for item 139
O0140: DB 'Fn 14 changed current drive$' ; observation record for item 140
O0141: DB 'Fn 14 logged selected drive$' ; observation record for item 141
O0142: DB 'Login vector accumulated A+B$' ; observation record for item 142
O0143: DB 'Prepare fixture with SCRATCH /BLANK$' ; observation record for item 143
O0144: DB 'FCB drive 0 used current disk$' ; observation record for item 144
O0145: DB 'Explicit FCB selected drive B$' ; observation record for item 145
O0146: DB 'Explicit FCB kept current drive$' ; observation record for item 146
O0147: DB 'Fn 24 returned login vector$' ; observation record for item 147
O0148: DB 'Login bits map A=0, B=1$'    ; observation record for item 148
O0149: DB 'Set bit means drive logged$' ; observation record for item 149
O0150: DB 'Fn 25 returned current drive$' ; observation record for item 150
O0151: DB 'Invalid drive call not portable$' ; observation record for item 151
O0154: DB 'UNAVAILABLE-DRIVE: Run: BDOSTEST /0154$' ; observation record for item 154
O0188: DB 'Search First accepted FCB in DE$' ; observation record for item 188
O0189: DB 'Search First began new scan$' ; observation record for item 189
O0190: DB 'Search success returned 0..3$' ; observation record for item 190
O0191: DB 'No match returned FFh$'      ; observation record for item 191
O0192: DB 'Search copied entry to DMA$' ; observation record for item 192
O0193: DB 'Result selected 32-byte slot$' ; observation record for item 193
O0194: DB 'Search entry layout matched FCB$' ; observation record for item 194
O0195: DB 'Entry user number was zero$' ; observation record for item 195
O0197: DB 'Wildcard matched search names$' ; observation record for item 197
O0199: DB 'Drive 0 searched current disk$' ; observation record for item 199
O0201: DB 'Search First tolerated S2 input$' ; observation record for item 201
O0203: DB 'Search Next continued scan$' ; observation record for item 203
O0205: DB 'Search Next updated DMA slot$' ; observation record for item 205
O0207: DB 'Search First restarted scan$' ; observation record for item 207
O0209: DB 'DMA persisted for search$'   ; observation record for item 209
O0211: DB 'Enumeration followed entries$' ; observation record for item 211
O0213: DB 'Order varies across media$'  ; observation record for item 213
O0215: DB 'Continuation state is private$' ; observation record for item 215
O0413: DB 'Structured errors not requested$' ; observation record for item 413
O0414: DB 'Fn 12 returned CP/M 2.2$'    ; observation record for item 414
O0415: DB 'Fn 32 queried user number$'  ; observation record for item 415
O0416: DB 'Fn 32 selected user 1$'      ; observation record for item 416
O0417: DB 'Set-user result not guaranteed$' ; observation record for item 417
O0418: DB 'Console status preserved DMA$' ; observation record for item 418
O0419: DB 'Identity calls preserved DMA$' ; observation record for item 419
O0420: DB 'Needs buffered-input session$' ; observation record for item 420
O0517: DB 'Malformed FCB not portable$' ; observation record for item 517
O0518: DB 'Drive, user, login state read$' ; observation record for item 518
O0519: DB 'BIOS resource check is manual$' ; observation record for item 519
O0520: DB 'Fn 26 persisted until reset$' ; observation record for item 520
O0521: DB 'Drive/user state independent$' ; observation record for item 521
O0522: DB 'ALV/DPB pointer lifetime varies$' ; observation record for item 522
O0523: DB 'Fn 37 profile not requested$' ; observation record for item 523
O0525: DB 'Fn 40 valid; Fn 41 unsupported$'
O0526: DB 'Gateway at 0005h accepted call$' ; observation record for item 526
O0527: DB 'C and DE carried selector/input$' ; observation record for item 527
O0528: DB 'Result aliases matched A/L B/H$' ; observation record for item 528
O0529: DB 'Unsupported call returned zero$' ; observation record for item 529
O0530: DB 'Registers may change$'       ; observation record for item 530
O0531: DB 'Returning call balanced stack$' ; observation record for item 531
O0532: DB 'Bad params are call-specific$' ; observation record for item 532

; ================================================================================
; =                        Catalog Records and Test State                        =
; =                                                                              =
; = Defines full catalog identities, fixture FCBs, runner state, saved system    =
; = state, diagnostic buffers, command strings, and the private test stack.      =
; ================================================================================
; -------------------------------------------------------------------------------
; Catalog Table
; -------------------------------------------------------------------------------

  ; Compact full-record identities.  /REPORT support will expand these records
  ; when the common reporter is extended in the next BDOSTEST batch.

R0034: DB 'BDOS-CALL-001-P0034 OR-0034$' ; catalog record for item 34
R0035: DB 'BDOS-CALL-001-P0035 OR-0035$' ; catalog record for item 35
R0036: DB 'BDOS-CALL-001-P0036 OR-0036$' ; catalog record for item 36
R0037: DB 'BDOS-CALL-001-P0037 OR-0037$' ; catalog record for item 37
R0038: DB 'BDOS-CALL-001-P0038 OR-0038$' ; catalog record for item 38
R0039: DB 'BDOS-CALL-001-P0039 OR-0039$' ; catalog record for item 39
R0040: DB 'BDOS-CALL-001-P0040 OR-0040$' ; catalog record for item 40
R0041: DB 'BDOS-CALL-001-P0041 OR-0041$' ; catalog record for item 41
R0042: DB 'BDOS-CALL-001-P0042 OR-0042$' ; catalog record for item 42
R0043: DB 'BDOS-CALL-001-P0043 OR-0043$' ; catalog record for item 43
R0044: DB 'BDOS-CALL-001-P0044 OR-0044$' ; catalog record for item 44
R0045: DB 'BDOS-CALL-001-P0045 OR-0045$' ; catalog record for item 45
R0046: DB 'BDOS-CALL-001-P0046 OR-0046$' ; catalog record for item 46
R0047: DB 'BDOS-CALL-001-P0047 OR-0047$' ; catalog record for item 47
R0048: DB 'BDOS-CALL-001-P0048 OR-0048$' ; catalog record for item 48
R0049: DB 'BDOS-CALL-001-P0049 OR-0049$' ; catalog record for item 49
R0050: DB 'BDOS-CALL-001-P0050 OR-0050$' ; catalog record for item 50
R0131: DB 'BDOS-STATE-002-P0131 OR-0131$' ; catalog record for item 131
R0132: DB 'BDOS-STATE-002-P0132 OR-0132$' ; catalog record for item 132
R0133: DB 'BDOS-STATE-002-P0133 OR-0133$' ; catalog record for item 133
R0134: DB 'BDOS-STATE-002-P0134 OR-0134$' ; catalog record for item 134
R0135: DB 'BDOS-STATE-002-P0135 OR-0135$' ; catalog record for item 135
R0136: DB 'BDOS-STATE-002-P0136 OR-0136$' ; catalog record for item 136
R0137: DB 'BDOS-STATE-002-P0137 OR-0137$' ; catalog record for item 137
R0138: DB 'BDOS-STATE-002-P0138 OR-0138$' ; catalog record for item 138
R0139: DB 'BDOS-STATE-002-P0139 OR-0139$' ; catalog record for item 139
R0140: DB 'BDOS-STATE-002-P0140 OR-0140$' ; catalog record for item 140
R0141: DB 'BDOS-STATE-002-P0141 OR-0141$' ; catalog record for item 141
R0142: DB 'BDOS-STATE-002-P0142 OR-0142$' ; catalog record for item 142
R0143: DB 'BDOS-STATE-002-P0143 OR-0143$' ; catalog record for item 143
R0144: DB 'BDOS-STATE-002-P0144 OR-0144$' ; catalog record for item 144
R0145: DB 'BDOS-STATE-002-P0145 OR-0145$' ; catalog record for item 145
R0146: DB 'BDOS-STATE-002-P0146 OR-0146$' ; catalog record for item 146
R0147: DB 'BDOS-STATE-002-P0147 OR-0147$' ; catalog record for item 147
R0148: DB 'BDOS-STATE-002-P0148 OR-0148$' ; catalog record for item 148
R0149: DB 'BDOS-STATE-002-P0149 OR-0149$' ; catalog record for item 149
R0150: DB 'BDOS-STATE-002-P0150 OR-0150$' ; catalog record for item 150
R0151: DB 'BDOS-STATE-002-P0151 OR-0151$' ; catalog record for item 151
R0152: DB 'BDOS-STATE-002-P0152 OR-0152$' ; catalog record for item 152
R0153: DB 'BDOS-STATE-002-P0153 OR-0153$' ; catalog record for item 153
R0154: DB 'BDOS-STATE-002-P0154 OR-0154$' ; catalog record for item 154
R0187: DB 'BDOS-STATE-003-P0187 OR-0187$' ; catalog record for item 187
R0188: DB 'BDOS-STATE-003-P0188 OR-0188$' ; catalog record for item 188
R0189: DB 'BDOS-STATE-003-P0189 OR-0189$' ; catalog record for item 189
R0190: DB 'BDOS-STATE-003-P0190 OR-0190$' ; catalog record for item 190
R0191: DB 'BDOS-STATE-003-P0191 OR-0191$' ; catalog record for item 191
R0192: DB 'BDOS-STATE-003-P0192 OR-0192$' ; catalog record for item 192
R0193: DB 'BDOS-STATE-003-P0193 OR-0193$' ; catalog record for item 193
R0194: DB 'BDOS-STATE-003-P0194 OR-0194$' ; catalog record for item 194
R0195: DB 'BDOS-STATE-003-P0195 OR-0195$' ; catalog record for item 195
R0197: DB 'BDOS-STATE-003-P0197 OR-0197$' ; catalog record for item 197
R0199: DB 'BDOS-STATE-003-P0199 OR-0199$' ; catalog record for item 199
R0201: DB 'BDOS-STATE-003-P0201 OR-0201$' ; catalog record for item 201
R0203: DB 'BDOS-STATE-003-P0203 OR-0203$' ; catalog record for item 203
R0205: DB 'BDOS-STATE-003-P0205 OR-0205$' ; catalog record for item 205
R0207: DB 'BDOS-STATE-003-P0207 OR-0207$' ; catalog record for item 207
R0209: DB 'BDOS-STATE-003-P0209 OR-0209$' ; catalog record for item 209
R0211: DB 'BDOS-STATE-003-P0211 OR-0211$' ; catalog record for item 211
R0213: DB 'BDOS-STATE-003-P0213 OR-0213$' ; catalog record for item 213
R0215: DB 'BDOS-STATE-003-P0215 OR-0215$' ; catalog record for item 215
R0217: DB 'BDOS-STATE-003-P0217 OR-0217$' ; catalog record for item 217
R0413: DB 'BDOS-STATE-001-P0413 OR-0413$' ; catalog record for item 413
R0414: DB 'BDOS-STATE-001-P0414 OR-0414$' ; catalog record for item 414
R0415: DB 'BDOS-STATE-001-P0415 OR-0415$' ; catalog record for item 415
R0416: DB 'BDOS-STATE-001-P0416 OR-0416$' ; catalog record for item 416
R0417: DB 'BDOS-STATE-001-P0417 OR-0417$' ; catalog record for item 417
R0418: DB 'BDOS-STATE-001-P0418 OR-0418$' ; catalog record for item 418
R0419: DB 'BDOS-STATE-001-P0419 OR-0419$' ; catalog record for item 419
R0420: DB 'BDOS-STATE-001-P0420 OR-0420$' ; catalog record for item 420
R0422: DB 'BDOS-STATE-001-P0422 OR-0422$' ; catalog record for item 422
R0517: DB 'BDOS-STATE-001-P0517 OR-0517$' ; catalog record for item 517
R0518: DB 'BDOS-STATE-001-P0518 OR-0518$' ; catalog record for item 518
R0519: DB 'BDOS-STATE-001-P0519 OR-0519$' ; catalog record for item 519
R0520: DB 'BDOS-STATE-001-P0520 OR-0520$' ; catalog record for item 520
R0521: DB 'BDOS-STATE-001-P0521 OR-0521$' ; catalog record for item 521
R0522: DB 'BDOS-STATE-001-P0522 OR-0522$' ; catalog record for item 522
R0523: DB 'BDOS-STATE-001-P0523 OR-0523$' ; catalog record for item 523
R0524: DB 'BDOS-STATE-001-P0524 OR-0524$' ; catalog record for item 524
R0525: DB 'BDOS-CALL-001-P0525 OR-0525$' ; catalog record for item 525
R0526: DB 'BDOS-CALL-001-P0526 OR-0526$' ; catalog record for item 526
R0527: DB 'BDOS-CALL-001-P0527 OR-0527$' ; catalog record for item 527
R0528: DB 'BDOS-CALL-001-P0528 OR-0528$' ; catalog record for item 528
R0529: DB 'BDOS-CALL-001-P0529 OR-0529$' ; catalog record for item 529
R0530: DB 'BDOS-CALL-001-P0530 OR-0530$' ; catalog record for item 530
R0531: DB 'BDOS-CALL-001-P0531 OR-0531$' ; catalog record for item 531
R0532: DB 'BDOS-CALL-001-P0532 OR-0532$' ; catalog record for item 532

; -------------------------------------------------------------------------------
; Fixtures and Runner State
; -------------------------------------------------------------------------------

WILDFCB:DB 0,'???????????',0,0,0,0      ; wildcard search FCB
        DS 20

NOMFCB: DB 0,'NOFILE  ','ZZZ',0,0,0,0   ; nomfcb
        DS 20

TMPFCB: DB 0,'BDT0144 ','TMP',0,0,0,0   ; tmpfcb
        DS 20

TWOFCB: DB 0,'BDS?    ','TMP',0,0,0,0   ; twofcb
        DS 20

ITEMNO:DW 0                             ; itemno
CURITEM:DW 0                            ; curitem
PROCPTR:DW 0                            ; procptr
OBSPTR:DW 0                             ; obsptr
PASSCT:DB 0                             ; passct
FAILCT:DB 0                             ; failct
OBSCT: DB 0                             ; obsct
FAILITEMS:DS 172                        ; failitems
CASECLS:DB 0                            ; casecls
RUNMODE:DB 0                            ; runmode
FILTERMODE:DB 0                         ; filtermode
REPORTMODE:DB 0                         ; reportmode
ARGBUF:DS 32                            ; argbuf
SH:     DB '/H',0                       ; sh
SHELP:  DB '/HELP',0                    ; shelp
SLIST:  DB '/LIST',0                    ; slist
SALL:   DB '/ALL',0                     ; sall
SSAFE:  DB '/SAFE',0                    ; ssafe
SINFO:  DB '/INFO',0                    ; sinfo
SVER:   DB '/VER',0                     ; sver
SVERSION:DB '/VERSION',0                ; sversion
SGLIST: DB '/GROUP:LIST',0              ; sglist
SGREQ:  DB '/GROUP:REQUIRED',0          ; sgreq
SGOBS:  DB '/GROUP:OBSERVATION',0       ; sgobs
SGMAN:  DB '/GROUP:MANUAL',0            ; sgman
SGGATE: DB '/GROUP:GATEWAY',0           ; sggate
SGDRIVE:DB '/GROUP:DRIVE',0             ; sgdrive
SGDIR:  DB '/GROUP:DIRECTORY',0         ; sgdir
SGIDENT:DB '/GROUP:IDENTITY',0          ; sgident
SGSTATE:DB '/GROUP:STATE',0             ; sgstate
SGCONTR:DB '/GROUP:CONTRACT',0          ; sgcontr
SHR:    DB '/H:RESULTS',0               ; shr
SHP:    DB '/H:PROFILES',0              ; shp
SREPORT:DB ':REPORT',0                  ; sreport
OLDDRV:DB 0                             ; olddrv
RETVAL:DB 0                             ; retval
SPBEFORE:DW 0                           ; spbefore
REGWORD:DW 0                            ; regword
SEARCHPTR:DW 0                          ; searchptr
FIRSTCHAR:DB 0                          ; firstchar
OLDUSR: DB 0                            ; oldusr
ALTDMA:DS 128                           ; altdma
        DS 128

STACKTOP:                               ; top of private test stack
        END     START
