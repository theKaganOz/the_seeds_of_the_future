extends SceneTree

# Run: godot --headless --path . --script scripts/tests/test_aggro.gd
# Confirms: (1) an untouched enemy defaults to targeting the player, and
# (2) taking damage from the teammate switches its aggro target to the
# teammate, even with the player also present.

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	var main: Node = main_scene.instantiate()
	get_root().add_child(main)

	var player: Node3D = main.get_node("Player")
	var teammate: Node3D = main.get_node("Teammate")
	var enemy_scene := load("res://scenes/Enemy.tscn") as PackedScene
	var enemy = enemy_scene.instantiate()
	main.add_child(enemy)

	player.global_position = Vector3(0, 1, 0)
	teammate.global_position = Vector3(5, 1, 0)
	enemy.global_position = Vector3(0, 1, 5)

	var failures := 0

	if is_instance_valid(enemy.aggro_target) and enemy.aggro_target == player:
		print("  PASS  untouched enemy defaults aggro to player")
	else:
		print("  FAIL  untouched enemy aggro is not the player")
		failures += 1

	enemy.take_damage(10, teammate)

	if enemy.aggro_target == teammate:
		print("  PASS  aggro switched to teammate after taking damage from them")
	else:
		print("  FAIL  aggro did not switch to teammate")
		failures += 1

	print("")
	if failures == 0:
		print("ALL AGGRO TESTS PASSED")
	else:
		print("%d AGGRO TEST(S) FAILED" % failures)
	quit()
