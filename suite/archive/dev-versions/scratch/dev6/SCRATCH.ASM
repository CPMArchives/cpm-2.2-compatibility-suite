; SPDX-License-Identifier: GPL-2.0-or-later

; ********************************************************************************
; *                  CP/M 2.2 Conformance Suite -- SCRATCH                      *
; *                                                                              *
; * Prepares destructive scratch-media fixtures used by DISKTEST, FILETEST,     *
; * DIRTEST, and BIOSTEST. No disk operation occurs until a non-A drive has     *
; * been explicitly selected and confirmed; completed profiles are independently*
; * verified before the caller's drive and user state are restored.             *
; ********************************************************************************

  ; Version 0.1.0-dev6

  ; Profiles:
  ;   /DISK   DISKTEST data-full fixture: BTFULL, BTREL, BTFILL
  ;   /CROSS  FILETEST/DIRTEST secondary fixture: BTBFILE.DAT
  ;   /BLANK  verified empty formatted data disk

  ; Revision history:
  ;   dev1    prepare and verify the DISKTEST data-full profile
  ;   dev2    add CROSS and BLANK; erase all users; accept drives B-P
  ;   dev3    identify BIOSTEST as a consumer of the BLANK profile
  ;   dev5    add period-style programmer's notes
  ;   dev6    add HELP and VERSION aliases; strengthen help warning
  ;

  ; Safety invariants:
  ;   No disk operation occurs before a valid drive and Y confirmation.
  ;   Drive A is never accepted.  The confirmed drive appears in every FCB.
  ;   Erasure covers user areas 0-15, including read-only/system attributes.
  ;   Every completed profile is verified, then caller drive/user are restored.
  ;

  ; PROGRAMMER'S NOTES
  ; ------------------
  ;
  ; This is the powder magazine of the suite.  It is kept separate so that no
  ; conformance test can erase a disk merely by being included in /ALL.  The
  ; selector must be spelled out, drive A is refused, the chosen drive is shown
  ; again, and a fresh Y is required before the first destructive call.
  ;
  ; A drive has two names in this program.  DRIVE0 is the zero-origin number
  ; wanted by Select Disk; DRIVE1 is the one-origin byte stored in an FCB.  The
  ; confirmed drive is written into every template FCB before work begins, so a
  ; later default-drive change cannot turn a cleanup wildcard toward the wrong
  ; disk.
  ;
  ; ERASEALL walks users 0 through 15.  Function 30 first clears any R/O or SYS
  ; attribute bits matched by ???????????, then Function 19 removes the entries.
  ; A disk reset brackets the sweep.  Thus a directory which looked empty in
  ; user zero cannot hide an old fixture in another user area.
  ;
  ; The DISK profile makes a 128-record control file, places FULL-127 at the
  ; start of its last record, makes a one-record relative file, then writes a
  ; filler until the disk itself refuses another record.  Verification does not
  ; trust the write refusal alone: it reopens both controls, checks their random
  ; sizes and marker, and proves that a brand-new test file cannot acquire even
  ; one block.
  ;
  ; CROSS writes one known 128-byte record and reads all of it back.  BLANK
  ; searches every user area after erasure.  A completed message is printed only
  ; after the selected oracle agrees.  The caller's drive and user are restored
  ; even when creation or verification fails.
  ;

  ; LINK establishes the CP/M transient load address at 0100h.
BDOS    EQU     0005H

; ================================================================================
; =                       Selector Parsing and Safety Gate                       =
; =                                                                              =
; = Requires full destructive profile names, refuses drive A, repeats the        =
; = selected drive, and demands explicit Y confirmation before any disk or       =
; = caller-state operation.                                                      =
; ================================================================================
; -------------------------------------------------------------------------------
; Exact Selector Parsing
; -------------------------------------------------------------------------------

  ; Exact selector parsing.  Full words are required for destructive profiles;
  ; accepting a convenient abbreviation here would be an expensive kindness.

START:  LD      SP,STACKTOP             ; enter scratch-media preparer
        LD      HL,0081H
        LD      A,(0080H)
        OR      A
        JP      Z,HELP
        LD      B,A

PSKIP:  LD      A,(HL)                  ; skip selector-leading spaces
        CP      ' '
        JP      NZ,PSLASH
        INC     HL
        DEC     B
        JP      NZ,PSKIP
        JP      HELP

