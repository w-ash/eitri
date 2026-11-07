# eitri

OpenSCAD and [BOSL2](https://github.com/BelfrySCAD/BOSL2) models for 3D printing on a Bambu Lab
X2D. You describe a model to Claude Code; it writes the `.scad` file, builds and checks the mesh,
reads its own renders, and slices it in Bambu Studio through `just` recipes. You get a sliced 3MF,
its print orientation and what to check on the print.

eitri supports the Bambu Lab X2D only for now: the build volume, presets and slicing are set for
it in the `justfile`.

## Requirements

- macOS.
- **OpenSCAD development snapshot**: `brew install --cask openscad@snapshot`. The 2021.01 stable
  release is too old.
- **Bambu Studio** at `/Applications/BambuStudio.app`: `brew install --cask bambu-studio`.
- **just** and **jq**: `brew install just jq`. `just manual` also needs pdftotext
  (`brew install poppler`).
- **BOSL2**, a git submodule at `lib/BOSL2`: clone with `git clone --recurse-submodules`, or run
  `git submodule update --init`.
- [Claude Code](https://code.claude.com), to design models with the `design-model` skill.

## Projects

A **project** is what you are making; a **model** is each `.scad` design in it; a **parameter set**
is a named variant of a model, such as a fit-test size. Each project is a folder with a brief, its
models and their parameter-set and slicer files
([project-format.md](docs/reference/project-format.md)).

Keep your projects in your own git repository, cloned into `eitri/projects/`, which eitri ignores.
Commit project work there with `git -C projects …`.

To try eitri first, run the example in `examples/`:

```sh
just projects=examples verify peg-fit
```

## Commands

- `just verify <model> [set]`: build the 3MF into `out/<model>/`, check it, and render five PNGs.
- `just build`, `just check`, `just render`: one step each, with the same arguments.
- `just check-all`: build and check every model and parameter set.
- `just slice <model> [set]`: check, then slice with the justfile's presets and the model's
  `.slice.json`, writing `out/<model>/<model>[-<set>]-print.3mf`.
- `tools/bambu-profile <machine|filament|process> "<name>"`: print a flattened Bambu Studio
  system profile.
- `just manual`: give the X2D User Manual as text.

Add `projects=<folder>` after `just` to use another projects folder.

## Why OpenSCAD

It has the largest code-CAD community, and MakerWorld's Parametric Model Maker runs OpenSCAD
files, so models can be remixed from there and published back. It exports meshes only and can't
import STEP; a second engine for those cases is an idea in
[unscheduled.md](docs/backlog/unscheduled.md).

## License

MIT ([LICENSE](LICENSE)).
