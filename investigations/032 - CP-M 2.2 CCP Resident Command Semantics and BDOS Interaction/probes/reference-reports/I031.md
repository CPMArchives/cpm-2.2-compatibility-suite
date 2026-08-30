# Investigation 031 - CP/M 2.2 BDOS User Area, File Visibility, and Directory Namespace Semantics

Date: 17 August 2026  
Status: complete evidence report; no ledger, earlier report, or BetterCP/M implementation modified

Evidence classes: A documented; B DRI implementation; I controlled observation; D unresolved policy.

## 1. Objective and scope

This investigation defines user areas as the CP/M 2.2 directory-namespace selector for ordinary searches and file operations. It covers Function 32, Search, Open, Make, Delete, Rename, sequential access, and CCP USER inheritance without treating user areas as directories, permissions, or security domains.

## 2. Relationship to previous investigations

I008 supplies FCB identity and activation, I009/I029 search and DMA, I012 Delete/Rename, I017 directory/allocation representation, I026 live BDOS system state, and I030 file lifecycle. I031 freshly reran I012's controlled user-isolation cases and cross-checked preserved I026/I029 state/search experiments.

## 3. Documentation findings

Function 32 uses C=20h. E=FFh returns the current user number in A; otherwise it sets the current user to E modulo 32. Ordinary CP/M 2.2 file operations implicitly use this current user together with the FCB drive and 8.3 identity. The FCB contains no ordinary user-number field. Directory-entry byte 0 records user 0-31 (E5h denotes free/deleted). Ordinary search filters to current user; the documented special FCB `dr='?'` complete-directory scan bypasses ordinary drive selection and user filtering.

The manuals do not define user areas as access controls, paths, hierarchical directories, or a user-0 public-file fallback.

## 4. BDOS source findings

DRI stores one global `usrcode`, initialized to zero. Function 32 masks setters with 1Fh. `reselect` combines current `usrcode` with the selected/default drive before Open, Make, Search, Delete, Rename, and I/O directory lookup. Thus activated FCB bytes do not capture a user: later operations are interpreted under then-current BDOS user state. DRI search compares the current user byte ordinarily; `dr='?'` sets comparison length zero. These mechanisms are explanatory B evidence; variable locations and routines are NOT REQUIRED.

## 5. User area state behavior

The reference boot began in user 0. Function 32 set/query persisted across unrelated returning BDOS calls and could be restored. Values are reduced modulo 32, so E=32 selects user 0. Current user is independent of current drive and DMA. I026 observed termination-path differences; applications should explicitly set/query required state rather than assume persistence across termination or warm boot.

## 6. File identity behavior

For ordinary BDOS operations, file identity is `(selected drive, current user, 8.3 name/type, extent as applicable)`. Identical names in different user areas are distinct directory objects. No ambiguity is resolved by search order across users because ordinary lookup does not search other users. A name present only elsewhere behaves as absent in the current user.

## 7. Directory visibility behavior

Ordinary exact and wildcard Search First/Next return only current-user matches, and returned DMA entries expose that user in byte 0. Multiple matching entries in the selected user enumerate in directory order. `dr='?'` is the explicit complete-directory exception and can expose other user bytes and free entries. It is not ordinary file lookup and does not create public visibility.

## 8. FCB and user area interaction

The FCB drive byte can override drive selection but cannot override user selection. Open/Make/Delete/Rename and sequential operations apply current BDOS user implicitly. Changing user after activating an FCB does not leave a portable retained-user binding inside that FCB; continued I/O under a different user is not a valid lifecycle assumption. Restore the activating user or reopen in the intended namespace.

## 9. File operation behavior

Open/read found only the current user's identity. Make created a directory entry whose byte 0 was the current user and allowed the same 8.3 name to exist independently elsewhere. User-0 Delete of a user-1-only file returned FFh; user 1 succeeded. Exact and wildcard Delete affected current-user matches only. Rename preserved the user byte and cannot express a cross-user move. Sequential read/write follow the activated lifecycle but still rely on valid current-user context for extent/directory operations.

