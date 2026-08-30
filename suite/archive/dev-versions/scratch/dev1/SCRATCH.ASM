;***************************************************************
;*                                                             *
;*       BetterCP/M scratch-media preparer, version dev1        *
;*                                                             *
;*       8080 instruction subset                                *
;*                                                             *
;***************************************************************
; Version 0.1.0-dev1
;
; Assemble with Z80ASM using the 8080 instruction subset.
; Run under CP/M 2.2 as:  SCRATCH /DISK
;
; SCRATCH prepares expendable media for suite utilities.  Profiles are
; deliberately separate because their required on-disk states conflict.
; This first version implements only the DISKTEST data-full profile.
;
; Safety invariants:
;   No disk operation occurs before a valid drive and Y confirmation.
;   Drive A is never offered as a target.
;   The selected drive is named again at the destructive confirmation.
;   All fixture FCBs carry an explicit drive byte.
;   A completed preparation is verified before success is reported.
;
        ORG     0100H
BDOS    EQU     0005H

; Entry and command parsing -------------------------------------------------

START:  LD      SP,STACKTOP
        LD      HL,0081H
        LD      A,(0080H)
        OR      A
        JP      Z,HELP
        LD      B,A
PSKIP:  LD      A,(HL)
        CP      ' '
        JP      NZ,PSLASH
        INC     HL
        DEC     B
        JP      NZ,PSKIP
        JP      HELP
PSLASH:CP      '/'
        JP      NZ,BADSEL
        INC     HL
        LD      A,(HL)
        AND     5FH
        CP      'D'
        JP      Z,PDISK
        CP      'H'
        JP      Z,HELP
        CP      'I'
        JP      Z,INFO
        JP      BADSEL

; Check the complete word DISK.  Rejecting abbreviations keeps later profile
; names unambiguous and prevents a typo from selecting a destructive action.
PDISK: INC     HL
        LD      A,(HL)
        AND     5FH
        CP      'I'
        JP      NZ,BADSEL
        INC     HL
        LD      A,(HL)
        AND     5FH
        CP      'S'
        JP      NZ,BADSEL
        INC     HL
        LD      A,(HL)
        AND     5FH
        CP      'K'
        JP      NZ,BADSEL
        JP      DISKPREP

HELP:   LD      DE,HELPMSG
        CALL    PUTS
        JP      EXIT
INFO:   LD      DE,INFOMSG
        CALL    PUTS
        JP      EXIT
BADSEL: LD      DE,BADMSG
        CALL    PUTS
        JP      EXIT

; Operator gate -------------------------------------------------------------

DISKPREP:
        LD      DE,ASKDRV
        CALL    PUTS
GETDRV: CALL    GETKEY
        CP      'Q'
        JP      Z,QUIT
        CP      'B'
        JP      C,DRVBAD
        CP      'F'+1
        JP      NC,DRVBAD
        LD      (CONFDRV),A
        LD      (WORKDRV),A
        SUB     'A'          ;BDOS 14 uses A=0, B=1, ...
        LD      (DRIVE0),A
        INC     A            ;an explicit FCB uses A=1, B=2, ...
        LD      (DRIVE1),A
        CALL    SETDRIVES
        LD      DE,CONFMSG
        CALL    PUTS
CONFIRM:CALL    GETKEY
        CP      'Q'
        JP      Z,QUIT
        CP      'N'
        JP      Z,QUIT
        CP      'Y'
        JP      NZ,CONFIRM
        CALL    PREPARE
        OR      A
        JP      NZ,PREPFAIL
        CALL    VERIFY
        OR      A
        JP      NZ,VERFAIL
        LD      DE,DONEMSG
        CALL    PUTS
        JP      EXIT
DRVBAD: LD      DE,DRVBADMSG
        CALL    PUTS
        JP      GETDRV
QUIT:   LD      DE,QUITMSG
        CALL    PUTS
        JP      EXIT
PREPFAIL:
        LD      DE,FAILMSG
        CALL    PUTS
        JP      EXIT
VERFAIL:
        LD      DE,VERMSG
        CALL    PUTS
        JP      EXIT

; PREPARE -------------------------------------------------------------------
; Reset CP/M's disk state after possible media exchange, select the target,
; remove its directory entries, then build the three DISKTEST fixture files.
; Exit: A=0 success, A=FFH error.

