; SPDX-License-Identifier: GPL-2.0-or-later
;
;***********************************************************************
;*                                                                     *
;*              F I L E T E S T   --   RELEASE DEV30                  *
;*                                                                     *
;*             CP/M 2.2 FILE COMPATIBILITY TEST PROGRAM               *
;*                                                                     *
;***********************************************************************
;
; Version 0.1.0-dev35 - report an absent cross-drive fixture as not-run
;
; ASSEMBLY: ZSM4, THEN DIGITAL RESEARCH LINK.  ONLY 8080 OPERATIONS ARE USED.
; LOAD AT:  0100H
;
;------------------------- PROGRAMMER'S NOTES --------------------------
;
; FILETEST is a card file of small experiments, not one long disk exercise.
; Each RUNnnnn routine arranges one state, makes the few calls needed for
; that card, and judges only the evidence named by its oracle.  Shared
; routines do the clerical work, but never decide a result from a ledger
; number or from the wording printed on the console.
;
; TESTFCB and DMABUF have tell-tales on both sides.  INITFCB writes A5H and
; 5AH around the 36-byte FCB; PREPDMA writes C3H and 3CH around the 128-byte
; record.  These values are unlike the fixture text and unlike each other.
; If a tell-tale changes, the card reports ERROR, not FAIL: an overrun means
; the program can no longer trust either its evidence or its own machinery.
;
; A DMA record is first filled with E7H.  Successful reads must replace the
; expected marker, and whole-record checks can also prove that no E7H was
; left behind.  The ordinary DMA address is restored to 0080H on every exit
; from a path which selects DMABUF.  When adding a path, write its RESTDMA or
; TEMPCLEAN exit before writing the success exit.
;
; BTTEMP.DAT is the expendable working file.  TEMPMAKE first erases any stale
; copy, and TEMPCLEAN closes and erases it after success, failure or error.
; Named BT files and their record marks are test instruments; they are never
; aliases for an operator's files.  Full-directory and cross-drive cards use
; SCRATCH-built D: and C: media and do not manufacture those conditions here.
;
; Several claims share an operation but not an oracle.  For example, one
; read may prove its return, its CR advance, its record bytes, or merely
; characterize state after EOF.  The NOT GUARANTEED cards go through the
; diagnostic table and always print O; no observed byte can promote one of
; them to PASS or demote it to FAIL.
;
; Random I/O keeps CR deliberately different from R0-R2.  This catches code
; which accidentally uses the sequential position.  Written records are
; closed, reopened and read again before their A5H mark is accepted, so the
; comparison is against disk state rather than the caller's old DMA image.
;
; The read-only write cards are special.  On the declared CP/M 2.2 profile a
; correct call may abandon this transient and return straight to the CCP.
; They are therefore absent from /ALL and belong to an outside terminal-
; outcome transcript.  A normal return from either call is itself the bad
; outcome.  Do not put cleanup code after a call which is not meant to return.
;
; Compact output and /REPORT are two views of the same result cells.  The
; long case records carry the four ledger digits used by compact printing;
; keep that first-line layout fixed unless PUTCID is changed with it.
;
;***********************************************************************

; LINK establishes the CP/M transient load address at 0100h.

BDOS    EQU     0005H
CMDLEN  EQU     0080H
CMDTXT  EQU     0081H
DIAG_COUNT EQU  23

START:
        ; Own the stack.  Every finished command jumps through page zero;
        ; no card depends upon the depth or contents of the CCP's old stack.
        LD      SP,STACKTOP
        CALL    PARSEARG
        LD      A,(PARSEBAD)
        OR      A
        JP      NZ,BADCOMMAND
        LD      A,(ARGBUF)
        OR      A
        JP      Z,DOHELP

        LD      HL,ARGBUF
        LD      DE,S0156
        CALL    STREQ
        JP      Z,RUN0156
        LD      HL,ARGBUF
        LD      DE,SC156
        CALL    STREQ
        JP      Z,RUN0156
        LD      HL,ARGBUF
        LD      DE,S0157
        CALL    STREQ
        JP      Z,RUN0157
        LD      HL,ARGBUF
        LD      DE,SC157
        CALL    STREQ
        JP      Z,RUN0157
        LD      HL,ARGBUF
        LD      DE,S0158
        CALL    STREQ
        JP      Z,RUN0158
        LD      HL,ARGBUF
        LD      DE,SC158
        CALL    STREQ
        JP      Z,RUN0158
        LD      HL,ARGBUF
        LD      DE,S0159
        CALL    STREQ
        JP      Z,RUN0159
        LD      HL,ARGBUF
        LD      DE,SC159
        CALL    STREQ
        JP      Z,RUN0159
        LD      HL,ARGBUF
        LD      DE,S0160
        CALL    STREQ
        JP      Z,RUN0160
        LD      HL,ARGBUF
        LD      DE,SC160
        CALL    STREQ
        JP      Z,RUN0160
        LD      HL,ARGBUF
        LD      DE,S0161
        CALL    STREQ
        JP      Z,RUN0161
        LD      HL,ARGBUF
        LD      DE,SC161
        CALL    STREQ
        JP      Z,RUN0161
        LD      HL,ARGBUF
        LD      DE,S0162
        CALL    STREQ
        JP      Z,RUN0162
        LD      HL,ARGBUF
        LD      DE,SC162
        CALL    STREQ
        JP      Z,RUN0162
        LD      HL,ARGBUF
        LD      DE,S0164
        CALL    STREQ
        JP      Z,RUN0164
        LD      HL,ARGBUF
        LD      DE,SC164
        CALL    STREQ
        JP      Z,RUN0164
        LD      HL,ARGBUF
        LD      DE,S0166
        CALL    STREQ
        JP      Z,RUN0166
        LD      HL,ARGBUF
        LD      DE,SC166
        CALL    STREQ
        JP      Z,RUN0166
        LD      HL,ARGBUF
        LD      DE,S0168
        CALL    STREQ
        JP      Z,RUN0168
        LD      HL,ARGBUF
        LD      DE,SC168
        CALL    STREQ
        JP      Z,RUN0168
        LD      HL,ARGBUF
        LD      DE,S0170
        CALL    STREQ
        JP      Z,RUN0170
        LD      HL,ARGBUF
        LD      DE,SC170
        CALL    STREQ
        JP      Z,RUN0170
        LD      HL,ARGBUF
        LD      DE,S0172
        CALL    STREQ
        JP      Z,RUN0172
        LD      HL,ARGBUF
        LD      DE,SC172
        CALL    STREQ
        JP      Z,RUN0172
        LD      HL,ARGBUF
        LD      DE,S0174
        CALL    STREQ
        JP      Z,RUN0174
        LD      HL,ARGBUF
        LD      DE,SC174
        CALL    STREQ
        JP      Z,RUN0174
        LD      HL,ARGBUF
        LD      DE,S0176
        CALL    STREQ
        JP      Z,RUN0176
        LD      HL,ARGBUF
        LD      DE,SC176
        CALL    STREQ
        JP      Z,RUN0176
        LD      HL,ARGBUF
        LD      DE,S0178
        CALL    STREQ
        JP      Z,RUN0178
        LD      HL,ARGBUF
        LD      DE,SC178
        CALL    STREQ
        JP      Z,RUN0178
        LD      HL,ARGBUF
        LD      DE,S0180
        CALL    STREQ
        JP      Z,RUN0180
        LD      HL,ARGBUF
        LD      DE,SC180
        CALL    STREQ
        JP      Z,RUN0180
        LD      HL,ARGBUF
        LD      DE,S0253
        CALL    STREQ
        JP      Z,RUN0253
        LD      HL,ARGBUF
        LD      DE,SC253
        CALL    STREQ
        JP      Z,RUN0253
        LD      HL,ARGBUF
        LD      DE,S0553
        CALL    STREQ
        JP      Z,RUN0553
        LD      HL,ARGBUF
        LD      DE,SC553
        CALL    STREQ
        JP      Z,RUN0553
        LD      HL,ARGBUF
        LD      DE,S0555
        CALL    STREQ
        JP      Z,RUN0555
        LD      HL,ARGBUF
        LD      DE,SC555
        CALL    STREQ
        JP      Z,RUN0555
        LD      HL,ARGBUF
        LD      DE,S0556
        CALL    STREQ
        JP      Z,RUN0556
        LD      HL,ARGBUF
        LD      DE,SC556
        CALL    STREQ
        JP      Z,RUN0556
        LD      HL,ARGBUF
        LD      DE,S0557
        CALL    STREQ
        JP      Z,RUN0557
        LD      HL,ARGBUF
        LD      DE,SC557
        CALL    STREQ
        JP      Z,RUN0557

        CALL    DIAGSELECT

        LD      HL,ARGBUF
        LD      DE,S0165
        CALL    STREQ
        JP      Z,RUN0165
        LD      HL,ARGBUF
        LD      DE,SCASE165
        CALL    STREQ
        JP      Z,RUN0165
        LD      HL,ARGBUF
        LD      DE,S0167
        CALL    STREQ
        JP      Z,RUN0167
        LD      HL,ARGBUF
        LD      DE,SCASE167
        CALL    STREQ
        JP      Z,RUN0167
        LD      HL,ARGBUF
        LD      DE,S0169
        CALL    STREQ
        JP      Z,RUN0169
        LD      HL,ARGBUF
        LD      DE,SCASE0169
        CALL    STREQ
        JP      Z,RUN0169
        LD      HL,ARGBUF
        LD      DE,S0171
        CALL    STREQ
        JP      Z,RUN0171
        LD      HL,ARGBUF
        LD      DE,SCASE0171
        CALL    STREQ
        JP      Z,RUN0171
        LD      HL,ARGBUF
        LD      DE,S0173
        CALL    STREQ
        JP      Z,RUN0173
        LD      HL,ARGBUF
        LD      DE,SC173
        CALL    STREQ
        JP      Z,RUN0173
        LD      HL,ARGBUF
        LD      DE,S0175
        CALL    STREQ
        JP      Z,RUN0175
        LD      HL,ARGBUF
        LD      DE,SC175
        CALL    STREQ
        JP      Z,RUN0175
        LD      HL,ARGBUF
        LD      DE,S0177
        CALL    STREQ
        JP      Z,RUN0177
        LD      HL,ARGBUF
        LD      DE,SC177
        CALL    STREQ
        JP      Z,RUN0177
        LD      HL,ARGBUF
        LD      DE,S0179
        CALL    STREQ
        JP      Z,RUN0179
        LD      HL,ARGBUF
        LD      DE,SC179
        CALL    STREQ
        JP      Z,RUN0179
        LD      HL,ARGBUF
        LD      DE,S0181
        CALL    STREQ
        JP      Z,RUN0181
        LD      HL,ARGBUF
        LD      DE,SC181
        CALL    STREQ
        JP      Z,RUN0181
        LD      HL,ARGBUF
        LD      DE,S0219
        CALL    STREQ
        JP      Z,RUN0219
        LD      HL,ARGBUF
        LD      DE,SC219
        CALL    STREQ
        JP      Z,RUN0219
        LD      HL,ARGBUF
        LD      DE,S0220
        CALL    STREQ
        JP      Z,RUN0220
        LD      HL,ARGBUF
        LD      DE,SC220
        CALL    STREQ
        JP      Z,RUN0220
        LD      HL,ARGBUF
        LD      DE,S0221
        CALL    STREQ
        JP      Z,RUN0221
        LD      HL,ARGBUF
        LD      DE,SC221
        CALL    STREQ
        JP      Z,RUN0221
        LD      HL,ARGBUF
        LD      DE,S0222
        CALL    STREQ
        JP      Z,RUN0222
        LD      HL,ARGBUF
        LD      DE,SC222
        CALL    STREQ
        JP      Z,RUN0222
        LD      HL,ARGBUF
        LD      DE,S0223
        CALL    STREQ
        JP      Z,RUN0223
        LD      HL,ARGBUF
        LD      DE,SC223
        CALL    STREQ
        JP      Z,RUN0223
        LD      HL,ARGBUF
        LD      DE,S0224
        CALL    STREQ
        JP      Z,RUN0224
        LD      HL,ARGBUF
        LD      DE,SC224
        CALL    STREQ
        JP      Z,RUN0224
        LD      HL,ARGBUF
        LD      DE,S0226
        CALL    STREQ
        JP      Z,RUN0226
        LD      HL,ARGBUF
        LD      DE,SC226
        CALL    STREQ
        JP      Z,RUN0226
        LD      HL,ARGBUF
        LD      DE,S0227
        CALL    STREQ
        JP      Z,RUN0227
        LD      HL,ARGBUF
        LD      DE,SC227
        CALL    STREQ
        JP      Z,RUN0227
        LD      HL,ARGBUF
        LD      DE,S0228
        CALL    STREQ
        JP      Z,RUN0228
        LD      HL,ARGBUF
        LD      DE,SC228
        CALL    STREQ
        JP      Z,RUN0228
        LD      HL,ARGBUF
        LD      DE,S0229
        CALL    STREQ
        JP      Z,RUN0229
        LD      HL,ARGBUF
        LD      DE,SC229
        CALL    STREQ
        JP      Z,RUN0229
        LD      HL,ARGBUF
        LD      DE,S0230
        CALL    STREQ
        JP      Z,RUN0230
        LD      HL,ARGBUF
        LD      DE,SC230
        CALL    STREQ
        JP      Z,RUN0230
        LD      HL,ARGBUF
        LD      DE,S0231
        CALL    STREQ
        JP      Z,RUN0231
        LD      HL,ARGBUF
        LD      DE,SC231
        CALL    STREQ
        JP      Z,RUN0231
        LD      HL,ARGBUF
        LD      DE,S0232
        CALL    STREQ
        JP      Z,RUN0232
        LD      HL,ARGBUF
        LD      DE,SC232
        CALL    STREQ
        JP      Z,RUN0232
        LD      HL,ARGBUF
        LD      DE,S0234
        CALL    STREQ
        JP      Z,RUN0234
        LD      HL,ARGBUF
        LD      DE,SC234
        CALL    STREQ
        JP      Z,RUN0234
        LD      HL,ARGBUF
        LD      DE,S0235
        CALL    STREQ
        JP      Z,RUN0235
        LD      HL,ARGBUF
        LD      DE,SC235
        CALL    STREQ
        JP      Z,RUN0235
        LD      HL,ARGBUF
        LD      DE,S0236
        CALL    STREQ
        JP      Z,RUN0236
        LD      HL,ARGBUF
        LD      DE,SC236
        CALL    STREQ
        JP      Z,RUN0236
        LD      HL,ARGBUF
        LD      DE,S0237
        CALL    STREQ
        JP      Z,RUN0237
        LD      HL,ARGBUF
        LD      DE,SC237
        CALL    STREQ
        JP      Z,RUN0237
        LD      HL,ARGBUF
        LD      DE,S0239
        CALL    STREQ
        JP      Z,RUN0239
        LD      HL,ARGBUF
        LD      DE,SC239
        CALL    STREQ
        JP      Z,RUN0239
        LD      HL,ARGBUF
        LD      DE,S0242
        CALL    STREQ
        JP      Z,RUN0242
        LD      HL,ARGBUF
        LD      DE,SC242
        CALL    STREQ
        JP      Z,RUN0242
        LD      HL,ARGBUF
        LD      DE,S0243
        CALL    STREQ
        JP      Z,RUN0243
        LD      HL,ARGBUF
        LD      DE,SC243
        CALL    STREQ
        JP      Z,RUN0243
        LD      HL,ARGBUF
        LD      DE,S0248
        CALL    STREQ
        JP      Z,RUN0248
        LD      HL,ARGBUF
        LD      DE,SC248
        CALL    STREQ
        JP      Z,RUN0248
        LD      HL,ARGBUF
        LD      DE,S0249
        CALL    STREQ
        JP      Z,RUN0249
        LD      HL,ARGBUF
        LD      DE,SC249
        CALL    STREQ
        JP      Z,RUN0249
        LD      HL,ARGBUF
        LD      DE,S0250
        CALL    STREQ
        JP      Z,RUN0250
        LD      HL,ARGBUF
        LD      DE,SC250
        CALL    STREQ
        JP      Z,RUN0250
        LD      HL,ARGBUF
        LD      DE,S0251
        CALL    STREQ
        JP      Z,RUN0251
        LD      HL,ARGBUF
        LD      DE,SC251
        CALL    STREQ
        JP      Z,RUN0251
        LD      HL,ARGBUF
        LD      DE,S0252
        CALL    STREQ
        JP      Z,RUN0252
        LD      HL,ARGBUF
        LD      DE,SC252
        CALL    STREQ
        JP      Z,RUN0252
        LD      HL,ARGBUF
        LD      DE,S0254
        CALL    STREQ
        JP      Z,RUN0254
        LD      HL,ARGBUF
        LD      DE,SC254
        CALL    STREQ
        JP      Z,RUN0254
        LD      HL,ARGBUF
        LD      DE,S0259
        CALL    STREQ
        JP      Z,RUN0259
        LD      HL,ARGBUF
        LD      DE,SC259
        CALL    STREQ
        JP      Z,RUN0259
        LD      HL,ARGBUF
        LD      DE,S0260
        CALL    STREQ
        JP      Z,RUN0260
        LD      HL,ARGBUF
        LD      DE,SC260
        CALL    STREQ
        JP      Z,RUN0260
        LD      HL,ARGBUF
        LD      DE,S0261
        CALL    STREQ
        JP      Z,RUN0261
        LD      HL,ARGBUF
        LD      DE,SC261
        CALL    STREQ
        JP      Z,RUN0261
        LD      HL,ARGBUF
        LD      DE,S0262
        CALL    STREQ
        JP      Z,RUN0262
        LD      HL,ARGBUF
        LD      DE,SC262
        CALL    STREQ
        JP      Z,RUN0262
        LD      HL,ARGBUF
        LD      DE,S0263
        CALL    STREQ
        JP      Z,RUN0263
        LD      HL,ARGBUF
        LD      DE,SC263
        CALL    STREQ
        JP      Z,RUN0263
        LD      HL,ARGBUF
        LD      DE,S0264
        CALL    STREQ
        JP      Z,RUN0264
        LD      HL,ARGBUF
        LD      DE,SC264
        CALL    STREQ
        JP      Z,RUN0264
        LD      HL,ARGBUF
        LD      DE,S0266
        CALL    STREQ
        JP      Z,RUN0266
        LD      HL,ARGBUF
        LD      DE,SC266
        CALL    STREQ
        JP      Z,RUN0266
        LD      HL,ARGBUF
        LD      DE,S0267
        CALL    STREQ
        JP      Z,RUN0267
        LD      HL,ARGBUF
        LD      DE,SC267
        CALL    STREQ
        JP      Z,RUN0267
        LD      HL,ARGBUF
        LD      DE,S0268
        CALL    STREQ
        JP      Z,RUN0268
        LD      HL,ARGBUF
        LD      DE,SC268
        CALL    STREQ
        JP      Z,RUN0268
        LD      HL,ARGBUF
        LD      DE,S0269
        CALL    STREQ
        JP      Z,RUN0269
        LD      HL,ARGBUF
        LD      DE,SC269
        CALL    STREQ
        JP      Z,RUN0269
        LD      HL,ARGBUF
        LD      DE,S0271
        CALL    STREQ
        JP      Z,RUN0271
        LD      HL,ARGBUF
        LD      DE,SC271
        CALL    STREQ
        JP      Z,RUN0271
        LD      HL,ARGBUF
        LD      DE,S0272
        CALL    STREQ
        JP      Z,RUN0272
        LD      HL,ARGBUF
        LD      DE,SC272
        CALL    STREQ
        JP      Z,RUN0272
        LD      HL,ARGBUF
        LD      DE,S0273
        CALL    STREQ
        JP      Z,RUN0273
        LD      HL,ARGBUF
        LD      DE,SC273
        CALL    STREQ
        JP      Z,RUN0273
        LD      HL,ARGBUF
        LD      DE,S0274
        CALL    STREQ
        JP      Z,RUN0274
        LD      HL,ARGBUF
        LD      DE,SC274
        CALL    STREQ
        JP      Z,RUN0274
        LD      HL,ARGBUF
        LD      DE,S0278
        CALL    STREQ
        JP      Z,RUN0278
        LD      HL,ARGBUF
        LD      DE,SC278
        CALL    STREQ
        JP      Z,RUN0278
        LD      HL,ARGBUF
        LD      DE,S0279
        CALL    STREQ
        JP      Z,RUN0279
        LD      HL,ARGBUF
        LD      DE,SC279
        CALL    STREQ
        JP      Z,RUN0279
        LD      HL,ARGBUF
        LD      DE,S0317
        CALL    STREQ
        JP      Z,RUN0317
        LD      HL,ARGBUF
        LD      DE,SC317
        CALL    STREQ
        JP      Z,RUN0317
        LD      HL,ARGBUF
        LD      DE,S0318
        CALL    STREQ
        JP      Z,RUN0318
        LD      HL,ARGBUF
        LD      DE,SC318
        CALL    STREQ
        JP      Z,RUN0318
        LD      HL,ARGBUF
        LD      DE,S0319
        CALL    STREQ
        JP      Z,RUN0319
        LD      HL,ARGBUF
        LD      DE,SC319
        CALL    STREQ
        JP      Z,RUN0319
        LD      HL,ARGBUF
        LD      DE,S0320
        CALL    STREQ
        JP      Z,RUN0320
        LD      HL,ARGBUF
        LD      DE,SC320
        CALL    STREQ
        JP      Z,RUN0320
        LD      HL,ARGBUF
        LD      DE,S0321
        CALL    STREQ
        JP      Z,RUN0321
        LD      HL,ARGBUF
        LD      DE,SC321
        CALL    STREQ
        JP      Z,RUN0321
        LD      HL,ARGBUF
        LD      DE,S0322
        CALL    STREQ
        JP      Z,RUN0322
        LD      HL,ARGBUF
        LD      DE,SC322
        CALL    STREQ
        JP      Z,RUN0322
        LD      HL,ARGBUF
        LD      DE,S0323
        CALL    STREQ
        JP      Z,RUN0323
        LD      HL,ARGBUF
        LD      DE,SC323
        CALL    STREQ
        JP      Z,RUN0323
        LD      HL,ARGBUF
        LD      DE,S0324
        CALL    STREQ
        JP      Z,RUN0324
        LD      HL,ARGBUF
        LD      DE,SC324
        CALL    STREQ
        JP      Z,RUN0324
        LD      HL,ARGBUF
        LD      DE,S0326
        CALL    STREQ
        JP      Z,RUN0326
        LD      HL,ARGBUF
        LD      DE,SC326
        CALL    STREQ
        JP      Z,RUN0326
        LD      HL,ARGBUF
        LD      DE,S0327
        CALL    STREQ
        JP      Z,RUN0327
        LD      HL,ARGBUF
        LD      DE,SC327
        CALL    STREQ
        JP      Z,RUN0327
        LD      HL,ARGBUF
        LD      DE,S0328
        CALL    STREQ
        JP      Z,RUN0328
        LD      HL,ARGBUF
        LD      DE,SC328
        CALL    STREQ
        JP      Z,RUN0328
        LD      HL,ARGBUF
        LD      DE,S0329
        CALL    STREQ
        JP      Z,RUN0329
        LD      HL,ARGBUF
        LD      DE,SC329
        CALL    STREQ
        JP      Z,RUN0329
        LD      HL,ARGBUF
        LD      DE,S0330
        CALL    STREQ
        JP      Z,RUN0330
        LD      HL,ARGBUF
        LD      DE,SC330
        CALL    STREQ
        JP      Z,RUN0330
        LD      HL,ARGBUF
        LD      DE,S0331
        CALL    STREQ
        JP      Z,RUN0331
        LD      HL,ARGBUF
        LD      DE,SC331
        CALL    STREQ
        JP      Z,RUN0331
        LD      HL,ARGBUF
        LD      DE,S0332
        CALL    STREQ
        JP      Z,RUN0332
        LD      HL,ARGBUF
        LD      DE,SC332
        CALL    STREQ
        JP      Z,RUN0332
        LD      HL,ARGBUF
        LD      DE,S0333
        CALL    STREQ
        JP      Z,RUN0333
        LD      HL,ARGBUF
        LD      DE,SC333
        CALL    STREQ
        JP      Z,RUN0333
        LD      HL,ARGBUF
        LD      DE,S0335
        CALL    STREQ
        JP      Z,RUN0335
        LD      HL,ARGBUF
        LD      DE,SC335
        CALL    STREQ
        JP      Z,RUN0335
        LD      HL,ARGBUF
        LD      DE,S0336
        CALL    STREQ
        JP      Z,RUN0336
        LD      HL,ARGBUF
        LD      DE,SC336
        CALL    STREQ
        JP      Z,RUN0336
        LD      HL,ARGBUF
        LD      DE,S0337
        CALL    STREQ
        JP      Z,RUN0337
        LD      HL,ARGBUF
        LD      DE,SC337
        CALL    STREQ
        JP      Z,RUN0337
        LD      HL,ARGBUF
        LD      DE,S0338
        CALL    STREQ
        JP      Z,RUN0338
        LD      HL,ARGBUF
        LD      DE,SC338
        CALL    STREQ
        JP      Z,RUN0338
        LD      HL,ARGBUF
        LD      DE,S0339
        CALL    STREQ
        JP      Z,RUN0339
        LD      HL,ARGBUF
        LD      DE,SC339
        CALL    STREQ
        JP      Z,RUN0339
        LD      HL,ARGBUF
        LD      DE,S0340
        CALL    STREQ
        JP      Z,RUN0340
        LD      HL,ARGBUF
        LD      DE,SC340
        CALL    STREQ
        JP      Z,RUN0340
        LD      HL,ARGBUF
        LD      DE,S0341
        CALL    STREQ
        JP      Z,RUN0341
        LD      HL,ARGBUF
        LD      DE,SC341
        CALL    STREQ
        JP      Z,RUN0341
        LD      HL,ARGBUF
        LD      DE,S0342
        CALL    STREQ
        JP      Z,RUN0342
        LD      HL,ARGBUF
        LD      DE,SC342
        CALL    STREQ
        JP      Z,RUN0342
        LD      HL,ARGBUF
        LD      DE,S0343
        CALL    STREQ
        JP      Z,RUN0343
        LD      HL,ARGBUF
        LD      DE,SC343
        CALL    STREQ
        JP      Z,RUN0343
        LD      HL,ARGBUF
        LD      DE,S0344
        CALL    STREQ
        JP      Z,RUN0344
        LD      HL,ARGBUF
        LD      DE,SC344
        CALL    STREQ
        JP      Z,RUN0344
        LD      HL,ARGBUF
        LD      DE,S0345
        CALL    STREQ
        JP      Z,RUN0345
        LD      HL,ARGBUF
        LD      DE,SC345
        CALL    STREQ
        JP      Z,RUN0345
        LD      HL,ARGBUF
        LD      DE,S0346
        CALL    STREQ
        JP      Z,RUN0346
        LD      HL,ARGBUF
        LD      DE,SC346
        CALL    STREQ
        JP      Z,RUN0346
        LD      HL,ARGBUF
        LD      DE,S0347
        CALL    STREQ
        JP      Z,RUN0347
        LD      HL,ARGBUF
        LD      DE,SC347
        CALL    STREQ
        JP      Z,RUN0347
        LD      HL,ARGBUF
        LD      DE,S0348
        CALL    STREQ
        JP      Z,RUN0348
        LD      HL,ARGBUF
        LD      DE,SC348
        CALL    STREQ
        JP      Z,RUN0348
        LD      HL,ARGBUF
        LD      DE,S0349
        CALL    STREQ
        JP      Z,RUN0349
        LD      HL,ARGBUF
        LD      DE,SC349
        CALL    STREQ
        JP      Z,RUN0349
        LD      HL,ARGBUF
        LD      DE,S0350
        CALL    STREQ
        JP      Z,RUN0350
        LD      HL,ARGBUF
        LD      DE,SC350
        CALL    STREQ
        JP      Z,RUN0350
        LD      HL,ARGBUF
        LD      DE,S0351
        CALL    STREQ
        JP      Z,RUN0351
        LD      HL,ARGBUF
        LD      DE,SC351
        CALL    STREQ
        JP      Z,RUN0351
        LD      HL,ARGBUF
        LD      DE,S0368
        CALL    STREQ
        JP      Z,RUN0368
        LD      HL,ARGBUF
        LD      DE,SC368
        CALL    STREQ
        JP      Z,RUN0368
        LD      HL,ARGBUF
        LD      DE,S0369
        CALL    STREQ
        JP      Z,RUN0369
        LD      HL,ARGBUF
        LD      DE,SC369
        CALL    STREQ
        JP      Z,RUN0369
        LD      HL,ARGBUF
        LD      DE,S0550
        CALL    STREQ
        JP      Z,RUN0550
        LD      HL,ARGBUF
        LD      DE,SC550
        CALL    STREQ
        JP      Z,RUN0550
        LD      HL,ARGBUF
        LD      DE,S0551
        CALL    STREQ
        JP      Z,RUN0551
        LD      HL,ARGBUF
        LD      DE,SC551
        CALL    STREQ
        JP      Z,RUN0551
        LD      HL,ARGBUF
        LD      DE,SGROUPOPEN
        CALL    STREQ
        JP      Z,RUNOPEN
        LD      HL,ARGBUF
        LD      DE,SGROUPSEQ
        CALL    STREQ
        JP      Z,RUNSEQ
        LD      HL,ARGBUF
        LD      DE,SGROUPCLOSE
        CALL    STREQ
        JP      Z,RUNCLOSE
        LD      HL,ARGBUF
        LD      DE,SGLIST
        CALL    STREQ
        JP      Z,DOGROUPLIST
        LD      HL,ARGBUF
        LD      DE,SGFCB
        CALL    STREQ
        JP      Z,RUNFCBOPEN
        LD      HL,ARGBUF
        LD      DE,SGREAD
        CALL    STREQ
        JP      Z,RUNGREAD
        LD      HL,ARGBUF
        LD      DE,SGWRITE
        CALL    STREQ
        JP      Z,RUNGWRITE
        LD      HL,ARGBUF
        LD      DE,SGRANDOM
        CALL    STREQ
        JP      Z,RUNGRANDOM
        LD      HL,ARGBUF
        LD      DE,SGLIFE
        CALL    STREQ
        JP      Z,RUNGLIFE
        LD      HL,ARGBUF
        LD      DE,SGREQ
        CALL    STREQ
        JP      Z,RUNREQUIRED
        LD      HL,ARGBUF
        LD      DE,SGOBS
        CALL    STREQ
        JP      Z,RUNOBSERVATION
        LD      HL,ARGBUF
        LD      DE,SGMAN
        CALL    STREQ
        JP      Z,RUNMANUAL
        LD      HL,ARGBUF
        LD      DE,SFN15
        CALL    STREQ
        JP      Z,RUNALL
        LD      HL,ARGBUF
        LD      DE,SGFN15
        CALL    STREQ
        JP      Z,RUNALL
        LD      HL,ARGBUF
        LD      DE,SFN16
        CALL    STREQ
        JP      Z,RUNCLOSE
        LD      HL,ARGBUF
        LD      DE,SGFN16
        CALL    STREQ
        JP      Z,RUNCLOSE
        LD      HL,ARGBUF
        LD      DE,SFN20
        CALL    STREQ
        JP      Z,RUNREADS
        LD      HL,ARGBUF
        LD      DE,SGFN20
        CALL    STREQ
        JP      Z,RUNREADS
        LD      HL,ARGBUF
        LD      DE,SSAFE
        CALL    STREQ
        JP      Z,RUNALL
        LD      HL,ARGBUF
        LD      DE,SALL
        CALL    STREQ
        JP      Z,RUNCOMPLETE
        LD      HL,ARGBUF
        LD      DE,SLIST
        CALL    STREQ
        JP      Z,DOLIST
        LD      HL,ARGBUF
        LD      DE,SHELP
        CALL    STREQ
        JP      Z,DOHELP
        LD      HL,ARGBUF
        LD      DE,SHELP2
        CALL    STREQ
        JP      Z,DOHELP
        LD      HL,ARGBUF
        LD      DE,SHRESULTS
        CALL    STREQ
        JP      Z,DOHRESULTS
        LD      HL,ARGBUF
        LD      DE,SHPROFILES
        CALL    STREQ
        JP      Z,DOHPROFILES
        LD      HL,ARGBUF
        LD      DE,SINFO
        CALL    STREQ
        JP      Z,DOINFO
        LD      HL,ARGBUF
        LD      DE,SVER
        CALL    STREQ
        JP      Z,DOVERSION
        LD      HL,ARGBUF
        LD      DE,SVERSION
        CALL    STREQ
        JP      Z,DOVERSION

