// The difference makes Manifold convert the imported mesh. Set file with -D to an absolute path,
// and shift with -D to move the mesh by [x, y, z] mm.
shift = [0, 0, 0];
translate(shift) difference() { import(file); cube(0); }
