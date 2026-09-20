extends Node3D

# Simple Doom-style layout: a chain of rectangular rooms connected by corridors.
# Everything is boxes for now -- swap in real geometry later once the mechanics
# (movement, shooting, enemy chase, branching state) are validated.

const WALL_HEIGHT := 4.0
const CORRIDOR_WIDTH := 3.0

@export var enemy_scene: PackedScene

var _rooms := [
	{"pos": Vector3(0, 0, 0), "size": Vector3(10, WALL_HEIGHT, 10)},
	{"pos": Vector3(0, 0, -20), "size": Vector3(14, WALL_HEIGHT, 10)},
	{"pos": Vector3(16, 0, -20), "size": Vector3(10, WALL_HEIGHT, 14)},
	{"pos": Vector3(16, 0, -50), "size": Vector3(28, WALL_HEIGHT, 28)},
]

func _ready() -> void:
	_build_floor_and_ceiling()
	for i in range(_rooms.size()):
		var openings: Array[int] = []
		if i > 0:
			openings.append(_wall_index_toward(_rooms[i]["pos"], _rooms[i - 1]["pos"]))
		if i < _rooms.size() - 1:
			openings.append(_wall_index_toward(_rooms[i]["pos"], _rooms[i + 1]["pos"]))
		_build_room(_rooms[i], openings)
		if i < _rooms.size() - 1:
			_build_corridor(_rooms[i], _rooms[i + 1])
	_spawn_enemies()

# Wall indices match the `walls` array order in _build_room: 0=-z (front),
# 1=+z (back), 2=-x (left), 3=+x (right). Connections in this level are
# always axis-aligned, so a simple direction check is enough to know which
# wall of `from_room` needs a doorway gap to reach `to_room`.
func _wall_index_toward(from_pos: Vector3, to_pos: Vector3) -> int:
	var delta := to_pos - from_pos
	if absf(delta.z) >= absf(delta.x):
		return 0 if delta.z < 0 else 1
	else:
		return 2 if delta.x < 0 else 3

func _build_floor_and_ceiling() -> void:
	var floor_mesh := _make_box(Vector3(80, 0.5, 90), Color(0.15, 0.15, 0.17))
	floor_mesh.position = Vector3(11.5, -0.25, -29.5)
	add_child(floor_mesh)
	_add_static_collision(floor_mesh, Vector3(80, 0.5, 90))

func _build_room(room: Dictionary, openings: Array[int] = []) -> void:
	var pos: Vector3 = room["pos"]
	var size: Vector3 = room["size"]
	var wall_thickness := 0.5

	# four walls as thin boxes around the room perimeter
	# index: 0=-z (front), 1=+z (back), 2=-x (left), 3=+x (right)
	var walls := [
		{"offset": Vector3(0, WALL_HEIGHT / 2, -size.z / 2), "size": Vector3(size.x, WALL_HEIGHT, wall_thickness), "axis": "x", "length": size.x},
		{"offset": Vector3(0, WALL_HEIGHT / 2, size.z / 2), "size": Vector3(size.x, WALL_HEIGHT, wall_thickness), "axis": "x", "length": size.x},
		{"offset": Vector3(-size.x / 2, WALL_HEIGHT / 2, 0), "size": Vector3(wall_thickness, WALL_HEIGHT, size.z), "axis": "z", "length": size.z},
		{"offset": Vector3(size.x / 2, WALL_HEIGHT / 2, 0), "size": Vector3(wall_thickness, WALL_HEIGHT, size.z), "axis": "z", "length": size.z},
	]
	for i in range(walls.size()):
		var w: Dictionary = walls[i]
		if i in openings and w["length"] > CORRIDOR_WIDTH:
			_build_wall_with_gap(pos, w)
		else:
			var wall_mesh := _make_box(w["size"], Color(0.3, 0.28, 0.32))
			wall_mesh.position = pos + w["offset"]
			add_child(wall_mesh)
			_add_static_collision(wall_mesh, w["size"])

func _build_wall_with_gap(room_pos: Vector3, wall: Dictionary) -> void:
	var segment_len: float = (wall["length"] - CORRIDOR_WIDTH) / 2.0
	var thickness: float = wall["size"].x if wall["axis"] == "z" else wall["size"].z
	for side in [-1, 1]:
		var center_offset: float = side * (CORRIDOR_WIDTH / 2.0 + segment_len / 2.0)
		var seg_size: Vector3
		var seg_pos: Vector3
		if wall["axis"] == "x":
			seg_size = Vector3(segment_len, WALL_HEIGHT, thickness)
			seg_pos = wall["offset"] + Vector3(center_offset, 0, 0)
		else:
			seg_size = Vector3(thickness, WALL_HEIGHT, segment_len)
			seg_pos = wall["offset"] + Vector3(0, 0, center_offset)
		var seg_mesh := _make_box(seg_size, Color(0.3, 0.28, 0.32))
		seg_mesh.position = room_pos + seg_pos
		add_child(seg_mesh)
		_add_static_collision(seg_mesh, seg_size)

func _build_corridor(room_a: Dictionary, room_b: Dictionary) -> void:
	var a_pos: Vector3 = room_a["pos"]
	var b_pos: Vector3 = room_b["pos"]
	var a_size: Vector3 = room_a["size"]
	var b_size: Vector3 = room_b["size"]
	var delta: Vector3 = b_pos - a_pos
	var dir: Vector3 = delta.normalized()

	# Trim the corridor to run wall-to-wall instead of center-to-center, so
	# it doesn't overlap into either room's interior past the doorway.
	var a_half: float
	var b_half: float
	if absf(delta.z) >= absf(delta.x):
		a_half = a_size.z / 2.0
		b_half = b_size.z / 2.0
	else:
		a_half = a_size.x / 2.0
		b_half = b_size.x / 2.0
	var start: Vector3 = a_pos + dir * a_half
	var end: Vector3 = b_pos - dir * b_half
	var mid: Vector3 = (start + end) / 2.0
	var length: float = start.distance_to(end)
	var size := Vector3(CORRIDOR_WIDTH, WALL_HEIGHT, length)

	var corridor := Node3D.new()
	add_child(corridor)
	corridor.position = mid
	corridor.look_at(end, Vector3.UP)

	var side_a := _make_box(Vector3(0.4, WALL_HEIGHT, length), Color(0.25, 0.24, 0.27))
	side_a.position = Vector3(CORRIDOR_WIDTH / 2, WALL_HEIGHT / 2, 0)
	corridor.add_child(side_a)
	_add_static_collision(side_a, Vector3(0.4, WALL_HEIGHT, length))

	var side_b := _make_box(Vector3(0.4, WALL_HEIGHT, length), Color(0.25, 0.24, 0.27))
	side_b.position = Vector3(-CORRIDOR_WIDTH / 2, WALL_HEIGHT / 2, 0)
	corridor.add_child(side_b)
	_add_static_collision(side_b, Vector3(0.4, WALL_HEIGHT, length))

func _make_box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_instance.material_override = mat
	return mesh_instance

func _add_static_collision(mesh_instance: MeshInstance3D, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	mesh_instance.add_child(body)

func _spawn_enemies() -> void:
	if not enemy_scene:
		return
	var spawn_points := [
		_rooms[1]["pos"] + Vector3(3, 1, 2),
		_rooms[2]["pos"] + Vector3(-2, 1, 3),
		_rooms[2]["pos"] + Vector3(2, 1, -3),
	]
	for p in spawn_points:
		var e := enemy_scene.instantiate()
		add_child(e)
		e.position = p
