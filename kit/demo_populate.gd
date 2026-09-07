extends Node3D

# Populates the GridMap in code via set_cell_item, which is safe/testable —
# avoids hand-encoding GridMap's packed cell data format.
@onready var grid_map: GridMap = $GridMap

const FLOOR := 0
const WALL := 1
const CORNER := 2
const DOORWAY := 3
const PILLAR := 4

func _ready() -> void:
	# A simple 3x3-cell room to prove the kit paints and aligns correctly.
	for x in range(3):
		for z in range(3):
			grid_map.set_cell_item(Vector3i(x, 0, z), FLOOR)

	# Perimeter walls (orientation 0 = default facing; GridMap.ORTHOGONAL_INDEX
	# values rotate the piece — 10 = 90°, 16 = 180°, 22 = 270° in Godot 4's table)
	grid_map.set_cell_item(Vector3i(0, 0, 0), WALL, 0)
	grid_map.set_cell_item(Vector3i(1, 0, 0), WALL, 0)
	grid_map.set_cell_item(Vector3i(2, 0, 0), CORNER, 10)
	grid_map.set_cell_item(Vector3i(2, 0, 1), WALL, 10)
	grid_map.set_cell_item(Vector3i(2, 0, 2), CORNER, 16)
	grid_map.set_cell_item(Vector3i(1, 0, 2), DOORWAY, 16)
	grid_map.set_cell_item(Vector3i(0, 0, 2), CORNER, 22)
	grid_map.set_cell_item(Vector3i(0, 0, 1), WALL, 22)

	grid_map.set_cell_item(Vector3i(1, 0, 1), PILLAR)
