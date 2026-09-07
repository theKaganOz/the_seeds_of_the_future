# Level Kit (GridMap-based)

## What this is
A modular, hand-paintable level-building kit using Godot's built-in `GridMap`
node — the 3D equivalent of a tilemap. Instead of hand-placing individual
boxes (what `scripts/level_builder.gd` in the main project does), you paint
rooms cell-by-cell from a palette, snapped to a 4x4x4 unit grid.

## Files
- `kit/build_kit.gd` — generator script. Builds the five starter pieces
  (floor, straight wall, corner, doorway, pillar) as procedural meshes and
  saves them into `kit/LevelKit.tres`, a `MeshLibrary` resource. You do NOT
  need to run this normally — the generated `.tres` is already committed.
  Only re-run it if you change piece dimensions/geometry:
  ```
  godot --headless --path . --script kit/build_kit.gd
  ```
- `kit/LevelKit.tres` — the generated MeshLibrary. This is what you assign
  to a GridMap node's Mesh Library property.
- `kit/KitDemo.tscn` — a working example: a small 3x3-cell room built from
  the kit, to show correct usage and cell alignment.
- `kit/demo_populate.gd` — populates KitDemo's GridMap via code
  (`set_cell_item`) rather than hand-painting, just so there's a working
  reference open in the editor.

## How to use it for real level design
1. Open `kit/KitDemo.tscn` in the editor to see the reference layout, or
   create a new scene with a `GridMap` node.
2. Select the GridMap node, assign `kit/LevelKit.tres` as its **Mesh
   Library** in the Inspector.
3. With the GridMap selected, a palette panel appears at the bottom of the
   3D viewport showing the five pieces. Click one, then click-drag in the
   viewport to paint cells. Right-click removes a cell.
4. Use the rotate buttons in that same panel (or your configured rotate
   hotkeys) to orient walls/corners/doorways as needed per cell.
5. Floors go in the cell itself (Y=0 layer); walls/corners/doorways are
   placed in the *same* cell as the floor beneath them, on the edge they're
   meant to represent — the demo scene shows this directly.

## Extending the kit
To add a new piece type (e.g. a window, a ceiling piece, a broken/collapsed
wall variant for later chapters):
1. Add a new `_add_item(lib, <next id>, "name", <mesh>, <offset>, <color>)`
   call in `build_kit.gd`, following the existing patterns (`_box_mesh`,
   `_cylinder_mesh`, or `_merge_boxes` for compound shapes like the corner
   and doorway).
2. Re-run the generator command above.
3. The new piece appears automatically in the GridMap palette next time you
   open a scene using `LevelKit.tres`.

## Known caveat
The corner and doorway pieces' rotation orientation indices in
`demo_populate.gd` (10/16/22 for 90°/180°/270°) were derived from Godot's
orthogonal-basis rotation table, not visually confirmed — this sandbox has
no display to render against. If a piece looks mirrored or misaligned when
you open the editor, use the GridMap panel's rotate control on that cell
(one click) rather than editing the script; it's a placement issue, not a
geometry one.

## Relationship to the existing procedural level
`scripts/level_builder.gd` (the fully-procedural gray box level in the main
game) still works and is untouched. The two approaches can coexist — you
might keep procedural generation for quick playtesting layouts and use the
GridMap kit for actual authored, shippable levels. Nothing forces a choice
between them yet.
