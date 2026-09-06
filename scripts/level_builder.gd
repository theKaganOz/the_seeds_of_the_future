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
]

func _ready() -> void:
	_build_floor_and_ceiling()
	for i in range(_rooms.size()):
		_build_room(_rooms[i])
		if i < _rooms.size() - 1:
			_build_corridor(_rooms[i], _rooms[i + 1])
	_spawn_enemies()

func _build_floor_and_ceiling() -> void:
	var floor_mesh := _make_box(Vector3(60, 0.5, 60), Color(0.15, 0.15, 0.17))
	floor_mesh.position = Vector3(0, -0.25, -10)
	add_child(floor_mesh)
	_add_static_collision(floor_mesh, Vector3(60, 0.5, 60))

func _build_room(room: Dictionary) -> void:
	var pos: Vector3 = room["pos"]
	var size: Vector3 = room["size"]
	var wall_thickness := 0.5

	# four walls as thin boxes around the room perimeter
	var walls := [
		{"offset": Vector3(0, WALL_HEIGHT / 2, -size.z / 2), "size": Vector3(size.x, WALL_HEIGHT, wall_thickness)},
		{"offset": Vector3(0, WALL_HEIGHT / 2, size.z / 2), "size": Vector3(size.x, WALL_HEIGHT, wall_thickness)},
		{"offset": Vector3(-size.x / 2, WALL_HEIGHT / 2, 0), "size": Vector3(wall_thickness, WALL_HEIGHT, size.z)},
		{"offset": Vector3(size.x / 2, WALL_HEIGHT / 2, 0), "size": Vector3(wall_thickness, WALL_HEIGHT, size.z)},
	]
	for w in walls:
		var wall_mesh := _make_box(w["size"], Color(0.3, 0.28, 0.32))
		wall_mesh.position = pos + w["offset"]
		add_child(wall_mesh)
		_add_static_collision(wall_mesh, w["size"])

func _build_corridor(room_a: Dictionary, room_b: Dictionary) -> void:
	var a: Vector3 = room_a["pos"]
	var b: Vector3 = room_b["pos"]
	var mid := (a + b) / 2.0
	var length := a.distance_to(b)
	var size := Vector3(CORRIDOR_WIDTH, WALL_HEIGHT, length)

	var corridor := Node3D.new()
	add_child(corridor)
	corridor.position = mid
	corridor.look_at(b, Vector3.UP)

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