BADCOMMAND:
        LD      DE,MSG_BADSEL
        CALL    PUTS
        JP      0000H

;------------------------ DECODE COMMAND TAIL -------------------------
; Copy and fold exactly one selector.  A second nonblank token is invalid.
; /NNNN:REPORT is canonicalized to /NNNN after selecting the full report.
PARSEARG:
        XOR     A
        LD      (FULLMODE),A
        LD      (PARSEBAD),A
        LD      A,(CMDLEN)
        LD      B,A
        LD      HL,CMDTXT
        LD      DE,ARGBUF
PASKIP:
        LD      A,B
        OR      A
        JP      Z,PADONE
        LD      A,(HL)
        CP      ' '
        JP      NZ,PACOPY
        INC     HL
        DEC     B
        JP      PASKIP
PACOPY:
        LD      A,B
        OR      A
        JP      Z,PADONE
        LD      A,(HL)
        CP      ' '
        JP      Z,PATRAIL
        CP      'a'
        JP      C,PASTORE
        CP      'z'+1
        JP      NC,PASTORE
        SUB     20H
PASTORE:
        LD      (DE),A
        INC     DE
        INC     HL
        DEC     B
        JP      PACOPY
PATRAIL:
        INC     HL
        DEC     B
PATLOOP:
        LD      A,B
        OR      A
        JP      Z,PADONE
        LD      A,(HL)
        CP      ' '
        JP      NZ,PABAD
        INC     HL
        DEC     B
        JP      PATLOOP
PABAD:  LD      A,1
        LD      (PARSEBAD),A
PADONE:
        XOR     A
        LD      (DE),A
        LD      A,(PARSEBAD)
        OR      A
        RET     NZ
        LD      HL,ARGBUF
        LD      A,(HL)
        CP      '/'
        RET     NZ
        INC     HL
        LD      B,4
PARDIG:LD      A,(HL)
        CP      '0'
        RET     C
        CP      '9'+1
        RET     NC
        INC     HL
        DEC     B
        JP      NZ,PARDIG
        LD      A,(HL)
        CP      ':'
        RET     NZ
        PUSH    HL
        LD      DE,SREPORT
        CALL    STREQ
        POP     HL
        RET     NZ
        XOR     A
        LD      (HL),A
        INC     A
        LD      (FULLMODE),A
        RET

; Compare two zero-ended words.  Exit Z only when both ends agree.
STREQ:
        LD      A,(DE)
        CP      (HL)
        RET     NZ
        OR      A
        RET     Z
        INC     DE
        INC     HL
        JP      STREQ

DOLIST:
        LD      DE,MSG_LIST
        CALL    PUTS
        JP      0000H
DOGROUPLIST:
        LD      DE,MSG_GROUPS
        CALL    PUTS
        JP      0000H

DOHELP:
        LD      DE,MSG_HELP
        CALL    PUTS
        JP      0000H
DOHRESULTS:
        LD      DE,MSG_RESULTS
        CALL    PUTS
        JP      0000H
DOHPROFILES:
        LD      DE,MSG_PROFILES
        CALL    PUTS
        JP      0000H
DOINFO:
        LD      DE,MSG_INFO
        CALL    PUTS
        JP      0000H
DOVERSION:
        LD      DE,MSG_VERSION
        CALL    PUTS
        JP      0000H

;----------------------- GROUP RUN CONTROL ----------------------------
; AGGMODE keeps an individual card from returning through page zero.  Counts
; belong only to cards actually called; catalog coverage is printed elsewhere.
AGGINIT:
        LD      A,1
        LD      (AGGMODE),A
        XOR     A
        LD      (PASSCT),A
        LD      (FAILCT),A
        LD      (ERRCT),A
        LD      (OBSCT),A
        LD      (NOTRUNCT),A
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPACTHEAD
        LD      DE,HAGG1
        CALL    PUTS
        LD      HL,ARGBUF
        CALL    PUTZ
        RET

RUNOPEN:
        CALL    AGGINIT
        LD      DE,HOPEN
        CALL    PUTFULL
        CALL    RUN0165
        CALL    RUN0169
        CALL    RUN0171
        CALL    RUN0173
        CALL    RUN0175
        CALL    PUTSUM
        JP      0000H

RUNSEQ:
        CALL    AGGINIT
        LD      DE,HSEQ
        CALL    PUTFULL
        CALL    RUN0167
        CALL    RUN0179
        CALL    RUN0219
        CALL    RUN0220
        CALL    RUN0221
        CALL    RUN0222
        CALL    RUNB10
        CALL    RUND10
        CALL    RUN0243
        CALL    PUTSUM
        JP      0000H

RUNCLOSE:
        CALL    AGGINIT
        LD      DE,HCLOSE
        CALL    PUTFULL
        CALL    RUN0177
        CALL    RUN0181
        CALL    PUTSUM
        JP      0000H

RUNREADS:
        CALL    AGGINIT
        LD      DE,HREADS
        CALL    PUTFULL
        CALL    RUN0167
        CALL    RUN0173
        CALL    RUN0179
        CALL    RUN0219
        CALL    RUN0220
        CALL    RUN0221
        CALL    RUN0222
        CALL    RUNB10
        CALL    RUND10
        CALL    RUN0243
        CALL    PUTSUM
        JP      0000H

RUNALL:
        CALL    AGGINIT
        LD      DE,HALL
        CALL    PUTFULL
        CALL    RUN0165
        CALL    RUN0167
        CALL    RUN0169
        CALL    RUN0171
        CALL    RUN0173
        CALL    RUN0175
        CALL    RUN0177
        CALL    RUN0179
        CALL    RUN0219
        CALL    RUN0220
        CALL    RUN0221
        CALL    RUN0222
        CALL    RUNB10
        CALL    RUND10
        CALL    RUN0243
        CALL    PUTSUM
        JP      0000H

; Functional and universal groups reuse the established card routines.
RUNFCBOPEN:
        CALL    AGGINIT
        LD      DE,HGFCB
        CALL    PUTFULL
        CALL    RUN0156
        CALL    RUN0157
        CALL    RUN0158
        CALL    RUN0159
        CALL    RUN0160
        CALL    RUN0161
        CALL    RUN0162
        CALL    RUN0164
        CALL    RUN0165
        CALL    RUN0166
        CALL    RUN0167
        CALL    RUN0168
        CALL    RUN0169
        CALL    RUN0170
        CALL    RUN0171
        CALL    RUN0172
        CALL    RUN0173
        CALL    RUN0174
        CALL    RUN0175
        CALL    RUN0176
        CALL    RUN0177
        CALL    RUN0178
        CALL    RUN0179
        CALL    RUN0180
        CALL    RUN0181
        LD      A,0
        CALL    RUNDIAGONE
        LD      A,1
        CALL    RUNDIAGONE
        LD      A,2
        CALL    RUNDIAGONE
        LD      DE,SKIPFCB
        LD      A,3
        CALL    PUTSKIPS
        CALL    PUTSUM
        JP      0000H

RUNGREAD:
        CALL    AGGINIT
        LD      DE,HGREAD
        CALL    PUTFULL
        CALL    RUN0219
        CALL    RUN0220
        CALL    RUN0221
        CALL    RUN0222
        CALL    RUN0223
        CALL    RUN0224
        CALL    RUN0226
        CALL    RUN0227
        CALL    RUN0228
        CALL    RUN0229
        CALL    RUN0230
        CALL    RUN0231
        CALL    RUN0232
        CALL    RUN0234
        CALL    RUN0235
        CALL    RUN0236
        CALL    RUN0237
        CALL    RUN0239
        CALL    RUN0242
        CALL    RUN0243
        CALL    RUN0248
        CALL    RUN0249
        CALL    RUN0250
        CALL    RUN0251
        CALL    RUN0252
        CALL    RUN0253
        CALL    RUN0254
        LD      A,3
        CALL    RUNDIAGONE
        LD      A,4
        CALL    RUNDIAGONE
        LD      A,5
        CALL    RUNDIAGONE
        LD      A,6
        CALL    RUNDIAGONE
        LD      A,7
        CALL    RUNDIAGONE
        LD      A,8
        CALL    RUNDIAGONE
        LD      A,9
        CALL    RUNDIAGONE
        LD      A,10
        CALL    RUNDIAGONE
        LD      DE,SKIPREAD
        LD      A,3
        CALL    PUTSKIPS
        CALL    PUTSUM
        JP      0000H

RUNGWRITE:
        CALL    AGGINIT
        LD      DE,HGWRITE
        CALL    PUTFULL
        CALL    RUN0259
        CALL    RUN0260
        CALL    RUN0261
        CALL    RUN0262
        CALL    RUN0263
        CALL    RUN0264
        CALL    RUN0266
        CALL    RUN0267
        CALL    RUN0268
        CALL    RUN0269
        CALL    RUN0271
        CALL    RUN0272
        CALL    RUN0273
        CALL    RUN0274
        CALL    RUN0278
        CALL    RUN0279
        LD      A,11
        CALL    RUNDIAGONE
        LD      A,12
        CALL    RUNDIAGONE
        LD      A,13
        CALL    RUNDIAGONE
        LD      A,14
        CALL    RUNDIAGONE
        LD      A,15
        CALL    RUNDIAGONE
        LD      DE,SKIPWRITE
        LD      A,3
        CALL    PUTSKIPS
        CALL    PUTSUM
        JP      0000H

RUNGRANDOM:
        CALL    AGGINIT
        LD      DE,HGRANDOM
        CALL    PUTFULL
        CALL    RUN0317
        CALL    RUN0318
        CALL    RUN0319
        CALL    RUN0320
        CALL    RUN0321
        CALL    RUN0322
        CALL    RUN0323
        CALL    RUN0324
        CALL    RUN0326
        CALL    RUN0327
        CALL    RUN0328
        CALL    RUN0329
        CALL    RUN0330
        CALL    RUN0331
        CALL    RUN0332
        CALL    RUN0333
        CALL    RUN0335
        CALL    RUN0336
        CALL    RUN0337
        CALL    RUN0338
        CALL    RUN0339
        CALL    RUN0340
        CALL    RUN0341
        CALL    RUN0342
        CALL    RUN0343
        CALL    RUN0344
        CALL    RUN0345
        CALL    RUN0346
        CALL    RUN0347
        CALL    RUN0348
        CALL    RUN0349
        CALL    RUN0350
        CALL    RUN0351
        LD      A,16
        CALL    RUNDIAGONE
        LD      A,17
        CALL    RUNDIAGONE
        LD      A,18
        CALL    RUNDIAGONE
        LD      DE,SKIPRANDOM
        LD      A,1
        CALL    PUTSKIPS
        CALL    PUTSUM
        JP      0000H

RUNGLIFE:
        CALL    AGGINIT
        LD      DE,HGLIFE
        CALL    PUTFULL
        CALL    RUN0550
        CALL    RUN0551
        CALL    RUN0553
        CALL    RUN0555
        CALL    RUN0556
        CALL    RUN0557
        LD      A,19
        CALL    RUNDIAGONE
        LD      A,20
        CALL    RUNDIAGONE
        LD      A,21
        CALL    RUNDIAGONE
        LD      A,22
        CALL    RUNDIAGONE
        LD      DE,SKIPMAN
        LD      A,2
        CALL    PUTSKIPS
        CALL    PUTSUM
        JP      0000H

RUNREQUIRED:
        CALL    AGGINIT
        LD      DE,HGREQ
        CALL    PUTFULL
        CALL    RUN0156
        CALL    RUN0157
        CALL    RUN0158
        CALL    RUN0159
        CALL    RUN0160
        CALL    RUN0161
        CALL    RUN0162
        CALL    RUN0164
        CALL    RUN0165
        CALL    RUN0166
        CALL    RUN0167
        CALL    RUN0168
        CALL    RUN0169
        CALL    RUN0170
        CALL    RUN0171
        CALL    RUN0172
        CALL    RUN0173
        CALL    RUN0174
        CALL    RUN0175
        CALL    RUN0176
        CALL    RUN0177
        CALL    RUN0178
        CALL    RUN0179
        CALL    RUN0180
        CALL    RUN0181
        CALL    RUN0219
        CALL    RUN0220
        CALL    RUN0221
        CALL    RUN0222
        CALL    RUN0223
        CALL    RUN0224
        CALL    RUN0226
        CALL    RUN0227
        CALL    RUN0228
        CALL    RUN0229
        CALL    RUN0230
        CALL    RUN0231
        CALL    RUN0232
        CALL    RUN0234
        CALL    RUN0235
        CALL    RUN0236
        CALL    RUN0237
        CALL    RUN0239
        CALL    RUN0242
        CALL    RUN0243
        CALL    RUN0248
        CALL    RUN0249
        CALL    RUN0250
        CALL    RUN0251
        CALL    RUN0252
        CALL    RUN0253
        CALL    RUN0254
        CALL    RUN0259
        CALL    RUN0260
        CALL    RUN0261
        CALL    RUN0262
        CALL    RUN0263
        CALL    RUN0264
        CALL    RUN0266
        CALL    RUN0267
        CALL    RUN0268
        CALL    RUN0269
        CALL    RUN0271
        CALL    RUN0272
        CALL    RUN0273
        CALL    RUN0274
        CALL    RUN0278
        CALL    RUN0279
        CALL    RUN0317
        CALL    RUN0318
        CALL    RUN0319
        CALL    RUN0320
        CALL    RUN0321
        CALL    RUN0322
        CALL    RUN0323
        CALL    RUN0324
        CALL    RUN0326
        CALL    RUN0327
        CALL    RUN0328
        CALL    RUN0329
        CALL    RUN0330
        CALL    RUN0331
        CALL    RUN0332
        CALL    RUN0333
        CALL    RUN0335
        CALL    RUN0336
        CALL    RUN0337
        CALL    RUN0338
        CALL    RUN0339
        CALL    RUN0340
        CALL    RUN0341
        CALL    RUN0342
        CALL    RUN0343
        CALL    RUN0344
        CALL    RUN0345
        CALL    RUN0346
        CALL    RUN0347
        CALL    RUN0348
        CALL    RUN0349
        CALL    RUN0350
        CALL    RUN0351
        CALL    RUN0550
        CALL    RUN0551
        CALL    RUN0553
        CALL    RUN0555
        CALL    RUN0556
        CALL    RUN0557
        LD      DE,SKIPMAN
        LD      A,2
        CALL    PUTSKIPS
        CALL    PUTSUM
        JP      0000H

RUNOBSERVATION:
        CALL    AGGINIT
        LD      DE,HGOBS
        CALL    PUTFULL
        CALL    RUNDIAGALL
        CALL    PUTSUM
        JP      0000H

RUNMANUAL:
        LD      DE,MSG_MANUAL
        CALL    PUTS
        JP      0000H

PUTSKIPS:
        LD      (NOTRUNCT),A
        OR      A
        RET     Z
        JP      PUTS


; /ALL means all implemented cards which can return, plus the observation
; deck.  It cannot include 0368 and 0369: either may lose the transient and
; return directly to CCP.  Those two require their outside terminal transcript.
RUNCOMPLETE:
        CALL    AGGINIT
        LD      DE,HCOMPLETE
        CALL    PUTFULL
        CALL    RUN0156
        CALL    RUN0157
        CALL    RUN0158
        CALL    RUN0159
        CALL    RUN0160
        CALL    RUN0161
        CALL    RUN0162
        CALL    RUN0164
        CALL    RUN0165
        CALL    RUN0166
        CALL    RUN0167
        CALL    RUN0168
        CALL    RUN0169
        CALL    RUN0170
        CALL    RUN0171
        CALL    RUN0172
        CALL    RUN0173
        CALL    RUN0174
        CALL    RUN0175
        CALL    RUN0176
        CALL    RUN0177
        CALL    RUN0178
        CALL    RUN0179
        CALL    RUN0180
        CALL    RUN0181
        CALL    RUN0219
        CALL    RUN0220
        CALL    RUN0221
        CALL    RUN0222
        CALL    RUNB10
        CALL    RUND10
        CALL    RUND9
        CALL    RUN0262
        CALL    RUN0263
        CALL    RUN0264
        CALL    RUN0266
        CALL    RUN0267
        CALL    RUN0268
        CALL    RUN0269
        CALL    RUN0271
        CALL    RUN0272
        CALL    RUN0273
        CALL    RUN0274
        CALL    RUN0278
        CALL    RUN0279
        CALL    RUN0317
        CALL    RUN0318
        CALL    RUN0319
        CALL    RUN0320
        CALL    RUN0321
        CALL    RUN0322
        CALL    RUN0323
        CALL    RUN0324
        CALL    RUN0326
        CALL    RUN0327
        CALL    RUN0328
        CALL    RUN0329
        CALL    RUN0330
        CALL    RUN0331
        CALL    RUN0332
        CALL    RUN0333
        CALL    RUN0335
        CALL    RUN0336
        CALL    RUN0337
        CALL    RUN0338
        CALL    RUN0339
        CALL    RUN0340
        CALL    RUN0341
        CALL    RUN0342
        CALL    RUN0343
        CALL    RUN0344
        CALL    RUN0345
        CALL    RUN0346
        CALL    RUN0347
        CALL    RUN0348
        CALL    RUN0349
        CALL    RUN0350
        CALL    RUN0351
        CALL    RUN0550
        CALL    RUN0551
        CALL    RUN0253
        CALL    RUN0553
        CALL    RUN0555
        CALL    RUN0556
        CALL    RUN0557
        CALL    RUNDIAGALL
        LD      DE,SKIPALL
        LD      A,12
        CALL    PUTSKIPS
        CALL    PUTSUM
        JP      0000H

; Walk the observation deck.  Each seven-byte entry contains two selector
; pointers, a case pointer and a one-byte operation number.
RUNDIAGALL:
        LD      HL,DIAGTAB
        LD      A,DIAG_COUNT
        LD      (DIAGLEFT),A
RDAL1:  LD      DE,4
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        EX      DE,HL
        LD      (CASEPTR),HL
        EX      DE,HL
        LD      A,(HL)
        INC     HL
        LD      (DIAGPTR),HL
        CALL    RUNDIAG
        LD      HL,(DIAGPTR)
        LD      A,(DIAGLEFT)
        DEC     A
        LD      (DIAGLEFT),A
        JP      NZ,RDAL1
        RET

; Run one observation entry selected by its zero-based DIAGTAB index.
RUNDIAGONE:
        LD      H,0
        LD      L,A
        LD      D,H
        LD      E,L
        ADD     HL,HL
        ADD     HL,DE
        ADD     HL,HL
        ADD     HL,DE
        LD      DE,DIAGTAB
        ADD     HL,DE
        INC     HL
        INC     HL
        INC     HL
        INC     HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        EX      DE,HL
        LD      (CASEPTR),HL
        EX      DE,HL
        LD      A,(HL)
        JP      RUNDIAG

RUNB10:
        CALL    RUN0223
        CALL    RUN0224
        CALL    RUN0226
        CALL    RUN0227
        CALL    RUN0228
        CALL    RUN0229
        CALL    RUN0230
        CALL    RUN0231
        CALL    RUN0232
        RET

RUND10:
        CALL    RUN0234
        CALL    RUN0235
        CALL    RUN0236
        CALL    RUN0237
        CALL    RUN0239
        CALL    RUN0242
        RET

RUND9:
        CALL    RUN0243
        CALL    RUN0248
        CALL    RUN0249
        CALL    RUN0250
        CALL    RUN0251
        CALL    RUN0252
        CALL    RUN0254
        CALL    RUN0259
        CALL    RUN0260
        CALL    RUN0261
        RET

;---------------------- OBSERVATION CARD DECK -------------------------
; These NOT GUARANTEED cards are absent from /SAFE and can never add a PASS.
; Each table entry holds the short selector, long selector, printed card and
; a small operation number understood by RUNDIAG.
DIAGSELECT:
        LD      HL,DIAGTAB
        LD      B,DIAG_COUNT
DSL1:   LD      (DIAGPTR),HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        PUSH    BC
        PUSH    HL
        LD      HL,ARGBUF
        CALL    STREQ
        POP     HL
        POP     BC
        JP      Z,DSFOUND
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        PUSH    BC
        PUSH    HL
        LD      HL,ARGBUF
        CALL    STREQ
        POP     HL
        POP     BC
        JP      Z,DSFOUND2
        INC     HL
        INC     HL
        INC     HL
        DEC     B
        JP      NZ,DSL1
        RET
DSFOUND:
        INC     HL
        INC     HL
DSFOUND2:
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        EX      DE,HL
        LD      (CASEPTR),HL
        LD      A,(HL)
        JP      RUNDIAG

; Make an observation without inventing an oracle.  NEWOBS1 is normally the
; call result; NEWOBS2 is a selected FCB or DMA byte.  Whatever values arrive,
; DIAGDONE prints O and leaves the PASS and FAIL counters alone.
RUNDIAG:
        PUSH    AF
        CALL    INDHEAD
        POP     AF
        CP      1
        JP      Z,DGOPEN1
        CP      2
        JP      Z,DGOPENM
        CP      3
        JP      Z,DGREADU
        CP      4
        JP      Z,DGMAKEX
        CP      5
        JP      Z,DGMAKEW
        CP      6
        JP      Z,DGPART
        CP      7
        JP      Z,DGWRITEU
        CP      8
        JP      Z,DGTEMPW
        CP      9
        JP      Z,DGF36
        CP      10
        JP      Z,DGRFAIL
        CP      11
        JP      Z,DGF35
        CP      12
        JP      Z,DGREOPEN
        CP      13
        JP      Z,DGPROT
        CP      14
        JP      Z,DGALLOC
        CP      15
        JP      Z,DGINVALID
        CP      16
        JP      Z,DGEOF
        CP      17
        JP      Z,DGEFDMA
        CP      18
        JP      Z,DGEFFCB
        JP      DGOPEN1

DGOPEN1:
        LD      HL,ONEFCB
        CALL    OPENHL
        LD      A,(TESTFCB+13)
        LD      (NEWOBS2),A
        JP      DIAGDONE
DGOPENM:
        LD      HL,MISSFCB
        CALL    OPENHL
        LD      A,(TESTFCB+13)
        LD      (NEWOBS2),A
        JP      DIAGDONE
