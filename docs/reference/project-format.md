# Project format

How eitri lays out what the user makes, and the brief each project keeps. A request from the user
is enough to start or change a project; projects have no backlog stories. `examples/peg-fit/`
follows this format.

## Terms

- **Project:** what the user is making, such as `peg-fit`.
- **Model:** each `.scad` design in a project, such as `peg-fit`, or `shelf-bracket` in a `shelf`
  project. Its name, written `<model>` throughout eitri, is the file name without `.scad`:
  `<project>-<name>`, or `<project>` alone for a one-model project. Recipes take this full name.
- **Parameter set:** a named variant of a model, in OpenSCAD's parameter-set file. It keeps
  OpenSCAD's name.
- "Part" is retired, because the tools around eitri use it for something smaller than a design:
  - Bambu Studio cuts or splits a model into objects or parts; a part is one piece of a
    multi-part object, and each part can take its own filament
    ([cut tool](https://wiki.bambulab.com/en/software/bambu-studio/cut-tool)). A plate "is a
    container that holds the models"
    ([plates](https://wiki.bambulab.com/en/software/bambu-studio/plates_management)).
  - MakerWorld calls an uploaded design a model, and the pieces of a model its parts ("If a model
    has multiple parts", [print profile upload](https://wiki.bambulab.com/en/MakerWorld/tutorials/print-profile-upload);
    [FAQ](https://makerworld.com/en/faq)).
  - A 3MF file holds one model, made of one or more objects, and calls each file inside the
    package a part
    ([3MF core specification](https://github.com/slic3r/Slic3r/wiki/3MF-Document-Core-Specification)).
  - CAD splits a product into assemblies, sub-assemblies, components and parts
    ([GrabCAD](https://cad.grabcad.com/questions/what-is-a-difference-between-the-physical-product-assembly-sub-assembly-component-and-part)).

## Layout

```text
projects/<project>/
  <project>.md                    the brief
  <model>.scad                    one file per model
  <model>.json                    optional parameter sets for that model
  <model>.slice.json              optional Bambu Studio process overrides for just slice, and
                                  other CLI options in its "cli" list
  reference/<topic>.md            research and design studies for this project only
```

- General research stays in `docs/reference/`. Build outputs go to `out/<model>/`, which git
  ignores.
- `just verify <model> [set]` finds the model as the one `projects/*/<model>.scad`, and fails when
  the name matches no file or files in two projects. `just check-all` treats only
  `<project>.scad` and `<project>-*.scad` as models, so any other `.scad` file in the folder is a
  helper (`justfile`).
- The justfile's `projects` variable names the folder the recipes search. `just projects=examples
  verify peg-fit` runs a recipe on the example project.

## Names

- Lowercase letters and digits, joined by single hyphens. A dot is allowed only between digits,
  as in the set `slop-0.15`. The recipes refuse a model or set name that breaks this (`justfile`).
- A set name can't hold a minus sign, so a negative number takes an `m` prefix, as in
  `fit-m0.05`.
- A set can't be named `print` or end in `-print`, since `just slice` writes
  `<model>[-<set>]-print.3mf` (`justfile`).
- No dates in file names.

## Brief

`projects/<project>/<project>.md` is Markdown with YAML frontmatter:

- `project`: the folder name.
- `title`: what the user calls it.
- `status`: `planned`, `active`, `printed`, `done` or `parked`.
- `due`: a date, `YYYY-MM-DD`.
- `models`: the list of model names.
- `filament`: the project's filament.

Then these sections, in this order:

1. **Goal.**
2. **Decisions**, grouped under `###` headings that name the model or models they cover when there
   are several models, such as `### shelf-bracket and shelf-clip`. A model's filament here
   overrides the project's.
3. **Dimensions:** a table of parameter, value, source and model. It holds only inputs: values
   from the user, measurements and research. Give research values at full scale with the scale rule,
   so they stay right when the size changes. Derived values and design choices live only in the
   `.scad`, and cite the row they come from.
4. **Reference:** one line per reference file or diagram link.
5. **Open questions.**
6. **The user's words:** verbatim and dated, in order.
7. **Prints:** a log of date, model, set, result and what the user found. A fit size the user
   picks goes from here into the parameter set. Per-model progress shows here, so models carry no
   status of their own.

## Template

```markdown
---
project: <project>
title: <title>
status: planned
due: YYYY-MM-DD
models: [<model>]
filament: <brand, material, color>
---

# <title>

## Goal

<What the user is making, what it is for, and when it is needed.>

## Decisions

### <model>

- <decision> (<source>)

## Dimensions

<The scale rule, when research values are at full scale.>

| Parameter | Value | Source | Model |
|---|---|---|---|
| <name> | <value and unit> | <the user, a caliper measurement, or a link> | <model, or all> |

## Reference

- [reference/<topic>.md](reference/<topic>.md): <what it holds>

## Open questions

- <question for the user>

## The user's words

- YYYY-MM-DD: "<verbatim>"

## Prints

| Date | Model | Set | Result | What the user found |
|---|---|---|---|---|
```
