# Investigation 073 - Release Assembly and Artifact Synchronization

## 1. Purpose and scope

I073 converts I072's readiness findings into a controlled release assembly plan. It identifies the authoritative inputs, final package contents, owners, creation order, synchronization rules, missing components, and follow-up work. It does not create the release candidate package, modify a compatibility proposition, reopen policy, redefine conformance, or alter BetterCP/M.

The frozen compatibility input is Ledger 072, SHA-256 `eb16466fdbff8fb2bc07bd02a07198b8426fb6452be3dd1f256cbff4af0547d3`.

## 2. Authoritative release inputs

`probes/artifact-inventory.tsv` records 21 source artifacts with full paths, hashes, present roles, and release treatment. Ledger 072 is the normative behavior record. I070 is the policy/profile integration source. I071 is the normative conformance source. I072 is release-readiness evidence. Draft 0.1 policy and strategy files and the current Gopher map are historical/stale release inputs, not current normative authority.

## 3. Release documentation assembly

The proposed package contains nine controlled artifact groups in `release-content-plan.tsv`: compatibility standard, final policy, frozen ledger, conformance specification, profile registry, frozen test/oracle tables, release manifest, publication index, and release notes.

Two are already ready without semantic editing: Ledger 072 and the I071 frozen tables. Seven require creation, promotion, or publication repair. Each has an owner, authoritative inputs, creation plan, and acceptance gate. Historical drafts remain preserved and explicitly superseded; they are not overwritten as if they had always contained the final policy.

## 4. Conformance package preparation

I071 can be published without redesign. The conformance package must include the 62 test identifiers and 627 proposition cases/oracles at version 1.0.0, traceability, certification levels, campaign/result schemas, failure handling, and phases. The public conformance specification explains these artifacts and binds their exact hashes.

Implementation guidance must distinguish specification from execution: runners may combine observations operationally but must emit proposition-level results; successful software cannot replace failed narrow cases; profiles are selected explicitly; BLOCKED/ERROR cannot become PASS; and candidate certification requires preserved campaign evidence.

## 5. Registry and manifest synchronization

`synchronization-matrix.tsv` defines nine cross-document invariants. Ledger identity, proposition IDs, disposition totals, profile applicability, test/case/oracle identity, certification claims, supersession, and publication paths must agree. `release-manifest-schema.tsv` defines the minimum release manifest fields and authority precedence.

The profile registry remains the critical normalization step. It assigns stable IDs/versions and first-RC status while preserving all 28 profile-required and three optional case meanings from Ledger 072/I071. It may organize existing profiles but cannot weaken or expand their propositions.

## 6. Artifact inventory and missing components

The inventory verifies all frozen inputs needed to create the package. `missing-release-components.tsv` identifies seven incomplete groups: final standard, final policy, conformance specification, profile registry, release manifest, publication index, and release notes. No missing component requires new CP/M behavior research.

The current Gopher map remains stale: it points to an absent generic ledger path and labels the compatibility structure incomplete. It is repaired only after the manifest fixes final public paths and authority.

## 7. Historical integrity

Ledger 072 remains unchanged: 627 unique contiguous propositions, 458 REQUIRED, 116 NOT GUARANTEED, 53 NOT REQUIRED, and no POLICY PENDING. Historical ledgers and Draft 0.1 documents remain accessible as historical artifacts. Release metadata must state that they are superseded, avoiding deletion and avoiding ambiguity.

I073 adds no ledger history because the prompt does not authorize a controlled ledger update. It changes no evidence, disposition, applicability, or oracle.

## 8. Ownership and creation order

F073-01 produces the standard, synchronized policy, conformance specification, and profile registry from frozen sources. Its owners are the release standards, policy, conformance, and profile editors. F073-02 follows by creating the release manifest, publication index, release notes, and assembled package. The release engineer and publication maintainer own validation.

F073-03 is later implementation follow-up: implement runners/fixtures and execute a candidate campaign. It is not a prerequisite for publishing a specification RC if release notes clearly state that no product certification is claimed.

## 9. Required follow-up work

`follow-up-work.tsv` defines two controlled release-engineering tasks and one later implementation/certification task. None is a new compatibility investigation. If document production discovers a requested semantic change to a proposition, disposition, profile applicability, or oracle, that change is rejected from assembly and recorded for separately authorized investigation.

## 10. Release assembly conclusion

I073 meets its assembly-planning objective. The release package contents are identified; every component has an owner and creation plan; identifiers, hashes, authority, and cross-document synchronization rules are defined; and the frozen compatibility record is unchanged.

The package itself is not yet assembled. Remaining pre-RC work is limited to controlled release engineering and publication: F073-01 followed by F073-02. BetterCP/M implementation and candidate certification remain separately deferred under F073-03.

Completion review: all required outputs are present; source hashes verify; the ledger remains `eb16466fdbff8fb2bc07bd02a07198b8426fb6452be3dd1f256cbff4af0547d3`; missing artifacts and follow-ups are explicit; no prior investigation or implementation file was modified; and no unsupported certification or compatibility claim is made.
