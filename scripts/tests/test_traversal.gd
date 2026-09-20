extends SceneTree

# Run: godot --headless --path . --script scripts/tests/test_traversal.gd
# Loads the real level and raycasts along the center-to-center line between
# every connected room pair, at chest height, confirming nothing blocks it.
# This directly tests the doorway-gap fix — arithmetic that "looks right"
# isn't trustworthy until something actually confirms the space is open.

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var level_scene := load("res://scenes/Main.tscn") as PackedScene
	var main: Node = level_scene.instantiate()
	get_root().add_child(main)

	var level: Node = main.get_node("Level")
	var rooms: Array = level._rooms
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state

	var failures := 0
	for i in range(rooms.size() - 1):
		var a: Vector3 = rooms[i]["pos"] + Vector3(0, 1.5, 0)
		var b: Vector3 = rooms[i + 1]["pos"] + Vector3(0, 1.5, 0)
		var query := PhysicsRayQueryParameters3D.create(a, b)
		var result: Dictionary = space.intersect_ray(query)
		if result.is_empty():
			print("  PASS  room %d -> room %d: doorway clear" % [i, i + 1])
		else:
			print("  FAIL  room %d -> room %d: blocked by %s at %s" % [i, i + 1, result["collider"].name, result["position"]])
			failures += 1

	print("")
	if failures == 0:
		print("ALL TRAVERSAL TESTS PASSED")
	else:
		print("%d TRAVERSAL TEST(S) FAILED" % failures)
	quit()
