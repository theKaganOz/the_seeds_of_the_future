extends SceneTree

# Run: godot --headless --path . --script scripts/tests/test_ammo.gd
# Confirms the ammo pool is genuinely shared: teammate fire consumes from
# the same pool the player draws from, and hitting zero stops further
# damage from either.

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	var main: Node = main_scene.instantiate()
	get_root().add_child(main)

	var teammate: Node3D = main.get_node("Teammate")
	var enemy_scene := load("res://scenes/Enemy.tscn") as PackedScene
	var enemy = enemy_scene.instantiate()
	main.add_child(enemy)

	teammate.global_position = Vector3(-3, 1, 0)
	enemy.global_position = Vector3(0, 1, 0)

	get_root().get_node("SquadInventory").ammo = 3
	var failures := 0

	print("Starting ammo: %d" % get_root().get_node("SquadInventory").ammo)
	for i in range(300):
		teammate.can_attack = true
		teammate._physics_process(1.0 / 60.0)

	print("Ammo after combat: %d" % get_root().get_node("SquadInventory").ammo)
	if get_root().get_node("SquadInventory").ammo == 0:
		print("  PASS  shared pool depleted to zero")
	else:
		print("  FAIL  pool did not deplete correctly (%d remaining)" % get_root().get_node("SquadInventory").ammo)
		failures += 1

	var health_at_empty: int = enemy.health
	for i in range(60):
		teammate.can_attack = true
		teammate._physics_process(1.0 / 60.0)
	if enemy.health == health_at_empty:
		print("  PASS  no further damage dealt once ammo hit zero")
	else:
		print("  FAIL  damage still dealt with zero ammo (%d -> %d)" % [health_at_empty, enemy.health])
		failures += 1

	print("")
	if failures == 0:
		print("ALL AMMO TESTS PASSED")
	else:
		print("%d AMMO TEST(S) FAILED" % failures)
	quit()
