# Saba-Hall-Build-Loop: Reflexive Build Protocol

- Status: Draft
- Last Updated: 2026-04-02
- Owners: Saba Core, Avici Working Group
- Related: Saba-Spirit.md, Saba-CCV2.md, Saba-Operations.md, Saba-Conformance.md

## Summary

Saba is self-hosting by design: architecture and code evolution are modeled as debate moves inside the hall.

Normative statement:

1. every significant product change MUST be representable as canonical move lineage
2. implementation is not outside discourse; implementation is one discourse substrate
3. accepted changes SHOULD produce reusable residue artifacts (nucleants/crystals)

## 1) Build Moves as First-Class Debate Moves

The existing move membrane (`assert`, `challenge`, `fork`, `fold`, `crystallize`, etc.) is sufficient, with build-specific intent tags.

Recommended move intent tags:

1. `intent=spec_change`
2. `intent=implementation_change`
3. `intent=architecture_change`
4. `intent=ops_change`

Example flow:

1. `assert` proposed architectural change
2. `challenge` risk and assumptions
3. `fork` implementation alternatives
4. `fold` side branches (`⊚` when complete-for-now)
5. `crystallize` accepted residue into reusable artifact

## 2) Merge Eligibility Contract

A branch is merge-eligible when:

1. claim lineage is complete
2. commitment references resolve
3. replay package reaches at least L0-L2
4. unresolved critical challenges are either conceded or explicitly deferred

## 3) Opacity and Piercing Protocol

Saba allows private substrate reasoning, but authoritative cross-branch claims are pierceable.

Pierce triggers:

1. claim crosses branch boundaries with normative impact
2. claim is used to block/merge/deprecate another branch
3. operator requests audit on policy/safety grounds

Minimum pierce payload:

1. commitment set and parent commitments
2. move lineage (`assert/challenge/reframe/concede` path)
3. replay package L0-L2
4. declared policy and adapter versions

Failure mode:

1. if payload is missing, claim is downgraded to non-authoritative proposal
2. non-authoritative claims cannot force branch inheritance

## 4) Capital Day Profile

Exactly one day per month, Saba runs practical commercial debate mode (for example Coca-Cola vs Pepsi).

Constraints:

1. same lineage and challengeability rules apply
2. no global winner semantics are persisted
3. mandatory crystallization before mode exit

## 5) Output Contract

Each accepted build cycle SHOULD emit:

1. one nucleant summarizing the accepted delta
2. one crystal or explicit defer record
3. provenance links to touched code/spec artifacts
4. replay pointers for audit and onboarding