PSLASH:CP      '/'                      ; parse selector slash
        JP      NZ,BADSEL
        INC     HL
        LD      A,(HL)
        AND     5FH
        CP      'D'
        JP      Z,PDISK
        CP      'C'
        JP      Z,PCROSS
        CP      'B'
        JP      Z,PBLANK
        CP      'L'
        JP      Z,PLIST
        CP      'H'
        JP      Z,PHELP
        CP      'I'
        JP      Z,PINFO
        CP      'V'
        JP      Z,PVER
        JP      BADSEL

  ; Full destructive names are required so a typo cannot select an erasure.

PDISK: INC     HL                       ; select DISK profile
        LD      DE,WDISK
        CALL    MATCH
        JP      NZ,BADSEL
        LD      A,1
        LD      (PROFILE),A
        LD      DE,DISKDESC
        JP      BEGIN

PCROSS:INC     HL                       ; select CROSS profile
        LD      DE,WCROSS
        CALL    MATCH
        JP      NZ,BADSEL
        LD      A,2
        LD      (PROFILE),A
        LD      DE,CROSSDESC
        JP      BEGIN

PBLANK:INC     HL                       ; select BLANK profile
        LD      DE,WBLANK
        CALL    MATCH
        JP      NZ,BADSEL
        LD      A,3
        LD      (PROFILE),A
        LD      DE,BLANKDESC
        JP      BEGIN

PLIST: INC     HL                       ; display profile list
        LD      DE,WLIST
        CALL    MATCH
        JP      NZ,BADSEL
        LD      DE,LISTMSG
        CALL    PUTS
        JP      EXIT

PINFO: INC     HL                       ; display utility information
        LD      DE,WINFO
        CALL    MATCH
        JP      NZ,BADSEL
        LD      DE,INFOMSG
        CALL    PUTS
        JP      EXIT

PHELP: INC     HL                       ; display help
        LD      A,(HL)
        CP      13
        JP      Z,HELP
        OR      A
        JP      Z,HELP
        CP      ' '
        JP      Z,HELP
        LD      DE,WHELP
        CALL    MATCH
        JP      NZ,BADSEL
        JP      HELP

PVER:  INC     HL                       ; display version
        PUSH    HL
        LD      DE,WVER
        CALL    MATCH
        POP     HL
        JP      Z,DOVER
        LD      DE,WVERSION
        CALL    MATCH
        JP      NZ,BADSEL

DOVER: LD      DE,VERSIONMSG            ; finish selector dispatch
        CALL    PUTS
        JP      EXIT

HELP:   LD      DE,HELPMSG              ; print help and exit
        CALL    PUTS
        JP      EXIT

BADSEL: LD      DE,BADMSG               ; report invalid selector
        CALL    PUTS
        JP      EXIT

; -------------------------------------------------------------------------------
; Selector Comparison
; -------------------------------------------------------------------------------

  ; MATCH compares upper-case command characters at HL with a zero-terminated
  ; tail at DE.  Entry points have already consumed the first selector letter.

MATCH:  LD      A,(DE)                  ; compare selector word
        OR      A
        JP      Z,MATCHEND
        LD      C,A
        LD      A,(HL)
        AND     5FH
        CP      C
        RET     NZ
        INC     HL
        INC     DE
        JP      MATCH

MATCHEND:                               ; matchend
        LD      A,(HL)
        CP      13            ;normal CCP command-tail terminator
        RET     Z
        CP      ' '           ;permit harmless trailing blanks
        RET     Z
        OR      A             ;also tolerate a zero-filled command tail
        RET

; -------------------------------------------------------------------------------
; Operator Gate
; -------------------------------------------------------------------------------

  ; Selection is still harmless at this point.  SAVEENV is deliberately below
  ; the Y gate so a refusal or typo cannot leave even the caller's state changed.

BEGIN:  EX      DE,HL                   ; begin destructive workflow
        LD      (DESCPTR),HL
        EX      DE,HL
        LD      DE,ASKDRV
        CALL    PUTS

