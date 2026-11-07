#!/bin/bash
# Compile the edited model without geometry, and send each OpenSCAD error or warning to Claude.
set -uo pipefail

file=$(jq -r '.tool_input.file_path // empty')
# Act only on a .scad file in projects/<project>/ or examples/<project>/, so lib/, tools/ and other
# folders are skipped.
dir=$(dirname "$file")
project=$(basename "$dir")
case "$file" in
    */projects/"$project"/*.scad | */examples/"$project"/*.scad) ;;
    *) exit 0 ;;
esac
# A model is <project>.scad or <project>-*.scad. Any other file is a helper, which can read a
# model's globals and so fails alone: compile each model in its project.
case "$file" in
    */"$project".scad | */"$project"-*.scad) models=("$file") ;;
    *) models=("$dir/$project".scad "$dir/$project"-*.scad) ;;
esac

status=0
for model in "${models[@]}"; do
    # Skip a pattern that matched no file.
    [[ -f "$model" ]] || continue
    log=$(OPENSCADPATH="$CLAUDE_PROJECT_DIR/lib" "$CLAUDE_PROJECT_DIR/tools/openscad" \
        --export-format=echo -o - "$model" 2>&1) && continue
    # Exit 2 on PostToolUse shows stderr to Claude. Print the whole log when no line has a prefix.
    status=2
    {
        echo "OpenSCAD compile failed: $model"
        [[ "$model" == "$file" ]] || echo "It was compiled because the helper $file changed."
        grep -E '^(ERROR|TRACE|WARNING|DEPRECATED|EXPORT-ERROR):|^ECHO: "WARNING' <<< "$log" \
            || printf '%s\n' "$log"
    } >&2
done
exit "$status"