DGALLOC:
        LD      HL,ONEFCB
        CALL    OPENHL
        LD      A,(TESTFCB+16)
        LD      (NEWOBS1),A
        LD      A,(TESTFCB+17)
        LD      (NEWOBS2),A
        JP      DIAGDONE
DGREADU:
        LD      HL,ONEFCB
        CALL    INITFCB
        CALL    PREPDMA
        CALL    READTEST
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        CALL    RESTDMA
        JP      DIAGDONE
DGINVALID:
        LD      HL,ONEFCB
        CALL    INITFCB
        LD      A,0FFH
        LD      (TESTFCB+12),A
        CALL    PREPDMA
        CALL    READTEST
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        CALL    RESTDMA
        JP      DIAGDONE
DGMAKEX:
        LD      HL,ONEFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,22
        CALL    BDOS
        LD      (NEWOBS1),A
        LD      A,(TESTFCB+15)
        LD      (NEWOBS2),A
        JP      DIAGDONE
DGMAKEW:
        LD      HL,WILDFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,22
        CALL    BDOS
        LD      (NEWOBS1),A
        LD      A,(TESTFCB+15)
        LD      (NEWOBS2),A
        JP      DIAGDONE
DGPART:
        LD      HL,PARTFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,DIAGDONE
        CALL    PREPDMA
        CALL    READTEST
        LD      A,(DMABUF+127)
        LD      (NEWOBS2),A
        CALL    RESTDMA
        JP      DIAGDONE
; EOF and failure residue are recorded exactly as found.  They are useful
; fingerprints, but no particular DMA or working-FCB residue is required.
DGEOF:
        LD      HL,ONEFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,DIAGDONE
        CALL    PREPDMA
        CALL    READTEST
        CALL    READTEST
        LD      A,(NEWOBS2)
        LD      (NEWOBS1),A
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        CALL    RESTDMA
        JP      DIAGDONE
DGEFDMA:
        LD      HL,EMPTYFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,DIAGDONE
        CALL    PREPDMA
        CALL    READTEST
        LD      A,(NEWOBS2)
        LD      (NEWOBS1),A
        LD      A,(DMABUF)
        LD      (NEWOBS2),A
        CALL    RESTDMA
        JP      DIAGDONE
DGEFFCB:
        LD      HL,EMPTYFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,DIAGDONE
        CALL    PREPDMA
        CALL    READTEST
        LD      A,(NEWOBS2)
        LD      (NEWOBS1),A
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        CALL    RESTDMA
        JP      DIAGDONE
DGWRITEU:
        LD      HL,TEMPFCB
        CALL    INITFCB
        CALL    PREPDMA
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        LD      (NEWOBS1),A
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        CALL    RESTDMA
        JP      DIAGDONE
DGTEMPW:
        CALL    WRITEONE
        LD      A,(TESTFCB+16)
        LD      (NEWOBS1),A
        LD      A,(TESTFCB+15)
        LD      (NEWOBS2),A
        CALL    TEMPCLEAN
        JP      DIAGDONE
DGF36:
        LD      HL,ONEFCB
        CALL    OPENHL
        LD      A,1
        LD      (TESTFCB+32),A
        LD      DE,TESTFCB
        LD      C,36
        CALL    BDOS
        LD      (NEWOBS1),A
        LD      A,(TESTFCB+33)
        LD      (NEWOBS2),A
        JP      DIAGDONE
DGRFAIL:
        CALL    RANDOPEN
        LD      A,130
        LD      (TESTFCB+33),A
        XOR     A
        LD      (TESTFCB+34),A
        LD      (TESTFCB+35),A
        CALL    RANDREAD
        LD      A,(DMABUF)
        LD      (NEWOBS2),A
        CALL    RESTDMA
        JP      DIAGDONE
DGF35:
        LD      HL,ONEFCB
        CALL    OPENHL
        LD      DE,TESTFCB
        LD      C,35
        CALL    BDOS
        LD      (NEWOBS1),A
        LD      A,(TESTFCB+33)
        LD      (NEWOBS2),A
        JP      DIAGDONE
DGREOPEN:
        LD      HL,ONEFCB
        CALL    OPENHL
        LD      A,(TESTFCB+16)
        LD      (NEWOBS1),A
        LD      HL,ONEFCB
        CALL    OPENHL
        LD      A,(TESTFCB+16)
        LD      (NEWOBS2),A
        JP      DIAGDONE
DGPROT:
        LD      HL,ROFCB
        CALL    OPENHL
        LD      A,(TESTFCB+9)
        LD      (NEWOBS2),A
DIAGDONE:
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPOBS
        CALL    PUTNEWCASE
        LD      DE,MSG_DOBS
        CALL    PUTS
        CALL    PUTDOBS
        LD      DE,DIAGEVID
        CALL    PUTS
        LD      DE,MENDOBS
        CALL    PUTS
        LD      A,(AGGMODE)
        OR      A
        RET     NZ
        JP      0000H

;--------------------- FCB AND OPEN CARDS -----------------------------
; Required FCB-layout and Function-15 cards begin here.
RUN0156:
        LD      HL,C156MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    INITFCB
        LD      A,07FH
        LD      (TESTFCB+32),A
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        CP      07FH
        JP      NZ,NEWFAIL
        CALL    CHECKGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS

RUN0157:
        LD      HL,C157MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    INITFCB
        LD      A,1
        LD      (TESTFCB+12),A
        LD      A,2
        LD      (TESTFCB+32),A
        LD      DE,TESTFCB
        LD      C,36
        CALL    BDOS
        LD      A,(TESTFCB+33)
        LD      (NEWOBS2),A
        CP      082H
        JP      NZ,NEWFAIL
        LD      A,(TESTFCB+34)
        OR      A
        JP      NZ,NEWFAIL
        LD      A,(TESTFCB+35)
        OR      A
        JP      NZ,NEWFAIL
        CALL    CHECKGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS

RUN0158:
        LD      HL,C158MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    INITFCB
        LD      A,(TESTFCB)
        OR      A
        JP      NZ,NEWFAIL
        CALL    OPENRAW
        CP      0FFH
        JP      Z,NEWFAIL
        LD      HL,BFILEFCB
        CALL    INITFCB
        LD      A,(TESTFCB)
        LD      (NEWOBS2),A
        CP      3
        JP      NZ,NEWFAIL
        CALL    OPENRAW
        CP      0FFH
        JP      Z,NEWFAIL
        JP      NEWPASS

RUN0159:
        LD      HL,C159MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        LD      HL,TESTFCB+1
        LD      DE,NMONE
        LD      B,8
        CALL    MEMEQ
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0160:
        LD      HL,C160MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        LD      HL,TESTFCB+9
        LD      DE,TYPDAT
        LD      B,3
        CALL    MEMEQ
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0161:
        LD      HL,C161MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ROFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        LD      A,(TESTFCB+9)
        LD      (NEWOBS2),A
        AND     080H
        JP      Z,NEWFAIL
        JP      NEWPASS

RUN0162:
        LD      HL,C162MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,BIGFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        LD      A,31
        LD      (TESTFCB+12),A
        LD      A,127
        LD      (TESTFCB+32),A
        LD      DE,TESTFCB
        LD      C,36
        CALL    BDOS
        LD      A,(TESTFCB+12)
        LD      (NEWOBS2),A
        CP      31
        JP      NZ,NEWFAIL
        JP      NEWPASS

; 0164 separates caller input from returned working state.  S2 goes in zero;
; a successful Open may use it afterward.  Record the returned byte, but do
; not demand that BDOS hand the input zero back to us.
RUN0164:
        LD      HL,C164MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    INITFCB
        LD      A,(TESTFCB+14)
        OR      A
        JP      NZ,NEWFAIL
        CALL    OPENRAW
        CP      0FFH
        JP      Z,NEWFAIL
        LD      A,(TESTFCB+14)
        LD      (NEWOBS2),A
        CALL    TEMPCLEAN
        CALL    TEMPMAKE
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    TEMPCLEAN
        JP      NEWPASS

RUN0166:
        LD      HL,C166MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,BIGFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        LD      HL,TESTFCB+16
        LD      B,16
        XOR     A
R166LP: OR      (HL)
        INC     HL
        DEC     B
        JP      NZ,R166LP
        LD      (NEWOBS2),A
        OR      A
        JP      Z,NEWFAIL
        JP      NEWPASS

RUN0168:
        LD      HL,C168MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,0FH
        CALL    BDOS
        LD      (NEWOBS2),A
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    CHECKGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS

RUN0170:
        LD      HL,C170MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    OPENHL
        LD      (NEWOBS2),A
        CP      4
        JP      NC,NEWFAIL
        JP      NEWPASS

RUN0172:
        LD      HL,C172MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        JP      NZ,R172BAD
        LD      HL,DMABUF
        LD      DE,MONE
        LD      B,3
        CALL    MEMEQ
        JP      NZ,R172BAD
        CALL    RESTDMA
        JP      NEWPASS
R172BAD: CALL    RESTDMA
        JP      NEWFAIL

RUN0174:
        LD      HL,C174MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,WILDFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        JP      NZ,R174BAD
        LD      HL,DMABUF
        LD      DE,MWILD1
        LD      B,5
        CALL    MEMEQ
        JP      NZ,R174BAD
        CALL    RESTDMA
        JP      NEWPASS
R174BAD: CALL    RESTDMA
        JP      NEWFAIL

RUN0176:
        LD      HL,C176MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    INITFCB
        XOR     A
        LD      (TESTFCB+32),A
        CALL    OPENRAW
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        JP      NZ,R176BAD
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        CP      1
        JP      NZ,R176BAD
        CALL    RESTDMA
        JP      NEWPASS
R176BAD: CALL    RESTDMA
        JP      NEWFAIL

RUN0178:
        LD      HL,C178MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      VERIFYWRITE

RUN0180:
        LD      HL,C180MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,CLOSEFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      (NEWOBS2),A
        CP      4
        JP      NC,NEWFAIL
        JP      NEWPASS

RUN0165:
        LD      HL,C165MSG
        LD      (CASEPTR),HL
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,R165GO
        LD      DE,H165MSG
        CALL    PUTFULL
R165GO:
        LD      HL,ONEFCB
        CALL    INITFCB
        LD      A,0E7H
        LD      (TESTFCB+15),A
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        LD      (O165RET),A
        LD      A,(TESTFCB+15)
        LD      (O165RC),A
        CALL    CHECKGUARDS
        JP      NZ,C165ERR
        LD      A,(O165RET)
        CP      0FFH
        JP      Z,C165FAIL
        LD      A,(O165RC)
        CP      081H
        JP      NC,C165FAIL
        JP      C165PASS

C165PASS:
        LD      A,(O165RET)
        LD      (NEWOBS1),A
        LD      A,(O165RC)
        LD      (NEWOBS2),A
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPPASS
        LD      DE,C165MSG
        CALL    PUTS
        LD      DE,MSG_PASS
        CALL    PUTS
        CALL    PO165
        LD      DE,E165MSG
        CALL    PUTS
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,A165PASS
        LD      DE,MENDP
        CALL    PUTS
        JP      0000H
A165PASS:
        LD      HL,PASSCT
        INC     (HL)
        LD      DE,ENDONLY
        CALL    PUTS
        RET

C165FAIL:
        LD      A,(O165RET)
        LD      (NEWOBS1),A
        LD      A,(O165RC)
        LD      (NEWOBS2),A
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPFAIL
        LD      DE,C165MSG
        CALL    PUTS
        LD      DE,MSG_FAIL
        CALL    PUTS
        CALL    PO165
        LD      DE,MC003
        CALL    PUTS
        LD      DE,E165MSG
        CALL    PUTS
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,A165FAIL
        LD      DE,MENDF
        CALL    PUTS
        JP      0000H
A165FAIL:
        LD      HL,FAILCT
        INC     (HL)
        LD      DE,ENDONLY
        CALL    PUTS
        RET

C165ERR:
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPERR
        LD      DE,C165MSG
        CALL    PUTS
        LD      DE,MSG_ERROR
        CALL    PUTS
        CALL    PO165
        LD      DE,ME005
        CALL    PUTS
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,A165ERR
        LD      DE,MENDE
        CALL    PUTS
        JP      0000H
A165ERR:
        LD      HL,ERRCT
        INC     (HL)
        LD      DE,ENDONLY
        CALL    PUTS
        RET

PO165:
        LD      DE,O165A
        CALL    PUTS
        LD      A,(O165RET)
        CALL    HEXBYTE
        LD      DE,O165B
        CALL    PUTS
        LD      A,(O165RC)
        CALL    HEXBYTE
        LD      E,13
        CALL    PUTC
        LD      E,10
        JP      PUTC

RUN0169:
        LD      HL,C169MSG
        LD      (CASEPTR),HL
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,R169CHECK
        LD      A,(FULLMODE)
        OR      A
        JP      NZ,R169CHECK
        CALL    COMPACTHEAD
R169CHECK:
        CALL    CROSSREADY
        JP      NZ,NEWNOTRUN
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,R169GO
        LD      DE,H169MSG
        CALL    PUTFULL
R169GO:
        LD      C,25
        CALL    BDOS
        LD      (DRVBEFORE),A
        LD      HL,OPENFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        LD      (OBS169A),A
        CALL    CHECKGUARDS
        JP      NZ,C169ERR
        LD      A,(OBS169A)
        CP      0FFH
        JP      Z,C169FAIL
        LD      HL,BFILEFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        LD      (OBS169B),A
        CALL    CHECKGUARDS
        JP      NZ,C169ERR
        LD      C,25
        CALL    BDOS
        LD      (DRVAFTER),A
        LD      B,A
        LD      A,(OBS169B)
        CP      0FFH
        JP      Z,C169FAIL
        LD      A,(DRVBEFORE)
        CP      B
        JP      NZ,C169FAIL
        JP      C169PASS

;------------------------- GUARDED FCB --------------------------------
; HL -> drive/name/type template.  Put fresh tell-tales around TESTFCB, copy
; its first twelve bytes and clear all working fields.  No earlier call is
; allowed to lend extent, record or allocation state to the next card.
INITFCB:
        PUSH    HL
        LD      HL,GPRE
        LD      B,8
        LD      A,0A5H
IFG1:   LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,IFG1
        LD      HL,GPOST
        LD      B,8
        LD      A,05AH
IFG2:   LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,IFG2
        POP     HL
        LD      DE,TESTFCB
        LD      B,12
IFCP:   LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,IFCP
        LD      B,24
        XOR     A
IFCL:   LD      (DE),A
        INC     DE
        DEC     B
        JP      NZ,IFCL
        RET

C169PASS:
        LD      A,(OBS169A)
        LD      (NEWOBS1),A
        LD      A,(OBS169B)
        LD      (NEWOBS2),A
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPPASS
        LD      DE,C169MSG
        CALL    PUTS
        LD      DE,MSG_PASS
        CALL    PUTS
        CALL    PUTOBS169
        LD      DE,E169MSG
        CALL    PUTS
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,A169PASS
        LD      DE,MENDP
        CALL    PUTS
        JP      0000H
A169PASS:
        LD      HL,PASSCT
        INC     (HL)
        LD      DE,ENDONLY
        CALL    PUTS
        RET

C169FAIL:
        LD      A,(OBS169A)
        LD      (NEWOBS1),A
        LD      A,(OBS169B)
        LD      (NEWOBS2),A
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPFAIL
        LD      DE,C169MSG
        CALL    PUTS
        LD      DE,MSG_FAIL
        CALL    PUTS
        CALL    PUTOBS169
        LD      DE,MC004
        CALL    PUTS
        LD      DE,E169MSG
        CALL    PUTS
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,A169FAIL
        LD      DE,MENDF
        CALL    PUTS
        JP      0000H
A169FAIL:
        LD      HL,FAILCT
        INC     (HL)
        LD      DE,ENDONLY
        CALL    PUTS
        RET

C169ERR:
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPERR
        LD      DE,C169MSG
        CALL    PUTS
        LD      DE,MSG_ERROR
        CALL    PUTS
        CALL    PUTOBS169
        LD      DE,ME005
        CALL    PUTS
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,A169ERR
        LD      DE,MENDE
        CALL    PUTS
        JP      0000H
A169ERR:
        LD      HL,ERRCT
        INC     (HL)
        LD      DE,ENDONLY
        CALL    PUTS
        RET

PUTOBS169:
        LD      DE,O169A
        CALL    PUTS
        LD      A,(OBS169A)
        CALL    HEXBYTE
        LD      DE,O169B
        CALL    PUTS
        LD      A,(OBS169B)
        CALL    HEXBYTE
        LD      DE,O169C
        CALL    PUTS
        LD      A,(DRVBEFORE)
        CALL    HEXBYTE
        LD      DE,O169D
        CALL    PUTS
        LD      A,(DRVAFTER)
        CALL    HEXBYTE
        LD      E,13
        CALL    PUTC
        LD      E,10
        JP      PUTC

RUN0171:
        LD      HL,MSG_CASE_BEGIN
        LD      (CASEPTR),HL
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,R171GO
        LD      DE,MSG_HEADER
        CALL    PUTFULL
R171GO:
        CALL    INIT0171
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        LD      (OBSERVED),A
        CALL    CHECKGUARDS
        JP      NZ,CASE_ERROR
        LD      A,(OBSERVED)
        CP      0FFH
        JP      Z,CASE_PASS
        JP      CASE_FAIL

INIT0171:
        LD      HL,GPRE
        LD      B,8
        LD      A,0A5H
I17G1:
        LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,I17G1
        LD      HL,GPOST
        LD      B,8
        LD      A,05AH
I17G2:
        LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,I17G2
        LD      HL,MISSFCB
        LD      DE,TESTFCB
        LD      B,12
I17CP:
        LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,I17CP
        LD      B,24
        XOR     A
I17CL:
        LD      (DE),A
        INC     DE
        DEC     B
        JP      NZ,I17CL
        RET

CHECKGUARDS:
        LD      HL,GPRE
        LD      B,8
        LD      C,0A5H
CG1:
        LD      A,(HL)
        CP      C
        RET     NZ
        INC     HL
        DEC     B
        JP      NZ,CG1
        LD      HL,GPOST
        LD      B,8
        LD      C,05AH
CG2:
        LD      A,(HL)
        CP      C
        RET     NZ
        INC     HL
        DEC     B
        JP      NZ,CG2
        XOR     A
        RET

CASE_PASS:
        LD      A,(OBSERVED)
        LD      (NEWOBS1),A
        XOR     A
        LD      (NEWOBS2),A
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPPASS
        LD      DE,MSG_CASE_BEGIN
        CALL    PUTS
        LD      DE,MSG_PASS
        CALL    PUTS
        CALL    PUTOBS
        LD      DE,MSG_EVIDENCE
        CALL    PUTS
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,A171PASS
        LD      DE,MENDP
        CALL    PUTS
        JP      0000H
A171PASS:
        LD      HL,PASSCT
        INC     (HL)
        LD      DE,ENDONLY
        CALL    PUTS
        RET

CASE_FAIL:
        LD      A,(OBSERVED)
        LD      (NEWOBS1),A
        XOR     A
        LD      (NEWOBS2),A
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPFAIL
        LD      DE,MSG_CASE_BEGIN
        CALL    PUTS
        LD      DE,MSG_FAIL
        CALL    PUTS
        CALL    PUTOBS
        LD      DE,MC002
        CALL    PUTS
        LD      DE,MSG_EVIDENCE
        CALL    PUTS
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,A171FAIL
        LD      DE,MENDF
        CALL    PUTS
        JP      0000H
A171FAIL:
        LD      HL,FAILCT
        INC     (HL)
        LD      DE,ENDONLY
        CALL    PUTS
        RET

CASE_ERROR:
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPERR
        LD      DE,MSG_CASE_BEGIN
        CALL    PUTS
        LD      DE,MSG_ERROR
        CALL    PUTS
        CALL    PUTOBS
        LD      DE,ME005
        CALL    PUTS
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,A171ERR
        LD      DE,MENDE
        CALL    PUTS
        JP      0000H
A171ERR:
        LD      HL,ERRCT
        INC     (HL)
        LD      DE,ENDONLY
        CALL    PUTS
        RET

;---------------------- SEQUENTIAL READ CARDS -------------------------
; The following cards share reporting, not evidence.  Each opens and guards
; its own FCB and selects a freshly marked DMA record.
RUN0167:
        LD      HL,C167MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,MULTIFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        LD      (NEWOBS1),A
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        LD      B,3
R167LP:
        PUSH    BC
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        LD      (NEWOBS2),A
        POP     BC
        OR      A
        JP      NZ,R167BAD
        ; B is the descending loop count; expected CR is 4-B.
        LD      A,4
        SUB     B
        LD      C,A
        LD      A,(TESTFCB+32)
        CP      C
        JP      NZ,R167BAD
        DEC     B
        JP      NZ,R167LP
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        LD      HL,DMABUF
        LD      DE,MMULTI
        LD      B,5
        CALL    MEMEQ
        JP      NZ,NEWFAIL
        JP      NEWPASS
R167BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0173:
        LD      HL,C173MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        LD      (NEWOBS1),A
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        LD      (NEWOBS2),A
        CALL    RESTDMA
        LD      A,(NEWOBS2)
        OR      A
        JP      NZ,NEWFAIL
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        LD      HL,DMABUF
        LD      DE,MONE
        LD      B,3
        CALL    MEMEQ
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0175:
        LD      HL,C175MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,WILDFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        LD      (NEWOBS1),A
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        LD      (NEWOBS2),A
        CALL    RESTDMA
        LD      A,(NEWOBS2)
        OR      A
        JP      NZ,NEWFAIL
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        LD      HL,DMABUF
        LD      DE,MWILD1
        LD      B,5
        CALL    MEMEQ
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0177:
        LD      HL,C177MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,CLOSEFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        LD      (NEWOBS1),A
        CP      0FFH
        JP      Z,NEWFAIL
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      (NEWOBS2),A
        CALL    CHECKGUARDS
        JP      NZ,NEWERROR
        LD      A,(NEWOBS2)
        CP      0FFH
        JP      Z,NEWFAIL
        JP      NEWPASS

RUN0179:
        LD      HL,C179MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        LD      (NEWOBS1),A
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        LD      (NEWOBS2),A
        CALL    RESTDMA
        LD      A,(NEWOBS2)
        OR      A
        JP      NZ,NEWFAIL
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        LD      HL,DMABUF
        LD      DE,MONE
        LD      B,3
        CALL    MEMEQ
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0181:
        LD      HL,C181MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,MISSFCB
        CALL    INITFCB
        LD      A,1
        LD      (TESTFCB+15),A
        LD      (TESTFCB+16),A
        XOR     A
        LD      (TESTFCB+14),A
        LD      (NEWOBS1),A
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      (NEWOBS2),A
        CALL    CHECKGUARDS
        JP      NZ,NEWERROR
        LD      A,(NEWOBS2)
        CP      0FFH
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0219:
        LD      HL,C219MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        LD      (NEWOBS1),A
        CP      0FFH
        JP      Z,NEWFAIL
        ; A different valid decoy FCB exists, but DE selects TESTFCB.
        CALL    PREPDMA
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        LD      (NEWOBS2),A
        CALL    RESTDMA
        LD      A,(NEWOBS2)
        OR      A
        JP      NZ,NEWFAIL
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        LD      HL,DMABUF
        LD      DE,MONE
        LD      B,3
        CALL    MEMEQ
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0220:
        LD      HL,C220MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        LD      (NEWOBS1),A
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        LD      (NEWOBS2),A
        CALL    RESTDMA
        LD      A,(NEWOBS2)
        OR      A
        JP      NZ,NEWFAIL
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        LD      HL,DMABUF
        LD      DE,MONE
        LD      B,3
        CALL    MEMEQ
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0221:
        LD      HL,C221MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,MULTIFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        LD      (NEWOBS1),A
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        LD      (NEWOBS2),A
        OR      A
        JP      NZ,R221BAD
        LD      HL,DMABUF
        LD      DE,MMULTI0
        LD      B,9
        CALL    MEMEQ
        JP      NZ,R221BAD
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        LD      (NEWOBS2),A
        OR      A
        JP      NZ,R221BAD
        LD      HL,DMABUF
        LD      DE,MMULTI1
        LD      B,9
        CALL    MEMEQ
        JP      NZ,R221BAD
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        LD      (NEWOBS2),A
        OR      A
        JP      NZ,R221BAD
        LD      HL,DMABUF
        LD      DE,MMULTI2
        LD      B,9
        CALL    MEMEQ
        JP      NZ,R221BAD
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS
R221BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0222:
        LD      HL,C222MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        LD      (NEWOBS1),A
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        LD      (NEWOBS2),A
        CALL    RESTDMA
        LD      A,(NEWOBS2)
        OR      A
        JP      NZ,NEWFAIL
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        CALL    CHECKONE128
        JP      NZ,NEWFAIL
        JP      NEWPASS

; Open the template at HL in the guarded FCB.  OPENRAW records A before any
; following instruction can obscure it.
OPENHL:
        CALL    INITFCB
OPENRAW:
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        LD      (NEWOBS1),A
        RET

READTEST:
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        LD      (NEWOBS2),A
        RET

RUN0223:
        LD      HL,C223MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        CALL    READTEST
        CALL    RESTDMA
        LD      A,(NEWOBS2)
        OR      A
        JP      NZ,NEWFAIL
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        CALL    CHECKONE128
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0224:
        LD      HL,C224MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    INITDEF
        LD      HL,ONEFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        CALL    READTEST
        CALL    RESTDMA
        LD      A,(NEWOBS2)
        OR      A
        JP      NZ,NEWFAIL
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        CALL    CHECKDEF
        JP      NZ,NEWFAIL
        CALL    CHECKONE128
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0226:
        LD      HL,C226MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,MULTIFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        JP      NZ,R226BAD
        LD      HL,DMABUF
        LD      DE,MMULTI0
        LD      B,9
        CALL    MEMEQ
        JP      NZ,R226BAD
        CALL    READTEST
        OR      A
        JP      NZ,R226BAD
        LD      HL,DMABUF
        LD      DE,MMULTI1
        LD      B,9
        CALL    MEMEQ
        JP      NZ,R226BAD
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        LD      A,(NEWOBS2)
        CP      2
        JP      NZ,NEWFAIL
        JP      NEWPASS
R226BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0227:
        LD      HL,C227MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,MULTIFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        LD      B,3
R227LP:
        PUSH    BC
        CALL    READTEST
        POP     BC
        OR      A
        JP      NZ,R227BAD
        LD      A,4
        SUB     B
        LD      C,A
        LD      A,(TESTFCB+32)
        CP      C
        JP      NZ,R227BAD
        DEC     B
        JP      NZ,R227LP
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS
R227BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0228:
        LD      HL,C228MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,BNDFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        LD      B,128
R228LP:
        PUSH    BC
        CALL    READTEST
        POP     BC
        OR      A
        JP      NZ,R228BAD
        DEC     B
        JP      NZ,R228LP
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        LD      A,(NEWOBS2)
        CP      128
        JP      NZ,NEWFAIL
        LD      HL,DMABUF
        LD      DE,MBOUND127
        LD      B,9
        CALL    MEMEQ
        JP      NZ,NEWFAIL
        JP      NEWPASS
R228BAD:
        CALL    RESTDMA
        JP      NEWFAIL

