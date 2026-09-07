extends SceneTree

# Generates kit/LevelKit.tres — a MeshLibrary of modular level pieces for use
# with a GridMap node. Run once via:
#   godot --headless --script kit/build_kit.gd
# Re-run any time you want to regenerate the kit (e.g. after tweaking sizes).

const CELL := 4.0        # matches GridMap.cell_size below
const WALL_H := 3.0
const WALL_T := 0.3
const HALF := CELL / 2.0

func _initialize() -> void:
	var lib := MeshLibrary.new()

	_add_item(lib, 0, "floor", _box_mesh(Vector3(CELL, 0.3, CELL)), Vector3(0, -0.15, 0), Color(0.16, 0.16, 0.18))
	_add_item(lib, 1, "wall_straight", _box_mesh(Vector3(CELL, WALL_H, WALL_T)), Vector3(0, WALL_H / 2.0, -HALF + WALL_T / 2.0), Color(0.32, 0.30, 0.34))
	_add_item(lib, 2, "wall_corner", _corner_mesh(), Vector3.ZERO, Color(0.32, 0.30, 0.34))
	_add_item(lib, 3, "doorway", _doorway_mesh(), Vector3.ZERO, Color(0.30, 0.28, 0.30))
	_add_item(lib, 4, "pillar", _cylinder_mesh(0.4, WALL_H), Vector3(0, WALL_H / 2.0, 0), Color(0.28, 0.26, 0.3))

	var dir := DirAccess.open("res://")
	if not dir.dir_exists("kit"):
		dir.make_dir("kit")

	var err := ResourceSaver.save(lib, "res://kit/LevelKit.tres")
	print("LevelKit.tres save result: ", err)
	quit()

func _box_mesh(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m

func _cylinder_mesh(radius: float, height: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	return m

func _corner_mesh() -> ArrayMesh:
	# Two wall segments meeting at the back-left corner of the cell, forming an L.
	var boxes := [
		{"size": Vector3(CELL, WALL_H, WALL_T), "pos": Vector3(0, WALL_H / 2.0, -HALF + WALL_T / 2.0)},
		{"size": Vector3(WALL_T, WALL_H, CELL), "pos": Vector3(-HALF + WALL_T / 2.0, WALL_H / 2.0, 0)},
	]
	return _merge_boxes(boxes)

func _doorway_mesh() -> ArrayMesh:
	# A wall segment with a walkable gap in the middle: two jambs + a lintel.
	var door_w := 1.2
	var jamb_w := (CELL - door_w) / 2.0
	var door_h := 2.2
	var lintel_h := WALL_H - door_h
	var z := -HALF + WALL_T / 2.0
	var boxes := [
		{"size": Vector3(jamb_w, WALL_H, WALL_T), "pos": Vector3(-(door_w / 2.0 + jamb_w / 2.0), WALL_H / 2.0, z)},
		{"size": Vector3(jamb_w, WALL_H, WALL_T), "pos": Vector3((door_w / 2.0 + jamb_w / 2.0), WALL_H / 2.0, z)},
		{"size": Vector3(door_w, lintel_h, WALL_T), "pos": Vector3(0, door_h + lintel_h / 2.0, z)},
	]
	return _merge_boxes(boxes)

func _merge_boxes(boxes: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b in boxes:
		var box := BoxMesh.new()
		box.size = b["size"]
		var xform := Transform3D(Basis(), b["pos"])
		st.append_from(box, 0, xform)
	st.generate_normals()
	return st.commit()

func _add_item(lib: MeshLibrary, id: int, item_name: String, mesh: Mesh, mesh_offset: Vector3, color: Color) -> void:
	lib.create_item(id)
	lib.set_item_name(id, item_name)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.surface_set_material(0, mat)

	lib.set_item_mesh(id, mesh)
	lib.set_item_mesh_transform(id, Transform3D(Basis(), mesh_offset))

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(mesh.get_faces())
	lib.set_item_shapes(id, [shape, Transform3D(Basis(), mesh_offset)])
