# 0578 — USER baseline range, revision 1.1.0

The baseline requires every USER value 0–15 to select the corresponding shared BDOS user state. Accepting additional user numbers is an extension, not a baseline failure. This replaces the previous oracle that included USER 16 as a rejection case.

The ledger, live oracle/framework tables, executable catalog and CCPTEST /0578 operator procedure agree. Case and oracle versions are now 1.1.0, and the executable reference uses the catalog case ID CCP-004-P0578. Historical investigation/release snapshots remain unchanged.

Run each value 0–15, query BDOS Function 32 (E=FFh) from a transient after each selection, and restore the original user. Record higher values and implementation-specific invalid-input limits separately. This remains an externally observed CCP test; displaying its instructions is not a passing execution.

Previous 0578 results belong to the previous oracle. Do not retroactively relabel historical failures or increment a target's passing count without a new run against this revision.
