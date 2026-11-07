# Bambu Studio command line

Every option of the Bambu Studio 02.09.01.70 command line, the latest public release
(`gh release list -R bambulab/BambuStudio`, 2026-11-05), and what `just slice` does with each.
Sources:

- `--help` of `/Applications/BambuStudio.app/Contents/MacOS/BambuStudio`, which lists 57 options.
  Its text is the same as in 02.08.02.61, apart from the version line (diffed 2026-11-05);
- Bambu's [Command Line Usage wiki](https://github.com/bambulab/BambuStudio/wiki/Command-Line-Usage)
  (last edited 2026-03-31), which lists 16 of them;
- the source at tag v02.08.02.61, which the line numbers below cite: `src/libslic3r/PrintConfig.cpp` (`CLIActionsConfigDef`,
  `CLITransformConfigDef`, `CLIMiscConfigDef`) and `src/BambuStudio.cpp`.

How eitri uses them is in [bambu-x2d.md](bambu-x2d.md), "Bambu Studio from the command line".

## What eitri does with each option

- **slice**: `just slice` sets it. A `"cli"` list that names it fails.
- **cli**: pass it in the model's `.slice.json` `"cli"` list, such as
  `"cli": ["--rotate", "90"]`. `just slice` puts the list after its own options. A value that
  names a file in the project folder is made absolute, since Bambu Studio runs in a temporary
  folder. That folder is deleted on exit, so a file an option writes there, such as
  `--export-stls`, is lost unless its value is an absolute path. The log, which `--info` and
  `--debug` write to, shows only on a failed slice (`justfile`).

| Option | What it does (`--help`, unless noted) | Wiki | eitri |
|---|---|---|---|
| `--allow-mix-temp option` | Allow filaments with high and low temperatures to print together | | cli |
| `--allow-multicolor-oneplate` | Arrange allows several colors on one plate | | cli |
| `--allow-newer-file option` | Slice a 3MF from a newer version | | cli |
| `--allow-rotations` | Arrange may rotate objects | | cli |
| `--avoid-extrusion-cali-region` | Arrange avoids the extrusion calibration region | | cli |
| `--camera-view angle` | View for `--export-png`: 0 Iso, 1 Top_Front, 2 Left, 3 Right, 10–12 Iso_1–3 | | slice (`plate_view`) |
| `--check-preset` | Check that loaded filament presets suit the printer | | cli |
| `--clone-objects "1,3,1,10"` | Clone objects in the load list | | cli |
| `--datadir dir` | Keep program settings in this folder | | cli |
| `--debug level` | Log level, 0 fatal to 5 trace | yes | cli |
| `--downward-check` | Check that the machine is downward compatible with `--downward-settings` | | cli |
| `--downward-settings "m1.json;m2.json"` | Machines for `--downward-check` | | cli |
| `--enable-timelapse` | Slice as for a timelapse. In the source, it only keeps the prime tower of a one-filament print when `timelapse_type` is smooth (BambuStudio.cpp ~4178–4190) | | cli |
| `--estimate-mode` | After a machine switch, fill filament presets and extruder state for estimates | | cli |
| `--load-assemble-list file.json` | Load an assembly object list | | cli |
| `--load-custom-gcodes file.json` | Load custom G-code | | cli |
| `--load-filament-ids "1,2,3,1"` | Filament per object | | cli |
| `--load-filaments "f1.json;…"` | Load filament settings | yes | slice |
| `--load-settings "m.json;p.json"` | Load machine and process settings | yes | slice |
| `--makerlab-name name` | MakerLab name written into the 3MF | | cli |
| `--makerlab-version version` | MakerLab version written into the 3MF | | cli |
| `--metadata-name "n1;n2"` | Metadata names added to the 3MF | | cli |
| `--metadata-value "v1;v2"` | Metadata values added to the 3MF | | cli |
| `--outputdir dir` | Folder for exported files | yes | slice |
| `--skip-modified-gcodes option` | Skip G-code in the 3MF changed from the printer or filament presets | | cli |
| `--skip-objects "3,5,10"` | Skip these objects | | cli |
| `--skip-useless-pick option` | Don't write the unused pick and top images into the 3MF | | cli |
| `--uptodate-filaments "f1.json;…"` | Filament settings for `--uptodate` | | cli |
| `--uptodate-settings "s1.json;s2.json"` | Machine and process settings for `--uptodate` | | cli |
| `--arrange option` | 0 off, 1 on, other auto | yes | slice (0) |
| `--assemble` | Arrange the models on one plate and merge them into one model | | cli |
| `--convert-unit` | Convert the model's units | | cli |
| `--ensure-on-bed` | Lift an object that is partly below the bed | | cli |
| `--orient option` | 0 off, 1 on, other auto. Takes a value (`coInt`, PrintConfig.cpp), though the wiki shows none | yes | cli |
| `--repetitions count` | Repeat the whole model | | cli |
| `--rotate angle` | Rotate about Z, in degrees | | cli |
| `--rotate-x angle` | Rotate about X, in degrees | | cli |
| `--rotate-y angle` | Rotate about Y, in degrees | | cli |
| `--scale factor` | Scale the model | yes | cli |
| `--export-3mf file.3mf` | Export the project as 3MF | yes | slice |
| `--export-png option` | PNG of plate i, or 0 for all | | slice (`-plate.png`) |
| `--export-settings file.json` | Export the settings | yes | slice (`-settings.json`) |
| `--export-slicedata dir` | Export slicing data to a folder | yes | cli |
| `--export-stl` | Export the objects as one STL | | cli |
| `--export-stls dir` | Export the objects as STLs | | cli |
| `--help`, `-h` | Show help | yes | refused |
| `--info` | Print the model's information | yes | cli |
| `--load-defaultfila option` | Use the first filament for objects without one | | cli |
| `--load-slicedata dir` | Load cached slicing data | yes | cli |
| `--min-save option` | Export the smallest 3MF | | cli |
| `--mstpp time` | Maximum slicing time per plate, in seconds | | cli |
| `--mtcpp count` | Maximum triangles per plate | | cli |
| `--no-check` | Skip validity checks, such as G-code path conflicts | | cli |
| `--normative-check option` | Check the normative items | | cli |
| `--pipe name` | Send progress to a pipe. Linux only; does nothing on macOS (BambuStudio.cpp ~1766) | yes | cli |
| `--slice option` | Slice plate i, or 0 for all | yes | slice (0) |
| `--uptodate` | Update the 3MF's config values to the latest | yes | cli |

