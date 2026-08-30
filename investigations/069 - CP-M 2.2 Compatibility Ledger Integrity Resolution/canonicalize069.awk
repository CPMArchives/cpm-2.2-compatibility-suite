#!/usr/bin/awk -f

# Investigation 069 canonical ledger transformation.
# Input:  authoritative Investigation 068 ledger.
# Output: canonical Investigation 069 ledger.

function add_sources() {
  print "  I030 - CP-M 2.2 BDOS File Lifecycle, Extent Management, and Metadata State Transition Semantics"
  print "  I031 - CP-M 2.2 BDOS User Area, File Visibility, and Directory Namespace Semantics"
  print "  I032 - CP-M 2.2 CCP Resident Command Semantics and BDOS Interaction"
  print "  I033 - CP-M 2.2 BDOS-BIOS Error Propagation and Recovery Semantics"
  print "  I034 - CP-M 2.2 Memory Layout, System Area, and Transient Program Boundary Semantics"
  print "  I035 - CP-M 2.2 Cold Boot, Warm Boot, and Restart Semantics"
  print "  I036 - CP-M 2.2 BIOS Runtime Environment and Hardware Abstraction Boundary Semantics"
  print "  I037 - CP-M 2.2 BDOS Remaining Functions and Interface Consolidation Semantics"
  print "  I038 - CP-M 2.2 Character Device Runtime Semantics"
  print "  I039 - CP-M 2.2 IOBYTE and Runtime Device Assignment Semantics"
  print "  I040 - CP-M 2.2 Disk Format, Drive Geometry, and Direct Structure Compatibility Semantics"
  print "  I041 - CP-M 2.2 Direct System Access and Undocumented Application Interface Compatibility Semantics"
  print "  I042 - CP-M 2.2 Common Software Compatibility Assumptions"
  print "  I043 - CP-M 2.2 Memory and Execution Edge Case Compatibility Semantics"
  print "  I044 - CP-M 2.2 Failure, Recovery, and Boundary Condition Compatibility Semantics"
  print "  I045 - CP-M 2.2 Cross-Layer Compatibility Boundary Review"
  print "  I046 - CP-M 2.2 Compatibility Boundary Closure and Remaining Gap Analysis"
  print "  I047 - CP-M 2.2 Standard Utility Compatibility Survey"
  print "  I048 - CP-M 2.2 Development Toolchain Compatibility Survey"
  print "  I049 - CP-M 2.2 Application Compatibility Survey"
  print "  I050 - CP-M 2.2 Communications Software Compatibility Survey"
  print "  I051 - CP-M 2.2 Hardware-Dependent Software Compatibility Survey"
  print "  I052 - CP-M 2.2 Compatibility Regression Test Specification"
  print "  I053 - CP-M 2.2 Software Corpus Validation"
  print "  I054 - CP-M 2.2 Undocumented Behavior Validation"
  print "  I055 - CP-M 2.2 Community Compatibility Standard"
  print "  I056 - CP-M 2.2 Compatibility Requirements to Architecture Mapping"
  print "  I057 - CP-M 2.2 Required CP-M Personality Boundary"
  print "  I058 - CP-M 2.2 Non-CP-M BetterCP-M Feature Boundary"
  print "  I059 - CP-M 2.2 Compatibility Conformance Test Suite Design"
  print "  I060 - CP-M 2.2 Compatibility Engineering Gap Assessment"
  print "  I061 - CP-M 2.2 Cross-Implementation Differential Validation"
  print "  I062 - CP-M 2.2 Compatibility Conformance Pilot Execution"
  print "  I063 - CP-M 2.2 Processor and Instruction Profile"
  print "  I064 - CP-M 2.2 Expanded Software Corpus Validation"
  print "  I065 - CP-M 2.2 Communications Profile Validation"
  print "  I066 - CP-M 2.2 Physical Fault and Recovery Validation"
  print "  I067 - CP-M 2.2 Hardware Profile Validation"
  print "  I068 - CP-M 2.2 Final Engineering Gap Assessment"
  print "  I069 - CP-M 2.2 Compatibility Ledger Integrity Resolution"
  print ""
}

function function37_crossref() {
  print "0523. Function 37 state-effect profile scope"
  print ""
  print "      Entry 0435 is the canonical compatibility-status proposition for"
  print "      DRI CP/M 2.2 Function 37. If that optional profile is adopted,"
  print "      Function 37 clears DE-selected A-P drive bits from both login and"
  print "      read-only vectors without changing the current-drive number."
  print ""
  print "      Disposition: POLICY PENDING"
  print ""
  print "      Evidence:    I026; BDOS; I007; I017; IG/AG silence; I027;"
  print "                   I028; I029; I030; I031; entry 0435."
  print ""
  print "      Conformance: If entry 0435 is adopted, test inactive, current,"
  print "                   multiple, and read-only drive bits independently;"
  print "                   otherwise this profile-scoped behavior is inapplicable."
  print ""
}

