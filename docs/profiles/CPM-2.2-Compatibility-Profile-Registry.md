# CP/M 2.2 Compatibility Profile Registry

## Version 1.0-rc1

### 1. What this registry is for

The CP/M 2.2 compatibility baseline deliberately does not require every behavior ever associated with CP/M 2.2.

Some behavior belongs to a particular Digital Research implementation, a particular command processor, a particular device arrangement, a hardware feature, or an optional extension. Those behaviors can still matter for compatibility, but they should not automatically become requirements for every CP/M 2.2 implementation.

That is what compatibility profiles are for.

A profile gives a stable public name to a specific set of additional compatibility requirements already identified in the Compatibility Ledger and the conformance case matrix.

The registry does **not** create new compatibility propositions, merge existing ones, broaden their meaning, or weaken the baseline. It gives already-defined applicability groups stable identifiers that an implementation can claim and test.

### 2. Baseline and profile status

The generic CP/M 2.2 baseline is:

`CPM22-BASE`

Its status is **INCLUDED**.

That means the generic baseline requirements are always part of a CP/M 2.2 compatibility claim. No profile may remove or weaken them.

Every other profile in this release candidate is marked **AVAILABLE**.

AVAILABLE means that the profile has been defined and may be selected in an implementation or certification claim.

It does **not** mean that:

- the feature is implemented by any particular system;
- the feature is enabled by default;
- every CP/M-compatible implementation must provide it;
- or any implementation has already passed certification for it.

An implementation claiming one of these profiles identifies the profile by its stable ID and version and must pass every conformance case mapped to that profile.

Optional profiles remain outside baseline certification unless explicitly claimed.

### 3. How profiles inherit requirements

Every named profile inherits `CPM22-BASE`.

Profiles therefore add requirements. They do not replace the baseline.

If an implementation selects more than one profile, the requirements of all selected profiles are combined.

For example, selecting both a DRI line-editor profile and a BIOS list-device profile means that the implementation must satisfy:

1. all generic `CPM22-BASE` requirements;
2. all cases required by the selected line-editor profile;
3. all cases required by the selected list-device profile.

If two selected profiles genuinely conflict, that is a release-definition error. It must not be resolved by silently weakening a baseline requirement.

### 4. Registered profiles

The following profiles are defined for version 1.0-rc1.

| Profile ID | Title | Kind | Status | Inherits | Mapped cases | What it adds |
| --- | --- | --- | --- | --- | ---: | --- |
| `CPM22-BASE` | Generic CP/M 2.2 baseline | BASELINE | INCLUDED | none | 0 | Universal generic REQUIRED propositions; no profile may waive them. |
| `DRI-CCP-ECO` | Strict DRI CCP/ecosystem | FIDELITY | AVAILABLE | `CPM22-BASE` | 2 | Second default FCB and strict DRI CCP/ecosystem entry behavior. |
| `DRI-CONSOLE` | DRI formatted-console | FIDELITY | AVAILABLE | `CPM22-BASE` | 5 | DRI logical-column and formatted-console exactness. |
| `DRI-LINE` | DRI line-editor | FIDELITY | AVAILABLE | `CPM22-BASE` | 4 | DRI line-editor input and editing behavior. |
| `DRI-LINE-PRES` | DRI line-editor presentation | FIDELITY | AVAILABLE | `CPM22-BASE` | 1 | Exact DRI line-edit correction presentation. |
| `DRI-ERROR-INT` | Interactive DRI error | FIDELITY | AVAILABLE | `CPM22-BASE` | 1 | Interactive DRI error handling where separately named by the ledger. |
| `CPM-DISKERR-INT` | Interactive CP/M disk-error | FIDELITY | AVAILABLE | `CPM22-BASE` | 4 | Operator interaction, abort/ignore, and recovery for physical disk errors. |
| `DRI-PROTECT-INT` | Interactive DRI protection-error | FIDELITY | AVAILABLE | `CPM22-BASE` | 1 | DRI nonreturning interactive protection-error behavior. |
| `DRI-DIAG-PRES` | DRI diagnostic presentation | FIDELITY | AVAILABLE | `CPM22-BASE` | 3 | Exact DRI diagnostic strings and presentation. |
| `REMOVABLE-MEDIA` | Removable-media hardware | HARDWARE | AVAILABLE | `CPM22-BASE` | 1 | Media-change behavior when the declared hardware/BIOS supplies it. |
| `IOBYTE-DEVICE` | IOBYTE logical-device | DEVICE | AVAILABLE | `CPM22-BASE` | 1 | Active IOBYTE logical-device routing. |
| `BIOS-LIST` | BIOS/list-device | DEVICE | AVAILABLE | `CPM22-BASE` | 1 | Declared LIST/list-status device behavior. |
| `DRI-CCP` | Strict DRI CCP | FIDELITY | AVAILABLE | `CPM22-BASE` | 1 | Strict DRI CCP behavior specifically named by the ledger. |
| `DECLARED-CCP` | Declared CCP | CCP | AVAILABLE | `CPM22-BASE` | 1 | A declared CCP accepted-line and command behavior contract. |
| `CCP-LIFECYCLE` | CCP/lifecycle | CCP | AVAILABLE | `CPM22-BASE` | 1 | Declared CCP termination/reentry lifecycle behavior. |
| `DRI-RES-PRES` | DRI resident presentation | FIDELITY | AVAILABLE | `CPM22-BASE` | 1 | Exact DRI resident-command presentation. |
| `EXT-STRUCTERR` | Headless structured-error extension | OPTIONAL | AVAILABLE | `CPM22-BASE` | 1 | Opt-in structured/headless physical-error interface isolated from CP/M paths. |
| `OPT-FN37` | Undocumented Function 37 compatibility | OPTIONAL | AVAILABLE | `CPM22-BASE` | 2 | Opt-in Function 37 behavior and conditional vector effects. |