GETDRV: CALL    GETKEY                  ; read scratch drive
        CP      'Q'
        JP      Z,QUIT
        CP      'B'
        JP      C,DRVBAD
        CP      'P'+1
        JP      NC,DRVBAD
        LD      (CONFDRV),A
        SUB     'A'          ;BDOS select: A=0 through P=15
        LD      (DRIVE0),A
        INC     A            ;FCB drive: A=1 through P=16
        LD      (DRIVE1),A
        CALL    SETDRIVES
        LD      DE,CONFMSG
        CALL    PUTS
        LD      HL,(DESCPTR)
        EX      DE,HL
        CALL    PUTS
        LD      DE,CONFEND
        CALL    PUTS

CONFIRM:CALL    GETKEY                  ; confirm destructive operation
        CP      'Q'
        JP      Z,QUIT
        CP      'N'
        JP      Z,QUIT
        CP      'Y'
        JP      NZ,CONFIRM
        CALL    SAVEENV
        CALL    PREPARE
        LD      (PREPRES),A
        CALL    RESTENV
        LD      A,(PREPRES)
        CP      1
        JP      Z,PREPFAIL
        CP      2
        JP      Z,VERFAIL
        LD      DE,DONEMSG
        CALL    PUTS
        JP      EXIT

DRVBAD: LD      DE,DRVBADMSG            ; reject invalid scratch drive
        CALL    PUTS
        JP      GETDRV

QUIT:   LD      DE,QUITMSG              ; cancel preparation
        CALL    PUTS
        JP      EXIT

PREPFAIL:                               ; report creation failure
        LD      DE,FAILMSG
        CALL    PUTS
        JP      EXIT

VERFAIL:                                ; report verification failure
        LD      DE,VERIFYMSG
        CALL    PUTS
        JP      EXIT

; ================================================================================
; =                      Caller State and Directory Erasure                      =
; =                                                                              =
; = Saves the caller's current disk and user, clears attributes and deletes      =
; = wildcard matches through all sixteen user areas, then restores the borrowed  =
; = environment.                                                                 =
; ================================================================================
; -------------------------------------------------------------------------------
; Borrow and Return the Machine
; -------------------------------------------------------------------------------

  ; Save the caller's current disk and user.  Restoration resets disk state,
  ; reselects the original disk, and occurs before any success/failure report.

SAVEENV:LD      C,25                    ; save caller drive and user
        CALL    BDOS
        LD      (OLDDRV),A
        LD      E,0FFH
        LD      C,32
        CALL    BDOS
        LD      (OLDUSR),A
        RET

RESTENV:LD      A,(OLDUSR)              ; restore caller drive and user
        LD      E,A
        LD      C,32
        CALL    BDOS
        LD      C,13
        CALL    BDOS
        LD      A,(OLDDRV)
        LD      E,A
        LD      C,14
        CALL    BDOS
        RET

; -------------------------------------------------------------------------------
; Erase All User Areas
; -------------------------------------------------------------------------------

  ; Clear attributes, then delete wildcard matches in every user area.

ERASEALL:                               ; erase all user areas
        LD      C,13
        CALL    BDOS
        LD      A,(DRIVE0)
        LD      E,A
        LD      C,14
        CALL    BDOS
        XOR     A
        LD      (USERNO),A

ERASEUSR:                               ; erase current user area
        LD      A,(USERNO)
        LD      E,A
        LD      C,32
        CALL    BDOS
        LD      DE,ALLFCB
        LD      C,30
        CALL    BDOS
        LD      DE,ALLFCB
        LD      C,19
        CALL    BDOS
        LD      A,(USERNO)
        INC     A
        LD      (USERNO),A
        CP      16
        JP      NZ,ERASEUSR
        XOR     A
        LD      E,A
        LD      C,32
        CALL    BDOS
        LD      C,13
        CALL    BDOS
        LD      A,(DRIVE0)
        LD      E,A
        LD      C,14
        CALL    BDOS
        RET

; ================================================================================
; =                               Profile Dispatch                               =
; =                                                                              =
; = Dispatches DISK, CROSS, or BLANK preparation and distinguishes creation      =
; = failures from verification failures before any completed message is printed. =
; ================================================================================
; -------------------------------------------------------------------------------
; Profile Selection
; -------------------------------------------------------------------------------

  ; PREPARE returns 0 success, 1 creation failure, 2 verification failure.

