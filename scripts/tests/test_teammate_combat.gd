extends SceneTree

# Run: godot --headless --path . --script scripts/tests/test_teammate_combat.gd
# Places a teammate and an enemy with clear line of sight to each other and
# confirms the enemy's health actually drops over real physics steps.

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	var main: Node = main_scene.instantiate()
	get_root().add_child(main)

	var teammate: Node3D = main.get_node("Teammate")
	var enemy_scene := load("res://scenes/Enemy.tscn") as PackedScene
	var enemy: Node = enemy_scene.instantiate()
	main.add_child(enemy)

	# Place teammate and enemy close together with a clear line of sight,
	# inside the starting room, away from the player so only the teammate
	# is responsible for any damage dealt.
	teammate.global_position = Vector3(-3, 1, 0)
	enemy.global_position = Vector3(0, 1, 0)

	var initial_health: int = enemy.health
	print("Enemy initial health: %d" % initial_health)

	for i in range(180):
		teammate._physics_process(1.0 / 60.0)

	var final_health: int = enemy.health
	print("Enemy health after 180 physics steps: %d" % final_health)

	if final_health < initial_health:
		print("  PASS  teammate dealt damage to visible enemy")
	else:
		print("  FAIL  enemy health unchanged (%d -> %d)" % [initial_health, final_health])

	quit()