### 5. What the profile kinds mean

The registry groups profiles by the kind of compatibility they add.

#### BASELINE

`CPM22-BASE` is the generic CP/M 2.2 compatibility foundation.

It is not optional and is inherited by every other profile.

#### FIDELITY

FIDELITY profiles ask for closer reproduction of a specific Digital Research behavior or presentation that is not required by the generic baseline.

Examples include:

- exact CCP behavior;
- Digital Research line editing;
- formatted-console behavior;
- diagnostic presentation;
- interactive error handling.

These profiles are for implementations that want to claim not merely generic CP/M compatibility, but closer fidelity to particular DRI behavior.

#### HARDWARE

HARDWARE profiles apply when compatibility depends on a declared hardware or BIOS capability.

`REMOVABLE-MEDIA`, for example, covers media-change behavior when the selected hardware and BIOS actually provide that facility.

#### DEVICE

DEVICE profiles cover optional or declared device behavior exposed through CP/M interfaces.

The current registry includes:

- `IOBYTE-DEVICE`;
- `BIOS-LIST`.

#### CCP

CCP profiles describe compatibility claims associated with a declared command processor or its lifecycle.

The current registry includes:

- `DECLARED-CCP`;
- `CCP-LIFECYCLE`.

A separate `DRI-CCP` fidelity profile exists for implementations specifically claiming strict Digital Research CCP behavior.

#### OPTIONAL

OPTIONAL profiles describe features that generic CP/M 2.2 compatibility does not require.

The current optional profiles are:

- `EXT-STRUCTERR`;
- `OPT-FN37`.

These become part of a conformance claim only when an implementation explicitly selects them.

### 6. Profile-to-case mapping

The machine-readable normative registry is:

`Compatibility Profile Registry 1.0-rc1.tsv`

The normative profile-to-case mapping is:

`profile-case-map.tsv`

Together they map 31 proposition-level conformance cases:

- 28 PROFILE REQUIRED cases;
- 3 OPTIONAL cases.

Each mapped case appears exactly once in the profile mapping.

The original ledger applicability label is retained in both files so that the framework can be traced back to the exact compatibility proposition from which each profile requirement came.

The Markdown version explains the profile system to human readers. The TSV registry and case map remain the machine-readable normative sources used by the conformance framework.

### 7. What profiles do not do

Profiles are not a way to turn every observable CP/M difference into a compatibility requirement.

In particular, propositions classified as **NOT GUARANTEED** or **OUTSIDE SCOPE** do not become profile requirements merely because an implementation happens to reproduce them.

The undocumented wildcard behavior of Rename remains outside the compatibility claim.

Likewise, support for a particular machine or application is not implied by `CPM22-BASE`.

A machine-, application-, or ecosystem-level compatibility claim requires its own declared profile and supporting evidence.

### 8. How to read a compatibility claim

A useful compatibility claim tells the reader exactly what was tested.

For example:

`CPM22-BASE 1.0-rc1`

means that the implementation claims the generic CP/M 2.2 baseline.

A claim such as:

`CPM22-BASE 1.0-rc1 + DRI-LINE 1.0-rc1 + BIOS-LIST 1.0-rc1`

means that the implementation claims:

- the generic CP/M 2.2 baseline;
- the additional DRI line-editor behavior;
- the declared BIOS LIST/list-status behavior.

The implementation must then pass every applicable generic REQUIRED case plus every case mapped to those selected profiles.

This makes a profile claim explicit rather than leaving readers to guess what "CP/M compatible" is supposed to include.

### 9. The guiding idea

The baseline contains the behavior that defines generic CP/M 2.2 compatibility.

Profiles contain additional behavior that matters only when an implementation deliberately chooses to promise it.

That leaves implementations free to differ where CP/M legitimately differed while still allowing much stronger compatibility claims where those claims are useful.

A profile is therefore neither an escape hatch from the baseline nor a grab bag of interesting historical behavior.

It is a precise additional promise.
