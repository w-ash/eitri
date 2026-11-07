---
name: design-model
description: Designs, changes and verifies a 3D-printable OpenSCAD model in eitri, from the user's description in chat to a checked 3MF for Bambu Studio. Use when the user asks to design, model, make, change, resize, fix or print a model or anything to 3D print, or when editing a .scad file under projects/ or examples/.
---

# Design a model

## Starting work

- Read `.claude/rules/openscad.md` before the first Write of a `.scad` file. It loads on its own
  only once a `.scad` file is read or written.
- Read the project's brief, `projects/<project>/<project>.md`, and its `reference/` files: they
  hold the decisions, dimensions and reference images. For a new project, follow the layout,
  names and brief template in `docs/reference/project-format.md`.
- Keep the brief's `status` current, from the values in `project-format.md`: `active` once work
  starts, `printed` once the user reports a print, and `done` or `parked` only when the user says
  so.
- Take printer, plate and Bambu Studio facts from `docs/reference/bambu-x2d.md`,
  `tools/bambu-profile` and `just manual` first. When they don't cover a question, search for
  X2D sources, and label what comes from another printer, a forum user or an inference. For
  wiki.bambulab.com, use the `web-fetch-fallback` skill if that skill is available. Record what
  you learn in `bambu-x2d.md`.
- A fact about the user's own setup that `projects/CLAUDE.md` doesn't give, such as which hotend
  the AMS feeds, is a question for the user. Don't guess it.
- Before using a filament in a role it wasn't made for, such as a support interface, read its
  Bambu store page and data sheet.
- Beyond CLAUDE.md's dimension rule, a size you would choose, such as a wall width, is a
  proposal for the user. A size that reads two ways, such as across flats or across corners of a
  polygon, inner or outer, or diameter or radius, is a question for the user. Ask these, with any
  missing dimension, in one message before writing geometry.
- In that message, also lay out the print choices that trade against each other for this model,
  each with its numbers and a recommendation. Raise only the ones that matter for this model:
  - layer height: steps on shallow slopes against print time; 0.08–0.28 mm on the 0.4 mm nozzle,
    and the Fine finish keys for a smooth surface (both in `docs/reference/bambu-x2d.md`).
  - walls and infill: strength against time and filament. Small features that carry load, such as
    keys, bosses and strap loops, need a higher `wall_loops` (`docs/reference/bambu-x2d.md`, PLA
    Pure).
  - orientation: which faces show steps or need supports, and the weak direction across layers.
  - one print or several pieces.
  - fit test prints against time.

  The user's choices go in the brief's Decisions, and the slicer values in `<model>.slice.json`.
- Give a fit test's `.slice.json` the same values as the model it tests: layers, speeds, walls,
  infill and supports. Then it prints to the same size, flexes the same, and its supported faces
  match.

## After every change

1. Run `just verify <model> [set]`. It builds `out/<model>/<stem>.3mf` once (`<stem>` is
   `<model>`, or `<model>-<set>`), checks it, then renders five PNGs. Every build first deletes
   the 3MF and PNGs it replaces. It fails on a non-manifold mesh, min z other than 0, a model
   bigger than the build volume (`bed` in the justfile), or any OpenSCAD error or warning. Fix
   from the `FAIL`, `ERROR` or `WARNING` line it prints.
   - The check prints its JSON line `{model,size,min,max}` only when the mesh imports cleanly. A
     non-manifold mesh fails on `WARNING: PolySet -> Manifold conversion failed`, with no JSON,
     and can't be rendered. After a failed size or min-z check, `just render <model> [set]` still
     shows the model.
   - A `NOTE` that a model is too wide (over 235.5 mm in X) or too tall (over 256 mm) for the
     auxiliary hotend is not a failure: only the main hotend can print it.
2. Compare the JSON `size` with what the `.scad` parameters give.
3. Read all five PNGs in parallel: `out/<model>/<stem>-{iso,front,top,side,bottom}.png`. They are
   current only after a `verify` or `render` that exited 0. Write one short line per view naming
   the features in it, then a verdict against the request and any reference images in the
   project's `reference/` files. These lines are your check, not part of the hand-over. When
   parameter sets differ only in a fit dimension, read the renders of one set and check the
   others by their JSON line.
4. Fix and repeat until the check passes and the latest renders match.