PREPARE:LD      DE,WORKMSG
        CALL    PUTS
        LD      C,13
        CALL    BDOS
        LD      A,(DRIVE0)
        LD      E,A
        LD      C,14
        CALL    BDOS
        LD      DE,ALLFCB
        LD      C,19         ;delete every ordinary directory entry
        CALL    BDOS         ;FF is valid when the formatted disk is empty
        LD      C,13         ;discard allocation information from before delete
        CALL    BDOS
        LD      A,(DRIVE0)
        LD      E,A
        LD      C,14
        CALL    BDOS

        LD      DE,ZEROBUF
        LD      C,26
        CALL    BDOS
        LD      HL,FULLFCB
        LD      DE,WORKFCB
        CALL    COPY36
        LD      DE,WORKFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        JP      Z,PREPBAD
        XOR     A
        LD      (RECCNT),A
FULLLP:LD      A,(RECCNT)
        CP      127
        JP      NZ,FULLWRITE
        CALL    PUTMARK       ;record 127 identifies an intact BTFULL.DAT
FULLWRITE:
        LD      DE,WORKFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      NZ,PREPBAD
        LD      A,(RECCNT)
        INC     A
        LD      (RECCNT),A
        CP      128
        JP      NZ,FULLLP
        LD      DE,WORKFCB
        LD      C,16
        CALL    BDOS
        CP      0FFH
        JP      Z,PREPBAD

        CALL    CLEARBUF
        LD      HL,RELFCB
        LD      DE,WORKFCB
        CALL    COPY36
        LD      DE,WORKFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        JP      Z,PREPBAD
        LD      DE,WORKFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      NZ,PREPBAD
        LD      DE,WORKFCB
        LD      C,16
        CALL    BDOS
        CP      0FFH
        JP      Z,PREPBAD

        LD      HL,FILLFCB
        LD      DE,WORKFCB
        CALL    COPY36
        LD      DE,WORKFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        JP      Z,PREPBAD
FILLMORE:
        LD      DE,WORKFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      Z,FILLMORE    ;the expected terminating write fills the disk
        LD      DE,WORKFCB
        LD      C,16
        CALL    BDOS
        CP      0FFH
        JP      Z,PREPBAD
        XOR     A
        RET
PREPBAD:LD      A,0FFH
        RET

; VERIFY --------------------------------------------------------------------
; Prove the two controlled files have their required logical sizes and marker,
; then prove a newly made file cannot allocate even one data record.  The empty
; probe directory entry is removed on both the passing and failing paths.
; Exit: A=0 verified, A=FFH not verified.

VERIFY: LD      HL,FULLFCB
        LD      DE,WORKFCB
        CALL    COPY36
        LD      DE,WORKFCB
        LD      C,15
        CALL    BDOS
        CP      0FFH
        JP      Z,VERBAD
        LD      DE,WORKFCB
        LD      C,35
        CALL    BDOS
        LD      A,(WORKFCB+33)
        CP      128
        JP      NZ,VERBAD
        LD      A,(WORKFCB+34)
        OR      A
        JP      NZ,VERBAD
        LD      A,127
        LD      (WORKFCB+33),A
        XOR     A
        LD      (WORKFCB+34),A
        LD      (WORKFCB+35),A
        LD      DE,WORKFCB
        LD      C,33
        CALL    BDOS
        OR      A
        JP      NZ,VERBAD
        LD      HL,ZEROBUF
        LD      DE,LASTMARK
        LD      B,8
MARKLP: LD      A,(DE)
        CP      (HL)
        JP      NZ,VERBAD
        INC     DE
        INC     HL
        DEC     B
        JP      NZ,MARKLP

        LD      HL,RELFCB
        LD      DE,WORKFCB
        CALL    COPY36
        LD      DE,WORKFCB
        LD      C,15
        CALL    BDOS
        CP      0FFH
        JP      Z,VERBAD
        LD      DE,WORKFCB
        LD      C,35
        CALL    BDOS
        LD      A,(WORKFCB+33)
        CP      1
        JP      NZ,VERBAD
        LD      A,(WORKFCB+34)
        OR      A
        JP      NZ,VERBAD

        LD      HL,TESTFCB
        LD      DE,WORKFCB
        CALL    COPY36
        LD      DE,WORKFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        JP      Z,VERBAD      ;a full data area must still allow empty Make
        LD      DE,WORKFCB
        LD      C,21
        CALL    BDOS
        LD      (WRITERES),A
        LD      HL,TESTFCB
        LD      DE,WORKFCB
        CALL    COPY36
        LD      DE,WORKFCB
        LD      C,19
        CALL    BDOS
        CP      0FFH
        JP      Z,VERBAD
        LD      A,(WRITERES)
        OR      A
        JP      Z,VERBAD      ;success would mean at least one block was free
        XOR     A
        RET