; Start BIG130 at CR=127 and read twice.  The fixture marks both records, so
; the test sees the extent crossing in data as well as in FCB state.
BIGCROSS:
        LD      HL,BIGFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,BIGFAIL
        LD      A,127
        LD      (TESTFCB+32),A
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        RET     NZ
        LD      HL,DMABUF
        LD      DE,MBIG127
        LD      B,7
        CALL    MEMEQ
        RET     NZ
        CALL    READTEST
        OR      A
        RET     NZ
        LD      HL,DMABUF
        LD      DE,MBIG128
        LD      B,7
        CALL    MEMEQ
        RET
BIGFAIL:
        LD      A,1
        OR      A
        RET

RUN0229:
        LD      HL,C229MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    BIGCROSS
        JP      NZ,R229BAD
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS
R229BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0230:
        LD      HL,C230MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    BIGCROSS
        JP      NZ,R230BAD
        LD      A,(TESTFCB+12)
        CP      1
        JP      NZ,R230BAD
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        CP      1
        JP      NZ,R230BAD
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS
R230BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0231:
        LD      HL,C231MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    BIGCROSS
        JP      NZ,R231BAD
        CALL    READTEST
        OR      A
        JP      NZ,R231BAD
        LD      HL,DMABUF
        LD      DE,MBIG129
        LD      B,7
        CALL    MEMEQ
        JP      NZ,R231BAD
        LD      A,(TESTFCB+12)
        CP      1
        JP      NZ,R231BAD
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        CP      2
        JP      NZ,R231BAD
        LD      A,(TESTFCB+15)
        CP      2
        JP      C,R231BAD
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS
R231BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0232:
        LD      HL,C232MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        JP      NZ,R232BAD
        CALL    READTEST
        LD      A,(NEWOBS2)
        OR      A
        JP      Z,R232BAD
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS
R232BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0234:
        LD      HL,C234MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,EMPTYFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        CALL    READTEST
        LD      A,(NEWOBS2)
        OR      A
        JP      Z,R234BAD
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS
R234BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0235:
        LD      HL,C235MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,PARTFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        JP      NZ,R235BAD
        CALL    READTEST
        OR      A
        JP      NZ,R235BAD
        CALL    READTEST
        LD      A,(NEWOBS2)
        OR      A
        JP      Z,R235BAD
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS
R235BAD:
        CALL    RESTDMA
        JP      NEWFAIL

; Read all 128 records of the boundary fixture.  DMA remains selected for the
; caller's final inspection; every caller must take a RESTDMA exit.
READBOUND:
        LD      HL,BNDFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,RBFAIL
        CALL    PREPDMA
        LD      B,128
RBDLP:  PUSH    BC
        CALL    READTEST
        POP     BC
        OR      A
        RET     NZ
        DEC     B
        JP      NZ,RBDLP
        XOR     A
        RET
RBFAIL: LD      A,1
        OR      A
        RET

RUN0236:
        LD      HL,C236MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    READBOUND
        JP      NZ,R236BAD
        CALL    READTEST
        LD      A,(NEWOBS2)
        OR      A
        JP      Z,R236BAD
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS
R236BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0237:
        LD      HL,C237MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,EMPTYFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        JP      Z,R237BAD
        CALL    READTEST
        LD      A,(NEWOBS2)
        OR      A
        JP      Z,R237BAD
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS
R237BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0239:
        LD      HL,C239MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,MULTIFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        LD      A,(TESTFCB+32)
        LD      (OLDCR),A
        CALL    PREPDMA
        LD      B,3
R239LP: PUSH    BC
        CALL    READTEST
        POP     BC
        OR      A
        JP      NZ,R239BAD
        DEC     B
        JP      NZ,R239LP
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        LD      B,A
        LD      A,(OLDCR)
        CP      B
        JP      Z,R239BAD
        LD      A,B
        CP      3
        JP      NZ,R239BAD
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS
R239BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0242:
        LD      HL,C242MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    CROSSREADY
        JP      NZ,NEWNOTRUN
        LD      C,25
        CALL    BDOS
        LD      (DRVBEFORE),A
        LD      HL,BFILEFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        JP      NZ,R242BAD
        LD      HL,DMABUF
        LD      DE,MBFILE
        LD      B,9
        CALL    MEMEQ
        JP      NZ,R242BAD
        LD      C,25
        CALL    BDOS
        LD      (NEWOBS2),A
        LD      B,A
        LD      A,(DRVBEFORE)
        CP      B
        JP      NZ,R242BAD
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS
R242BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0243:
        LD      HL,C243MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ROFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        JP      NZ,R243BAD
        LD      HL,DMABUF
        LD      DE,MRO
        LD      B,12
        CALL    MEMEQ
        JP      NZ,R243BAD
        CALL    RESTDMA
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS
R243BAD:
        CALL    RESTDMA
        JP      NEWFAIL

;----------------------- SCRATCH FILE OFFICE --------------------------
; First erase the reserved name, then Make it.  Every caller owes TEMPCLEAN
; before reporting, so a stopped or repeated selector begins from one state.
TEMPMAKE:
        LD      HL,TEMPFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        LD      HL,TEMPFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,22
        CALL    BDOS
        LD      (NEWOBS1),A
        RET

TEMPCLEAN:
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      HL,TEMPFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        JP      RESTDMA

MAKESIMPLE:
        CALL    TEMPMAKE
        CP      0FFH
        JP      Z,MSFAIL
        LD      A,(TESTFCB+32)
        LD      (NEWOBS2),A
        CALL    CHECKGUARDS
        JP      NZ,MSERROR
        CALL    TEMPCLEAN
        JP      NEWPASS
MSFAIL: CALL    TEMPCLEAN
        JP      NEWFAIL
MSERROR:
        CALL    TEMPCLEAN
        JP      NEWERROR

RUN0248:
        LD      HL,C248MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      MAKESIMPLE
RUN0249:
        LD      HL,C249MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      MAKESIMPLE
RUN0250:
        LD      HL,C250MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    TEMPMAKE
        CP      0FFH
        JP      Z,METFAIL
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      HL,TEMPFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,METFAIL
        CALL    PREPDMA
        CALL    READTEST
        LD      A,(NEWOBS2)
        OR      A
        JP      Z,METFAIL
        CALL    CHECKALLGUARDS
        JP      NZ,METERROR
        CALL    TEMPCLEAN
        JP      NEWPASS
METFAIL:
        CALL    TEMPCLEAN
        JP      NEWFAIL
METERROR:
        CALL    TEMPCLEAN
        JP      NEWERROR
RUN0251:
        LD      HL,C251MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      MAKESIMPLE
RUN0252:
        LD      HL,C252MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      MAKESIMPLE
RUN0254:
        LD      HL,C254MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    TEMPMAKE
        CP      0FFH
        JP      Z,MVFAIL
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      HL,TEMPFCB
        CALL    OPENHL
        LD      (NEWOBS2),A
        CP      0FFH
        JP      Z,MVFAIL
        CALL    CHECKGUARDS
        JP      NZ,MVERROR
        CALL    TEMPCLEAN
        JP      NEWPASS
MVFAIL: CALL    TEMPCLEAN
        JP      NEWFAIL
MVERROR:
        CALL    TEMPCLEAN
        JP      NEWERROR

; Make an active temporary FCB and write one complete current-DMA record.
WRITEONE:
        CALL    TEMPMAKE
        CP      0FFH
        RET     Z
        CALL    PREPDMA
        LD      HL,DMABUF
        LD      B,128
        LD      A,05AH
W1FILL: LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,W1FILL
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        LD      (NEWOBS2),A
        RET

WRITECASE:
        CALL    WRITEONE
        LD      A,(NEWOBS1)
        CP      0FFH
        JP      Z,WCFAIL
        LD      A,(NEWOBS2)
        OR      A
        JP      NZ,WCFAIL
        LD      A,(TESTFCB+32)
        CP      1
        JP      NZ,WCFAIL
        CALL    CHECKALLGUARDS
        JP      NZ,WCERROR
        CALL    TEMPCLEAN
        JP      NEWPASS
WCFAIL: CALL    TEMPCLEAN
        JP      NEWFAIL
WCERROR:
        CALL    TEMPCLEAN
        JP      NEWERROR

RUN0259:
        LD      HL,C259MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      WRITECASE
RUN0260:
        LD      HL,C260MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      WRITECASE
RUN0261:
        LD      HL,C261MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      WRITECASE

RUN0262:
        LD      HL,C262MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      WRITECASE
RUN0263:
        LD      HL,C263MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      VERIFYWRITE
RUN0264:
        LD      HL,C264MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      VERIFYWRITE
RUN0266:
        LD      HL,C266MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      WRITECASE
RUN0267:
        LD      HL,C267MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    WRITEONE
        LD      A,(NEWOBS1)
        CP      0FFH
        JP      Z,R267BAD
        LD      A,(NEWOBS2)
        OR      A
        JP      NZ,R267BAD
        LD      A,(TESTFCB+15)
        OR      A
        JP      Z,R267BAD
        CALL    TEMPCLEAN
        JP      NEWPASS
R267BAD:
        CALL    TEMPCLEAN
        JP      NEWFAIL

; Close, reopen and read the full 5AH record written by WRITEONE.  Reopening
; prevents the old DMA buffer from masquerading as persistent data.
VERIFYWRITE:
        CALL    WRITEONE
        LD      A,(NEWOBS1)
        CP      0FFH
        JP      Z,VWBAD
        LD      A,(NEWOBS2)
        OR      A
        JP      NZ,VWBAD
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      HL,TEMPFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,VWBAD
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        JP      NZ,VWBAD
        LD      HL,DMABUF
        LD      B,128
VWLP:   LD      A,(HL)
        CP      05AH
        JP      NZ,VWBAD
        INC     HL
        DEC     B
        JP      NZ,VWLP
        CALL    CHECKALLGUARDS
        JP      NZ,VWERR
        CALL    TEMPCLEAN
        JP      NEWPASS
VWBAD:  CALL    TEMPCLEAN
        JP      NEWFAIL
VWERR:  CALL    TEMPCLEAN
        JP      NEWERROR

RUN0268:
        LD      HL,C268MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    WRITEONE
        LD      A,(NEWOBS2)
        OR      A
        JP      NZ,R268BAD
        XOR     A
        LD      (TESTFCB+32),A
        LD      HL,DMABUF
        LD      B,128
        LD      A,0A5H
R268FL: LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,R268FL
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        LD      (NEWOBS2),A
        OR      A
        JP      NZ,R268BAD
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      HL,TEMPFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,R268BAD
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        JP      NZ,R268BAD
        LD      HL,DMABUF
        LD      B,128
R268CK: LD      A,(HL)
        CP      0A5H
        JP      NZ,R268BAD
        INC     HL
        DEC     B
        JP      NZ,R268CK
        CALL    TEMPCLEAN
        JP      NEWPASS
R268BAD:
        CALL    TEMPCLEAN
        JP      NEWFAIL

RUN0269:
        LD      HL,C269MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      VERIFYWRITE

; Write 129 marked records.  The last write cannot succeed unless sequential
; output carries itself from extent zero into extent one.
WRITE129:
        CALL    TEMPMAKE
        CP      0FFH
        RET     Z
        CALL    PREPDMA
        LD      HL,DMABUF
        LD      B,128
        LD      A,05AH
W129F:  LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,W129F
        LD      B,128
W129L:  PUSH    BC
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        POP     BC
        OR      A
        RET     NZ
        DEC     B
        JP      NZ,W129L
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        LD      (NEWOBS2),A
        RET

BOUNDWRITE:
        CALL    WRITE129
        LD      A,(NEWOBS1)
        CP      0FFH
        JP      Z,BWBAD
        LD      A,(NEWOBS2)
        OR      A
        JP      NZ,BWBAD
        LD      A,(TESTFCB+12)
        CP      1
        JP      NZ,BWBAD
        LD      A,(TESTFCB+32)
        CP      1
        JP      NZ,BWBAD
        CALL    CHECKALLGUARDS
        JP      NZ,BWERR
        CALL    TEMPCLEAN
        JP      NEWPASS
BWBAD:  CALL    TEMPCLEAN
        JP      NEWFAIL
BWERR:  CALL    TEMPCLEAN
        JP      NEWERROR

RUN0271:
        LD      HL,C271MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      BOUNDWRITE
RUN0272:
        LD      HL,C272MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      BOUNDWRITE
RUN0273:
        LD      HL,C273MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      BOUNDWRITE

RUN0274:
        LD      HL,C274MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    TEMPMAKE
        CP      0FFH
        JP      Z,R274BAD
        LD      A,15
        LD      (TESTFCB+14),A
        LD      A,31
        LD      (TESTFCB+12),A
        LD      A,128
        LD      (TESTFCB+32),A
        CALL    PREPDMA
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        LD      (NEWOBS2),A
        OR      A
        JP      Z,R274BAD
        CALL    TEMPCLEAN
        JP      NEWPASS
R274BAD:
        CALL    TEMPCLEAN
        JP      NEWFAIL

RUN0278:
        LD      HL,C278MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      C,25
        CALL    BDOS
        LD      (DRVBEFORE),A
        LD      HL,CTEMPFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        LD      HL,CTEMPFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,22
        CALL    BDOS
        LD      (NEWOBS1),A
        CP      0FFH
        JP      Z,R278BAD
        CALL    PREPDMA
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        LD      (NEWOBS2),A
        OR      A
        JP      NZ,R278BAD
        LD      C,25
        CALL    BDOS
        LD      B,A
        LD      A,(DRVBEFORE)
        CP      B
        JP      NZ,R278BAD
        CALL    CTEMPCLEAN
        JP      NEWPASS
R278BAD:
        CALL    CTEMPCLEAN
        JP      NEWFAIL

CTEMPCLEAN:
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      HL,CTEMPFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        JP      RESTDMA

RUN0279:
        LD      HL,C279MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      VERIFYWRITE

;------------------------ RANDOM I/O CARDS ----------------------------
; Open BIG130 and select the guarded alternate DMA.
RANDOPEN:
        LD      HL,BIGFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,ROFAIL
        CALL    PREPDMA
        XOR     A
        RET
ROFAIL: LD      A,1
        OR      A
        RET

RANDREAD:
        LD      DE,TESTFCB
        LD      C,33
        CALL    BDOS
        LD      (NEWOBS2),A
        RET

RUN0317:
        LD      HL,C317MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RANDOPEN
        JP      NZ,R317BAD
        LD      A,1
        LD      (TESTFCB+33),A
        XOR     A
        LD      (TESTFCB+34),A
        LD      (TESTFCB+35),A
        CALL    RANDREAD
        OR      A
        JP      NZ,R317BAD
        LD      HL,DMABUF
        LD      DE,MBIG001
        LD      B,7
        CALL    MEMEQ
        JP      NZ,R317BAD
        CALL    RESTDMA
        JP      NEWPASS
R317BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0318:
        LD      HL,C318MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RANDOPEN
        JP      NZ,R318BAD
        LD      A,128
        LD      (TESTFCB+33),A
        XOR     A
        LD      (TESTFCB+34),A
        LD      (TESTFCB+35),A
        CALL    RANDREAD
        OR      A
        JP      NZ,R318BAD
        LD      HL,DMABUF
        LD      DE,MBIG128
        LD      B,7
        CALL    MEMEQ
        JP      NZ,R318BAD
        CALL    RESTDMA
        JP      NEWPASS
R318BAD:
        CALL    RESTDMA
        JP      NEWFAIL

; Function 36 maps EX/S2/CR into little-endian R0/R1/R2.  Cards set awkward
; boundary values so byte-order or carry mistakes cannot hide at record zero.
SETF36:
        LD      DE,TESTFCB
        LD      C,36
        CALL    BDOS
        RET

RUN0319:
        LD      HL,C319MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,BIGFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        LD      A,31
        LD      (TESTFCB+12),A
        LD      A,15
        LD      (TESTFCB+14),A
        LD      A,127
        LD      (TESTFCB+32),A
        CALL    SETF36
        LD      A,(TESTFCB+33)
        CP      0FFH
        JP      NZ,NEWFAIL
        LD      A,(TESTFCB+34)
        CP      0FFH
        JP      NZ,NEWFAIL
        LD      A,(TESTFCB+35)
        OR      A
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0320:
        LD      HL,C320MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RANDOPEN
        JP      NZ,R320BAD
        LD      A,7
        LD      (TESTFCB+32),A
        LD      A,1
        LD      (TESTFCB+33),A
        XOR     A
        LD      (TESTFCB+34),A
        LD      (TESTFCB+35),A
        CALL    RANDREAD
        OR      A
        JP      NZ,R320BAD
        LD      HL,DMABUF
        LD      DE,MBIG001
        LD      B,7
        CALL    MEMEQ
        JP      NZ,R320BAD
        LD      A,(TESTFCB+33)
        CP      1
        JP      NZ,R320BAD
        CALL    RESTDMA
        JP      NEWPASS
R320BAD:
        CALL    RESTDMA
        JP      NEWFAIL

RUN0321:
        LD      HL,C321MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,BIGFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        LD      A,3
        LD      (TESTFCB+32),A
        CALL    SETF36
        LD      A,(TESTFCB+33)
        CP      3
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0322:
        LD      HL,C322MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,BIGFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        LD      A,1
        LD      (TESTFCB+12),A
        LD      (TESTFCB+32),A
        CALL    SETF36
        LD      A,(TESTFCB+33)
        CP      129
        JP      NZ,NEWFAIL
        LD      A,(TESTFCB+34)
        OR      A
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0323:
        LD      HL,C323MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,BIGFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        LD      A,1
        LD      (TESTFCB+12),A
        XOR     A
        LD      (TESTFCB+32),A
        CALL    SETF36
        LD      A,(TESTFCB+33)
        CP      128
        JP      NZ,NEWFAIL
        LD      A,(TESTFCB+34)
        OR      A
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0324:
        LD      HL,C324MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,MISSFCB
        CALL    INITFCB
        LD      A,1
        LD      (TESTFCB+12),A
        LD      A,2
        LD      (TESTFCB+32),A
        CALL    SETF36
        LD      A,(TESTFCB+33)
        CP      130
        JP      NZ,NEWFAIL
        CALL    CHECKGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS

; Common good random read.  CR says 7 while R says 1; using the sequential
; byte by mistake therefore fetches a visibly different marked record.
RANDONE:
        CALL    RANDOPEN
        RET     NZ
        LD      A,7
        LD      (TESTFCB+32),A
        LD      A,1
        LD      (TESTFCB+33),A
        XOR     A
        LD      (TESTFCB+34),A
        LD      (TESTFCB+35),A
        CALL    RANDREAD
        OR      A
        RET     NZ
        LD      HL,DMABUF
        LD      DE,MBIG001
        LD      B,7
        JP      MEMEQ

RANDONECASE:
        CALL    RANDONE
        JP      NZ,ROCFAIL
        CALL    CHECKALLGUARDS
        JP      NZ,ROCERR
        CALL    RESTDMA
        JP      NEWPASS
ROCFAIL:
        CALL    RESTDMA
        JP      NEWFAIL
ROCERR: CALL    RESTDMA
        JP      NEWERROR

RUN0326:
        LD      HL,C326MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      RANDONECASE
RUN0327:
        LD      HL,C327MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      RANDONECASE
RUN0328:
        LD      HL,C328MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      RANDONECASE
RUN0329:
        LD      HL,C329MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      RANDONECASE

RUN0330:
        LD      HL,C330MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RANDONE
        JP      NZ,R330BAD
        CALL    PREPDMA
        CALL    RANDREAD
        OR      A
        JP      NZ,R330BAD
        LD      HL,DMABUF
        LD      DE,MBIG001
        LD      B,7
        CALL    MEMEQ
        JP      NZ,R330BAD
        CALL    RESTDMA
        JP      NEWPASS
R330BAD:
        CALL    RESTDMA
        JP      NEWFAIL

; Ask beyond the fixture and require a defined nonzero refusal.  Residue is
; checked only by the separate observation card, never by this oracle.
RANDBADCASE:
        CALL    RANDREAD
        LD      A,(NEWOBS2)
        OR      A
        JP      Z,RBCFAIL
        CALL    CHECKALLGUARDS
        JP      NZ,RBCERR
        CALL    RESTDMA
        JP      NEWPASS
RBCFAIL:
        CALL    RESTDMA
        JP      NEWFAIL
RBCERR: CALL    RESTDMA
        JP      NEWERROR

RUN0331:
        LD      HL,C331MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RANDOPEN
        JP      NZ,NEWFAIL
        LD      A,130
        LD      (TESTFCB+33),A
        XOR     A
        LD      (TESTFCB+34),A
        LD      (TESTFCB+35),A
        JP      RANDBADCASE

RUN0332:
        LD      HL,C332MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RANDOPEN
        JP      NZ,NEWFAIL
        XOR     A
        LD      (TESTFCB+33),A
        LD      A,1
        LD      (TESTFCB+34),A
        XOR     A
        LD      (TESTFCB+35),A
        JP      RANDBADCASE

RUN0333:
        LD      HL,C333MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RANDOPEN
        JP      NZ,NEWFAIL
        XOR     A
        LD      (TESTFCB+33),A
        LD      (TESTFCB+34),A
        LD      A,1
        LD      (TESTFCB+35),A
        JP      RANDBADCASE

RUN0335:
        LD      HL,C335MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    TEMPMAKE
        CP      0FFH
        JP      Z,R335BAD
        CALL    PREPDMA
        LD      HL,DMABUF
        LD      B,128
        LD      A,05AH
R335FL: LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,R335FL
        XOR     A
        LD      (TESTFCB+33),A
        LD      (TESTFCB+34),A
        LD      (TESTFCB+35),A
        LD      DE,TESTFCB
        LD      C,34
        CALL    BDOS
        LD      (NEWOBS2),A
        OR      A
        JP      NZ,R335BAD
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      HL,TEMPFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,R335BAD
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        JP      NZ,R335BAD
        LD      HL,DMABUF
        LD      B,128
R335CK: LD      A,(HL)
        CP      05AH
        JP      NZ,R335BAD
        INC     HL
        DEC     B
        JP      NZ,R335CK
        CALL    TEMPCLEAN
        JP      NEWPASS
R335BAD:
        CALL    TEMPCLEAN
        JP      NEWFAIL

; Prepare a new temporary file and fill the complete DMA record with A5H.
RWPREP:
        CALL    TEMPMAKE
        CP      0FFH
        RET     Z
        CALL    PREPDMA
        LD      HL,DMABUF
        LD      B,128
        LD      A,0A5H
RWFILL: LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,RWFILL
        XOR     A
        RET

; Random-write record A, with upper R bytes cleared.  Return the call result.
RWWRITE:
        LD      (TESTFCB+33),A
        XOR     A
        LD      (TESTFCB+34),A
        LD      (TESTFCB+35),A
        LD      DE,TESTFCB
        LD      C,34
        CALL    BDOS
        LD      (NEWOBS2),A
        RET

; Close, reopen, random-read record A and verify all 128 A5H bytes.  This is
; the persistence oracle used by the random-write cards.
RWVERIFY:
        PUSH    AF
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      HL,TEMPFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,RWVFAIL
        POP     AF
        LD      (TESTFCB+33),A
        XOR     A
        LD      (TESTFCB+34),A
        LD      (TESTFCB+35),A
        CALL    PREPDMA
        CALL    RANDREAD
        OR      A
        RET     NZ
        LD      HL,DMABUF
        LD      B,128
RWVLP:  LD      A,(HL)
        CP      0A5H
        RET     NZ
        INC     HL
        DEC     B
        JP      NZ,RWVLP
        XOR     A
        RET
RWVFAIL:
        POP     AF
        LD      A,1
        OR      A
        RET

RWGOOD0:
        CALL    RWPREP
        RET     NZ
        XOR     A
        CALL    RWWRITE
        RET

RUN0336:
        LD      HL,C336MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RWGOOD0
        JP      NZ,RWFAIL
        XOR     A
        CALL    RWVERIFY
        JP      RWRESULT
RUN0337:
        LD      HL,C337MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RWGOOD0
        JP      RWRESULT
RUN0338:
        LD      HL,C338MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RWGOOD0
        JP      NZ,RWFAIL
        LD      A,(TESTFCB+15)
        OR      A
        JP      Z,RWFAIL
        XOR     A
        JP      RWDONE
RUN0339:
        LD      HL,C339MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RWPREP
        JP      NZ,RWFAIL
        LD      A,2
        CALL    RWWRITE
        JP      NZ,RWFAIL
        LD      A,2
        JP      RWDONE
RUN0340:
        LD      HL,C340MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RWPREP
        JP      NZ,RWFAIL
        LD      A,2
        CALL    RWWRITE
        JP      NZ,RWFAIL
        LD      A,(TESTFCB+15)
        CP      3
        JP      C,RWFAIL
        JP      RWPASS
RUN0341:
        LD      HL,C341MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RWPREP
        JP      NZ,RWFAIL
        LD      A,2
        CALL    RWWRITE
        JP      NZ,RWFAIL
        LD      A,(TESTFCB+12)
        OR      A
        JP      NZ,RWFAIL
        LD      A,(TESTFCB+15)
        CP      3
        JP      C,RWFAIL
        JP      RWPASS
RUN0342:
        LD      HL,C342MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RWPREP
        JP      NZ,RWFAIL
        LD      A,2
        CALL    RWWRITE
        JP      NZ,RWFAIL
        LD      A,(TESTFCB+33)
        CP      2
        JP      NZ,RWFAIL
        LD      A,(TESTFCB+34)
        OR      A
        JP      NZ,RWFAIL
        JP      RWPASS
RUN0343:
        LD      HL,C343MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RWPREP
        JP      NZ,RWFAIL
        LD      A,127
        CALL    RWWRITE
        JP      NZ,RWFAIL
        LD      A,(TESTFCB+33)
        CP      127
        JP      NZ,RWFAIL
        LD      A,(TESTFCB+12)
        OR      A
        JP      NZ,RWFAIL
        JP      RWPASS
RUN0344:
        LD      HL,C344MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RWGOOD0
        JP      NZ,RWFAIL
        XOR     A
RWDONE:
        CALL    RWVERIFY
RWRESULT:
        OR      A
        JP      NZ,RWFAIL
RWPASS: CALL    CHECKALLGUARDS
        JP      NZ,RWERROR
        CALL    TEMPCLEAN
        JP      NEWPASS
RWFAIL: CALL    TEMPCLEAN
        JP      NEWFAIL
RWERROR:
        CALL    TEMPCLEAN
        JP      NEWERROR
RUN0345:
        LD      HL,C345MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RWPREP
        JP      NZ,RWFAIL
        XOR     A
        LD      (TESTFCB+33),A
        LD      (TESTFCB+34),A
        LD      A,1
        LD      (TESTFCB+35),A
        LD      DE,TESTFCB
        LD      C,34
        CALL    BDOS
        LD      (NEWOBS2),A
        OR      A
        JP      Z,RWFAIL
        JP      RWPASS

; Function 35 office.  F35OPEN obtains the size; F35EXPECT compares the three
; returned random-record bytes with DE and a zero high byte.
F35OPEN:
        CALL    OPENHL
        CP      0FFH
        RET     Z
        LD      DE,TESTFCB
        LD      C,35
        CALL    BDOS
        XOR     A
        RET

F35EXPECT:
        LD      A,(TESTFCB+33)
        CP      E
        RET     NZ
        LD      A,(TESTFCB+34)
        CP      D
        RET     NZ
        LD      A,(TESTFCB+35)
        OR      A
        RET

