# Build, render and check OpenSCAD models. A model is projects/<project>/<model>.scad, where
# <model> is <project>-<name>, or <project> in a one-model project, with parameter sets in the
# .json beside it. Recipes take <model> and write to out/<model>/
# (docs/reference/project-format.md).

set default-list
set script-interpreter := ["bash", "-euo", "pipefail"]

export OPENSCADPATH := justfile_directory() / "lib"

projects := "projects"
out := "out"

# X2D build volume with the main nozzle, in mm (CLAUDE.md, "Fit the build volume").
bed := "[256, 256, 260]"

# The X2D auxiliary hotend's print area, in mm: x 20.5-256, up to 256 high. Only the main hotend
# reaches the strip at x < 20.5 and the height above 256 (extruder_printable_area and
# extruder_printable_height in Bambu Studio's machine/Bambu Lab X2D 0.4 nozzle.json; X2D User
# Manual §6.2.1).
aux_x := "[20.5, 256]"
aux_z := "256"

# The default presets. Override with `just machine="…" filament="…" process="…" slice …`.
# The presets selected in Bambu Studio are in .presets in
# ~/Library/Application Support/BambuStudio/BambuStudio.conf. Read only .presets: the file also
# holds access codes.
machine := "Bambu Lab X2D 0.4 nozzle"
filament := "Bambu PLA Pure @BBL X2D 0.4 nozzle"
process := "0.24mm Standard @BBL X2D"

# The default spool colour, black. The flattened profile has no colour, so without one the 3MF
# shows Bambu Studio's default green and can't be matched to the spool by colour when sending.
# Override with --set filament_colour for another spool.
filament_colour := "#000000"

# The hotend that prints a one-filament slice: 1 is the main (left, direct drive) hotend, 2 the
# auxiliary. "Manual" grouping keeps it there when the 3MF is reopened and synced in the app; the
# default "Auto For Flush" regroups to wherever the spool is loaded. The manual says to use the main
# hotend whenever possible (X2D User Manual §8.2). Passed on the command line, since set in the
# process JSON it doesn't reach the G-code (docs/reference/bambu-x2d.md, two-filament slicing).
hotend := "1"

# The default plate, the Textured PEI Plate that ships with the X2D (X2D User Manual §2.1.2,
# §6.4.2). Override with --set plate for another plate.
plate := "Textured PEI Plate"

# The Bambu Studio install. slice runs its binary and reads its profiles through
# tools/bambu-profile, so both come from this one app.
bambu_app := "/Applications/BambuStudio.app"

# Bambu Studio's camera view for slice's plate PNG: 0 Iso, 1 Top_Front, 2 Left, 3 Right, 10-12 Iso
# 1-3 (BambuStudio --help, v02.08.02.61). Every view frames the objects only, with no bed or
# support (tested 2026-11-04), so Iso shows the most.
plate_view := "0"

# Bambu Studio options that slice sets itself, so a .slice.json "cli" list can't pass them
# (docs/reference/bambu-studio-cli.md).
slice_owned := "--arrange --load-settings --load-filaments --slice --outputdir --export-3mf --export-png --camera-view --export-settings --help"
manual_url := "https://csm.bblcdn.com/hub/7c58718aaa2e40edab56efb87419a96a.pdf"