function processor_entries() {
  print ""
  print "0623. Intel 8080-compatible binary execution baseline"
  print ""
  print "      A generic CP/M 2.2 binary personality shall execute documented"
  print "      Intel 8080 instructions with their documented register, flag,"
  print "      stack, control-flow, and encoding semantics sufficiently to run"
  print "      the CP/M environment and 8080 transient programs."
  print ""
  print "      Disposition: REQUIRED"
  print ""
  print "      Evidence:    I063 PROCESSOR INSTRUCTION PROFILE subsystem IG AG;"
  print "                   sections 4-6 and T01-T03; I064; I067."
  print ""
  print "      Conformance: Run an 8080-only instruction/flag probe and"
  print "                   representative CP/M software on the claimed"
  print "                   execution environment."
  print ""
  print ""
  print "0624. Declared processor-profile instruction semantics"
  print ""
  print "      A configuration advertising a processor profile shall implement"
  print "      the documented instructions and CPU-visible state of that profile"
  print "      while preserving every generic CP/M requirement it inherits. A"
  print "      Z80 claim includes its documented extensions and 8080-compatible"
  print "      subset; a processor profile may add but may not waive requirements."
  print ""
  print "      Disposition: REQUIRED"
  print ""
  print "      Evidence:    I063 PROCESSOR INSTRUCTION PROFILE subsystem IG AG;"
  print "                   T03-T05; I064; I067 HARDWARE PROFILE VALIDATION"
  print "                   subsystem IG AG."
  print ""
  print "      Conformance: Test profile-specific instruction families separately"
  print "                   from CP/M service tests, then run the inherited"
  print "                   generic CP/M suite unchanged."
  print ""
  print ""
  print "0625. Z80 extensions outside a generic CP/M claim"
  print ""
  print "      Documented Z80-only instructions and registers are not required by"
  print "      a generic CP/M 2.2 claim that does not advertise a Z80 processor"
  print "      profile."
  print ""
  print "      Disposition: NOT REQUIRED"
  print ""
  print "      Evidence:    I063 PROCESSOR INSTRUCTION PROFILE subsystem IG AG;"
  print "                   DRI source screen and T01-T05; I067."
  print ""
  print "      Conformance: Do not fail a generic 8080-profile implementation"
  print "                   merely because a Z80-only transient cannot execute."
  print ""
  print ""
  print "0626. Undocumented processor behavior"
  print ""
  print "      Undocumented opcodes, undocumented flag bits, and results of"
  print "      instructions outside the selected processor profile are not"
  print "      guaranteed by generic CP/M 2.2."
  print ""
  print "      Disposition: NOT GUARANTEED"
  print ""
  print "      Evidence:    I063 PROCESSOR INSTRUCTION PROFILE subsystem IG AG;"
  print "                   T06-T07; I067."
  print ""
  print "      Conformance: A generic suite may verify permitted variation or"
  print "                   trapping; stronger behavior requires a named profile."
  print ""
  print ""
  print "0627. Processor timing and interrupt topology"
  print ""
  print "      CP/M 2.2 does not require a universal CPU clock, exact instruction"
  print "      timing, wait-state pattern, refresh behavior, or machine interrupt"
  print "      topology."
  print ""
  print "      Disposition: NOT REQUIRED"
  print ""
  print "      Evidence:    I063 PROCESSOR INSTRUCTION PROFILE subsystem IG AG;"
  print "                   section 7 and T08; I051; I065; I067."
  print ""
  print "      Conformance: Test such properties only under a profile that"
  print "                   explicitly advertises them."
  print ""
}

BEGIN { section011=0; skipdup=0; skip0523=0; in0622=0; sources_added=0 }

# Extend the stale source catalogue immediately after its existing I029 row.
/^  I029 -/ {
  print
  if (!sources_added) { add_sources(); sources_added=1 }
  next
}

# Remove the second complete 011 header and its verbatim 0248-0277 block.
/^011 - CP\/M 2\.2 BDOS Sequential Write and File Creation Semantics$/ {
  section011++
  if (section011 == 2) { skipdup=1; next }
}
skipdup && /^0278\. / { skipdup=0; print; next }
skipdup { next }

# Preserve both stable IDs for Function 37 but make 0523 an explicit profile-
# scope cross-reference to canonical policy proposition 0435.
/^0523\. / { function37_crossref(); skip0523=1; next }
skip0523 && /^0524\. / { skip0523=0; print; next }
skip0523 { next }

# Insert canonical 0623-0627 immediately after entry 0622.
/^0622\. / { in0622=1; print; next }
in0622 && /^----------------------------------------------------------------------------$/ {
  processor_entries()
  in0622=0
  print
  next
}

{ print }

END {
  print ""
  print ""
  print "----------------------------------------------------------------------------"
  print ""
  print "069 - CP/M 2.2 Compatibility Ledger Integrity Resolution"
  print ""
  print "----------------------------------------------------------------------------"
  print ""
  print "Investigation 069 produced the canonical ledger by removing the second"
  print "verbatim 0248-0277 block, explicitly cross-referencing the overlapping"
  print "Function-37 policy scopes at 0435 and 0523, and assigning canonical"
  print "identifiers 0623-0627 to the processor propositions evidenced by I063."
  print ""
  print "The resulting numbered proposition sequence is contiguous and unique."
  print "No existing required proposition or evidence history was removed. The"
  print "source catalogue was extended through I069. Detailed before/after and"
  print "disposition audits are preserved in the Investigation 069 artifacts."
}