RUN0346:
        LD      HL,C346MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RWPREP
        JP      NZ,RWFAIL
        XOR     A
        LD      (TESTFCB+33),A
        LD      (TESTFCB+34),A
R346LP:LD      DE,TESTFCB
        LD      C,34
        CALL    BDOS
        OR      A
        JP      NZ,R346END
        LD      HL,TESTFCB+33
        INC     (HL)
        JP      NZ,R346LP
        INC     HL
        INC     (HL)
        JP      R346LP
R346END:
        LD      (NEWOBS2),A
        CP      2
        JP      Z,RWPASS
        JP      RWFAIL

RUN0347:
        LD      HL,C347MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    F35OPEN
        JP      NZ,NEWFAIL
        LD      DE,1
        CALL    F35EXPECT
        JP      Z,NEWPASS
        JP      NEWFAIL
RUN0348:
        LD      HL,C348MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    F35OPEN
        JP      NZ,NEWFAIL
        LD      DE,1
        CALL    F35EXPECT
        JP      Z,NEWPASS
        JP      NEWFAIL
RUN0349:
        LD      HL,C349MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ONEFCB
        CALL    F35OPEN
        JP      NZ,NEWFAIL
        LD      DE,1
        CALL    F35EXPECT
        JP      Z,NEWPASS
        JP      NEWFAIL
RUN0350:
        LD      HL,C350MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,BIGFCB
        CALL    F35OPEN
        JP      NZ,NEWFAIL
        LD      DE,130
        CALL    F35EXPECT
        JP      Z,NEWPASS
        JP      NEWFAIL
RUN0351:
        LD      HL,C351MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    RWPREP
        JP      NZ,RWFAIL
        LD      A,2
        CALL    RWWRITE
        JP      NZ,RWFAIL
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      HL,TEMPFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,RWFAIL
        LD      DE,TESTFCB
        LD      C,35
        CALL    BDOS
        LD      DE,3
        CALL    F35EXPECT
        JP      Z,RWPASS
        JP      RWFAIL

;---------------------- TERMINAL OUTCOME CARDS ------------------------
; The read-only write path is terminal on the declared profile.  The outside
; harness owns the verdict after the call; reaching NEWFAIL means it returned.
RUN0368:
        LD      HL,C368MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ROFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        JP      NEWFAIL       ; a normal return is nonconforming for this profile
RUN0369:
        LD      HL,C369MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,ROFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        CALL    PREPDMA
        XOR     A
        LD      (TESTFCB+33),A
        LD      (TESTFCB+34),A
        LD      (TESTFCB+35),A
        LD      DE,TESTFCB
        LD      C,34
        CALL    BDOS
        JP      NEWFAIL       ; a normal return is nonconforming for this profile

RUN0550:
        LD      HL,C550MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,QFCB
        CALL    INITFCB
        CALL    PREPDMA
        LD      DE,TESTFCB
        LD      C,17
        CALL    BDOS
        LD      (NEWOBS2),A
        CP      4
        JP      NC,NEWFAIL
        CALL    CHECKALLGUARDS
        JP      NZ,NEWERROR
        JP      NEWPASS
RUN0551:
        LD      HL,C551MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    TEMPMAKE
        CP      0FFH
        JP      Z,RWFAIL
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        CP      0FFH
        JP      Z,RWFAIL
        LD      HL,TEMPFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,RWFAIL
        CALL    CHECKGUARDS
        JP      NZ,RWERROR
        CALL    TEMPCLEAN
        JP      NEWPASS

RUN0253:
        LD      HL,C253MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,DTEMPFCB
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,22
        CALL    BDOS
        LD      (NEWOBS2),A
        CP      0FFH
        JP      NZ,NEWFAIL
        JP      NEWPASS

RUN0553:
        LD      HL,C553MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        JP      VERIFYWRITE

; Read the three marked records 127, 128 and 129 in order.  The marks prove
; that the apparent extent crossing did not merely repeat record 127.
RUN0555:
        LD      HL,C555MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        LD      HL,BIGFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,NEWFAIL
        XOR     A
        LD      (TESTFCB+12),A
        LD      A,127
        LD      (TESTFCB+32),A
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        JP      NZ,R555BAD
        LD      HL,DMABUF
        LD      DE,MBIG127
        LD      B,7
        CALL    MEMEQ
        JP      NZ,R555BAD
        CALL    READTEST
        OR      A
        JP      NZ,R555BAD
        LD      HL,DMABUF
        LD      DE,MBIG128
        LD      B,7
        CALL    MEMEQ
        JP      NZ,R555BAD
        CALL    READTEST
        OR      A
        JP      NZ,R555BAD
        LD      HL,DMABUF
        LD      DE,MBIG129
        LD      B,7
        CALL    MEMEQ
        JP      NZ,R555BAD
        CALL    RESTDMA
        JP      NEWPASS
R555BAD: CALL    RESTDMA
        JP      NEWFAIL

; D: has a full directory and a complete 128-record BTFULL.DAT.  Attempt to
; grow it at record 128, then ask Function 35 whether its old size survived.
FULLFAIL:
        LD      HL,FULLFCB
        CALL    OPENHL
        CP      0FFH
        RET     Z
        CALL    PREPDMA
        LD      A,128
        LD      (TESTFCB+33),A
        XOR     A
        LD      (TESTFCB+34),A
        LD      (TESTFCB+35),A
        LD      DE,TESTFCB
        LD      C,34
        CALL    BDOS
        LD      (NEWOBS2),A
        OR      A
        RET     Z
        LD      DE,TESTFCB
        LD      C,35
        CALL    BDOS
        LD      A,(TESTFCB+33)
        CP      128
        RET     NZ
        LD      A,(TESTFCB+34)
        OR      A
        RET     NZ
        LD      A,(TESTFCB+35)
        OR      A
        RET

RUN0556:
        LD      HL,C556MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    FULLFAIL
        JP      NZ,R556BAD
        LD      HL,FULLFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,R556BAD
        CALL    PREPDMA
        LD      A,127
        LD      (TESTFCB+33),A
        XOR     A
        LD      (TESTFCB+34),A
        LD      (TESTFCB+35),A
        CALL    RANDREAD
        OR      A
        JP      NZ,R556BAD
        LD      HL,DMABUF
        LD      DE,MFULL127
        LD      B,8
        CALL    MEMEQ
        JP      NZ,R556BAD
        CALL    RESTDMA
        JP      NEWPASS
R556BAD: CALL    RESTDMA
        JP      NEWFAIL

RUN0557:
        LD      HL,C557MSG
        LD      (CASEPTR),HL
        CALL    INDHEAD
        CALL    FULLFAIL
        JP      NZ,R557BAD
        CALL    RESTDMA
        JP      NEWPASS
R557BAD: CALL    RESTDMA
        JP      NEWFAIL

INITDEF:
        LD      HL,0080H
        LD      B,128
        LD      A,06DH
IDFLP:  LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,IDFLP
        RET

CHECKDEF:
        LD      HL,0080H
        LD      B,128
        LD      C,06DH
CDFLP:  LD      A,(HL)
        CP      C
        RET     NZ
        INC     HL
        DEC     B
        JP      NZ,CDFLP
        XOR     A
        RET

; Fixture records are ASCII; an E7H therefore proves that the prefill survived
; and that the complete record did not arrive.
CHECKFULLDMA:
        LD      HL,DMABUF
        LD      B,128
CFDLP:  LD      A,(HL)
        CP      0E7H
        RET     Z
        INC     HL
        DEC     B
        JP      NZ,CFDLP
        XOR     A
        RET

CHECKONE128:
        LD      HL,DMABUF
        LD      C,16
CO1LP:  PUSH    BC
        LD      DE,MONE8
        LD      B,8
        CALL    MEMEQ
        POP     BC
        RET     NZ
        DEC     C
        JP      NZ,CO1LP
        XOR     A
        RET

; Verify the explicit C: fixture before judging a cross-drive card.  An absent
; or incorrectly marked provider fixture is a setup condition, not a failed
; CP/M compatibility assertion.
CROSSREADY:
        LD      HL,BFILEFCB
        CALL    OPENHL
        CP      0FFH
        JP      Z,CROSSNO
        CALL    PREPDMA
        CALL    READTEST
        OR      A
        JP      NZ,CROSSBAD
        LD      HL,DMABUF
        LD      DE,MBFILE
        LD      B,9
        CALL    MEMEQ
        JP      NZ,CROSSBAD
        CALL    RESTDMA
        XOR     A
        RET
CROSSBAD:
        CALL    RESTDMA
CROSSNO:
        LD      A,1
        OR      A
        RET

INDHEAD:
        LD      A,(AGGMODE)
        OR      A
        RET     NZ
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPACTHEAD
        LD      DE,HNEW1
        CALL    PUTS
        LD      HL,ARGBUF
        CALL    PUTZ
        LD      DE,HNEW2
        JP      PUTS

;------------------------- GUARDED DMA --------------------------------
; Put unlike tell-tales before and after DMABUF, fill the record with E7H,
; and select it.  RESTDMA is intentionally tiny so all unwind paths can use it.
PREPDMA:
        LD      HL,DPRE
        LD      B,16
        LD      A,0C3H
PDI1:   LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,PDI1
        LD      HL,DMABUF
        LD      B,128
        LD      A,0E7H
PDI2:   LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,PDI2
        LD      HL,DPOST
        LD      B,16
        LD      A,03CH
PDI3:   LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,PDI3
        LD      DE,DMABUF
        LD      C,26
        JP      BDOS

RESTDMA:
        LD      DE,0080H
        LD      C,26
        JP      BDOS

; A changed tell-tale is ERROR, not an ordinary failed card.  BDOS has written
; outside the object offered to it, so both the evidence and this transient
; may already be spoiled.
CHECKALLGUARDS:
        CALL    CHECKGUARDS
        RET     NZ
        LD      HL,DPRE
        LD      B,16
        LD      C,0C3H
CAG1:   LD      A,(HL)
        CP      C
        RET     NZ
        INC     HL
        DEC     B
        JP      NZ,CAG1
        LD      HL,DPOST
        LD      B,16
        LD      C,03CH
CAG2:   LD      A,(HL)
        CP      C
        RET     NZ
        INC     HL
        DEC     B
        JP      NZ,CAG2
        XOR     A
        RET

; Compare B bytes at HL and DE.  Exit Z on a complete match.
MEMEQ:
        LD      A,(DE)
        CP      (HL)
        RET     NZ
        INC     DE
        INC     HL
        DEC     B
        JP      NZ,MEMEQ
        XOR     A
        RET

;------------------------- REPORT OFFICE ------------------------------
; CASEPTR names both the long evidence card and the ledger digits used by the
; short row.  NEWOBS1/2 are raw bytes; presentation never changes the oracle.
PUTNEWCASE:
        LD      HL,(CASEPTR)
        PUSH    HL
        POP     DE
        JP      PUTS

PUTNEWOBS:
        LD      DE,NOBS1
        CALL    PUTS
        LD      A,(NEWOBS1)
        CALL    HEXBYTE
        LD      DE,NOBS2
        CALL    PUTS
        LD      A,(NEWOBS2)
        CALL    HEXBYTE
        LD      E,13
        CALL    PUTC
        LD      E,10
        JP      PUTC

PUTDOBS:
        LD      DE,DOBS1
        CALL    PUTS
        LD      A,(NEWOBS1)
        CALL    HEXBYTE
        LD      DE,DOBS2
        CALL    PUTS
        LD      A,(NEWOBS2)
        CALL    HEXBYTE
        LD      E,13
        CALL    PUTC
        LD      E,10
        JP      PUTC

NEWPASS:
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPPASS
        CALL    PUTNEWCASE
        LD      DE,MSG_PASS
        CALL    PUTS
        CALL    PUTNEWOBS
        LD      DE,NEVID
        CALL    PUTS
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,NEWAPASS
        LD      DE,MENDP
        CALL    PUTS
        JP      0000H
NEWAPASS:
        LD      HL,PASSCT
        INC     (HL)
        LD      DE,ENDONLY
        JP      PUTS

NEWFAIL:
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPFAIL
        CALL    PUTNEWCASE
        LD      DE,MSG_FAIL
        CALL    PUTS
        CALL    PUTNEWOBS
        LD      DE,MC006
        CALL    PUTS
        LD      DE,NEVID
        CALL    PUTS
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,NEWAFAIL
        LD      DE,MENDF
        CALL    PUTS
        JP      0000H
NEWAFAIL:
        LD      HL,FAILCT
        INC     (HL)
        LD      DE,ENDONLY
        JP      PUTS

NEWERROR:
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPERR
        CALL    PUTNEWCASE
        LD      DE,MSG_ERROR
        CALL    PUTS
        CALL    PUTNEWOBS
        LD      DE,ME005
        CALL    PUTS
        LD      DE,NEVID
        CALL    PUTS
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,NEWAERR
        LD      DE,MENDE
        CALL    PUTS
        JP      0000H
NEWAERR:
        LD      HL,ERRCT
        INC     (HL)
        LD      DE,ENDONLY
        JP      PUTS

NEWNOTRUN:
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPNOTRUN
        CALL    PUTNEWCASE
        LD      DE,MSG_NOTRUN
        CALL    PUTS
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,NEWANOTRUN
        LD      DE,MENDNOTRUN
        CALL    PUTS
        JP      0000H
NEWANOTRUN:
        LD      HL,NOTRUNCT
        INC     (HL)
        LD      DE,ENDONLY
        JP      PUTS

COMPACTHEAD:
        LD      DE,CTITLE
        JP      PUTS

; Find the four ledger digits after the first LF in the long card.  The card's
; opening layout is consequently part of the program; change PUTCID whenever
; that layout is changed.
PUTCID:
        LD      HL,(CASEPTR)
PCID1: LD      A,(HL)
        INC     HL
        CP      10
        JP      NZ,PCID1
        LD      DE,7
        ADD     HL,DE
        LD      B,4
PCID2: LD      E,(HL)
        PUSH    HL
        PUSH    BC
        CALL    PUTC
        POP     BC
        POP     HL
        INC     HL
        DEC     B
        JP      NZ,PCID2
        RET

; DE names the padded result word.  The short row gives useful byte labels;
; the complete requirement remains in the ledger and /REPORT card.
COMPROW:
        PUSH    DE
        CALL    PUTCID
        LD      DE,CSEP
        CALL    PUTS
        POP     DE
        CALL    PUTS
        CALL    PUTDISP
        CALL    PUTSEMOBS
        LD      E,13
        CALL    PUTC
        LD      E,10
        JP      PUTC

; Class comes from the card, not from its runtime result.  NOT GUARANTEED
; cards print as observations even when their calls return quite normally.
PUTDISP:
        LD      A,(ROWSTATUS)
        CP      3
        LD      DE,CDREQ
        JP      NZ,PUTS
        LD      DE,CDNOTG
        JP      PUTS

; Exit Z when CASEPTR names the card at DE.
CASEIS:
        LD      HL,(CASEPTR)
        LD      A,L
        CP      E
        RET     NZ
        LD      A,H
        CP      D
        RET

; Pick labels suitable for Open, Read, Write, Random or life-cycle evidence.
; Ledger digits select wording only; no test result or class is decided here.
PUTSEMOBS:
        LD      DE,C165MSG
        CALL    CASEIS
        JP      Z,PSO165
        LD      DE,C167MSG
        CALL    CASEIS
        JP      Z,PSO167
        LD      DE,C169MSG
        CALL    CASEIS
        JP      Z,PSO169
        LD      DE,MSG_CASE_BEGIN
        CALL    CASEIS
        JP      Z,PSO171
        ; Locate the ledger digits following the first LF in CASEPTR.
        LD      HL,(CASEPTR)
PSOFIND:LD      A,(HL)
        INC     HL
        CP      10
        JP      NZ,PSOFIND
        LD      DE,7
        ADD     HL,DE
        LD      A,(HL)
        CP      '0'
        JP      NZ,PSOGEN
        INC     HL
        LD      A,(HL)
        CP      '1'
        JP      Z,PSOOPEN
        CP      '2'
        JP      Z,PSO2XX
        CP      '3'
        JP      Z,PSORAND
        CP      '5'
        JP      Z,PSOLIFE
PSOGEN:LD      DE,CSFVALUE
        LD      HL,CS2VALUE
        JP      PSOSET
PSO2XX:INC     HL
        LD      A,(HL)
        CP      '4'
        JP      C,PSOREAD
        JP      NZ,PSOWRITE
        INC     HL
        LD      A,(HL)
        CP      '6'
        JP      C,PSOREAD
PSOWRITE:
        LD      DE,CSFWRITE
        LD      HL,CS2WRITE
        JP      PSOSET
PSOOPEN:
        LD      DE,CSFOPEN
        LD      HL,CS2OPEN
        JP      PSOSET
PSOREAD:
        LD      DE,CSFREAD
        LD      HL,CS2READ
        JP      PSOSET
PSORAND:
        LD      DE,CSFRANDOM
        LD      HL,CS2RANDOM
        JP      PSOSET
PSOLIFE:
        LD      DE,CSFLIFE
        LD      HL,CS2LIFE
PSOSET: LD      (OBSSEPPTR),HL
PSOTWO:CALL    PUTS
        LD      A,(NEWOBS1)
        CALL    HEXBYTE
        LD      HL,(OBSSEPPTR)
        PUSH    HL
        POP     DE
        CALL    PUTS
        LD      A,(NEWOBS2)
        JP      HEXBYTE

PSO165:LD      DE,CF165A
        CALL    PUTS
        LD      A,(O165RET)
        CALL    HEXBYTE
        LD      DE,CF165B
        CALL    PUTS
        LD      A,(O165RC)
        JP      HEXBYTE
PSO167:LD      DE,CF167A
        LD      A,(ROWSTATUS)
        OR      A
        JP      NZ,PSO167F
        CALL    PUTS
        LD      A,(NEWOBS2)
        JP      HEXBYTE
PSO167F:
        LD      DE,CF167F
        CALL    PUTS
        LD      A,(NEWOBS1)
        CALL    HEXBYTE
        LD      DE,CF167G
        CALL    PUTS
        LD      A,(NEWOBS2)
        JP      HEXBYTE
PSO169:LD      DE,CF169A
        CALL    PUTS
        LD      A,(OBS169A)
        CALL    HEXBYTE
        LD      DE,CF169B
        CALL    PUTS
        LD      A,(OBS169B)
        CALL    HEXBYTE
        LD      DE,CF169C
        CALL    PUTS
        LD      A,(DRVBEFORE)
        ADD     A,'A'
        LD      E,A
        CALL    PUTC
        LD      DE,CF169D
        CALL    PUTS
        LD      A,(DRVAFTER)
        ADD     A,'A'
        LD      E,A
        JP      PUTC
PSO171:LD      DE,CF171A
        CALL    PUTS
        LD      A,(OBSERVED)
        CALL    HEXBYTE
        LD      A,(ROWSTATUS)
        CP      2
        LD      DE,CF171B
        JP      NZ,PUTS
        LD      DE,CF171E
        JP      PUTS

COMPPASS:
        XOR     A
        LD      (ROWSTATUS),A
        LD      DE,CSTPASS
        CALL    COMPROW
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,CPASSA
        LD      DE,CSUMPASS
        CALL    PUTS
        JP      0000H
CPASSA:LD      HL,PASSCT
        INC     (HL)
        RET

COMPFAIL:
        LD      A,1
        LD      (ROWSTATUS),A
        LD      DE,CSTFAIL
        CALL    COMPROW
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,CFAILA
        LD      DE,CSUMFAIL
        CALL    PUTS
        JP      0000H
CFAILA:LD      HL,FAILCT
        INC     (HL)
        RET

COMPERR:
        LD      A,2
        LD      (ROWSTATUS),A
        LD      DE,CSTERR
        CALL    COMPROW
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,CERRA
        LD      DE,CSUMERR
        CALL    PUTS
        JP      0000H
CERRA: LD      HL,ERRCT
        INC     (HL)
        RET

COMPOBS:
        LD      A,3
        LD      (ROWSTATUS),A
        LD      DE,CSTOBS
        CALL    COMPROW
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,COBSA
        LD      DE,CSUMOBS
        CALL    PUTS
        JP      0000H
COBSA:  LD      HL,OBSCT
        INC     (HL)
        RET

COMPNOTRUN:
        CALL    PUTCID
        LD      DE,CSEP
        CALL    PUTS
        LD      DE,CSTNOT
        CALL    PUTS
        LD      DE,CDREQ
        CALL    PUTS
        LD      DE,CROSSMISS
        CALL    PUTS
        LD      E,13
        CALL    PUTC
        LD      E,10
        CALL    PUTC
        LD      A,(AGGMODE)
        OR      A
        JP      NZ,CNOTRUNA
        LD      DE,CSUMNOTRUN
        CALL    PUTS
        JP      0000H
CNOTRUNA:
        LD      HL,NOTRUNCT
        INC     (HL)
        RET

COMPSUM:
        LD      DE,CSUM1
        CALL    PUTS
        LD      A,(PASSCT)
        CALL    PUTNUM
        LD      DE,CSUM2
        CALL    PUTS
        LD      A,(FAILCT)
        CALL    PUTNUM
        LD      DE,CSUM3
        CALL    PUTS
        LD      A,(ERRCT)
        CALL    PUTNUM
        LD      DE,CSUM4
        CALL    PUTS
        LD      DE,CSUM5
        CALL    PUTS
        LD      A,(OBSCT)
        CALL    PUTNUM
        LD      DE,CSUM6
        CALL    PUTS
        LD      A,(NOTRUNCT)
        CALL    PUTNUM
        LD      DE,CSUM7
        JP      PUTS

PUTFULL:
        LD      A,(FULLMODE)
        OR      A
        RET     Z
        JP      PUTS

PUTSUM:
        LD      A,(FULLMODE)
        OR      A
        JP      Z,COMPSUM
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
        LD      A,(ERRCT)
        CALL    PUTNUM
        LD      DE,SUM4
        CALL    PUTS
        LD      DE,SUMOBS1
        CALL    PUTS
        LD      A,(OBSCT)
        CALL    PUTNUM
        LD      DE,SUMOBS2
        CALL    PUTS
        LD      DE,SUMNR1
        CALL    PUTS
        LD      A,(NOTRUNCT)
        CALL    PUTNUM
        LD      DE,SUMNR2
        CALL    PUTS
        LD      A,(ERRCT)
        OR      A
        LD      DE,SUMYES
        JP      Z,PSOUT
        LD      DE,SUMNO
PSOUT:  JP      PUTS

PUTDIG:
        ADD     A,'0'
        LD      E,A
        JP      PUTC

; Print unsigned A in decimal, without leading zeroes.
PUTNUM:
        CP      100
        JP      C,PNUNDER
        LD      B,0
PNHUND: SUB     100
        INC     B
        CP      100
        JP      NC,PNHUND
        PUSH    AF
        LD      A,B
        CALL    PUTDIG
        POP     AF
        LD      B,0
PNTENS: CP      10
        JP      C,PNPTEN
        SUB     10
        INC     B
        JP      PNTENS
PNPTEN: PUSH    AF
        LD      A,B
        CALL    PUTDIG
        POP     AF
        JP      PUTDIG
PNUNDER:
        CP      10
        JP      C,PUTDIG
        LD      B,0
PNLOOP:
        SUB     10
        INC     B
        CP      10
        JP      NC,PNLOOP
        PUSH    AF
        LD      A,B
        CALL    PUTDIG
        POP     AF
        JP      PUTDIG

; Print the zero-ended word at HL, one character at a time.
PUTZ:
        LD      A,(HL)
        OR      A
        RET     Z
        LD      E,A
        PUSH    HL
        CALL    PUTC
        POP     HL
        INC     HL
        JP      PUTZ

PUTOBS:
        LD      DE,MSG_OBS
        CALL    PUTS
        LD      A,(OBSERVED)
        CALL    HEXBYTE
        LD      E,13
        CALL    PUTC
        LD      E,10
        JP      PUTC

PUTS:
        LD      C,9
        JP      BDOS

PUTC:
        LD      C,2
        JP      BDOS

HEXBYTE:
        PUSH    AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL    HEXNIB
        POP     AF
HEXNIB:
        AND     0FH
        ADD     A,'0'
        CP      '9'+1
        JP      C,HXOUT
        ADD     A,7
HXOUT:
        LD      E,A
        JP      PUTC

S0163: DB '/0163',0
SC163: DB '/CASE:BDOS-FILE-001-P0163',0
S0182: DB '/0182',0
SC182: DB '/CASE:BDOS-FILE-002-P0182',0
S0183: DB '/0183',0
SC183: DB '/CASE:BDOS-FILE-001-P0183',0
S0244: DB '/0244',0
SC244: DB '/CASE:BDOS-FILE-004-P0244',0
S0245: DB '/0245',0
SC245: DB '/CASE:BDOS-FILE-004-P0245',0
S0256: DB '/0256',0
SC256: DB '/CASE:BDOS-FILE-011-P0256',0
S0257: DB '/0257',0
SC257: DB '/CASE:BDOS-FILE-005-P0257',0
S0265: DB '/0265',0
SC265: DB '/CASE:BDOS-FILE-005-P0265',0
S0270: DB '/0270',0
SC270: DB '/CASE:BDOS-FILE-011-P0270',0
S0277: DB '/0277',0
SC277: DB '/CASE:BDOS-FILE-002-P0277',0
S0280: DB '/0280',0
SC280: DB '/CASE:BDOS-FILE-002-P0280',0
S0281: DB '/0281',0
SC281: DB '/CASE:BDOS-FILE-005-P0281',0
S0325: DB '/0325',0
SC325: DB '/CASE:BDOS-FILE-007-P0325',0
S0334: DB '/0334',0
SC334: DB '/CASE:BDOS-FILE-008-P0334',0
S0352: DB '/0352',0
SC352: DB '/CASE:BDOS-FILE-006-P0352',0
S0372: DB '/0372',0
SC372: DB '/CASE:BDOS-FILE-006-P0372',0
S0388: DB '/0388',0
SC388: DB '/CASE:BDOS-FILE-006-P0388',0
S0552: DB '/0552',0
SC552: DB '/CASE:BDOS-FILE-011-P0552',0
S0554: DB '/0554',0
SC554: DB '/CASE:BDOS-FILE-011-P0554',0

; Short selector, frozen selector, report card, observation operation.
DIAGTAB:
        DW S0163,SC163,C163MSG
        DB 1
        DW S0182,SC182,C182MSG
        DB 14
        DW S0183,SC183,C183MSG
        DB 2
        DW S0225,SC225,C225MSG
        DB 6
        DW S0233,SC233,C233MSG
        DB 16
        DW S0238,SC238,C238MSG
        DB 17
        DW S0240,SC240,C240MSG
        DB 18
        DW S0244,SC244,C244MSG
        DB 3
        DW S0245,SC245,C245MSG
        DB 15
        DW S0256,SC256,C256MSG
        DB 4
        DW S0257,SC257,C257MSG
        DB 5
        DW S0265,SC265,C265MSG
        DB 6
        DW S0270,SC270,C270MSG
        DB 8
        DW S0277,SC277,C277MSG
        DB 7
        DW S0280,SC280,C280MSG
        DB 8
        DW S0281,SC281,C281MSG
        DB 8
        DW S0325,SC325,C325MSG
        DB 9
        DW S0334,SC334,C334MSG
        DB 10
        DW S0352,SC352,C352MSG
        DB 11
        DW S0372,SC372,C372MSG
        DB 13
        DW S0388,SC388,C388MSG
        DB 13
        DW S0552,SC552,C552MSG
        DB 8
        DW S0554,SC554,C554MSG
        DB 12

