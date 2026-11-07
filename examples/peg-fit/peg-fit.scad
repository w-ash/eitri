// Peg fit test: a plate with a round hole, and a peg to push into it, side by side on the bed.
// Each parameter set in peg-fit.json prints one clearance. Brief: examples/peg-fit/peg-fit.md.

include <BOSL2/std.scad>

/* [Peg] */
// Peg diameter, mm (Dimensions, "Peg diameter").
peg_d = 8; // [3:0.5:20]
// Peg length, mm (Dimensions, "Peg length").
peg_h = 10; // [3:0.5:40]

/* [Plate] */
// Plate thickness, mm (Dimensions, "Plate thickness").
plate_t = 5; // [2:0.5:20]
// Plate border round the hole, mm. Design choice.
plate_margin = 6; // [2:0.5:20]
// Radius of the plate's vertical corners, mm. Design choice.
corner_r = 2; // [0:0.5:10]

/* [Fit] */
// Clearance between peg and hole on each side, mm. Fit test: the sets in peg-fit.json.
clearance = 0.2; // [0:0.05:1]

/* [Finish] */
// Chamfer on the peg's ends and the hole's edges, mm. Design choice: it eases entry and offsets
// the first layer's squish.
chamfer = 0.5; // [0:0.1:2]
// Gap between the plate and the peg on the bed, mm. Design choice.
spacing = 5; // [2:0.5:20]

/* [Hidden] */
$fa = 2;
$fs = 0.25;
eps = 0.01;
hole_d = peg_d + 2 * clearance;
plate_w = hole_d + 2 * plate_margin;

assert(peg_h > plate_t, "peg_h must be more than plate_t, so the peg stands proud of the plate");
assert(2 * chamfer < min(peg_h, plate_t), "chamfer is too large for peg_h or plate_t");
assert(chamfer < peg_d / 2, "chamfer is too large for peg_d");
assert(corner_r < plate_w / 2, "corner_r is too large for the plate");

// The plate, centered on the origin, with the hole through it.
module fit_plate() {
    diff()
        cuboid([plate_w, plate_w, plate_t], rounding = corner_r, edges = "Z", anchor = BOTTOM)
            tag("remove") cyl(d = hole_d, h = plate_t, chamfer = -chamfer, extra = eps);
}

// The peg, standing on its end at the origin.
module fit_peg() {
    cyl(d = peg_d, h = peg_h, chamfer = chamfer, anchor = BOTTOM);
}

left(plate_w / 2 + spacing / 2) fit_plate();
right(peg_d / 2 + spacing / 2) fit_peg();
