---
paths:
  - "**/*.scad"
---

# OpenSCAD models

- **Parameters go at the top**, before the first module, in Customizer form, so they work in the
  OpenSCAD app and on MakerWorld: `/* [Group] */` headers, a description comment above each
  parameter that cites its row in the brief's Dimensions table or names the design choice, and a
  trailing `// [min:step:max]` range. Derived values go under `/* [Hidden] */`.
- **Validate parameters with `assert()`**, so a bad set fails the build with a message.
- **`include <BOSL2/std.scad>`, not `use`**, since BOSL2 relies on its global variables. Write
  `include <>` and `use <>` paths relative to the model's folder or to `lib/`, which the recipes
  put on `OPENSCADPATH`, not with `~` or an absolute path.
- **Reach for BOSL2 first** for rounding, chamfers, attachments, joiners and threads. Position
  with anchors and attachments where BOSL2 offers them, and wrap a nested `diff()` in
  `tag_scope()`.
- **Check a new function or module name against BOSL2** before defining it:
  `grep -E "^(function|module) +NAME *\(" lib/BOSL2/*.scad`. A model's definition replaces BOSL2's
  inside BOSL2 too, so it breaks the BOSL2 code that calls that name.
- **A helper file**, a `.scad` in the project folder not named `<project>` or `<project>-*`, holds
  only constants, zero-argument functions, and modules that read the model's globals at call time.
  A top-level assignment that uses a model's parameters fails when the helper is compiled alone.
- **A module's local assignment doesn't reach a module it calls** (lexical scope); the callee warns
  "Ignoring unknown variable". Pass a value that varies per call as an argument.
- **Overlap shapes by a small epsilon** in unions and differences, so no faces coincide.
- **Set curve resolution once** at the top with `$fa` and `$fs`.
- **Model in print orientation:** the face that sits on the bed is at z = 0.
- **Faces that point down are a trade-off: give the user the options and their costs.** Each layer
  needs material below it. A 45° chamfer prints clean where a fillet overhangs
  ([Prusa](https://help.prusa3d.com/article/modeling-with-3d-printing-in-mind_164135)), a teardrop
  does the same for a hole whose axis lies flat, and a short span bridges. A slope prints only
  where its lowest edge rests on material: one that starts in air, such as a sloped groove cut
  into the underside of a collar, prints its first layer as a floating ring. Supports allow any
  shape but add time, material and cleanup, and mark the face
  ([Hubs](https://www.hubs.com/knowledge-base/how-design-parts-fdm-3d-printing/)); turning or
  splitting the model can remove them. Limits, settings, and what support does to the brim:
  `docs/reference/bambu-x2d.md`, Supports.
- **Make a vertical clearance more than one layer height:** the `layer_height` in the model's
  `.slice.json`, else the preset's 0.24 mm; the 0.4 mm nozzle profile allows up to 0.28. Test
  results: `docs/reference/bambu-x2d.md`, PLA Pure.
- **A union adds no walls inside the body:** the slicer walls only the outer surface of the joined
  solid, so a wall modeled inside a solid feature merges into it. To print that wall, hollow the
  feature round it.
- **`-D name=value` overrides only a variable the file already assigns.** For any other name,
  top-level uses warn "Ignoring unknown variable" and get undef.
- **Render images made by hand with `--render`**, not a preview, which shows seams on coincident
  faces.

## BOSL2 notes

- `skin()` asserts when a profile degenerates, such as a taper that drives a width negative.
- `dovetail()` tapers only the width, and the female's `$slop` opens every face. For a key that
  tapers another way, loft it with `skin()` between offset paths with equal vertex counts.
- For a split seam, delta-offset one piece's region by +d and its complement by −(d + gap): the
  pieces keep a uniform `gap`, and the first reaches d past the seam.