PREPARE:LD      DE,WORKMSG              ; dispatch selected profile
        CALL    PUTS
        LD      HL,(DESCPTR)
        EX      DE,HL
        CALL    PUTS
        LD      DE,WORKEND
        CALL    PUTS
        CALL    ERASEALL
        LD      A,(PROFILE)
        CP      1
        JP      Z,MAKEDISK
        CP      2
        JP      Z,MAKECROSS
        CP      3
        JP      Z,VERIFYBLANK

MAKEBAD:LD      A,1                     ; makebad
        RET

VERIFYBAD:                              ; verifybad
        LD      A,2
        RET

; ================================================================================
; =                              Full-Disk Fixture                               =
; =                                                                              =
; = Builds the 128-record control file, relative reservation file, and filler    =
; = used to exhaust data blocks, then verifies sizes, the final-record marker,   =
; = and absence of free allocation.                                              =
; ================================================================================
; -------------------------------------------------------------------------------
; Build Full-Disk Fixture
; -------------------------------------------------------------------------------

  ; Controlled files are followed by a filler that exhausts all data blocks.
  ; Record 127 receives a marker before it is written; records 0..126 remain
  ; zero, giving the consumer both a boundary and a recognizable last record.

MAKEDISK:                               ; make full-disk fixture
        LD      DE,ZEROBUF
        LD      C,26
        CALL    BDOS
        LD      HL,FULLFCB
        CALL    MAKEFCB
        OR      A
        JP      NZ,MAKEBAD
        XOR     A
        LD      (RECCNT),A

FULLLP:LD      A,(RECCNT)               ; fulllp
        CP      127
        JP      NZ,FULLWRITE
        CALL    PUTMARK

FULLWRITE:                              ; fullwrite
        LD      DE,WORKFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      NZ,MAKEBAD
        LD      A,(RECCNT)
        INC     A
        LD      (RECCNT),A
        CP      128
        JP      NZ,FULLLP
        CALL    CLOSEWORK
        OR      A
        JP      NZ,MAKEBAD
        CALL    CLEARBUF
        LD      HL,RELFCB
        CALL    MAKEFCB
        OR      A
        JP      NZ,MAKEBAD
        LD      DE,WORKFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      NZ,MAKEBAD
        CALL    CLOSEWORK
        OR      A
        JP      NZ,MAKEBAD
        LD      HL,FILLFCB
        CALL    MAKEFCB
        OR      A
        JP      NZ,MAKEBAD

FILLMORE:                               ; fillmore
        LD      DE,WORKFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      Z,FILLMORE
        CALL    CLOSEWORK
        OR      A
        JP      NZ,MAKEBAD
        CALL    VERIFYDISK
        OR      A
        JP      NZ,VERIFYBAD
        XOR     A
        RET

; -------------------------------------------------------------------------------
; Verify Full-Disk Fixture
; -------------------------------------------------------------------------------

  ; Do not certify our own handiwork cheaply: verify sizes, marker and absence
  ; of even one free allocation block.

VERIFYDISK:                             ; verify full-disk fixture
        LD      HL,FULLFCB
        CALL    OPENFCB
        OR      A
        JP      NZ,VDFAIL
        LD      DE,WORKFCB
        LD      C,35
        CALL    BDOS
        LD      A,(WORKFCB+33)
        CP      128
        JP      NZ,VDFAIL
        LD      A,(WORKFCB+34)
        OR      A
        JP      NZ,VDFAIL
        LD      A,127
        LD      (WORKFCB+33),A
        XOR     A
        LD      (WORKFCB+34),A
        LD      (WORKFCB+35),A
        LD      DE,WORKFCB
        LD      C,33
        CALL    BDOS
        OR      A
        JP      NZ,VDFAIL
        LD      HL,ZEROBUF
        LD      DE,LASTMARK
        LD      B,8

MARKLP: LD      A,(DE)                  ; marklp
        CP      (HL)
        JP      NZ,VDFAIL
        INC     DE
        INC     HL
        DEC     B
        JP      NZ,MARKLP
        LD      HL,RELFCB
        CALL    OPENFCB
        OR      A
        JP      NZ,VDFAIL
        LD      DE,WORKFCB
        LD      C,35
        CALL    BDOS
        LD      A,(WORKFCB+33)
        CP      1
        JP      NZ,VDFAIL
        LD      A,(WORKFCB+34)
        OR      A
        JP      NZ,VDFAIL
        LD      HL,TESTFCB
        CALL    MAKEFCB
        OR      A
        JP      NZ,VDFAIL
        LD      DE,WORKFCB
        LD      C,21
        CALL    BDOS
        LD      (WRITERES),A
        LD      HL,TESTFCB
        CALL    DELETEFCB
        OR      A
        JP      NZ,VDFAIL
        LD      A,(WRITERES)
        OR      A
        JP      Z,VDFAIL
        XOR     A
        RET

