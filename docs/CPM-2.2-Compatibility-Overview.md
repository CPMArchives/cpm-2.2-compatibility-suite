# BetterCP/M CP/M 2.2 Compatibility Specification
## Release Candidate 1 — Community Edition

### Introduction

BetterCP/M began with a practical question:

> What does CP/M 2.2 compatibility actually mean?

The obvious answer is "whatever CP/M 2.2 software expects," but that only moves the problem one step back. Which expectations count?

Digital Research documented a substantial part of the operating environment, but not all of the behavior that programmers could observe. The original implementation exhibits details that were never presented as interfaces. Contemporary software sometimes relied on conventions that were never formally specified. Different machines and BIOSes legitimately varied in places where the generic CP/M environment did not.

So the compatibility boundary cannot be recovered from any single source.

Should a behavior count because it appears in a DRI manual? Because it appears in the DRI source? Because every DRI system we can test does it? Because contemporary programming material treated it as normal? Because enough existing software depends on it that omitting it would break otherwise reasonable CP/M programs?

Those are different questions, and BetterCP/M deliberately keeps them separate.

This specification records the compatibility model that resulted from that investigation. It does not claim that every CP/M project must draw the boundary in exactly the same place. It does claim that BetterCP/M should be explicit about where it draws that boundary and why.

### How the compatibility model was developed

The model was developed from several kinds of evidence:

- Digital Research CP/M documentation;
- original CP/M source and binaries where implementation behavior matters;
- historical CP/M software;
- contemporary programming practice and community expectations;
- controlled experiments against identifiable CP/M 2.2 environments;
- implementation and conformance work.

Each source answers a different question.

Documentation establishes the published contract. Source and binaries establish what particular DRI implementations actually did. Experiments establish what a particular reference environment does under controlled conditions. Existing software tells us whether some undocumented behavior became part of the practical software environment.

Agreement among those sources is useful, but silence in one source should not be turned into agreement by inference.

That distinction matters especially with undocumented behavior. An implementation detail may be perfectly stable and perfectly observable without becoming something a compatible replacement is obliged to reproduce. Conversely, a convention may be absent from the manuals yet still matter if enough software came to rely on it.

The point of the investigation was to sort those cases rather than collapse them into a single category called "what CP/M does."

### The Compatibility Ledger

The detailed results are maintained in the Compatibility Ledger.

Each ledger entry isolates one compatibility point and records, as appropriate:

- the behavior under consideration;
- its classification;
- the evidence supporting that classification;
- the BetterCP/M disposition;
- the associated conformance case.

The ledger is intentionally terse. It is a programmer reference, not the place where every argument is re-run in full.

A typical entry may state that a page-zero entry point is REQUIRED, that a particular residual register value is NOT GUARANTEED, or that some machine-specific behavior is OUTSIDE SCOPE. The interesting question is not the underlying CP/M fact; it is why that fact belongs in one category rather than another.

For example, the compatibility question is not whether 0000h performs a warm start but whether every observable consequence of the DRI warm-start path belongs to the contract, or only the behavior software was actually entitled to rely on.

That is the level at which the ledger is meant to operate.

The investigation reports preserve the longer evidentiary trail behind those decisions.

### Compatibility baseline

The BetterCP/M baseline covers the software-visible CP/M 2.2 environment, including:

- transient execution and memory conventions;
- BDOS behavior;
- CCP behavior;
- FCB, DMA, and filesystem semantics;
- documented BIOS interfaces;
- boot and restart behavior;
- processor baseline requirements;
- compatibility-significant ecosystem conventions.

The important boundary is between observable contract and private mechanism.

BetterCP/M is free to use different internal structures, algorithms, component boundaries, storage machinery, or implementation techniques. That freedom ends where an internal difference changes behavior that falls inside the compatibility contract.

This sounds straightforward until a DRI implementation detail leaks across that boundary.

The project therefore does not ask whether BetterCP/M resembles DRI CP/M internally. It asks whether a difference is observable in a way that matters to software, and whether the evidence is strong enough to make that behavior part of the compatibility requirement.

### Profiles and extensions

The baseline deliberately does not absorb every historically observed CP/M behavior.

Some behavior is tied to:

- a particular DRI presentation or command-processor convention;
- a specific device arrangement;
- removable-media handling;
- a machine or BIOS capability;
- an optional extension.

Profiles provide a way to make those stronger or narrower claims without pretending they belong to every CP/M 2.2 implementation.

A profile inherits the baseline and adds requirements. It cannot weaken the baseline.

That distinction is useful because "compatible with CP/M 2.2" and "behaves like this particular DRI environment in these additional respects" are not the same claim.

For example, exact DRI line-editing presentation may matter to a project seeking close DRI fidelity, while another implementation may satisfy the generic CP/M contract without reproducing that presentation exactly. The profile system lets those claims remain explicit instead of smuggling one into the other.

### What this specification is — and is not

This is not an industry standard issued by a standards organization.

It is a compatibility specification developed for BetterCP/M and published for the CP/M community.

That is not an apology for rigor. The project still needs stable propositions, traceable evidence, repeatable tests, and explicit claim boundaries. What it does not need is the fiction that every compatibility judgment is self-evident or universally binding.

There are places where reasonable projects may draw the line differently.

A project interested only in documented CP/M interfaces may reject some de facto ecosystem behavior that BetterCP/M chooses to preserve. A fidelity-oriented project may reproduce DRI details that BetterCP/M leaves outside the generic baseline. A machine-specific implementation may care about behaviors that do not belong in a portable CP/M 2.2 claim at all.

The useful thing is to make those differences visible.

If BetterCP/M says a behavior is required, the evidence and rationale should be recoverable.

If BetterCP/M permits variation, that should be explicit.

If the evidence is unresolved, the project should say so.

### Conformance

The conformance framework exists to connect those compatibility judgments to actual observations.

It defines:

- which ledger propositions are tested;
- how cases map back to those propositions;
- how expected results are interpreted;
- which claims a result gates;
- what evidence is preserved;
- how a campaign can be reproduced and reviewed.

The important point is traceability.

A compatibility claim should not reduce to "we ran some software and it seemed fine." It should be possible to move from a claim to the propositions that define it, from those propositions to the cases that test them, and from those cases to preserved observations produced by a specific candidate in a specific environment.

The framework also keeps failures from disappearing into later success.

If a candidate fails a case, is changed, and later passes it, those are two results, not one corrected history. The later run may supersede the earlier result for certification purposes, but the earlier evidence remains part of the record.

That may look formal, but it is simply the discipline required if somebody other than the original author is expected to reproduce or audit the result.

### Closing

BetterCP/M is not trying to preserve CP/M by freezing one historical implementation in amber.

It is trying to identify the parts of the CP/M 2.2 environment that actually constitute the compatibility contract, preserve those faithfully, and leave implementation freedom everywhere else.

That requires more discrimination than either of the easy approaches:

- "DRI did it, therefore we must do it";
- "DRI did not document it, therefore it cannot matter."

The Compatibility Ledger, policy, profiles, and conformance framework exist to keep the project between those two mistakes.

The result should be a compatibility claim that means something precise to people who already know CP/M well enough to care about the difference.