# Compile a model to a 3MF, after deleting the stem's old 3MF, summary and PNGs. On any OpenSCAD
# error or warning, BOSL2's included, fail and remove the 3MF. Every recipe runs OpenSCAD through
# tools/openscad, which does this check.
[script]
build name set="":
    projects={{ quote(projects) }} name={{ quote(name) }} set_name={{ quote(set) }}
    dir={{ quote(out / name) }} stem={{ quote(if set == "" { name } else { name + "-" + set }) }}
    # The names go into paths and into OpenSCAD -D strings, so allow only lowercase letters, digits
    # and hyphens, and a dot between digits.
    re_name='^[a-z0-9]+([.-][a-z0-9]+)*$' re_dot='[^0-9][.]|[.][^0-9]'
    for n in "$name" ${set_name:+"$set_name"}; do
        if [[ ! $n =~ $re_name || $n =~ $re_dot ]]; then
            echo "Bad name \"$n\": use lowercase letters, digits and hyphens, and a dot only between digits." >&2
            exit 1
        fi
    done
    # slice writes <stem>-print.3mf, so a set named print, or ending in -print, would share a
    # file with a slice.
    if [[ "$set_name" == print || "$set_name" == *-print ]]; then
        echo "Set name \"$set_name\" is reserved: slice writes <model>[-<set>]-print.3mf, so a set can't be \"print\" or end in \"-print\"." >&2
        exit 1
    fi
    shopt -s nullglob
    # A model is <project>.scad or <project>-*.scad; any other .scad file is a helper.
    srcs=()
    for f in "$projects"/*/"$name.scad"; do
        project=$(basename "$(dirname "$f")")
        if [[ "$name" == "$project" || "$name" == "$project"-* ]]; then srcs+=("$f"); fi
    done
    if ((${#srcs[@]} == 0)); then
        echo "No model \"$name\": no $projects/<project>/$name.scad named <project> or <project>-*." >&2
        exit 1
    elif ((${#srcs[@]} > 1)); then
        echo "Model \"$name\" is in more than one project: ${srcs[*]}" >&2
        exit 1
    fi
    src=${srcs[0]} json=${srcs[0]%.scad}.json
    set --
    if [[ -n "$set_name" ]]; then
        # OpenSCAD ignores a missing set or file, so test for the set here.
        jq -e --arg s "$set_name" '.parameterSets | has($s)' "$json" > /dev/null \
            || { echo "No parameter set \"$set_name\" in $json." >&2; exit 1; }
        set -- -p "$json" -P "$set_name"
    fi
    mkdir -p "$dir"
    rm -f "$dir/$stem.3mf" "$dir/$stem.summary.json" "$dir/$stem"-{iso,front,top,side,bottom}.png
    # color() is left out of the 3MF, so the renders use the Cornfield scheme only.
    tools/openscad "$@" -O export-3mf/color-mode=none -o "$dir/$stem.3mf" "$src" \
        || { rm -f "$dir/$stem.3mf"; exit 1; }
    # OpenSCAD exits 0 when it can't open the output file.
    [[ -s "$dir/$stem.3mf" ]] \
        || { rm -f "$dir/$stem.3mf"; echo "FAIL: OpenSCAD wrote no $dir/$stem.3mf." >&2; exit 1; }
    echo "Wrote $dir/$stem.3mf"

# Build a model, then render the 3MF to iso, front, top, side and bottom PNGs. Use a full render.
[script]
render name set="": (build name set)
    dir={{ quote(absolute_path(out / name)) }} stem={{ quote(if set == "" { name } else { name + "-" + set }) }}
    # View name, camera rotation x,y,z in degrees, projection. Front looks along +y, side looks
    # along -x. Top tilts 15 degrees toward the front: a flat render gives all level faces one
    # shade, so a raised feature has no outline when seen straight down. Bottom looks up at the
    # face on the bed, tilted 15 degrees toward the front and 15 to the side, so the walls of a
    # pocket outline it on two sides.
    for view in "iso 55,0,25 perspective" "front 90,0,0 ortho" "top 15,0,0 ortho" \
        "side 90,0,90 ortho" "bottom 165,15,0 ortho"; do
        read -r label rot proj <<< "$view"
        png="$dir/$stem-$label.png"
        tools/openscad -D "file=\"$dir/$stem.3mf\"" --render \
            --camera="0,0,0,$rot,0" --autocenter --viewall --projection="$proj" \
            --imgsize=1024,768 --colorscheme=Cornfield \
            -o "$png" tools/mesh.scad || { rm -f "$png"; exit 1; }
        echo "Wrote $png"
    done

# Build a model, then test the 3MF: on the bed at z = 0 and inside the build volume. A non-manifold
# mesh fails the import in tools/openscad on "WARNING: PolySet -> Manifold conversion failed".
[script]
check name set="": (build name set)
    dir={{ quote(absolute_path(out / name)) }} stem={{ quote(if set == "" { name } else { name + "-" + set }) }}
    summary="$dir/$stem.summary.json"
    tools/openscad -D "file=\"$dir/$stem.3mf\"" \
        --summary geometry --summary bounding-box --summary-file "$summary" \
        -o /dev/null --export-format 3mf tools/mesh.scad || { rm -f "$summary"; exit 1; }
    jq -r --unbuffered --arg model "$stem" --argjson bed {{ quote(bed) }} \
        --argjson aux_x {{ quote(aux_x) }} --argjson aux_z {{ quote(aux_z) }} '
        .geometry.bounding_box as $b
        | ($aux_x[1] - $aux_x[0]) as $aux_w
        | ({model: $model} + ($b | {size, min, max}) | tojson),
          (if $b.size[0] > $aux_w
           then "NOTE \($model): X size \($b.size[0]) is more than \($aux_w), so only the main"
                + " hotend can print it."
           else empty end),
          (if $b.size[2] > $aux_z
           then "NOTE \($model): Z size \($b.size[2]) is more than \($aux_z), so only the main"
                + " hotend can print it."
           else empty end),
          ([if ($b.min[2] | fabs) > 1e-6 then "Min z is \($b.min[2]), not 0." else empty end,
            (range(3) as $i | if $b.size[$i] > $bed[$i]
                then "\(["X", "Y", "Z"][$i]) size \($b.size[$i]) is more than \($bed[$i])."
                else empty end)]
           | select(length > 0) | map("FAIL \($model): \(.)\n") | add | halt_error(1))
        ' "$summary" || { rm -f "$summary"; exit 1; }

# Build a model once, then check it, then render it. A failed check stops the render.
verify name set="": (check name set) (render name set)

# Check a model, then slice it in Bambu Studio with the default presets and the model's
# .slice.json.
[script]
slice name set="": (check name set)
    # Writes out/<model>/<stem>-print.3mf, Bambu Studio's picture of the objects <stem>-plate.png
    # and the slice's full settings <stem>-settings.json, and prints
    # {model,print_time,filament_g,layer_height,bed}. Process values in
    # projects/<project>/<model>.slice.json, such as layer_height, override the preset's. The slice
    # fails when a requested value isn't in the sliced 3MF's settings. Its "cli" list holds other
    # Bambu Studio options, such as ["--enable-timelapse"].
    projects={{ quote(projects) }} name={{ quote(name) }} app={{ quote(bambu_app) }}
    dir={{ quote(absolute_path(out / name)) }} stem={{ quote(if set == "" { name } else { name + "-" + set }) }}
    bambu="$app/Contents/MacOS/BambuStudio"
    export BAMBU_APP="$app"
    [[ -x "$bambu" ]] || { echo "FAIL: no Bambu Studio at $bambu." >&2; exit 1; }
    rm -f "$dir/$stem-plate.png" "$dir/$stem-settings.json"
    shopt -s nullglob
    # build found exactly one model file; a .scad file not named for its project is a helper.
    own="" own_json="{}" project_dir=""
    for f in "$projects"/*/"$name.scad"; do
        project=$(basename "$(dirname "$f")")
        if [[ "$name" == "$project" || "$name" == "$project"-* ]]; then
            own=${f%.scad}.slice.json project_dir=$(cd "$(dirname "$f")" && pwd)
        fi
    done
    if [[ -f "$own" ]]; then
        own_json=$(jq -c 'if type == "object" then . else error("not an object") end' "$own") \
            || { echo "FAIL $stem: $own must hold one JSON object." >&2; exit 1; }
    fi
    cli_json=$(jq -c '.cli // []' <<< "$own_json")
    jq -e 'type == "array" and all(.[]; type == "string")' <<< "$cli_json" > /dev/null \
        || { echo "FAIL $stem: \"cli\" in $own must be a list of strings." >&2; exit 1; }
    own_json=$(jq -c 'del(.cli)' <<< "$own_json")
    # Bambu Studio writes its temporary 3MF and result.json into its working folder, so it runs
    # in this temporary folder outside the repo, which is also its --outputdir.
    work=$(mktemp -d "${TMPDIR:-/tmp}/slice.XXXXXX")
    trap 'rm -rf "$work"' EXIT
    # Pass on only options that this Bambu Studio's --help lists and slice doesn't set. Bambu
    # Studio runs in $work, so a value that names a file in the project folder becomes absolute.
    cli=()
    if [[ "$cli_json" != "[]" ]]; then
        known=" $( (cd "$work" && "$bambu" --help 2>&1) | grep -oE '^ --[a-z0-9-]+' | tr -d ' ' | tr '\n' ' ') "
        rm -f "$work/result.json"
        owned=" "{{ quote(slice_owned) }}" "
        while IFS= read -r arg; do
            if [[ "$arg" == --* ]]; then
                opt=${arg%%=*}
                if [[ "$owned" == *" $opt "* ]]; then
                    echo "FAIL $stem: \"cli\" in $own sets $opt, which just slice sets itself." >&2
                    exit 1
                elif [[ "$known" != *" $opt "* ]]; then
                    echo "FAIL $stem: \"cli\" in $own has $opt, which isn't in Bambu Studio's --help. A process key goes at the top level of the .slice.json." >&2
                    exit 1
                fi
            elif [[ -e "$project_dir/$arg" ]]; then
                arg="$project_dir/$arg"
            fi
            cli+=("$arg")
        done < <(jq -r '.[]' <<< "$cli_json")
    fi
    tools/bambu-profile machine {{ quote(machine) }} > "$work/machine.json"
    tools/bambu-profile filament {{ quote(filament) }} \
        | jq --arg c {{ quote(filament_colour) }} '. + {filament_colour: [$c]}' > "$work/filament.json"
    # Bambu Studio ignores a number or boolean value, so write each one as a string (Config.cpp,
    # ConfigBase::load_from_json, v02.08.02.61).
    want=$(jq -c -n --arg plate {{ quote(plate) }} --argjson own "$own_json" '
        {curr_bed_type: $plate}
        * ($own | walk(if type == "number" then tostring
            elif type == "boolean" then (if . then "1" else "0" end) else . end))')
    # different_settings_to_system[0] names the overridden process keys. The CLI copies it into the
    # 3MF, and on opening the GUI resets every process key not on it to the system preset
    # (PresetBundle.cpp load_config_file_config, Preset.cpp load_external_preset,
    # v02.08.02.61).
    tools/bambu-profile process {{ quote(process) }} \
        | jq --argjson want "$want" --argjson own "$own_json" \
            '. * $want + {different_settings_to_system: [$own | keys | join(";")]}' \
        > "$work/process.json"
    # Bambu Studio slices only an object fully on the bed, and its auto-arrange fails on a model
    # that fills the bed, so place the model here. A model that fits the auxiliary hotend's area
    # is centered in X on that area, off the strip at x < 20.5 that only the main hotend reaches
    # (extruder_printable_area and extruder_printable_height in machine/Bambu Lab X2D 0.4
    # nozzle.json; X2D User Manual §6.2.1). Any other model is centered on the bed. Y is
    # centered on the bed.
    move=$(jq -c --argjson bed {{ quote(bed) }} --argjson aux_x {{ quote(aux_x) }} \
        --argjson aux_z {{ quote(aux_z) }} '
        .geometry.bounding_box
        | (if .size[0] <= $aux_x[1] - $aux_x[0] and .size[2] <= $aux_z
           then ($aux_x[0] + $aux_x[1]) / 2 else $bed[0] / 2 end) as $x
        | [$x - (.min[0] + .max[0]) / 2, $bed[1] / 2 - (.min[1] + .max[1]) / 2, 0]
        ' "$dir/$stem.summary.json")
    tools/openscad -D "file=\"$dir/$stem.3mf\"" -D "shift=$move" -O export-3mf/color-mode=none \
        -o "$work/placed.3mf" tools/mesh.scad
    status=0
    (cd "$work" && "$bambu" --arrange 0 --load-settings "machine.json;process.json" \
        --load-filaments filament.json --slice 0 --outputdir "$work" \
        --export-3mf "$stem-print.3mf" --export-settings settings.json \
        --filament-map-mode Manual --filament-map {{ quote(hotend) }} \
        ${cli[@]+"${cli[@]}"} placed.3mf) > "$work/log" 2>&1 || status=$?
    if ((status != 0)) || [[ ! -s "$work/$stem-print.3mf" ]]; then
        result=$(jq -r '"\(.error_string) (return_code \(.return_code))"' "$work/result.json" \
            2> /dev/null || true)
        echo "FAIL $stem: no $stem-print.3mf. Bambu Studio exited $status${result:+: $result}." >&2
        { grep -v -E '\[(trace|debug|info)\]|ZFiller' "$work/log" || true; } | tail -n 20 >&2
        exit 1
    fi
    unzip -q -o "$work/$stem-print.3mf" Metadata/plate_1.gcode Metadata/project_settings.config \
        -d "$work"
    # A filament or machine key in the .slice.json can't take effect through the process profile,
    # so test that each requested value reached the slice. A string also matches a list of equal
    # strings, since some process keys hold one value per extruder.
    jq -n -r --arg model "$stem" --argjson want "$want" \
        --slurpfile cfg "$work/Metadata/project_settings.config" '
        [$want | to_entries[] | .key as $k | .value as $v | $cfg[0][$k] as $got
         | select($got != $v
             and (($v | type) != "string" or ($got | type) != "array" or $got == []
                  or any($got[]; . != $v)))
         | "FAIL \($model): requested \($k) \($v | tojson), but the sliced 3MF has "
           + (if $got == null then "none" else $got | tojson end) + ".\n"]
        | if . == [] then empty else add | halt_error(1) end'
    # The CLI writes the grouping into the config and G-code but leaves the plate's own
    # filament_map_mode at "Auto For Flush" (tested 2026-11-06), which the app keeps when it
    # reopens the 3MF (docs/reference/bambu-x2d.md, two-filament slicing). Set the plate's mode
    # too, so the app keeps the hotend.
    unzip -q -o "$work/$stem-print.3mf" Metadata/model_settings.config -d "$work"
    sed -i '' 's/key="filament_map_mode" value="[^"]*"/key="filament_map_mode" value="Manual"/' \
        "$work/Metadata/model_settings.config"
    (cd "$work" && zip -q "$stem-print.3mf" Metadata/model_settings.config)
    mv "$work/$stem-print.3mf" "$dir/$stem-print.3mf"
    [[ -s "$work/settings.json" ]] \
        || { echo "FAIL $stem: Bambu Studio wrote no settings.json." >&2; exit 1; }
    mv "$work/settings.json" "$dir/$stem-settings.json"
    # --export-png must be Bambu Studio's only action, so it runs again on the sliced 3MF
    # (BambuStudio.cpp ~6410, v02.08.02.61).
    png="$work/plate_1_"{{ quote(plate_view) }}".png"
    (cd "$work" && "$bambu" --export-png 1 --camera-view {{ quote(plate_view) }} \
        --outputdir "$work" "$dir/$stem-print.3mf") > "$work/png.log" 2>&1 || true
    if [[ ! -s "$png" ]]; then
        echo "FAIL $stem: Bambu Studio wrote no plate PNG." >&2
        { grep -v -E '\[(trace|debug|info)\]' "$work/png.log" || true; } | tail -n 20 >&2
        exit 1
    fi
    mv "$png" "$dir/$stem-plate.png"
    # Read the results from the sliced 3MF: time and grams from its G-code header, the rest from
    # its settings.
    head=$(sed '/^; HEADER_BLOCK_END/q' "$work/Metadata/plate_1.gcode")
    jq -c -n --arg model "$stem" --arg head "$head" \
        --slurpfile cfg "$work/Metadata/project_settings.config" '
        def header($re): ($head | capture($re).v) // null;
        {model: $model,
         print_time: header("; model printing time: (?<v>[^;\n]+)"),
         filament_g: (header("; total filament weight \\[g\\] : (?<v>[0-9.]+)") | tonumber? // null),
         layer_height: ($cfg[0].layer_height | tonumber? // null),
         bed: $cfg[0].curr_bed_type}
        | (to_entries | map(select(.value == null).key)) as $missing
        | if $missing == [] then .
          else "FAIL \($model): the sliced 3MF has no \($missing | join(", ")).\n" | halt_error(1) end'

# Check every model and each of its parameter sets. The checks write to a temporary folder that
# is removed on exit, so check-all never changes the out folder, and it writes no renders.
[script]
check-all:
    shopt -s nullglob
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/check-all.XXXXXX")
    trap 'rm -rf "$tmp"' EXIT
    just=({{ quote(just_executable()) }} --justfile {{ quote(justfile()) }} projects={{ quote(projects) }} out="$tmp")
    count=0
    failed=""
    for src in {{ quote(projects) }}/*/*.scad; do
        project=$(basename "$(dirname "$src")")
        name=$(basename "$src" .scad)
        # A model is <project>.scad or <project>-*.scad; any other .scad file is a helper.
        [[ "$name" == "$project" || "$name" == "$project"-* ]] || continue
        sets=("")
        json="${src%.scad}.json"
        if [[ -f "$json" ]]; then
            keys=$(jq -r '.parameterSets // {} | keys[]' "$json")
            while IFS= read -r key; do
                if [[ -n "$key" ]]; then sets+=("$key"); fi
            done <<< "$keys"
        fi
        for set in "${sets[@]}"; do
            count=$((count + 1))
            "${just[@]}" check "$name" "$set" || failed+="  $name${set:+ ($set)}"$'\n'
        done
    done
    if (( count == 0 )); then
        printf 'No models in %s.\n' {{ quote(projects) }}
        exit 0
    fi
    if [[ -n "$failed" ]]; then
        printf 'Failed checks:\n%s' "$failed" >&2
        exit 1
    fi
    echo "All $count checks pass."

# Download the X2D User Manual into out/manual/ once, convert it to text unless the text is newer
# than the PDF, and print the text path.
[script]
manual:
    dir={{ quote(out / "manual") }}
    pdf="$dir/x2d-manual.pdf" txt="$dir/x2d-manual.txt"
    mkdir -p "$dir"
    if [[ ! -s "$pdf" ]]; then
        curl -fsSL --retry 2 -o "$pdf.part" {{ quote(manual_url) }} \
            || { rm -f "$pdf.part"; echo "FAIL: could not download {{ manual_url }}." >&2; exit 1; }
        mv "$pdf.part" "$pdf"
    fi
    if [[ ! -s "$txt" || ! "$txt" -nt "$pdf" ]]; then
        pdftotext -layout "$pdf" "$txt.part" || { rm -f "$txt.part"; exit 1; }
        mv "$txt.part" "$txt"
    fi
    echo "$txt"