S0171:      DB '/0171',0
SCASE0171:  DB '/CASE:BDOS-FILE-001-P0171',0
S0156:      DB '/0156',0
SC156:      DB '/CASE:BDOS-FILE-002-P0156',0
S0157:      DB '/0157',0
SC157:      DB '/CASE:BDOS-FILE-001-P0157',0
S0158:      DB '/0158',0
SC158:      DB '/CASE:BDOS-FILE-002-P0158',0
S0159:      DB '/0159',0
SC159:      DB '/CASE:BDOS-FILE-001-P0159',0
S0160:      DB '/0160',0
SC160:      DB '/CASE:BDOS-FILE-002-P0160',0
S0161:      DB '/0161',0
SC161:      DB '/CASE:BDOS-FILE-001-P0161',0
S0162:      DB '/0162',0
SC162:      DB '/CASE:BDOS-FILE-002-P0162',0
S0164:      DB '/0164',0
SC164:      DB '/CASE:BDOS-FILE-002-P0164',0
S0166:      DB '/0166',0
SC166:      DB '/CASE:BDOS-FILE-002-P0166',0
S0168:      DB '/0168',0
SC168:      DB '/CASE:BDOS-FILE-002-P0168',0
S0170:      DB '/0170',0
SC170:      DB '/CASE:BDOS-FILE-002-P0170',0
S0172:      DB '/0172',0
SC172:      DB '/CASE:BDOS-FILE-002-P0172',0
S0174:      DB '/0174',0
SC174:      DB '/CASE:BDOS-FILE-002-P0174',0
S0176:      DB '/0176',0
SC176:      DB '/CASE:BDOS-FILE-002-P0176',0
S0178:      DB '/0178',0
SC178:      DB '/CASE:BDOS-FILE-002-P0178',0
S0180:      DB '/0180',0
SC180:      DB '/CASE:BDOS-FILE-002-P0180',0
S0253:      DB '/0253',0
SC253:      DB '/CASE:BDOS-FILE-005-P0253',0
S0553:      DB '/0553',0
SC553:      DB '/CASE:BDOS-FILE-011-P0553',0
S0555:      DB '/0555',0
SC555:      DB '/CASE:BDOS-FILE-011-P0555',0
S0556:      DB '/0556',0
SC556:      DB '/CASE:BDOS-FILE-011-P0556',0
S0557:      DB '/0557',0
SC557:      DB '/CASE:BDOS-FILE-011-P0557',0
S0165:      DB '/0165',0
SCASE165:   DB '/CASE:BDOS-FILE-001-P0165',0
S0167:      DB '/0167',0
SCASE167:   DB '/CASE:BDOS-FILE-001-P0167',0
S0169:      DB '/0169',0
SCASE0169:  DB '/CASE:BDOS-FILE-001-P0169',0
S0173:      DB '/0173',0
SC173:      DB '/CASE:BDOS-FILE-001-P0173',0
S0175:      DB '/0175',0
SC175:      DB '/CASE:BDOS-FILE-001-P0175',0
S0177:      DB '/0177',0
SC177:      DB '/CASE:BDOS-FILE-001-P0177',0
S0179:      DB '/0179',0
SC179:      DB '/CASE:BDOS-FILE-001-P0179',0
S0181:      DB '/0181',0
SC181:      DB '/CASE:BDOS-FILE-001-P0181',0
S0219:      DB '/0219',0
SC219:      DB '/CASE:BDOS-FILE-004-P0219',0
S0220:      DB '/0220',0
SC220:      DB '/CASE:BDOS-FILE-004-P0220',0
S0221:      DB '/0221',0
SC221:      DB '/CASE:BDOS-FILE-004-P0221',0
S0222:      DB '/0222',0
SC222:      DB '/CASE:BDOS-FILE-004-P0222',0
S0223:      DB '/0223',0
SC223:      DB '/CASE:BDOS-FILE-004-P0223',0
S0224:      DB '/0224',0
SC224:      DB '/CASE:BDOS-FILE-004-P0224',0
S0225:      DB '/0225',0
SC225:      DB '/CASE:BDOS-FILE-004-P0225',0
S0226:      DB '/0226',0
SC226:      DB '/CASE:BDOS-FILE-004-P0226',0
S0227:      DB '/0227',0
SC227:      DB '/CASE:BDOS-FILE-004-P0227',0
S0228:      DB '/0228',0
SC228:      DB '/CASE:BDOS-FILE-004-P0228',0
S0229:      DB '/0229',0
SC229:      DB '/CASE:BDOS-FILE-004-P0229',0
S0230:      DB '/0230',0
SC230:      DB '/CASE:BDOS-FILE-004-P0230',0
S0231:      DB '/0231',0
SC231:      DB '/CASE:BDOS-FILE-004-P0231',0
S0232:      DB '/0232',0
SC232:      DB '/CASE:BDOS-FILE-004-P0232',0
S0233:      DB '/0233',0
SC233:      DB '/CASE:BDOS-FILE-004-P0233',0
S0234:      DB '/0234',0
SC234:      DB '/CASE:BDOS-FILE-004-P0234',0
S0235:      DB '/0235',0
SC235:      DB '/CASE:BDOS-FILE-004-P0235',0
S0236:      DB '/0236',0
SC236:      DB '/CASE:BDOS-FILE-004-P0236',0
S0237:      DB '/0237',0
SC237:      DB '/CASE:BDOS-FILE-004-P0237',0
S0238:      DB '/0238',0
SC238:      DB '/CASE:BDOS-FILE-004-P0238',0
S0239:      DB '/0239',0
SC239:      DB '/CASE:BDOS-FILE-004-P0239',0
S0240:      DB '/0240',0
SC240:      DB '/CASE:BDOS-FILE-004-P0240',0
S0242:      DB '/0242',0
SC242:      DB '/CASE:BDOS-FILE-004-P0242',0
S0243:      DB '/0243',0
SC243:      DB '/CASE:BDOS-FILE-004-P0243',0
S0248:      DB '/0248',0
SC248:      DB '/CASE:BDOS-FILE-005-P0248',0
S0249:      DB '/0249',0
SC249:      DB '/CASE:BDOS-FILE-005-P0249',0
S0250:      DB '/0250',0
SC250:      DB '/CASE:BDOS-FILE-005-P0250',0
S0251:      DB '/0251',0
SC251:      DB '/CASE:BDOS-FILE-005-P0251',0
S0252:      DB '/0252',0
SC252:      DB '/CASE:BDOS-FILE-005-P0252',0
S0254:      DB '/0254',0
SC254:      DB '/CASE:BDOS-FILE-005-P0254',0
S0259:      DB '/0259',0
SC259:      DB '/CASE:BDOS-FILE-005-P0259',0
S0260:      DB '/0260',0
SC260:      DB '/CASE:BDOS-FILE-011-P0260',0
S0261:      DB '/0261',0
SC261:      DB '/CASE:BDOS-FILE-005-P0261',0
S0262:      DB '/0262',0
SC262:      DB '/CASE:BDOS-FILE-011-P0262',0
S0263:      DB '/0263',0
SC263:      DB '/CASE:BDOS-FILE-005-P0263',0
S0264:      DB '/0264',0
SC264:      DB '/CASE:BDOS-FILE-011-P0264',0
S0266:      DB '/0266',0
SC266:      DB '/CASE:BDOS-FILE-011-P0266',0
S0267:      DB '/0267',0
SC267:      DB '/CASE:BDOS-FILE-005-P0267',0
S0268:      DB '/0268',0
SC268:      DB '/CASE:BDOS-FILE-011-P0268',0
S0269:      DB '/0269',0
SC269:      DB '/CASE:BDOS-FILE-005-P0269',0
S0271:      DB '/0271',0
SC271:      DB '/CASE:BDOS-FILE-002-P0271',0
S0272:      DB '/0272',0
SC272:      DB '/CASE:BDOS-FILE-005-P0272',0
S0273:      DB '/0273',0
SC273:      DB '/CASE:BDOS-FILE-011-P0273',0
S0274:      DB '/0274',0
SC274:      DB '/CASE:BDOS-FILE-002-P0274',0
S0278:      DB '/0278',0
SC278:      DB '/CASE:BDOS-FILE-005-P0278',0
S0279:      DB '/0279',0
SC279:      DB '/CASE:BDOS-FILE-011-P0279',0
S0317:      DB '/0317',0
SC317:      DB '/CASE:BDOS-FILE-007-P0317',0
S0318:      DB '/0318',0
SC318:      DB '/CASE:BDOS-FILE-008-P0318',0
S0319:      DB '/0319',0
SC319:      DB '/CASE:BDOS-FILE-009-P0319',0
S0320:      DB '/0320',0
SC320:      DB '/CASE:BDOS-FILE-006-P0320',0
S0321:      DB '/0321',0
SC321:      DB '/CASE:BDOS-FILE-007-P0321',0
S0322:      DB '/0322',0
SC322:      DB '/CASE:BDOS-FILE-008-P0322',0
S0323:      DB '/0323',0
SC323:      DB '/CASE:BDOS-FILE-009-P0323',0
S0324:      DB '/0324',0
SC324:      DB '/CASE:BDOS-FILE-006-P0324',0
S0326:      DB '/0326',0
SC326:      DB '/CASE:BDOS-FILE-008-P0326',0
S0327:      DB '/0327',0
SC327:      DB '/CASE:BDOS-FILE-009-P0327',0
S0328:      DB '/0328',0
SC328:      DB '/CASE:BDOS-FILE-006-P0328',0
S0329:      DB '/0329',0
SC329:      DB '/CASE:BDOS-FILE-007-P0329',0
S0330:      DB '/0330',0
SC330:      DB '/CASE:BDOS-FILE-008-P0330',0
S0331:      DB '/0331',0
SC331:      DB '/CASE:BDOS-FILE-009-P0331',0
S0332:      DB '/0332',0
SC332:      DB '/CASE:BDOS-FILE-006-P0332',0
S0333:      DB '/0333',0
SC333:      DB '/CASE:BDOS-FILE-007-P0333',0
S0335:      DB '/0335',0
SC335:      DB '/CASE:BDOS-FILE-009-P0335',0
S0336:      DB '/0336',0
SC336:      DB '/CASE:BDOS-FILE-006-P0336',0
S0337:      DB '/0337',0
SC337:      DB '/CASE:BDOS-FILE-007-P0337',0
S0338:      DB '/0338',0
SC338:      DB '/CASE:BDOS-FILE-008-P0338',0
S0339:      DB '/0339',0
SC339:      DB '/CASE:BDOS-FILE-009-P0339',0
S0340:      DB '/0340',0
SC340:      DB '/CASE:BDOS-FILE-006-P0340',0
S0341:      DB '/0341',0
SC341:      DB '/CASE:BDOS-FILE-007-P0341',0
S0342:      DB '/0342',0
SC342:      DB '/CASE:BDOS-FILE-008-P0342',0
S0343:      DB '/0343',0
SC343:      DB '/CASE:BDOS-FILE-009-P0343',0
S0344:      DB '/0344',0
SC344:      DB '/CASE:BDOS-FILE-006-P0344',0
S0345:      DB '/0345',0
SC345:      DB '/CASE:BDOS-FILE-007-P0345',0
S0346:      DB '/0346',0
SC346:      DB '/CASE:BDOS-FILE-008-P0346',0
S0347:      DB '/0347',0
SC347:      DB '/CASE:BDOS-FILE-009-P0347',0
S0348:      DB '/0348',0
SC348:      DB '/CASE:BDOS-FILE-006-P0348',0
S0349:      DB '/0349',0
SC349:      DB '/CASE:BDOS-FILE-007-P0349',0
S0350:      DB '/0350',0
SC350:      DB '/CASE:BDOS-FILE-008-P0350',0
S0351:      DB '/0351',0
SC351:      DB '/CASE:BDOS-FILE-009-P0351',0
S0368:      DB '/0368',0
SC368:      DB '/CASE:BDOS-FILE-006-P0368',0
S0369:      DB '/0369',0
SC369:      DB '/CASE:BDOS-FILE-007-P0369',0
S0550:      DB '/0550',0
SC550:      DB '/CASE:BDOS-FILE-011-P0550',0
S0551:      DB '/0551',0
SC551:      DB '/CASE:BDOS-FILE-011-P0551',0
SGROUPOPEN: DB '/GROUP:OPEN',0
SGROUPSEQ:  DB '/GROUP:SEQREAD',0
SGROUPCLOSE: DB '/GROUP:CLOSE',0
SGLIST:     DB '/GROUP:LIST',0
SGFCB:      DB '/GROUP:FCBOPEN',0
SGREAD:     DB '/GROUP:READ',0
SGWRITE:    DB '/GROUP:WRITE',0
SGRANDOM:   DB '/GROUP:RANDOM',0
SGLIFE:     DB '/GROUP:LIFECYCLE',0
SGREQ:      DB '/GROUP:REQUIRED',0
SGOBS:      DB '/GROUP:OBSERVATION',0
SGMAN:      DB '/GROUP:MANUAL',0
SFN15:      DB '/FN:15',0
SFN16:      DB '/FN:16',0
SFN20:      DB '/FN:20',0
SGFN15:     DB '/GROUP:FN:15',0
SGFN16:     DB '/GROUP:FN:16',0
SGFN20:     DB '/GROUP:FN:20',0
SSAFE:      DB '/SAFE',0
SALL:       DB '/ALL',0
SLIST:      DB '/LIST',0
SHELP:      DB '/H',0
SHELP2:     DB '/HELP',0
SHRESULTS:  DB '/H:RESULTS',0
SHPROFILES: DB '/H:PROFILES',0
SINFO:      DB '/INFO',0
SVER:       DB '/VER',0
SVERSION:   DB '/VERSION',0
SREPORT:    DB ':REPORT',0

MSG_BADSEL:
        DB 'FILETEST: unknown command. Use /HELP or /GROUP:LIST.',13,10,'$'
MSG_LIST:
        DB 13,10,'CLASS: R=Required N=Not-guaranteed S=Out-of-scope',13,10
        DB 13,10,'FCB AND OPEN (31)',13,10
        DB '  0156 R A sequential FCB occupies bytes 0-32 (33 bytes).',13,10
        DB '  0157 R A random-access FCB adds random-record bytes 33-35.',13,10
        DB '  0158 R FCB byte 0 uses 0 for current default and 1-16 for...',13,10
        DB '  0159 R FCB bytes 1-8 contain an uppercase, high-bit-clear,...',13,10
        DB '  0160 R FCB bytes 9-11 contain the uppercase file type.',13,10
        DB '  0161 R High bits of type bytes 9-11 carry the documented...',13,10
        DB '  0162 R FCB byte 12 is current extent, normally...',13,10
        DB '  0163 N FCB byte 13 is reserved for system use; applications...',13,10
        DB '  0164 R FCB byte 14 is reserved for system use and supplied as...',13,10
        DB '  0165 R FCB byte 15 holds extent record count in the range 0-128.',13,10
        DB '  0166 R FCB bytes 16-31 hold CP/M-supplied allocation state...',13,10
        DB '  0167 R FCB byte 32 holds the sequential current record 0-127...',13,10
        DB '  0168 R Function 15 is selected by C=0Fh and takes the FCB...',13,10
        DB '  0169 R Function 15 opens an existing file for the current user...',13,10
        DB '  0170 R Successful function 15 returns a directory code 0-3 in A.',13,10
        DB '  0171 R Function 15 returns FFh in A when no matching file exists.',13,10
        DB '  0172 R Successful open supplies directory/allocation...',13,10
        DB '  0173 R Existing files must be successfully opened before...',13,10
        DB '  0174 R ? wildcards in open identity fields match corresponding...',13,10
        DB '  0175 R Wildcard open activates the first matching FCB rather...',13,10
        DB '  0176 R For sequential access from the beginning, the caller...',13,10
        DB '  0177 R Function 16 is selected by C=10h and takes an activated...',13,10
        DB '  0178 R Close after writes permanently records compatible new...',13,10
        DB '  0179 R A file used only for reads need not be closed.',13,10
        DB '  0180 R Successful close returns a directory code 0-3 in A.',13,10
        DB '  0181 R Close returns FFh when the FCB filename cannot be found.',13,10
        DB '  0182 N FCB allocation-map representation is...',13,10
        DB '  0183 N Exact FCB bytes after failed Open, except for...',13,10
        DB '  0184 S DRIs high-S2 no-write/dirty flag representation is private.',13,10
        DB '  0185 S DRIs exact zero result for unnecessary close after...',13,10
        DB '  0186 S DRIs internal open-copy order, search variables, and...',13,10
        DB 13,10,'SEQUENTIAL READ (38)',13,10
        DB '  0218 S DRI private search implementation',13,10
        DB '  0219 R Function 20 call convention',13,10
        DB '  0220 R Activated-FCB precondition',13,10
        DB '  0221 R Sequential position source',13,10
        DB '  0222 R Successful result',13,10
        DB '  0223 R Successful transfer size',13,10
        DB '  0224 R Current DMA destination',13,10
        DB '  0225 N Partial-byte count',13,10
        DB '  0226 R Advance after success',13,10
        DB '  0227 R CR progression within an extent',13,10
        DB '  0228 R Full-extent position',13,10
        DB '  0229 R Automatic extent transition',13,10
        DB '  0230 R New-extent first-record state',13,10
        DB '  0231 R Extent working-state replacement',13,10
        DB '  0232 R EOF/no-data result',13,10
        DB '  0233 N Exact EOF code',13,10
        DB '  0234 R Empty-file behavior',13,10
        DB '  0235 R Partial-final-extent EOF',13,10
        DB '  0236 R Exact-boundary EOF',13,10
        DB '  0237 R Repeated EOF indication',13,10
        DB '  0238 N DMA contents after failure',13,10
        DB '  0239 R FCB mutation',13,10
        DB '  0240 N Exact FCB image after failed read',13,10
        DB '  0241 S DRI exact-boundary EX drift',13,10
        DB '  0242 R Explicit-drive read',13,10
        DB '  0243 R Read-only readability',13,10
        DB '  0244 N Unopened-FCB result',13,10
        DB '  0245 N Invalid-FCB result',13,10
        DB '  0247 S DRI internal read machinery',13,10
        DB '  0248 R Function 22 convention',13,10
        DB '  0249 R Make uniqueness precondition',13,10
        DB '  0250 R New empty file',13,10
        DB '  0251 R Make activates FCB',13,10
        DB '  0252 R Make success result',13,10
        DB '  0253 R Make directory-full result',13,10
        DB '  0254 R Immediate empty-file visibility',13,10
        DB '  0256 N Make on existing name',13,10
        DB '  0257 N Ambiguous Make name',13,10
        DB 13,10,'WRITE (24)',13,10
        DB '  0258 S Immediate data-block reservation',13,10
        DB '  0259 R Function 21 convention',13,10
        DB '  0260 R Write activation precondition',13,10
        DB '  0261 R Write source position',13,10
        DB '  0262 R Successful write result',13,10
        DB '  0263 R Write transfer size',13,10
        DB '  0264 R Current DMA source',13,10
        DB '  0265 N Partial-record length',13,10
        DB '  0266 R CR advance after write',13,10
        DB '  0267 R RC extension',13,10
        DB '  0268 R Existing-record overwrite',13,10
        DB '  0269 R On-demand allocation',13,10
        DB '  0270 N Exact allocation choice',13,10
        DB '  0271 R Automatic write extent transition',13,10
        DB '  0272 R Successful transition state',13,10
        DB '  0273 R Full last record remains successful',13,10
        DB '  0274 R Next-extent failure result',13,10
        DB '  0277 N Unactivated write behavior',13,10
        DB '  0278 R Explicit-drive Make/Write',13,10
        DB '  0279 R Close commits final written metadata',13,10
        DB '  0280 N Unclosed final extent',13,10
        DB '  0281 N Pre-Close directory metadata',13,10
        DB '  0282 S Exact close-time update sequence',13,10
        DB '  0284 S DRI private write machinery',13,10
        DB 13,10,'RANDOM I/O (37)',13,10
        DB '  0317 R Random field location',13,10
        DB '  0318 R Random field byte order',13,10
        DB '  0319 R CP/M 2.2 random range',13,10
        DB '  0320 R Random/sequential state distinction',13,10
        DB '  0321 R Function 36 convention',13,10
        DB '  0322 R Function 36 direction',13,10
        DB '  0323 R Function 36 boundary equivalence',13,10
        DB '  0324 R Function 36 no I/O',13,10
        DB '  0325 N Function 36 A value',13,10
        DB '  0326 R Function 33 convention',13,10
        DB '  0327 R Random read destination',13,10
        DB '  0328 R Random read success',13,10
        DB '  0329 R Random read position',13,10
        DB '  0330 R Random read no advance',13,10
        DB '  0331 R Random read unwritten data',13,10
        DB '  0332 R Random read missing extent',13,10
        DB '  0333 R Random overflow',13,10
        DB '  0334 N DMA after failed random read',13,10
        DB '  0335 R Function 34 convention',13,10
        DB '  0336 R Random write transfer',13,10
        DB '  0337 R Random write success',13,10
        DB '  0338 R Random write allocation',13,10
        DB '  0339 R Random write holes',13,10
        DB '  0340 R Random write virtual length',13,10
        DB '  0341 R Random write working fields',13,10
        DB '  0342 R Random write no advance',13,10
        DB '  0343 R No automatic random extent switch',13,10
        DB '  0344 R Random write Close',13,10
        DB '  0345 R Random write extent failure',13,10
        DB '  0346 R Allocation-full exact code',13,10
        DB '  0347 R Function 35 convention',13,10
        DB '  0348 R Function 35 result location',13,10
        DB '  0349 R Function 35 unit',13,10
        DB '  0350 R Function 35 maximum',13,10
        DB '  0351 R Sparse virtual size',13,10
        DB '  0352 N Function 35 A value',13,10
        DB '  0353 S DRI random seek machinery',13,10
        DB 13,10,'LIFECYCLE AND PROTECTION (12)',13,10
        DB '  0368 R File read-only sequential protection',13,10
        DB '  0369 R File read-only random protection',13,10
        DB '  0372 N Protected-operation normal result',13,10
        DB '  0388 N Late attribute change versus dirty FCB',13,10
        DB '  0550 R Special drive-question search exposes complete...',13,10
        DB '  0551 R Make-to-open lifecycle equivalence',13,10
        DB '  0552 N Working FCB may lead directory metadata',13,10
        DB '  0553 R Successful Close establishes reopened consistency',13,10
        DB '  0554 N Reopen reconstructs behavior, not FCB byte identity',13,10
        DB '  0555 R Extents form one logical record stream',13,10
        DB '  0556 R Completed extent survives later extension failure',13,10
        DB '  0557 R Failed growth does not claim a new record',13,10
        DB 13,10,'TOTAL: 142 ITEMS',13,10,'$'
MSG_HELP:
        DB 13,10,'FILETEST 0.1.0-dev35',13,10,13,10
        DB '  FILETEST /NNNN[:REPORT]   Run, explain, or report one item',13,10
        DB '  FILETEST /ALL             Run checks and report all items',13,10
        DB '  FILETEST /SAFE            Run checks needing no destructive media',13,10
        DB '  FILETEST /LIST            List ledger items by useful group',13,10
        DB '  FILETEST /GROUP:LIST      List all available groupings',13,10
        DB '  FILETEST /GROUP:name      Run a tool-specific group',13,10
        DB '                              (run /GROUP:LIST for available groups)',13,10
        DB '  FILETEST /FN:n            Select BDOS function 15, 16, or 20',13,10
        DB '  FILETEST /H, /HELP        Show concise command help',13,10
        DB '  FILETEST /INFO            Show build information',13,10
        DB '  FILETEST /VER, /VERSION   Show name and version',13,10,'$'
MSG_RESULTS:
        DB 13,10,'FILETEST result terminology',13,10,13,10
        DB 'STATUS: P=Pass F=Fail -=Not-run O=Observed.',13,10
        DB 'PASS=completed and matched; FAIL=completed and mismatched.',13,10
        DB 'CLASS: R=Required N=Not-guaranteed S=Out-of-scope X=Profile.',13,10
        DB 'OUT SCOPE=FILETEST cannot execute or judge the catalog item.',13,10
        DB 'OBSERVED gives compact evidence.',13,10
        DB '/NNNN:REPORT gives complete expected/observed context.',13,10,'$'
MSG_PROFILES:
        DB 13,10,'FILETEST named profiles',13,10,13,10
        DB 'FILETEST currently defines no named compatibility profiles.',13,10
        DB 'Its optional selectors choose workflows or BDOS functions;',13,10
        DB 'they do not assert additional compatibility profiles.',13,10
        DB 'Prepare the cross-drive fixture with SCRATCH /CROSS;',13,10
        DB 'mount that disk as C: for the explicit-drive checks.',13,10
        DB 'Prepare the allocation-full fixture with SCRATCH /DISK;',13,10
        DB 'mount that disk as D: for the data-full checks.',13,10,'$'
MSG_INFO:
        DB 'FILETEST 0.1.0-dev35',13,10
        DB 'Coverage: 142 implemented FILETEST catalog items',13,10
        DB 'Required: 109  Diagnostics: 23  Outside scope: 10',13,10
        DB 'Interface revision: grouped catalog and exact selectors',13,10,'$'
MSG_VERSION:
        DB 'FILETEST 0.1.0-dev35',13,10,'$'
MSG_GROUPS:
        DB 13,10,'UNIVERSAL GROUPS',13,10
        DB '  REQUIRED      Run returning REQUIRED items; list manual items',13,10
        DB '  OBSERVATION   Run NOT GUARANTEED observation items',13,10
        DB '  MANUAL        List manual items; do not run them',13,10,13,10
        DB 'FUNCTIONAL GROUPS',13,10
        DB '  FCBOPEN       FCB representation, Open, and Close (31)',13,10
        DB '  READ          Sequential Read and Make prerequisites (38)',13,10
        DB '  WRITE         Sequential Write and persistence (24)',13,10
        DB '  RANDOM        Random I/O and file size (37)',13,10
        DB '  LIFECYCLE     Protection and lifecycle behavior (12)',13,10,13,10
        DB 'ADDITIONAL GROUPS',13,10
        DB '  OPEN          Core Open workflow',13,10
        DB '  SEQREAD       Core sequential-read workflow',13,10
        DB '  CLOSE         Core Close workflow',13,10,13,10
        DB 'ORTHOGONAL GROUPS',13,10
        DB '  FN:15         Function 15/Open-dependent items (/FN:15)',13,10
        DB '  FN:16         Function 16/Close-dependent items (/FN:16)',13,10
        DB '  FN:20         Function 20/Read-dependent items (/FN:20)',13,10,'$'
MSG_MANUAL:
        DB 13,10,'MANUAL ITEMS (2)',13,10
        DB '  0368 - R File read-only sequential protection',13,10
        DB '  0369 - R File read-only random protection',13,10
        DB 13,10,'These terminal procedures are listed but not run.',13,10,'$'
