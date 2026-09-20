extends SceneTree

# Run: godot --headless --path . --script scripts/tests/test_hitboxes.gd

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	var main: Node = main_scene.instantiate()
	get_root().add_child(main)

	var player: Node = main.get_node("Player")
	var teammate: Node = main.get_node("Teammate")
	var enemy_scene := load("res://scenes/Enemy.tscn") as PackedScene
	var enemy = enemy_scene.instantiate()
	main.add_child(enemy)

	var failures := 0

	# --- Classification ---
	enemy.global_position = Vector3(0, 1, 0)
	failures += _check(
		"enemy: high hit point classifies as headshot",
		enemy.is_headshot_at(Vector3(0, 1.8, 0))
	)
	failures += _check(
		"enemy: low hit point classifies as body shot",
		not enemy.is_headshot_at(Vector3(0, 1.0, 0))
	)

	player.global_position = Vector3(0, 1.2, 0)
	failures += _check(
		"player (standing): high hit point classifies as headshot",
		player.is_headshot_at(Vector3(0, 2.0, 0))
	)
	failures += _check(
		"player (standing): chest-height hit point classifies as body shot",
		not player.is_headshot_at(Vector3(0, 1.5, 0))
	)

	teammate.global_position = Vector3(0, 1, 0)
	failures += _check(
		"teammate: high hit point classifies as headshot",
		teammate.is_headshot_at(Vector3(0, 1.8, 0))
	)
	failures += _check(
		"teammate: chest-height hit point classifies as body shot",
		not teammate.is_headshot_at(Vector3(0, 1.2, 0))
	)

	# --- Consequences ---
	enemy.health = enemy.MAX_HEALTH
	enemy.take_damage(1, null, true)  # trivial amount, but headshot=true
	await process_frame
	failures += _check("enemy: headshot is an instant kill regardless of amount", not is_instance_valid(enemy))

	var enemy2 = enemy_scene.instantiate()
	main.add_child(enemy2)
	enemy2.health = enemy2.MAX_HEALTH
	enemy2.take_damage(30, null, false)
	failures += _check(
		"enemy: body shot only deals its amount, doesn't kill outright with new higher health",
		is_instance_valid(enemy2) and enemy2.health == enemy2.MAX_HEALTH - 30
	)

	player.is_down = false
	player.health = player.MAX_HEALTH
	player.take_damage(1, null, true)
	failures += _check("player: headshot forces incapacitation regardless of amount", player.is_down)

	teammate.is_down = false
	teammate.health = teammate.MAX_HEALTH
	teammate.take_damage(1, null, true)
	failures += _check("teammate: headshot forces incapacitation regardless of amount", teammate.is_down)

	print("")
	if failures == 0:
		print("ALL HITBOX TESTS PASSED")
	else:
		print("%d HITBOX TEST(S) FAILED" % failures)
	quit()

func _check(label: String, condition: bool) -> int:
	if condition:
		print("  PASS  ", label)
		return 0
	else:
		print("  FAIL  ", label)
		return 1