VDFAIL:LD      A,0FFH                   ; vdfail
        RET

; ================================================================================
; =                             Cross-Drive Fixture                              =
; =                                                                              =
; = Writes and reopens the canonical BTBFILE record used by explicit             =
; = secondary-drive tests and compares all 128 bytes rather than accepting size  =
; = alone.                                                                       =
; ================================================================================
; -------------------------------------------------------------------------------
; Cross-Drive Calling Card
; -------------------------------------------------------------------------------

  ; One canonical BTBFILE record for explicit secondary-drive tests.  The text
  ; buffer is compared byte for byte after reopen, not merely counted by size.

MAKECROSS:                              ; make cross-drive fixture
        LD      DE,CROSSBUF
        LD      C,26
        CALL    BDOS
        LD      HL,CROSSFCB
        CALL    MAKEFCB
        OR      A
        JP      NZ,MAKEBAD
        LD      DE,WORKFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      NZ,MAKEBAD
        CALL    CLOSEWORK
        OR      A
        JP      NZ,MAKEBAD
        CALL    VERIFYCROSS
        OR      A
        JP      NZ,VERIFYBAD
        XOR     A
        RET

VERIFYCROSS:                            ; verify cross-drive fixture
        LD      DE,ZEROBUF
        LD      C,26
        CALL    BDOS
        LD      HL,CROSSFCB
        CALL    OPENFCB
        OR      A
        JP      NZ,VCFAIL
        LD      DE,WORKFCB
        LD      C,35
        CALL    BDOS
        LD      A,(WORKFCB+33)
        CP      1
        JP      NZ,VCFAIL
        XOR     A
        LD      (WORKFCB+33),A
        LD      (WORKFCB+34),A
        LD      (WORKFCB+35),A
        LD      DE,WORKFCB
        LD      C,33
        CALL    BDOS
        OR      A
        JP      NZ,VCFAIL
        LD      HL,ZEROBUF
        LD      DE,CROSSBUF
        LD      B,128

VCLOOP: LD      A,(DE)                  ; vcloop
        CP      (HL)
        JP      NZ,VCFAIL
        INC     DE
        INC     HL
        DEC     B
        JP      NZ,VCLOOP
        XOR     A
        RET

VCFAIL:LD      A,0FFH                   ; vcfail
        RET

; ================================================================================
; =                           Blank-Disk Verification                            =
; =                                                                              =
; = Searches every user area after erasure and rejects any surviving directory   =
; = entry, independent of its physical directory slot.                           =
; ================================================================================
; -------------------------------------------------------------------------------
; Empty-Directory Oracle
; -------------------------------------------------------------------------------

  ; Prove no directory entry exists in any user area.  A search result other
  ; than FFh is enough to reject the disk; its slot number is immaterial.

VERIFYBLANK:                            ; verify empty directory
        XOR     A
        LD      (USERNO),A

VBLUSER:                                ; vbluser
        LD      A,(USERNO)
        LD      E,A
        LD      C,32
        CALL    BDOS
        LD      DE,ZEROBUF
        LD      C,26
        CALL    BDOS
        LD      DE,ALLFCB
        LD      C,17
        CALL    BDOS
        CP      0FFH
        JP      NZ,VBLFAIL
        LD      A,(USERNO)
        INC     A
        LD      (USERNO),A
        CP      16
        JP      NZ,VBLUSER
        XOR     A
        LD      E,A
        LD      C,32
        CALL    BDOS
        XOR     A
        RET

VBLFAIL:                                ; vblfail
        XOR     A
        LD      E,A
        LD      C,32
        CALL    BDOS
        JP      VERIFYBAD