MSG_HEADER:
        DB 'REPORT CPM22-COMPAT-RPT 1',13,10
        DB 'SUITE_VERSION 0.1.0-dev35',13,10
        DB 'EXECUTABLE FILETEST.COM',13,10
        DB 'PROCESSOR_REQUIRED 8080',13,10
        DB 'RUN_PURPOSE DEVELOPMENT',13,10
        DB 'WORKFLOW FILESYSTEM_BRINGUP',13,10
        DB 'RUN_MODE DEVELOPMENT_SUBSET',13,10
        DB 'REQUESTED_SCOPE LEDGER:0171',13,10
        DB 'REPORT_SINK CONSOLE',13,10
        DB 'CERTIFICATION_ELIGIBLE NO',13,10,13,10,'$'
HAGG1:
        DB 'REPORT CPM22-COMPAT-RPT 1',13,10
        DB 'SUITE_VERSION 0.1.0-dev35',13,10
        DB 'EXECUTABLE FILETEST.COM',13,10
        DB 'PROCESSOR_REQUIRED 8080',13,10
        DB 'RUN_PURPOSE DEVELOPMENT',13,10
        DB 'WORKFLOW FILESYSTEM_BRINGUP',13,10
        DB 'RUN_MODE DEVELOPMENT_SUBSET',13,10
        DB 'REQUESTED_SCOPE ','$'
HOPEN:
        DB 13,10,'SELECTED_CASES 0165,0169,0171,0173,0175',13,10
        DB 'REPORT_SINK CONSOLE',13,10
        DB 'CERTIFICATION_ELIGIBLE NO',13,10,13,10,'$'
HSEQ:
        DB 13,10,'SELECTED_CASES 0167,0179,0219-0243',13,10
        DB 'REPORT_SINK CONSOLE',13,10
        DB 'CERTIFICATION_ELIGIBLE NO',13,10,13,10,'$'
HCLOSE:
        DB 13,10,'SELECTED_CASES 0177,0181',13,10
        DB 'REPORT_SINK CONSOLE',13,10
        DB 'CERTIFICATION_ELIGIBLE NO',13,10,13,10,'$'
HREADS:
        DB 13,10,'SELECTED_CASES 0167,0173,0179,0219-0243',13,10
        DB 'REPORT_SINK CONSOLE',13,10
        DB 'CERTIFICATION_ELIGIBLE NO',13,10,13,10,'$'
HALL:
        DB 13,10,'SELECTED_CASES 0165,0167,0169,0171,0173,0175,0177,0179,0219-0243',13,10
        DB 'REPORT_SINK CONSOLE',13,10
        DB 'CERTIFICATION_ELIGIBLE NO',13,10,13,10,'$'
HCOMPLETE:
        DB 13,10,'SELECTED_CASES ALL_RETURNING_IMPLEMENTED',13,10
        DB 'EXCLUDED_TERMINAL_OUTCOMES 0368,0369',13,10
        DB 'REPORT_SINK CONSOLE',13,10
        DB 'CERTIFICATION_ELIGIBLE NO',13,10,13,10,'$'
HGFCB: DB 13,10,'SELECTED_GROUP FCBOPEN',13,10,'$'
HGREAD:DB 13,10,'SELECTED_GROUP READ',13,10,'$'
HGWRITE:DB 13,10,'SELECTED_GROUP WRITE',13,10,'$'
HGRANDOM:DB 13,10,'SELECTED_GROUP RANDOM',13,10,'$'
HGLIFE:DB 13,10,'SELECTED_GROUP LIFECYCLE',13,10,'$'
HGREQ: DB 13,10,'SELECTED_GROUP REQUIRED',13,10,'$'
HGOBS: DB 13,10,'SELECTED_GROUP OBSERVATION',13,10,'$'
SKIPFCB:
        DB '  0184 - S Private high-S2 flag representation',13,10
        DB '  0185 - S Unnecessary Close exact result',13,10
        DB '  0186 - S Private Open/Close algorithms',13,10,'$'
SKIPREAD:
        DB '  0218 - S Private search implementation',13,10
        DB '  0241 - S Exact-boundary EX drift',13,10
        DB '  0247 - S Private read machinery',13,10,'$'
SKIPWRITE:
        DB '  0258 - S Immediate block reservation',13,10
        DB '  0282 - S Exact Close update sequence',13,10
        DB '  0284 - S Private write machinery',13,10,'$'
SKIPRANDOM:
        DB '  0353 - S Private random-seek machinery',13,10,'$'
SKIPMAN:
        DB '  0368 - R Manual: sequential read-only protection',13,10
        DB '  0369 - R Manual: random read-only protection',13,10,'$'
SKIPALL:
        DB '  0184 - S Private high-S2 flag representation',13,10
        DB '  0185 - S Unnecessary Close exact result',13,10
        DB '  0186 - S Private Open/Close algorithms',13,10
        DB '  0218 - S Private search implementation',13,10
        DB '  0241 - S Exact-boundary EX drift',13,10
        DB '  0247 - S Private read machinery',13,10
        DB '  0258 - S Immediate block reservation',13,10
        DB '  0282 - S Exact Close update sequence',13,10
        DB '  0284 - S Private write machinery',13,10
        DB '  0353 - S Private random-seek machinery',13,10
        DB '  0368 - R Manual: sequential read-only protection',13,10
        DB '  0369 - R Manual: random read-only protection',13,10,'$'
SKIPNONE: DB '$'
HNEW1:
        DB 'REPORT CPM22-COMPAT-RPT 1',13,10
        DB 'SUITE_VERSION 0.1.0-dev35',13,10
        DB 'EXECUTABLE FILETEST.COM',13,10
        DB 'PROCESSOR_REQUIRED 8080',13,10
        DB 'RUN_PURPOSE DEVELOPMENT',13,10
        DB 'WORKFLOW FILESYSTEM_BRINGUP',13,10
        DB 'RUN_MODE DEVELOPMENT_SUBSET',13,10
        DB 'REQUESTED_SCOPE ','$'
HNEW2:
        DB 13,10,'REPORT_SINK CONSOLE',13,10
        DB 'CERTIFICATION_ELIGIBLE NO',13,10,13,10,'$'
H165MSG:
        DB 'REPORT CPM22-COMPAT-RPT 1',13,10
        DB 'SUITE_VERSION 0.1.0-dev35',13,10
        DB 'EXECUTABLE FILETEST.COM',13,10
        DB 'PROCESSOR_REQUIRED 8080',13,10
        DB 'RUN_PURPOSE DEVELOPMENT',13,10
        DB 'WORKFLOW FILESYSTEM_BRINGUP',13,10
        DB 'RUN_MODE DEVELOPMENT_SUBSET',13,10
        DB 'REQUESTED_SCOPE LEDGER:0165',13,10
        DB 'REPORT_SINK CONSOLE',13,10
        DB 'CERTIFICATION_ELIGIBLE NO',13,10,13,10,'$'
C156MSG: DB 'CASE BDOS-FILE-002-P0156',13,10,'LEDGER 0156',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-001',13,10
        DB 'ORACLE OR-0156',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Sequential FCB occupies bytes 0-32 without overlap.',13,10,'$'
C157MSG: DB 'CASE BDOS-FILE-001-P0157',13,10,'LEDGER 0157',13,10
        DB 'PARENT BDOS-FILE-001',13,10,'MODULE_CASE FIL-002',13,10
        DB 'ORACLE OR-0157',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random FCB adds little-endian record bytes 33-35.',13,10,'$'
C158MSG: DB 'CASE BDOS-FILE-002-P0158',13,10,'LEDGER 0158',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-003',13,10
        DB 'ORACLE OR-0158',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Drive byte 0 means default; 1-16 encode A-P.',13,10,'$'
C159MSG: DB 'CASE BDOS-FILE-001-P0159',13,10,'LEDGER 0159',13,10
        DB 'PARENT BDOS-FILE-001',13,10,'MODULE_CASE FIL-004',13,10
        DB 'ORACLE OR-0159',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Name bytes 1-8 are uppercase, clear, blank padded.',13,10,'$'
C160MSG: DB 'CASE BDOS-FILE-002-P0160',13,10,'LEDGER 0160',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-005',13,10
        DB 'ORACLE OR-0160',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Type bytes 9-11 contain uppercase DAT.',13,10,'$'
C161MSG: DB 'CASE BDOS-FILE-001-P0161',13,10,'LEDGER 0161',13,10
        DB 'PARENT BDOS-FILE-001',13,10,'MODULE_CASE FIL-006',13,10
        DB 'ORACLE OR-0161',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Type-byte high bit carries read-only attribute.',13,10,'$'
C162MSG: DB 'CASE BDOS-FILE-002-P0162',13,10,'LEDGER 0162',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-007',13,10
        DB 'ORACLE OR-0162',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED EX occupies byte 12 and accepts range 0-31.',13,10,'$'
C164MSG: DB 'CASE BDOS-FILE-002-P0164',13,10,'LEDGER 0164',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-009',13,10
        DB 'ORACLE OR-0164',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED S2 is byte 14 and supplied zero to Open and Make.',13,10,'$'
C166MSG: DB 'CASE BDOS-FILE-002-P0166',13,10,'LEDGER 0166',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-011',13,10
        DB 'ORACLE OR-0166',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Open supplies allocation state in bytes 16-31.',13,10,'$'
C168MSG: DB 'CASE BDOS-FILE-002-P0168',13,10,'LEDGER 0168',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-013',13,10
        DB 'ORACLE OR-0168',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 15 is invoked with C=0Fh and FCB in DE.',13,10,'$'
C170MSG: DB 'CASE BDOS-FILE-002-P0170',13,10,'LEDGER 0170',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-015',13,10
        DB 'ORACLE OR-0170',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Successful Open returns directory code 0-3.',13,10,'$'
C172MSG: DB 'CASE BDOS-FILE-002-P0172',13,10,'LEDGER 0172',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-017',13,10
        DB 'ORACLE OR-0172',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Open supplies FCB state supporting subsequent I/O.',13,10,'$'
C174MSG: DB 'CASE BDOS-FILE-002-P0174',13,10,'LEDGER 0174',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-019',13,10
        DB 'ORACLE OR-0174',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Question-mark wildcard matches one identity character.',13,10,'$'
C176MSG: DB 'CASE BDOS-FILE-002-P0176',13,10,'LEDGER 0176',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-021',13,10
        DB 'ORACLE OR-0176',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Caller-supplied CR zero selects first sequential record.',13,10,'$'
C178MSG: DB 'CASE BDOS-FILE-002-P0178',13,10,'LEDGER 0178',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-023',13,10
        DB 'ORACLE OR-0178',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Close after write persists new directory state.',13,10,'$'
C180MSG: DB 'CASE BDOS-FILE-002-P0180',13,10,'LEDGER 0180',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-025',13,10
        DB 'ORACLE OR-0180',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Successful Close returns directory code 0-3.',13,10,'$'
C253MSG: DB 'CASE BDOS-FILE-005-P0253',13,10,'LEDGER 0253',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE FIL-066',13,10
        DB 'ORACLE OR-0253',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Make on controlled directory-full drive returns FFh.',13,10,'$'
C553MSG: DB 'CASE BDOS-FILE-011-P0553',13,10,'LEDGER 0553',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE FIL-138',13,10
        DB 'ORACLE OR-0553',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Close establishes consistent reopened data.',13,10,'$'
C555MSG: DB 'CASE BDOS-FILE-011-P0555',13,10,'LEDGER 0555',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE FIL-140',13,10
        DB 'ORACLE OR-0555',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Extents form one logical sequential record stream.',13,10,'$'
C556MSG: DB 'CASE BDOS-FILE-011-P0556',13,10,'LEDGER 0556',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE FIL-141',13,10
        DB 'ORACLE OR-0556',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Completed extent survives later extension failure.',13,10,'$'
C557MSG: DB 'CASE BDOS-FILE-011-P0557',13,10,'LEDGER 0557',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE FIL-142',13,10
        DB 'ORACLE OR-0557',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Failed growth does not claim a new record.',13,10,'$'
C165MSG:
        DB 'CASE BDOS-FILE-001-P0165',13,10
        DB 'LEDGER 0165',13,10
        DB 'PARENT BDOS-FILE-001',13,10
        DB 'MODULE_CASE OPE-002',13,10
        DB 'ORACLE OR-0165',13,10
        DB 'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED FCB byte 15 holds extent RC in documented range 0-128.',13,10,'$'
H169MSG:
        DB 'REPORT CPM22-COMPAT-RPT 1',13,10
        DB 'SUITE_VERSION 0.1.0-dev35',13,10
        DB 'EXECUTABLE FILETEST.COM',13,10
        DB 'PROCESSOR_REQUIRED 8080',13,10
        DB 'RUN_PURPOSE DEVELOPMENT',13,10
        DB 'WORKFLOW FILESYSTEM_BRINGUP',13,10
        DB 'RUN_MODE DEVELOPMENT_SUBSET',13,10
        DB 'REQUESTED_SCOPE LEDGER:0169',13,10
        DB 'REPORT_SINK CONSOLE',13,10
        DB 'CERTIFICATION_ELIGIBLE NO',13,10,13,10,'$'
C169MSG:
        DB 'CASE BDOS-FILE-001-P0169',13,10
        DB 'LEDGER 0169',13,10
        DB 'PARENT BDOS-FILE-001',13,10
        DB 'MODULE_CASE OPE-003',13,10
        DB 'ORACLE OR-0169',13,10
        DB 'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Existing files open on current and explicit drives; current drive unchanged.',13,10,'$'
C167MSG:
        DB 'CASE BDOS-FILE-001-P0167',13,10,'LEDGER 0167',13,10
        DB 'PARENT BDOS-FILE-001',13,10,'MODULE_CASE SEQ-001',13,10
        DB 'ORACLE OR-0167',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED CR at FCB byte 32 progresses 1,2,3 with marked records.',13,10,'$'
C173MSG:
        DB 'CASE BDOS-FILE-001-P0173',13,10,'LEDGER 0173',13,10
        DB 'PARENT BDOS-FILE-001',13,10,'MODULE_CASE OPE-005',13,10
        DB 'ORACLE OR-0173',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Successful Function 15 precedes access to marked record.',13,10,'$'
C175MSG:
        DB 'CASE BDOS-FILE-001-P0175',13,10,'LEDGER 0175',13,10
        DB 'PARENT BDOS-FILE-001',13,10,'MODULE_CASE OPE-006',13,10
        DB 'ORACLE OR-0175',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Wildcard Open activates first deterministic BTWILD match.',13,10,'$'
C177MSG:
        DB 'CASE BDOS-FILE-001-P0177',13,10,'LEDGER 0177',13,10
        DB 'PARENT BDOS-FILE-001',13,10,'MODULE_CASE CLO-001',13,10
        DB 'ORACLE OR-0177',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 16 closes a successfully activated unchanged FCB.',13,10,'$'
C179MSG:
        DB 'CASE BDOS-FILE-001-P0179',13,10,'LEDGER 0179',13,10
        DB 'PARENT BDOS-FILE-001',13,10,'MODULE_CASE SEQ-002',13,10
        DB 'ORACLE OR-0179',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Marked record reads successfully without Function 16.',13,10,'$'
C181MSG:
        DB 'CASE BDOS-FILE-001-P0181',13,10,'LEDGER 0181',13,10
        DB 'PARENT BDOS-FILE-001',13,10,'MODULE_CASE CLO-002',13,10
        DB 'ORACLE OR-0181',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Dirty FCB with absent BTMISS.DAT returns FFh from Function 16.',13,10,'$'
C219MSG:
        DB 'CASE BDOS-FILE-004-P0219',13,10,'LEDGER 0219',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-004',13,10
        DB 'ORACLE OR-0219',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED DE-selected activated FCB controls the marked read.',13,10,'$'
C220MSG:
        DB 'CASE BDOS-FILE-004-P0220',13,10,'LEDGER 0220',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-005',13,10
        DB 'ORACLE OR-0220',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Successful Function 15 is recorded before Function 20.',13,10,'$'
C221MSG:
        DB 'CASE BDOS-FILE-004-P0221',13,10,'LEDGER 0221',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-006',13,10
        DB 'ORACLE OR-0221',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Three successive records have distinct 000,001,002 markers.',13,10,'$'
C222MSG:
        DB 'CASE BDOS-FILE-004-P0222',13,10,'LEDGER 0222',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-007',13,10
        DB 'ORACLE OR-0222',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Allocated record read returns 00h and all 128 bytes match.',13,10,'$'
C223MSG:
        DB 'CASE BDOS-FILE-004-P0223',13,10,'LEDGER 0223',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-008',13,10
        DB 'ORACLE OR-0223',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Complete 128-byte DMA transfer preserves 16-byte guards.',13,10,'$'
C224MSG:
        DB 'CASE BDOS-FILE-004-P0224',13,10,'LEDGER 0224',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-009',13,10
        DB 'ORACLE OR-0224',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Alternate DMA changes while 0080h and guards remain sentinels.',13,10,'$'
C225MSG:
        DB 'CASE BDOS-FILE-004-P0225',13,10,'LEDGER 0225',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-010',13,10
        DB 'ORACLE OR-0225',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 20 transfers a full record, not a byte-length value.',13,10,'$'
C226MSG:
        DB 'CASE BDOS-FILE-004-P0226',13,10,'LEDGER 0226',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-011',13,10
        DB 'ORACLE OR-0226',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Consecutive reads advance to distinct 000 and 001 markers.',13,10,'$'
C227MSG:
        DB 'CASE BDOS-FILE-004-P0227',13,10,'LEDGER 0227',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-012',13,10
        DB 'ORACLE OR-0227',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED CR equals 1,2,3 after three successful calls from CR=0.',13,10,'$'
C228MSG:
        DB 'CASE BDOS-FILE-004-P0228',13,10,'LEDGER 0228',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-013',13,10
        DB 'ORACLE OR-0228',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED 128th successful read leaves CR=80h and record 127 marker.',13,10,'$'
C229MSG:
        DB 'CASE BDOS-FILE-004-P0229',13,10,'LEDGER 0229',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-014',13,10
        DB 'ORACLE OR-0229',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Consecutive success and markers across records 127 and 128.',13,10,'$'
C230MSG:
        DB 'CASE BDOS-FILE-004-P0230',13,10,'LEDGER 0230',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-015',13,10
        DB 'ORACLE OR-0230',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED First record in new extent leaves EX=01h and CR=01h.',13,10,'$'
C231MSG:
        DB 'CASE BDOS-FILE-004-P0231',13,10,'LEDGER 0231',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-016',13,10
        DB 'ORACLE OR-0231',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED EX/RC/allocation remain coherent through record 129.',13,10,'$'
C232MSG:
        DB 'CASE BDOS-FILE-004-P0232',13,10,'LEDGER 0232',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-017',13,10
        DB 'ORACLE OR-0232',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED First read beyond controlled one-record file is nonzero.',13,10,'$'
C233MSG:
        DB 'CASE BDOS-FILE-004-P0233',13,10,'LEDGER 0233',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-018',13,10
        DB 'ORACLE OR-0233',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED EOF result is nonzero; no implementation-specific literal.',13,10,'$'
C234MSG:
        DB 'CASE BDOS-FILE-004-P0234',13,10,'LEDGER 0234',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-019',13,10
        DB 'ORACLE OR-0234',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Empty file opens; first read is nonzero with guards intact.',13,10,'$'
C235MSG:
        DB 'CASE BDOS-FILE-004-P0235',13,10,'LEDGER 0235',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-020',13,10
        DB 'ORACLE OR-0235',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Partial final extent gives two successes then nonzero EOF.',13,10,'$'
C236MSG:
        DB 'CASE BDOS-FILE-004-P0236',13,10,'LEDGER 0236',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-021',13,10
        DB 'ORACLE OR-0236',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Exact 128-record boundary is followed by nonzero EOF.',13,10,'$'
C237MSG:
        DB 'CASE BDOS-FILE-004-P0237',13,10,'LEDGER 0237',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-022',13,10
        DB 'ORACLE OR-0237',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Two consecutive reads after exhaustion are both nonzero.',13,10,'$'
C238MSG:
        DB 'CASE BDOS-FILE-004-P0238',13,10,'LEDGER 0238',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-023',13,10
        DB 'ORACLE OR-0238',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Failed-read DMA is observed without literal-content rule.',13,10,'$'
C239MSG:
        DB 'CASE BDOS-FILE-004-P0239',13,10,'LEDGER 0239',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-024',13,10
        DB 'ORACLE OR-0239',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Working FCB changes coherently through three reads.',13,10,'$'
C240MSG:
        DB 'CASE BDOS-FILE-004-P0240',13,10,'LEDGER 0240',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-025',13,10
        DB 'ORACLE OR-0240',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Failed-read FCB is observed without byte-identity rule.',13,10,'$'
C242MSG:
        DB 'CASE BDOS-FILE-004-P0242',13,10,'LEDGER 0242',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-027',13,10
        DB 'ORACLE OR-0242',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Explicit-drive marked read succeeds; default unchanged.',13,10,'$'
C243MSG:
        DB 'CASE BDOS-FILE-004-P0243',13,10,'LEDGER 0243',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE SEQ-028',13,10
        DB 'ORACLE OR-0243',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Read-only file opens and its marked record reads.',13,10,'$'
C248MSG:
        DB 'CASE BDOS-FILE-005-P0248',13,10,'LEDGER 0248',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE MAK-001',13,10
        DB 'ORACLE OR-0248',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 22 uses DE-selected FCB and returns success.',13,10,'$'
C249MSG:
        DB 'CASE BDOS-FILE-005-P0249',13,10,'LEDGER 0249',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE MAK-002',13,10
        DB 'ORACLE OR-0249',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Reserved name is absent before Make and creation succeeds.',13,10,'$'
C250MSG:
        DB 'CASE BDOS-FILE-005-P0250',13,10,'LEDGER 0250',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE MAK-003',13,10
        DB 'ORACLE OR-0250',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED New empty file reopens and its first read is nonzero.',13,10,'$'
C251MSG:
        DB 'CASE BDOS-FILE-005-P0251',13,10,'LEDGER 0251',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE MAK-004',13,10
        DB 'ORACLE OR-0251',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Successful Make activates the guarded working FCB.',13,10,'$'
C252MSG:
        DB 'CASE BDOS-FILE-005-P0252',13,10,'LEDGER 0252',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE MAK-005',13,10
        DB 'ORACLE OR-0252',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Make of unique reserved name returns a non-FF result.',13,10,'$'
C254MSG:
        DB 'CASE BDOS-FILE-005-P0254',13,10,'LEDGER 0254',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE MAK-007',13,10
        DB 'ORACLE OR-0254',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Newly made empty file is immediately open-visible.',13,10,'$'
C259MSG:
        DB 'CASE BDOS-FILE-005-P0259',13,10,'LEDGER 0259',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE WRI-001',13,10
        DB 'ORACLE OR-0259',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 21 writes through the DE-selected activated FCB.',13,10,'$'
C260MSG:
        DB 'CASE BDOS-FILE-011-P0260',13,10,'LEDGER 0260',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE WRI-002',13,10
        DB 'ORACLE OR-0260',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Sequential write follows successful FCB activation.',13,10,'$'
C261MSG:
        DB 'CASE BDOS-FILE-005-P0261',13,10,'LEDGER 0261',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE WRI-003',13,10
        DB 'ORACLE OR-0261',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Write at CR zero succeeds and advances CR to one.',13,10,'$'
C262MSG:
        DB 'CASE BDOS-FILE-011-P0262',13,10,'LEDGER 0262',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE WRI-004',13,10
        DB 'ORACLE OR-0262',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Successful sequential write returns 00h.',13,10,'$'
C263MSG:
        DB 'CASE BDOS-FILE-005-P0263',13,10,'LEDGER 0263',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE WRI-005',13,10
        DB 'ORACLE OR-0263',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Write persists one complete 128-byte record.',13,10,'$'
C264MSG:
        DB 'CASE BDOS-FILE-011-P0264',13,10,'LEDGER 0264',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE WRI-006',13,10
        DB 'ORACLE OR-0264',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Current DMA supplies all bytes of the written record.',13,10,'$'
C266MSG:
        DB 'CASE BDOS-FILE-011-P0266',13,10,'LEDGER 0266',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE WRI-008',13,10
        DB 'ORACLE OR-0266',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Successful write advances CR from zero to one.',13,10,'$'
C267MSG:
        DB 'CASE BDOS-FILE-005-P0267',13,10,'LEDGER 0267',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE WRI-009',13,10
        DB 'ORACLE OR-0267',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED First write extends the extent record count.',13,10,'$'
C268MSG:
        DB 'CASE BDOS-FILE-011-P0268',13,10,'LEDGER 0268',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE WRI-010',13,10
        DB 'ORACLE OR-0268',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Rewriting CR zero replaces the existing record.',13,10,'$'
C269MSG:
        DB 'CASE BDOS-FILE-005-P0269',13,10,'LEDGER 0269',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE WRI-011',13,10
        DB 'ORACLE OR-0269',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED First write allocates storage on demand and persists.',13,10,'$'
C271MSG:
        DB 'CASE BDOS-FILE-002-P0271',13,10,'LEDGER 0271',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE WRI-013',13,10
        DB 'ORACLE OR-0271',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Sequential writing crosses automatically into extent one.',13,10,'$'
C272MSG:
        DB 'CASE BDOS-FILE-005-P0272',13,10,'LEDGER 0272',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE WRI-014',13,10
        DB 'ORACLE OR-0272',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Successful transition leaves EX=01h and CR=01h.',13,10,'$'
C273MSG:
        DB 'CASE BDOS-FILE-011-P0273',13,10,'LEDGER 0273',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE WRI-015',13,10
        DB 'ORACLE OR-0273',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Full record at the extent transition remains successful.',13,10,'$'
C274MSG:
        DB 'CASE BDOS-FILE-002-P0274',13,10,'LEDGER 0274',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE WRI-016',13,10
        DB 'ORACLE OR-0274',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Write beyond maximum sequential extent is nonzero.',13,10,'$'
C278MSG:
        DB 'CASE BDOS-FILE-005-P0278',13,10,'LEDGER 0278',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE WRI-020',13,10
        DB 'ORACLE OR-0278',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Explicit-drive Make/write succeeds; default unchanged.',13,10,'$'
C279MSG:
        DB 'CASE BDOS-FILE-011-P0279',13,10,'LEDGER 0279',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE WRI-021',13,10
        DB 'ORACLE OR-0279',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Close commits written metadata for reopen and read.',13,10,'$'
C317MSG:
        DB 'CASE BDOS-FILE-007-P0317',13,10,'LEDGER 0317',13,10
        DB 'PARENT BDOS-FILE-007',13,10,'MODULE_CASE RAN-001',13,10
        DB 'ORACLE OR-0317',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random record fields occupy FCB bytes 33 through 35.',13,10,'$'
C318MSG:
        DB 'CASE BDOS-FILE-008-P0318',13,10,'LEDGER 0318',13,10
        DB 'PARENT BDOS-FILE-008',13,10,'MODULE_CASE RAN-002',13,10
        DB 'ORACLE OR-0318',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random record number is little-endian.',13,10,'$'
C319MSG:
        DB 'CASE BDOS-FILE-009-P0319',13,10,'LEDGER 0319',13,10
        DB 'PARENT BDOS-FILE-009',13,10,'MODULE_CASE RAN-003',13,10
        DB 'ORACLE OR-0319',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED CP/M 2.2 random range includes record 65535.',13,10,'$'