## What each view shows

- **iso**: the whole model, every feature present and joined.
- **front** and **side** (ortho): the profile. The renders draw no bed: the lowest outline is the
  model's own base, and z = 0 comes from the check's `min`. A gap under a piece means it floats.
- **top** (ortho, tilted toward the front): raised features and holes get an outline, and faces at
  different tilts shade differently.
- **bottom** (ortho, looking up at the face on the bed, tilted toward the front and one side):
  open-back holes and other through-holes show the background, and the walls of a pocket or
  hollow outline it.

Each view is fitted to the whole model, so small details come out tiny. To judge one, crop and
enlarge it into the session scratchpad with `sips` and Read the crop:

```sh
sips -c <h> <w> --cropOffset <y> <x> in.png --out <scratchpad>/crop.png
sips -Z 1024 <scratchpad>/crop.png
```

## Checks the renders can't make

- **A clearance:** in a scratchpad file that includes BOSL2 and `use`s the model, move the mating
  piece toward its partner by the intended gap and intersect the two. Run `tools/openscad` on it
  with `OPENSCADPATH=<repo>/lib:<repo>/projects/<project>`. Exit 1 with "Current top level object
  is empty" means the gap holds (touching counts as empty); a solid shows where it closes.
- **Supports:** after slicing a model with supports, print the z range of each support feature
  from the G-code (`docs/reference/bambu-x2d.md`, Inspecting a sliced 3MF). Support can reach
  features the settings were meant to keep it from.
- **Brim:** count the G-code's `; FEATURE: Brim` lines. Support on the first layer removes the
  brim at any width (`docs/reference/bambu-x2d.md`, Supports).
- **Same geometry after a refactor:** compare the two builds' vertex and triangle lists, since the
  3MF's metadata (creation date, UUIDs) changes on every build.

## Parameter sets

- OpenSCAD drops a set key that names no parameter, clamps a value to the parameter's
  `[min:step:max]` range, and ignores a dropdown value not in its list, all without a message.
  Spell each key as its parameter and keep each value valid; widen the range in the `.scad` when a
  real value needs it.
- Write a vector value as a string, `"[3, 4]"`, since OpenSCAD ignores a JSON array. JSON numbers
  work.

## Hand-over

Slice last, after the final `verify`. `just slice <model> [set]` runs `check`, slices with the
justfile's presets and the model's `.slice.json` (key rules: `docs/reference/bambu-x2d.md`,
Overrides), fails naming any key that didn't take effect, writes `out/<model>/<stem>-print.3mf`,
and prints `{model,print_time,filament_g,layer_height,bed}`. It also writes `<stem>-settings.json`, the
slice's full settings, and `<stem>-plate.png`, Bambu Studio's picture of the objects it loaded.
Read the PNG to confirm the orientation and that no piece is missing. It shows neither the bed nor
the supports. Other Bambu Studio options, such as `--rotate`, go in the `.slice.json` `"cli"` list
(`docs/reference/bambu-studio-cli.md`). A later build keeps these files, so slice again after any
change. Run a separate `just slice` for each model and set, not a shell loop: zsh passes
an unquoted `$a` that holds "model set" as one argument. `just slice` rebuilds the model, which
deletes its renders, so run `just render` before reading them again.

`just slice` takes one filament. For a second one, such as a support interface on the auxiliary
hotend, slice with the command in `docs/reference/bambu-x2d.md`, Supports, and record the
settings in the brief. Before hand-over, compare the support keys with Bambu Studio's
recommendation (`support_recommended_params.json`) and Bambu's support guide for that pair of
filaments, and check in the G-code that the second filament prints only where intended, on the
intended hotend.

Then tell the user:

- the `-print.3mf` path and the plate it was sliced for, the slice line's `bed`: the printer checks
  that the plate matches (manual §6.4.2, in `docs/reference/bambu-x2d.md`). The plain
  `<stem>.3mf` stays for slicing in the app;
- the print orientation: which face sits on the bed;
- the check's and the slice's JSON lines, quoted;
- the five renders read from the final build, and the `-plate.png` read from the slice, by file
  name;
- every assumed value, with the parameter that holds it;
- what to check on the print: fits, sizes and features the check and renders can't confirm.

When the user reports a print, add a row to the brief's Prints table.