; ================================================================================
; =                       FCB, Buffer, and Console Helpers                       =
; =                                                                              =
; = Copies immutable templates into a working FCB, translates public CP/M return =
; = conventions, manages the work buffer, and supplies console input/output      =
; = helpers.                                                                     =
; ================================================================================
; -------------------------------------------------------------------------------
; Tool Drawer
; -------------------------------------------------------------------------------

  ; Templates are always copied into WORKFCB because file calls alter their FCB.
  ; Helpers translate the public FFh failure convention into this program's
  ; zero-success convention.

MAKEFCB:LD      DE,WORKFCB              ; prepare working FCB
        CALL    COPY36
        LD      DE,WORKFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        RET     Z
        XOR     A
        RET

OPENFCB:LD      DE,WORKFCB              ; open working FCB
        CALL    COPY36
        LD      DE,WORKFCB
        LD      C,15
        CALL    BDOS
        CP      0FFH
        RET     Z
        XOR     A
        RET

DELETEFCB:                              ; delete working FCB
        LD      DE,WORKFCB
        CALL    COPY36
        LD      DE,WORKFCB
        LD      C,19
        CALL    BDOS
        CP      0FFH
        RET     Z
        XOR     A
        RET

CLOSEWORK:                              ; close working file
        LD      DE,WORKFCB
        LD      C,16
        CALL    BDOS
        CP      0FFH
        RET     Z
        XOR     A
        RET

SETDRIVES:                              ; apply selected drive to FCB templates
        LD      A,(DRIVE1)
        LD      (ALLFCB),A
        LD      (FULLFCB),A
        LD      (RELFCB),A
        LD      (FILLFCB),A
        LD      (TESTFCB),A
        LD      (CROSSFCB),A
        RET

COPY36: LD      B,36                    ; copy complete FCB

COPYLP: LD      A,(HL)                  ; copylp
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,COPYLP
        RET

CLEARBUF:                               ; clear work buffer
        LD      HL,ZEROBUF
        LD      B,128
        XOR     A

CLRLP:  LD      (HL),A                  ; clrlp
        INC     HL
        DEC     B
        JP      NZ,CLRLP
        RET

PUTMARK:LD      HL,LASTMARK             ; write record marker
        LD      DE,ZEROBUF
        LD      B,8

PUTMLP: LD      A,(HL)                  ; putmlp
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,PUTMLP
        RET

GETKEY: LD      C,1                     ; read console key
        CALL    BDOS
        AND     5FH
        RET

PUTS:   LD      C,9                     ; print $-terminated string
        JP      BDOS

EXIT:   JP      0000H                   ; return through warm boot

; ================================================================================
; =                    Messages, State, and Fixture Templates                    =
; =                                                                              =
; = Defines operator warnings and status text, saved state, explicit-drive FCB   =
; = templates, and the canonical 128-byte CROSS record.                          =
; ================================================================================
; -------------------------------------------------------------------------------
; Messages and Working State
; -------------------------------------------------------------------------------

  ; Messages ------------------------------------------------------------------

HELPMSG:DB      13,10,'SCRATCH 0.1.0-dev6',13,10,13,10 ; helpmsg
        DB      'SCRATCH creates test disks for the CP/M 2.2 compatibility tool tests.',13,10
        DB      'This requires a blank, formatted image; all content will be destroyed.',13,10,13,10
        DB      '  SCRATCH /DISK               Prepare the DISKTEST data-full disk',13,10
        DB      '  SCRATCH /CROSS              Prepare FILETEST/DIRTEST secondary disk',13,10
        DB      '  SCRATCH /BLANK              Erase and verify an empty data disk',13,10
        DB      '  SCRATCH /LIST               List preparation profiles',13,10
        DB      '  SCRATCH /H, /HELP           Show this help',13,10
        DB      '  SCRATCH /INFO               Show build information',13,10
        DB      '  SCRATCH /VER, /VERSION      Show name and version',13,10,13,10
        DB      'Only formatted expendable media may be selected.',13,10,'$'

LISTMSG:DB      13,10,'PROFILE  CONTENTS                         USED BY',13,10 ; listmsg
        DB      '-------  -------------------------------  ----------------',13,10
        DB      'DISK     Full data area; controlled files DISKTEST',13,10
        DB      'CROSS    BTBFILE.DAT, one record          FILETEST, DIRTEST',13,10
        DB      'BLANK    No files in users 0-15           BIOSTEST, manual',13,10,'$'