C320MSG:
        DB 'CASE BDOS-FILE-006-P0320',13,10,'LEDGER 0320',13,10
        DB 'PARENT BDOS-FILE-006',13,10,'MODULE_CASE RAN-004',13,10
        DB 'ORACLE OR-0320',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random field, not distinct CR, selects the record.',13,10,'$'
C321MSG:
        DB 'CASE BDOS-FILE-007-P0321',13,10,'LEDGER 0321',13,10
        DB 'PARENT BDOS-FILE-007',13,10,'MODULE_CASE RAN-005',13,10
        DB 'ORACLE OR-0321',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 36 maps the DE-selected FCB state.',13,10,'$'
C322MSG:
        DB 'CASE BDOS-FILE-008-P0322',13,10,'LEDGER 0322',13,10
        DB 'PARENT BDOS-FILE-008',13,10,'MODULE_CASE RAN-006',13,10
        DB 'ORACLE OR-0322',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 36 maps EX=1 CR=1 to random record 129.',13,10,'$'
C323MSG:
        DB 'CASE BDOS-FILE-009-P0323',13,10,'LEDGER 0323',13,10
        DB 'PARENT BDOS-FILE-009',13,10,'MODULE_CASE RAN-007',13,10
        DB 'ORACLE OR-0323',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED EX=1 CR=0 is equivalent to random record 128.',13,10,'$'
C324MSG:
        DB 'CASE BDOS-FILE-006-P0324',13,10,'LEDGER 0324',13,10
        DB 'PARENT BDOS-FILE-006',13,10,'MODULE_CASE RAN-008',13,10
        DB 'ORACLE OR-0324',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 36 computes fields without file I/O.',13,10,'$'
C326MSG:
        DB 'CASE BDOS-FILE-008-P0326',13,10,'LEDGER 0326',13,10
        DB 'PARENT BDOS-FILE-008',13,10,'MODULE_CASE RAN-010',13,10
        DB 'ORACLE OR-0326',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 33 uses DE-selected FCB random fields.',13,10,'$'
C327MSG:
        DB 'CASE BDOS-FILE-009-P0327',13,10,'LEDGER 0327',13,10
        DB 'PARENT BDOS-FILE-009',13,10,'MODULE_CASE RAN-011',13,10
        DB 'ORACLE OR-0327',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random read transfers to the current DMA.',13,10,'$'
C328MSG:
        DB 'CASE BDOS-FILE-006-P0328',13,10,'LEDGER 0328',13,10
        DB 'PARENT BDOS-FILE-006',13,10,'MODULE_CASE RAN-012',13,10
        DB 'ORACLE OR-0328',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Allocated random read returns 00h.',13,10,'$'
C329MSG:
        DB 'CASE BDOS-FILE-007-P0329',13,10,'LEDGER 0329',13,10
        DB 'PARENT BDOS-FILE-007',13,10,'MODULE_CASE RAN-013',13,10
        DB 'ORACLE OR-0329',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random record one selects marked record one.',13,10,'$'
C330MSG:
        DB 'CASE BDOS-FILE-008-P0330',13,10,'LEDGER 0330',13,10
        DB 'PARENT BDOS-FILE-008',13,10,'MODULE_CASE RAN-014',13,10
        DB 'ORACLE OR-0330',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Repeated random read does not advance random position.',13,10,'$'
C331MSG:
        DB 'CASE BDOS-FILE-009-P0331',13,10,'LEDGER 0331',13,10
        DB 'PARENT BDOS-FILE-009',13,10,'MODULE_CASE RAN-015',13,10
        DB 'ORACLE OR-0331',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random read beyond written records is nonzero.',13,10,'$'
C332MSG:
        DB 'CASE BDOS-FILE-006-P0332',13,10,'LEDGER 0332',13,10
        DB 'PARENT BDOS-FILE-006',13,10,'MODULE_CASE RAN-016',13,10
        DB 'ORACLE OR-0332',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random read of missing extent is nonzero.',13,10,'$'
C333MSG:
        DB 'CASE BDOS-FILE-007-P0333',13,10,'LEDGER 0333',13,10
        DB 'PARENT BDOS-FILE-007',13,10,'MODULE_CASE RAN-017',13,10
        DB 'ORACLE OR-0333',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random record above CP/M 2.2 range is nonzero.',13,10,'$'
C335MSG:
        DB 'CASE BDOS-FILE-009-P0335',13,10,'LEDGER 0335',13,10
        DB 'PARENT BDOS-FILE-009',13,10,'MODULE_CASE RAN-019',13,10
        DB 'ORACLE OR-0335',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 34 writes through DE-selected FCB fields.',13,10,'$'
C336MSG:
        DB 'CASE BDOS-FILE-006-P0336',13,10,'LEDGER 0336',13,10
        DB 'PARENT BDOS-FILE-006',13,10,'MODULE_CASE FIL-113',13,10
        DB 'ORACLE OR-0336',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random write transfers and persists all 128 DMA bytes.',13,10,'$'
C337MSG:
        DB 'CASE BDOS-FILE-007-P0337',13,10,'LEDGER 0337',13,10
        DB 'PARENT BDOS-FILE-007',13,10,'MODULE_CASE FIL-114',13,10
        DB 'ORACLE OR-0337',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Successful Function 34 returns 00h.',13,10,'$'
C338MSG:
        DB 'CASE BDOS-FILE-008-P0338',13,10,'LEDGER 0338',13,10
        DB 'PARENT BDOS-FILE-008',13,10,'MODULE_CASE FIL-115',13,10
        DB 'ORACLE OR-0338',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random write allocates a new file record.',13,10,'$'
C339MSG:
        DB 'CASE BDOS-FILE-009-P0339',13,10,'LEDGER 0339',13,10
        DB 'PARENT BDOS-FILE-009',13,10,'MODULE_CASE FIL-116',13,10
        DB 'ORACLE OR-0339',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random write across holes persists the selected record.',13,10,'$'
C340MSG:
        DB 'CASE BDOS-FILE-006-P0340',13,10,'LEDGER 0340',13,10
        DB 'PARENT BDOS-FILE-006',13,10,'MODULE_CASE FIL-117',13,10
        DB 'ORACLE OR-0340',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random write through record two extends virtual length.',13,10,'$'
C341MSG:
        DB 'CASE BDOS-FILE-007-P0341',13,10,'LEDGER 0341',13,10
        DB 'PARENT BDOS-FILE-007',13,10,'MODULE_CASE FIL-118',13,10
        DB 'ORACLE OR-0341',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random write leaves coherent working extent fields.',13,10,'$'
C342MSG:
        DB 'CASE BDOS-FILE-008-P0342',13,10,'LEDGER 0342',13,10
        DB 'PARENT BDOS-FILE-008',13,10,'MODULE_CASE FIL-119',13,10
        DB 'ORACLE OR-0342',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random write does not advance the random record field.',13,10,'$'
C343MSG:
        DB 'CASE BDOS-FILE-009-P0343',13,10,'LEDGER 0343',13,10
        DB 'PARENT BDOS-FILE-009',13,10,'MODULE_CASE FIL-120',13,10
        DB 'ORACLE OR-0343',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random write does not switch sequential extent state.',13,10,'$'
C344MSG:
        DB 'CASE BDOS-FILE-006-P0344',13,10,'LEDGER 0344',13,10
        DB 'PARENT BDOS-FILE-006',13,10,'MODULE_CASE FIL-121',13,10
        DB 'ORACLE OR-0344',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Close commits random-written data for reopen and read.',13,10,'$'
C345MSG:
        DB 'CASE BDOS-FILE-007-P0345',13,10,'LEDGER 0345',13,10
        DB 'PARENT BDOS-FILE-007',13,10,'MODULE_CASE FIL-122',13,10
        DB 'ORACLE OR-0345',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random write beyond CP/M 2.2 extent range is nonzero.',13,10,'$'
C346MSG: DB 'CASE BDOS-FILE-008-P0346',13,10,'LEDGER 0346',13,10
        DB 'PARENT BDOS-FILE-008',13,10,'MODULE_CASE FIL-123',13,10
        DB 'ORACLE OR-0346',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Allocation-full random write returns exact code 02h.',13,10,'$'
C347MSG: DB 'CASE BDOS-FILE-009-P0347',13,10,'LEDGER 0347',13,10
        DB 'PARENT BDOS-FILE-009',13,10,'MODULE_CASE FIL-124',13,10
        DB 'ORACLE OR-0347',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 35 uses the DE-selected FCB.',13,10,'$'
C348MSG: DB 'CASE BDOS-FILE-006-P0348',13,10,'LEDGER 0348',13,10
        DB 'PARENT BDOS-FILE-006',13,10,'MODULE_CASE FIL-125',13,10
        DB 'ORACLE OR-0348',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 35 returns size in FCB bytes 33-35.',13,10,'$'
C349MSG: DB 'CASE BDOS-FILE-007-P0349',13,10,'LEDGER 0349',13,10
        DB 'PARENT BDOS-FILE-007',13,10,'MODULE_CASE FIL-126',13,10
        DB 'ORACLE OR-0349',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 35 size unit is one 128-byte record.',13,10,'$'
C350MSG: DB 'CASE BDOS-FILE-008-P0350',13,10,'LEDGER 0350',13,10
        DB 'PARENT BDOS-FILE-008',13,10,'MODULE_CASE FIL-127',13,10
        DB 'ORACLE OR-0350',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 35 represents the controlled 130-record size.',13,10,'$'
C351MSG: DB 'CASE BDOS-FILE-009-P0351',13,10,'LEDGER 0351',13,10
        DB 'PARENT BDOS-FILE-009',13,10,'MODULE_CASE FIL-128',13,10
        DB 'ORACLE OR-0351',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Sparse write at record two gives virtual size three.',13,10,'$'
C368MSG: DB 'CASE BDOS-FILE-006-P0368',13,10,'LEDGER 0368',13,10
        DB 'PARENT BDOS-FILE-006',13,10,'MODULE_CASE FIL-131',13,10
        DB 'ORACLE OR-0368',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Sequential write to file read-only fixture is rejected.',13,10,'$'
C369MSG: DB 'CASE BDOS-FILE-007-P0369',13,10,'LEDGER 0369',13,10
        DB 'PARENT BDOS-FILE-007',13,10,'MODULE_CASE FIL-132',13,10
        DB 'ORACLE OR-0369',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Random write to file read-only fixture is rejected.',13,10,'$'
C550MSG: DB 'CASE BDOS-FILE-011-P0550',13,10,'LEDGER 0550',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE FIL-135',13,10
        DB 'ORACLE OR-0550',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Drive-question search exposes a complete directory entry.',13,10,'$'
C551MSG: DB 'CASE BDOS-FILE-011-P0551',13,10,'LEDGER 0551',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE FIL-136',13,10
        DB 'ORACLE OR-0551',13,10,'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Made file closes and reopens through ordinary lifecycle.',13,10,'$'
C163MSG: DB 'CASE BDOS-FILE-001-P0163',13,10,'LEDGER 0163',13,10
        DB 'PARENT BDOS-FILE-001',13,10,'MODULE_CASE FIL-008',13,10
        DB 'ORACLE OR-0163',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe reserved FCB byte 13 after Open.',13,10,'$'
C182MSG: DB 'CASE BDOS-FILE-002-P0182',13,10,'LEDGER 0182',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-027',13,10
        DB 'ORACLE OR-0182',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe format-dependent allocation state.',13,10,'$'
C183MSG: DB 'CASE BDOS-FILE-001-P0183',13,10,'LEDGER 0183',13,10
        DB 'PARENT BDOS-FILE-001',13,10,'MODULE_CASE FIL-028',13,10
        DB 'ORACLE OR-0183',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe FCB state after failed Open.',13,10,'$'
C244MSG: DB 'CASE BDOS-FILE-004-P0244',13,10,'LEDGER 0244',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE FIL-058',13,10
        DB 'ORACLE OR-0244',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe sequential read on unopened FCB.',13,10,'$'
C245MSG: DB 'CASE BDOS-FILE-004-P0245',13,10,'LEDGER 0245',13,10
        DB 'PARENT BDOS-FILE-004',13,10,'MODULE_CASE FIL-059',13,10
        DB 'ORACLE OR-0245',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe invalid/unactivated FCB result.',13,10,'$'
C256MSG: DB 'CASE BDOS-FILE-011-P0256',13,10,'LEDGER 0256',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE FIL-068',13,10
        DB 'ORACLE OR-0256',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe Make on an existing name.',13,10,'$'
C257MSG: DB 'CASE BDOS-FILE-005-P0257',13,10,'LEDGER 0257',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE FIL-069',13,10
        DB 'ORACLE OR-0257',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe Make with ambiguous name.',13,10,'$'
C265MSG: DB 'CASE BDOS-FILE-005-P0265',13,10,'LEDGER 0265',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE FIL-077',13,10
        DB 'ORACLE OR-0265',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe final byte of partial record.',13,10,'$'
C270MSG: DB 'CASE BDOS-FILE-011-P0270',13,10,'LEDGER 0270',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE FIL-082',13,10
        DB 'ORACLE OR-0270',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe allocation chosen for new file.',13,10,'$'
C277MSG: DB 'CASE BDOS-FILE-002-P0277',13,10,'LEDGER 0277',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-087',13,10
        DB 'ORACLE OR-0277',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe write through unactivated FCB.',13,10,'$'
C280MSG: DB 'CASE BDOS-FILE-002-P0280',13,10,'LEDGER 0280',13,10
        DB 'PARENT BDOS-FILE-002',13,10,'MODULE_CASE FIL-090',13,10
        DB 'ORACLE OR-0280',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe dirty working FCB before cleanup.',13,10,'$'
C281MSG: DB 'CASE BDOS-FILE-005-P0281',13,10,'LEDGER 0281',13,10
        DB 'PARENT BDOS-FILE-005',13,10,'MODULE_CASE FIL-091',13,10
        DB 'ORACLE OR-0281',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe pre-Close working metadata.',13,10,'$'
C325MSG: DB 'CASE BDOS-FILE-007-P0325',13,10,'LEDGER 0325',13,10
        DB 'PARENT BDOS-FILE-007',13,10,'MODULE_CASE FIL-102',13,10
        DB 'ORACLE OR-0325',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe Function 36 return in A.',13,10,'$'
C334MSG: DB 'CASE BDOS-FILE-008-P0334',13,10,'LEDGER 0334',13,10
        DB 'PARENT BDOS-FILE-008',13,10,'MODULE_CASE FIL-111',13,10
        DB 'ORACLE OR-0334',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe DMA after failed random read.',13,10,'$'
C352MSG: DB 'CASE BDOS-FILE-006-P0352',13,10,'LEDGER 0352',13,10
        DB 'PARENT BDOS-FILE-006',13,10,'MODULE_CASE FIL-129',13,10
        DB 'ORACLE OR-0352',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe Function 35 return in A.',13,10,'$'
C372MSG: DB 'CASE BDOS-FILE-006-P0372',13,10,'LEDGER 0372',13,10
        DB 'PARENT BDOS-FILE-006',13,10,'MODULE_CASE FIL-133',13,10
        DB 'ORACLE OR-0372',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: inspect protected fixture activation.',13,10,'$'
C388MSG: DB 'CASE BDOS-FILE-006-P0388',13,10,'LEDGER 0388',13,10
        DB 'PARENT BDOS-FILE-006',13,10,'MODULE_CASE FIL-134',13,10
        DB 'ORACLE OR-0388',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: inspect late attribute/working FCB state.',13,10,'$'
C552MSG: DB 'CASE BDOS-FILE-011-P0552',13,10,'LEDGER 0552',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE FIL-137',13,10
        DB 'ORACLE OR-0552',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: observe working FCB allocation metadata.',13,10,'$'
C554MSG: DB 'CASE BDOS-FILE-011-P0554',13,10,'LEDGER 0554',13,10
        DB 'PARENT BDOS-FILE-011',13,10,'MODULE_CASE FIL-139',13,10
        DB 'ORACLE OR-0554',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
        DB 'EXPECTED Diagnostic only: compare allocation byte across Opens.',13,10,'$'
MSG_CASE_BEGIN:
        DB 'CASE BDOS-FILE-001-P0171',13,10
        DB 'LEDGER 0171',13,10
        DB 'PARENT BDOS-FILE-001',13,10
        DB 'MODULE_CASE OPE-004',13,10
        DB 'ORACLE OR-0171',13,10
        DB 'ORACLE_VERSION 1.0.0',13,10
        DB 'EXPECTED Function 15 on absent BTMISS.DAT returns FFh in A.',13,10,'$'
MSG_PASS:       DB 'RESULT PASS',13,10,'$'
MSG_FAIL:       DB 'RESULT FAIL',13,10,'$'
MSG_ERROR:      DB 'RESULT ERROR',13,10,'$'
MSG_DOBS:       DB 'RESULT OBSERVATION',13,10,'$'
CTITLE:         DB 13,10,'FILETEST',13,10
                DB 'STATUS: P=Pass F=Fail -=Not-run O=Observed',13,10
                DB 'CLASS:  R=Required N=Not-guaranteed S=Out-of-scope',13,10
                DB 'ITEM  S  C  OBSERVED',13,10
                DB '----  -  -  ----------------------------------------------------------',13,10,'$'
CSEP:           DB '  ','$'
CDREQ:          DB 'R  ','$'
CDNOTG:         DB 'N  ','$'
CSFVALUE:       DB 'Result=','$'
CS2VALUE:       DB '; FCB/state=','$'
CSFOPEN:        DB 'Prereq/Open=','$'
CS2OPEN:        DB '; FCB/I/O state=','$'
CSFREAD:        DB 'Prereq/Open=','$'
CS2READ:        DB '; read/state=','$'
CSFWRITE:       DB 'Prereq=','$'
CS2WRITE:       DB '; Make/write=','$'
CSFRANDOM:      DB 'Prereq/Open=','$'
CS2RANDOM:      DB '; random-I/O=','$'
CSFLIFE:        DB 'Prereq=','$'
CS2LIFE:        DB '; lifecycle=','$'
CF165A:         DB 'Open=','$'
CF165B:         DB '; RC=','$'
CF167A:         DB 'Read returns=00,00,00; CR=','$'
CF167F:         DB 'Open=','$'
CF167G:         DB '; failing read/state=','$'
CF169A:         DB 'Current=','$'
CF169B:         DB '; explicit=','$'
CF169C:         DB '; drive ','$'
CF169D:         DB '->','$'
CF171A:         DB 'Open=','$'
CF171B:         DB '; FCB guards unchanged','$'
CF171E:         DB '; FCB guard corruption','$'
CSTPASS:        DB 'P  ','$'
CSTFAIL:        DB 'F  ','$'
CSTERR:         DB 'F  ','$'
CSTOBS:         DB 'O  ','$'
CSTNOT:         DB '-  ','$'
CROSSMISS:      DB 'Required C: BTBFILE.DAT fixture unavailable','$'
CSUMPASS:       DB 13,10,'Summary: 1 pass, 0 fail, 0 error',13,10
                DB 'Details: FILETEST /NNNN:REPORT    Help: FILETEST /HELP',13,10,'$'
CSUMFAIL:       DB 13,10,'Summary: 0 pass, 1 fail, 0 error',13,10
                DB 'Details: FILETEST /NNNN:REPORT    Help: FILETEST /HELP',13,10,'$'
CSUMERR:        DB 13,10,'Summary: 0 pass, 0 fail, 1 error',13,10
                DB 'Details: FILETEST /NNNN:REPORT    Help: FILETEST /HELP',13,10,'$'
CSUMOBS:        DB 13,10,'Summary: 1 observation, no conformance effect',13,10
                DB 'Details: FILETEST /NNNN:REPORT    Help: FILETEST /HELP',13,10,'$'
CSUMNOTRUN:     DB 13,10,'Summary: 0 pass, 0 fail, 0 error, 1 not-run',13,10
                DB 'Prepare C: with SCRATCH /CROSS and retry.',13,10,'$'
CSUM1:          DB 13,10,'Summary: ','$'
CSUM2:          DB ' pass, ','$'
CSUM3:          DB ' fail, ','$'
CSUM4:          DB ' error, ','$'
CSUM5:          DB '$'
CSUM6:          DB ' observations, ','$'
CSUM7:          DB ' not-run',13,10
                DB 'Details: FILETEST /NNNN:REPORT    Help: FILETEST /HELP',13,10,'$'
MSG_OBS:        DB 'OBSERVED Function 15 returned ','$'
MSG_NOTRUN:     DB 'STATUS NOT-RUN',13,10
                DB 'REASON Required C: BTBFILE.DAT fixture unavailable.',13,10,'$'
MC002:          DB 'CODE C002',13,10,'$'
MC003:          DB 'CODE C003',13,10,'$'
MC004:          DB 'CODE C004',13,10,'$'
MC006:          DB 'CODE C006',13,10,'$'
ME005:          DB 'CODE E005',13,10,'REASON FCB guard corruption detected.',13,10,'$'
MSG_EVIDENCE:   DB 'EVIDENCE Return value and 8-byte FCB guards before/after.',13,10,'$'
O165A:          DB 'OBSERVED Open returned ','$'
O165B:          DB '; FCB byte 15 RC=','$'
E165MSG:
        DB 'EVIDENCE RC read at offset 15 after Open; accepted range 00-80; FCB guards.',13,10,'$'
O169A:          DB 'OBSERVED current-drive Open returned ','$'
O169B:          DB '; explicit-drive Open returned ','$'
O169C:          DB '; drive before ','$'
O169D:          DB ', after ','$'
E169MSG:
        DB 'EVIDENCE Two Function-15 returns, current-drive snapshots, and FCB guards.',13,10,'$'
NOBS1:          DB 'OBSERVED prerequisite/Open return ','$'
NOBS2:          DB '; operation/state ','$'
DOBS1:          DB 'OBSERVED value-1 ','$'
DOBS2:          DB '; value-2 ','$'
NEVID:
        DB 'EVIDENCE Independent BDOS returns, FCB/DMA guards, state and record marker.',13,10,'$'
DIAGEVID:
        DB 'EVIDENCE Characterization only; observed values have no portable pass/fail oracle.',13,10,'$'
MENDP:
        DB 'END_CASE',13,10,13,10
        DB 'SUMMARY 1 PASS, 0 FAIL, 0 BLOCKED, 0 ERROR',13,10
        DB 'COMPLETE_FOR_REQUESTED_SCOPE YES',13,10,'$'
MENDF:
        DB 'END_CASE',13,10,13,10
        DB 'SUMMARY 0 PASS, 1 FAIL, 0 BLOCKED, 0 ERROR',13,10
        DB 'COMPLETE_FOR_REQUESTED_SCOPE YES',13,10,'$'
MENDE:
        DB 'END_CASE',13,10,13,10
        DB 'SUMMARY 0 PASS, 0 FAIL, 0 BLOCKED, 1 ERROR',13,10
        DB 'COMPLETE_FOR_REQUESTED_SCOPE NO',13,10,'$'
MENDOBS:
        DB 'END_CASE',13,10,13,10
        DB 'SUMMARY 0 PASS, 0 FAIL, 0 BLOCKED, 0 ERROR, 1 OBSERVATION',13,10
        DB 'COMPLETE_FOR_REQUESTED_SCOPE YES',13,10
        DB 'CONFORMANCE_EFFECT NONE',13,10,'$'
ENDONLY: DB 'END_CASE',13,10,13,10,'$'
MENDNOTRUN:
        DB 'END_CASE',13,10,13,10
        DB 'SUMMARY 0 PASS, 0 FAIL, 0 BLOCKED, 0 ERROR, 1 NOT-RUN',13,10
        DB 'COMPLETE_FOR_REQUESTED_SCOPE NO',13,10,'$'
SUM1:   DB 'SUMMARY ','$'
SUM2:   DB ' PASS, ','$'
SUM3:   DB ' FAIL, 0 BLOCKED, ','$'
SUM4:   DB ' ERROR',13,10,'$'
SUMOBS1: DB 'OBSERVATIONS ','$'
SUMOBS2: DB 13,10,'$'
SUMNR1:  DB 'NOT-RUN ','$'
SUMNR2:  DB 13,10,'$'
SUMYES: DB 'COMPLETE_FOR_REQUESTED_SCOPE YES',13,10,'$'
SUMNO:  DB 'COMPLETE_FOR_REQUESTED_SCOPE NO',13,10,'$'

;------------------------- TEST INSTRUMENTS ---------------------------
; Drive, name[8], type[3].  Every BT name is reserved to the suite.  A writing
; card may replace its scratch name; a media builder must never give that name
; to an operator's file.
MISSFCB:    DB 0,'BTMISS  ','DAT'
EMPTYFCB:   DB 0,'BTEMPTY ','DAT'
TEMPFCB:    DB 0,'BTTEMP  ','DAT'
CTEMPFCB:   DB 3,'BTTEMP  ','DAT'
ONEFCB:     DB 0,'BTONE   ','DAT'
NMONE:      DB 'BTONE   '
TYPDAT:     DB 'DAT'
OPENFCB:    DB 0,'BTOPEN  ','DAT'
BFILEFCB:   DB 3,'BTBFILE ','DAT'
FULLFCB:    DB 4,'BTFULL  ','DAT'
DTEMPFCB:   DB 4,'BTTEMP  ','DAT'
MULTIFCB:   DB 0,'BTMULTI ','DAT'
PARTFCB:    DB 0,'BTPART  ','DAT'
BNDFCB:     DB 0,'BTBND128','DAT'
BIGFCB:     DB 0,'BTBIG130','DAT'
ROFCB:      DB 0,'BTRO    ','DAT'
QFCB:       DB 3FH,'???????????'
WILDFCB:    DB 0,'BTWILD? ','DAT'
CLOSEFCB:   DB 0,'BTCLOSE ','DAT'
DECOYFCB:   DB 0,'BTMULTI ','DAT'
            DS 24
MONE:       DB 'ONE'
MMULTI:     DB 'MULTI'
MWILD1:     DB 'WILD1'
MMULTI0:    DB 'MULTI-000'
MMULTI1:    DB 'MULTI-001'
MMULTI2:    DB 'MULTI-002'
MONE8:      DB 'ONE-000 '
MPART0:     DB 'PART-000 '
MBOUND127:  DB 'BOUND-127'
MBIG127:    DB 'BIG-127'
MBIG001:    DB 'BIG-001'
MBIG128:    DB 'BIG-128'
MBIG129:    DB 'BIG-129'
MBFILE:     DB 'BFILE-000'
MFULL127:   DB 'FULL-127'
MRO:        DB 'READONLY-000'
OBSERVED:   DB 0
OBS169A:    DB 0
OBS169B:    DB 0
DRVBEFORE:  DB 0
DRVAFTER:   DB 0
AGGMODE:    DB 0
FULLMODE:   DB 0
PASSCT:     DB 0
FAILCT:     DB 0
ERRCT:      DB 0
OBSCT:      DB 0
NOTRUNCT:   DB 0
PARSEBAD:   DB 0
ROWSTATUS:  DB 0
O165RET:    DB 0
O165RC:     DB 0
NEWOBS1:    DB 0
NEWOBS2:    DB 0
OLDCR:      DB 0
CASEPTR:    DW 0
OBSSEPPTR:  DW 0
DIAGPTR:    DW 0
DIAGLEFT:   DB 0
ARGBUF:     DS 40
GPRE:       DS 8
TESTFCB:    DS 36
GPOST:      DS 8
DPRE:       DS 16
DMABUF:     DS 128
DPOST:      DS 16
            DS 128
STACKTOP:
        END     START
