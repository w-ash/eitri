# eitri: agent conventions

OpenSCAD and BOSL2 models for 3D printing on a Bambu Lab X2D. Claude designs each model, verifies
it, and hands the user a 3MF to open in Bambu Studio on their Mac. Use the `design-model` skill
for any model work: it holds the loop and the hand-over list.

## Layout and terms

A **project** is what the user is making (`peg-fit`). A **model** is each `.scad` design in it,
and `<model>` is always its full name, the file name without `.scad` (`peg-fit`, or
`<project>-<name>` in a project with several). A **parameter set** keeps OpenSCAD's name. Don't
call a design a part: in Bambu Studio a part is a piece of an object. The layout, names and brief
template are in `docs/reference/project-format.md`.

`projects/` is the user's own git repository, cloned into eitri and ignored by it. Commit project
work with `git -C projects …`; commit tooling in eitri. `projects/CLAUDE.md` says who the user is
and where their printer setup is recorded. `examples/peg-fit/` is an example project: run a recipe
on it with `just projects=examples <recipe>`.

## Requests and replies

The user isn't always watching the session: some requests are relayed in from elsewhere. So every
reply and hand-over stands on its own, and questions for the user go together in one message
rather than one per turn.

## Commands

- `just verify <model> [set]`: build the 3MF into `out/<model>/`, check it, and render five PNGs.
- `just build`, `just check`, `just render`: one step each, with the same arguments.
- `just check-all`: build and check every model and parameter set in a temporary folder. Run it
  after editing a helper `.scad` file or the justfile, and before handing over a multi-model
  project.
- `just slice <model> [set]`: check, then slice with the justfile's presets and the model's
  `.slice.json`, writing `-print.3mf`, `-plate.png` and `-settings.json`. Every CLI option is in
  `docs/reference/bambu-studio-cli.md`.
- `tools/bambu-profile <machine|filament|process> "<name>"`: print a flattened Bambu Studio
  system profile.
- `just manual`: give the X2D User Manual as text.

## Rules

- **Never invent a dimension.** Every length comes from the user, a caliper measurement, or a
  cited source, and goes with its source in the Dimensions table of the project brief. The
  parameter's Customizer description cites that row, or names the design choice. When one is
  missing or two sources disagree, ask. If the user says to go ahead without one, list every
  assumed value in the hand-over.
- **Fits come from test prints.** A press fit, slot or clip starts as a short print of sizes a few
  tenths of a millimeter apart, and the size the user picks goes in the parameter set. A default
  clearance is never treated as measured.
- **Check geometry by numbers and meaning by images.** `just check` measures only the bounding
  box. Clearances, walls, counts and positions come from the `.scad` parameters. Renders show
  orientation, missing features and floating pieces, so never hand over a model whose latest
  renders you haven't read.
- **Fit the build volume:** 256 × 256 × 260 mm with the main nozzle (Bambu's X2D spec sheet). A
  larger design splits into models that join.
- **The `.scad` file is the source.** Change a model there; `out/` holds build outputs, which git
  ignores.
- **Find a failure's cause before calling it a limit of the tool.** Read the tool's log and the
  macOS crash report in `~/Library/Logs/DiagnosticReports`, and change one input at a time.
- `lib/BOSL2` is a pinned submodule: read it for the API, don't edit it.
- Units are millimeters.
- Temporary files go in the session scratchpad, never the repo.

## Backlog

`docs/backlog/` holds tooling work only: the recipes, the skill and the settings. A request from
the user is enough to start or change a project. The backlog is one Markdown file per version
series of checklist stories (Effort, What, Why, Dependencies, Status, Notes), indexed in
`README.md`, with unscheduled ideas in `unscheduled.md`. The commit that flips a story to
Completed adds its `CHANGELOG.md` entry under `[Unreleased]`. Don't add, move or promote stories
unprompted.