INFOMSG:DB      13,10,'SCRATCH 0.1.0-dev6',13,10 ; infomsg
        DB      'Profiles: DISK, CROSS, BLANK',13,10
        DB      'Drive range: configured B through P',13,10
        DB      'User areas erased and verified: 0 through 15',13,10
        DB      'Instruction subset: Intel 8080',13,10,'$'

VERSIONMSG:DB   13,10,'SCRATCH 0.1.0-dev6',13,10,'$' ; versionmsg
BADMSG: DB      13,10,'SCRATCH: unknown selector. Use SCRATCH /HELP.',13,10,'$' ; badmsg
ASKDRV: DB      13,10,'Mount a blank formatted disk in a configured drive.',13,10 ; askdrv
        DB      'WARNING: This will erase the contents of the disk.',13,10
        DB      'Type the drive letter, or Q to quit (B-P or Q): $'

DRVBADMSG:DB    13,10,'Enter a configured drive B through P, or Q: $' ; drvbadmsg
CONFMSG:DB      13,10,'Erase drive '    ; confmsg
CONFDRV:DB      'B'                     ; confdrv
        DB      ': and prepare the $'

CONFEND:DB      ' profile (Y/N)? $'     ; confend
WORKMSG:DB      13,10,'Preparing $'     ; workmsg
WORKEND:DB      ' profile...',13,10,'$' ; workend
DISKDESC:DB     'DISK','$'              ; diskdesc
CROSSDESC:DB    'CROSS','$'             ; crossdesc
BLANKDESC:DB    'BLANK','$'             ; blankdesc
DONEMSG:DB      'Scratch disk prepared and verified.',13,10,'$' ; donemsg
QUITMSG:DB      13,10,'No disk was prepared.',13,10,'$' ; quitmsg
FAILMSG:DB      13,10,'ERROR: Scratch-disk preparation failed.',13,10,'$' ; failmsg
VERIFYMSG:DB    13,10,'ERROR: Prepared disk did not pass verification.',13,10,'$' ; verifymsg

  ; State and explicit-drive FCB templates -----------------------------------

PROFILE:DB      0                       ; profile
DRIVE0: DB      0                       ; drive0
DRIVE1: DB      0                       ; drive1
OLDDRV: DB      0                       ; olddrv
OLDUSR: DB      0                       ; oldusr
USERNO: DB      0                       ; userno
RECCNT: DB      0                       ; reccnt
WRITERES:DB     0                       ; writeres
PREPRES:DB      0                       ; prepres
DESCPTR:DW      0                       ; descptr
ALLFCB: DB      0,'????????','???'      ; allfcb
        DS      24

FULLFCB:DB      0,'BTFULL  ','DAT'      ; fullfcb
        DS      24

RELFCB: DB      0,'BTREL   ','DAT'      ; relfcb
        DS      24

FILLFCB:DB      0,'BTFILL  ','DAT'      ; fillfcb
        DS      24

TESTFCB:DB      0,'BTTEST  ','TMP'      ; testfcb
        DS      24

CROSSFCB:DB     0,'BTBFILE ','DAT'      ; crossfcb
        DS      24

WORKFCB:DS      36                      ; workfcb
LASTMARK:DB     'FULL-127'              ; lastmark
  ; Canonical 128-byte record: twelve 10-byte groups plus eight bytes.

CROSSBUF:                               ; crossbuf
        DB      'BFILE-000 ','BFILE-000 ','BFILE-000 ','BFILE-000 '
        DB      'BFILE-000 ','BFILE-000 ','BFILE-000 ','BFILE-000 '
        DB      'BFILE-000 ','BFILE-000 ','BFILE-000 ','BFILE-000 '
        DB      'BFILE-00'

ZEROBUF:DS      128                     ; zerobuf
WDISK:  DB      'ISK',0                 ; wdisk
WCROSS: DB      'ROSS',0                ; wcross
WBLANK: DB      'LANK',0                ; wblank
WLIST:  DB      'IST',0                 ; wlist
WINFO:  DB      'NFO',0                 ; winfo
WHELP:  DB      'ELP',0                 ; whelp
WVER:   DB      'ER',0                  ; wver
WVERSION:DB    'ERSION',0               ; wversion
        DS      128

STACKTOP:                               ; top of private stack
        END
