---
project: peg-fit
title: Peg fit test
status: planned
due: 2026-12-31 # example date
models: [peg-fit]
filament: Bambu Lab PLA Pure
---

# Peg fit test

## Goal

An example project that shows eitri's format: a small plate with a round hole and a peg to push
into it. Each parameter set prints one clearance, so a print of the sets shows which clearance
gives the fit you want.

## Decisions

### peg-fit

- The plate prints flat and the peg stands on its end beside it (example design choice).
- The clearance is per side, as BOSL2's `$slop` is: the hole is the peg diameter plus twice the
  clearance (example design choice).
- The parameter sets `fit-0.1`, `fit-0.2` and `fit-0.3` print clearances 0.1 mm apart, from the
  fit-test rule in eitri's `CLAUDE.md`.
- 15% sparse infill in `peg-fit.slice.json`, since the pieces carry no load (example design
  choice).

## Dimensions

These values are example design choices, not measurements. A real project takes them from the
user, a caliper measurement or a cited source.

| Parameter | Value | Source | Model |
|---|---|---|---|
| Peg diameter | 8 mm | Example design choice | peg-fit |
| Peg length | 10 mm | Example design choice | peg-fit |
| Plate thickness | 5 mm | Example design choice | peg-fit |

## Reference

None.

## Open questions

None.

## The user's words

None: this is an example project.

## Prints

| Date | Model | Set | Result | What the user found |
|---|---|---|---|---|