## 10. Search behavior

A new Search First takes the current user at initialization. Search Next depends on retained global search state and the saved FCB, not a user embedded in the FCB. Changing user during an ordinary sequence destroys portable sequence meaning; start a new Search First after changing user. The special all-user scan deliberately returns directory entries as namespace data rather than opening them across users.

## 11. CCP USER interaction

DRI CCP's `USER n` accepts 0-15 and calls BDOS Function 32. Subsequent resident commands and transient programs observe the same BDOS current-user state. The BDOS interface itself supports 0-31 modulo 32, so the CCP command's smaller accepted range is a CCP policy/interface distinction. USER changes namespace selection, not permissions. Exact command-error text and parser internals are not required.

## 12. Experimental results

Seven named, rebuildable probe views use the freshly rerun comprehensive Delete/Rename/user-switch body and are cross-checked against I026/I029 transcripts:

| Probe | Result |
|---|---|
| USER31 | Function 32 state was live, queryable, persistent across returning calls, and restorable. |
| VIS31 | User-0 lookup did not see a user-1-only target; identical names across users remained distinct. |
| OPEN31 | Open/read resolved only the current-user target; absence in current user returned failure. |
| SEARCH31 | Ordinary search was current-user scoped; `dr='?'` exposed multiple user bytes. |
| CREATE31 | Make/recreate recorded the current user and did not conflict with another user's same name. |
| RENAME31 | Rename changed matching current-user entries and preserved user identity. |
| DELETE31 | User 0 returned FFh for U1FILE; user 1 deleted it successfully; wildcards remained scoped. |

All seven COM files rebuilt byte-identically. Before/after images, fresh raw output, imported reference transcripts, listings, sources, and hashes are preserved.

## 13. Compatibility conclusions

REQUIRED: Function 32 get/set/modulo-32 behavior; current user as implicit ordinary namespace selector; directory user byte; same name may exist independently in different users; ordinary Search/Open/Make/Delete/Rename scope; Rename user preservation; `dr='?'` complete-directory exception; CCP USER using shared BDOS state.

NOT GUARANTEED: cross-user fallback; continuation after changing user; an activated FCB retaining its old user; current-user persistence across termination/warm boot; USER command access to BDOS users 16-31.

NOT REQUIRED: DRI `usrcode` address, comparison routine, CCP packed disk/user variables, exact error text, or any modern security semantics.

POLICY PENDING: whether BetterCP/M offers an explicit nonbaseline public-file or cross-user API; it must not be presented as CP/M 2.2 ordinary lookup.

## 14. Proposed Compatibility Ledger additions

The authoritative I030 ledger ends at 0558.

0559. User area participates in ordinary file identity

    Ordinary CP/M 2.2 identity combines selected drive, current BDOS user, and FCB name/type; identical names in different users are distinct objects.

    Disposition: REQUIRED

    Evidence: I031; BDOS; IG; I008; I012.

    Conformance: create the same 8.3 identity in two users and read distinct content.

0560. Function 32 user-state contract

    Function 32 uses C=20h; E=FFh returns current user and other E values set user modulo 32.

    Disposition: REQUIRED

    Evidence: I031; BDOS; IG; I026.

    Conformance: query, set 1/31/32, query, and restore.

0561. FCB does not carry ordinary user identity

    An ordinary FCB has no user-number field; BDOS applies live current-user state when resolving directory operations.

    Disposition: REQUIRED

    Evidence: I031; BDOS; IG; I008; I026.

    Conformance: hold FCB bytes constant while changing current user and repeat lookup.

0562. Ordinary lookup has no cross-user fallback

    Search and Open failure in the current user do not trigger lookup in user 0 or another user.

    Disposition: REQUIRED

    Evidence: I031; BDOS; IG.

    Conformance: place the target only in another user and require ordinary failure.