## Notes

- **Config keys:** any print, filament or machine key also works as `--key=value`. The priority,
  highest first: command line, then `--load-settings` and `--load-filaments`, then the 3MF
  (`--help`, wiki). eitri doesn't pass config keys this way. A process key goes at the top level
  of `.slice.json`, so it is listed in `different_settings_to_system` and the app keeps it
  ([bambu-x2d.md](bambu-x2d.md), Overrides). A `"cli"` entry such as `--layer_height=0.2` fails.
- **`--export-png`** must be the only action. With any other, the run exits with
  `CLI_INVALID_PARAMS` (BambuStudio.cpp ~6410). So `just slice` runs Bambu Studio a second time on
  the sliced 3MF. It writes a 512 × 512 `plate_<i>_<view>.png` (~8175–8215). Every view frames
  the objects alone, without the bed or supports (views 0, 1, 2 and 10 tested 2026-11-04). It
  shows what Bambu Studio loaded, but not where it sits on the plate.
- **`--export-settings`** matches the sliced 3MF's `Metadata/project_settings.config`, but leaves
  out `extruder_nozzle_stats_new` (tested 2026-11-04).
- **Not in `--help`:** the source defines `export_svg`, `cut`, `cut_grid`, `cut_x`, `cut_y`,
  `scale_to_fit`, `help_sla`, `config_compatibility`, `single_instance` and `autosave`, but
  `--help` doesn't list them, so they're left out here (PrintConfig.cpp ~9713–10204).
- **Smooth timelapse doesn't slice yet:** `timelapse_type` 1 failed with "Found G-code outside of
  the printable area" (return_code -104), with or without `--enable-timelapse`. The message
  blames the wipe tower (tested 2026-11-04; not investigated).
- **After a Bambu Studio upgrade**, compare `--help` with the table:

  ```sh
  (cd "$TMPDIR" && /Applications/BambuStudio.app/Contents/MacOS/BambuStudio --help 2>&1) \
      | grep -oE '^ --[a-z0-9-]+' | tr -d ' ' | sort
  ```