VERBAD: LD      A,0FFH
        RET

; Small reusable helpers ----------------------------------------------------

; GETKEY returns one upper-case console character in A.  Function 1 echoes it.
GETKEY: LD      C,1
        CALL    BDOS
        AND     5FH
        RET

; PUTS prints the dollar-terminated string addressed by DE.
PUTS:   LD      C,9
        JP      BDOS

; SETDRIVES installs the selected explicit-drive byte in every fixture FCB.
SETDRIVES:
        LD      A,(DRIVE1)
        LD      (ALLFCB),A
        LD      (FULLFCB),A
        LD      (RELFCB),A
        LD      (FILLFCB),A
        LD      (TESTFCB),A
        RET

; COPY36 copies one complete CP/M 2.2 FCB from HL to DE.
COPY36: LD      B,36
COPYLP: LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,COPYLP
        RET

; CLEARBUF restores the DMA buffer to zeroes after writing the marker record.
CLEARBUF:
        LD      HL,ZEROBUF
        LD      B,128
        XOR     A
CLRLP:  LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,CLRLP
        RET

; PUTMARK places the eight-byte record-127 signature at the start of DMA.
PUTMARK:LD      HL,LASTMARK
        LD      DE,ZEROBUF
        LD      B,8
PUTMLP: LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,PUTMLP
        RET

EXIT:   JP      0000H

; Messages ------------------------------------------------------------------

HELPMSG:DB      13,10,'SCRATCH 0.1.0-dev1',13,10,13,10
        DB      '  SCRATCH /DISK   Prepare a DISKTEST data-full disk',13,10
        DB      '  SCRATCH /H      Show this help',13,10
        DB      '  SCRATCH /INFO   Show build information',13,10,13,10
        DB      'Only blank formatted expendable media may be selected.',13,10,'$'
INFOMSG:DB      13,10,'BetterCP/M SCRATCH 0.1.0-dev1',13,10
        DB      'Implemented preparation profiles: DISKTEST',13,10
        DB      'Instruction subset: Intel 8080',13,10,'$'
BADMSG: DB      13,10,'Unknown selector. Use SCRATCH /H.',13,10,'$'
ASKDRV: DB      13,10,'Mount a blank formatted disk in an available drive.',13,10
        DB      'WARNING: This will erase the contents of the disk.',13,10
        DB      'Type the drive letter, or Q to quit (B-F or Q): $'
DRVBADMSG:DB    13,10,'Enter B, C, D, E, F, or Q: $'
CONFMSG:DB      13,10,'Erase and prepare drive '
CONFDRV:DB      'B'
        DB      ': (Y/N)? $'
WORKMSG:DB      13,10,'Preparing drive '
WORKDRV:DB      'B'
        DB      ': for DISKTEST...',13,10,'$'
DONEMSG:DB      'Scratch disk prepared and verified.',13,10,'$'
QUITMSG:DB      13,10,'No disk was prepared.',13,10,'$'
FAILMSG:DB      13,10,'ERROR: Scratch-disk preparation failed.',13,10,'$'
VERMSG: DB      13,10,'ERROR: Prepared disk did not pass verification.',13,10,'$'

; Mutable state and CP/M file-control blocks --------------------------------

DRIVE0: DB      0           ;zero-based drive number used by BDOS function 14
DRIVE1: DB      0           ;one-based explicit drive byte stored in each FCB
RECCNT: DB      0
WRITERES:DB     0

ALLFCB: DB      0,'????????','???'
        DS      24,0
FULLFCB:DB      0,'BTFULL  ','DAT'
        DS      24,0
RELFCB: DB      0,'BTREL   ','DAT'
        DS      24,0
FILLFCB:DB      0,'BTFILL  ','DAT'
        DS      24,0
TESTFCB:DB      0,'BTTEST  ','TMP'
        DS      24,0
WORKFCB:DS      36,0

LASTMARK:DB     'FULL-127'
ZEROBUF:DS      128,0

        DS      128,0
STACKTOP:
        END
