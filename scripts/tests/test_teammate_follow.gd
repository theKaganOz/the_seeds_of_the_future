extends SceneTree

# Run: godot --headless --path . --script scripts/tests/test_teammate_follow.gd
# Instantiates the real Main scene, teleports the player away, steps real
# physics frames, and confirms the teammate's distance to the player
# actually decreases — not just that the node exists and runs error-free.

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	var main: Node = main_scene.instantiate()
	get_root().add_child(main)

	var player: Node3D = main.get_node("Player")
	var teammate: Node3D = main.get_node("Teammate")

	# Force the deferred player lookup to have happened before we test.
	teammate.call("_find_player")

	player.global_position = Vector3(20, 1.2, 3)
	var initial_dist: float = teammate.global_position.distance_to(player.global_position)
	print("Initial distance after teleport: %.2f" % initial_dist)

	for i in range(120):
		teammate._physics_process(1.0 / 60.0)

	var final_dist: float = teammate.global_position.distance_to(player.global_position)
	print("Distance after 120 physics steps: %.2f" % final_dist)

	if final_dist < initial_dist:
		print("  PASS  teammate closed distance toward player")
	else:
		print("  FAIL  teammate did not close distance (%.2f -> %.2f)" % [initial_dist, final_dist])

	quit()