0563. Make records current-user ownership

    Successful Make creates its directory entry in the current user and may create a name that independently exists in another user.

    Disposition: REQUIRED

    Evidence: I031; BDOS; IG; I011; I030.

    Conformance: Make the same exact name under two user numbers and inspect entry byte 0.

0564. Delete and Rename are current-user scoped

    Exact and wildcard Delete/Rename modify matching entries in the current user only; Rename preserves their user number.

    Disposition: REQUIRED

    Evidence: I031; BDOS; IG; I012.

    Conformance: operate on duplicate names and verify the other user's entry/content remains.

0565. User change invalidates retained namespace assumptions

    After changing current user, applications may not assume an activated FCB or active ordinary search remains bound to its previous user.

    Disposition: NOT GUARANTEED

    Evidence: I031; BDOS; IG; I026; I029; I030.

    Conformance: require restore/reopen/new Search First after user change.

0566. Complete-directory search is not public lookup

    FCB `dr='?'` may enumerate entries across user numbers, but does not make those files ordinary Open/Delete/Rename targets in the current user.

    Disposition: REQUIRED

    Evidence: I031; BDOS; IG; I009; I029.

    Conformance: enumerate another-user entry then show ordinary Open still fails.

0567. CCP USER and BDOS user state are shared

    CCP USER changes BDOS current-user state inherited by subsequent commands and transients; DRI CCP accepts USER values 0-15 while BDOS supports modulo 32.

    Disposition: REQUIRED

    Evidence: I031; CCP; BDOS; IG; I021; I026.

    Conformance: issue USER, run a transient Function-32 query, and test visibility.

0568. User areas are not a security contract

    CP/M 2.2 user areas provide namespace filtering and do not guarantee permissions, isolation against complete-directory inspection, or modern access control.

    Disposition: NOT REQUIRED

    Evidence: I031; BDOS; IG; AG.

    Conformance: test namespace results without asserting security properties.

## 15. Proposed existing-entry updates

Add I031 evidence without disposition change to FCB entries 0156-0187; Search entries 0188-0218 and 0542-0550; Make/write entries 0248-0284; Delete/Rename entries 0285-0316; system-state entries 0518-0525; and lifecycle entries 0551-0558. Add I031/CCP evidence to the established CCP USER/current-user transient lookup entries. No correction or reclassification is proposed.

## 16. Open questions

1. Should BetterCP/M expose optional public-file/cross-user services outside baseline CP/M 2.2?
2. Which application corpus depends directly on BDOS users 16-31 despite DRI CCP limiting USER to 0-15?
3. Exact outcomes of continuing already-open sequential state after a user change remain deliberately outside the valid lifecycle contract.

## 17. Conformance implications

Tests must create identical names with distinct content in multiple users; query/set/restore Function 32 including modulo boundaries; test exact/wildcard Search, Open/read, Make/write, Delete, and Rename under each user; inspect DMA user bytes; distinguish ordinary and `dr='?'` searches; change user during a search only as a negative test; and exercise CCP USER inheritance without treating namespaces as permissions.

### Preservation audit

The I030 ledger began and ended SHA-256 `b4ec7c5d7b11a7157c5cc488a2574298bd4c64c137ea0f8d174693741ec032a4`. Protected-tree hashes were recorded before creation and verified afterward. Seven ASM/COM/listing sets, source bodies, transcripts, before/after images, rebuild evidence, reference reports, and manifests are present. No ZIP or BetterCP/M implementation change was made.

### Sources

Digital Research, *CP/M 2.0 Interface Guide* (FCB, Search, Open/Make/Delete/Rename, Function 32); Digital Research, *CP/M 2.2 Alteration Guide*; DRI `OS3BDOS.ASM` February 1980 and `OS2CCP.ASM`; I008, I009, I012, I017, I021, I026, I029, I030; z80pack cpmsim 1.39 with DRI CP/M 2.2.
