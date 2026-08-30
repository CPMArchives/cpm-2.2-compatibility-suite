# BetterCP/M CP/M 2.2 Compatibility Standard

## Release Candidate 1 — Version 1.0-rc1

This repository contains the BetterCP/M project's current definition of **CP/M 2.2 compatibility**.

It is the result of the compatibility investigation work that asked a deceptively simple question:

**What does a new implementation actually have to reproduce before we can reasonably call it CP/M 2.2 compatible?**

The answer turns out to involve more than copying a list of BDOS calls from a manual. CP/M software can depend on documented interfaces, stable implementation behavior, programming conventions, hardware-facing interfaces, and—in some cases—behavior Digital Research never formally documented.

The documents and conformance material in this release try to make those boundaries explicit and testable.

### What this release is

Release ID:

`bettercpm-cpm22-standard-1.0-rc1`

This is a **release candidate of the compatibility specification**.

It does **not** contain:

- a BetterCP/M operating-system implementation;
- a completed candidate conformance campaign;
- a conformance certificate;
- or a claim that BetterCP/M or any other implementation has passed the suite.

The purpose of this release is to define the compatibility target and the framework used to test it.

### Where to start

The project is organized around several related documents.

#### Compatibility Standard

The Compatibility Standard gives the overall definition of the CP/M 2.2 compatibility target.

It explains the baseline, profiles, allowed variation, conformance model, and scope of a compatibility claim.

#### Compatibility Ledger

The Compatibility Ledger is the detailed record of the individual CP/M behaviors investigated by the project.

It contains the numbered compatibility propositions and records what is required, what may vary, and what falls outside the compatibility claim.

When there is a disagreement about the meaning or disposition of a numbered compatibility proposition, the ledger is the controlling record.

#### Compatibility Policy

The Compatibility Policy explains how compatibility evidence is evaluated.

It distinguishes among documented behavior, observed Digital Research behavior, de facto software dependencies, implementation accidents, and unresolved questions.

#### Conformance Specification

The Conformance Specification explains how compatibility claims are tested.

It defines the relationship between ledger propositions, conformance cases, expected results, campaign evidence, certification levels, and failure handling.

#### Compatibility Profile Registry

The Compatibility Profile Registry defines the additional named profiles that an implementation may choose to claim beyond the generic CP/M 2.2 baseline.

Profiles can add requirements, but they cannot weaken the baseline.

### The basic idea

The project does not require a new CP/M implementation to reproduce Digital Research's source code or internal design.

What matters is the behavior visible across the compatibility boundary.

At the same time, the project does not assume that the published manuals tell the whole story. If real CP/M software came to depend on stable undocumented behavior, that behavior may also matter.

The goal is therefore neither:

- source-level imitation of Digital Research CP/M;

nor:

- a compatibility definition limited to whatever happened to appear in the manuals.

The goal is a practical, evidence-backed definition of the CP/M 2.2 environment that existing software reasonably expects.

### Release metadata

The release package uses:

- `RELEASE-MANIFEST.tsv` as the authoritative package manifest;
- `PACKAGE-SHA256SUMS` for package integrity;
- `SOURCE-MAP.tsv` to identify the source of each published artifact.

The publication base for this release is:

`/bettercpm/compatibility/releases/BetterCPM-CPM22-Compatibility-Standard-1.0-rc1/`

These files exist to make the release reproducible and auditable. They are not additional compatibility requirements.

### Reproducing the package

The release can be reconstructed from its recorded sources.

To reproduce it:

1. Copy each source identified by `SOURCE-MAP.tsv` byte-for-byte to its designated package path.
2. Generate the four publication metadata files defined by task `F073-02`.
3. Verify the resulting package against `PACKAGE-SHA256SUMS`.

The task evidence preserves the generation and validation records, so an archived ZIP file is not required to establish the contents of the release.

### Status

This is **1.0-rc1**, not the final 1.0 release.

The compatibility propositions and frozen conformance material belong to the release candidate defined by this package. Editorial work may make the documentation clearer, but it must not silently change the underlying compatibility requirements.

The purpose of publishing the release this way is straightforward: someone implementing, testing, or studying CP/M compatibility should be able to determine what is being claimed, why it is required, how it is tested, and what evidence supports the result.
