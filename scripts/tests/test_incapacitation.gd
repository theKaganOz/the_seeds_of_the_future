extends SceneTree

# Run: godot --headless --path . --script scripts/tests/test_incapacitation.gd

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	var main: Node = main_scene.instantiate()
	get_root().add_child(main)

	var player: Node = main.get_node("Player")
	var teammate: Node = main.get_node("Teammate")

	var failures := 0
	failures += _check("player starts not down", not player.is_down)
	failures += _check("teammate starts not down", not teammate.is_down)

	player.take_damage(player.MAX_HEALTH)
	failures += _check("player health floors at 0", player.health == 0)
	failures += _check("player is down after health hits 0", player.is_down)

	player.take_damage(50)
	failures += _check("further damage while down is a no-op", player.health == 0)

	player.revive()
	failures += _check("player revive clears is_down", not player.is_down)
	failures += _check("player revive restores health to REVIVE_HEAL", player.health == player.REVIVE_HEAL)

	teammate.take_damage(teammate.MAX_HEALTH)
	failures += _check("teammate health floors at 0", teammate.health == 0)
	failures += _check("teammate is down after health hits 0", teammate.is_down)

	teammate.take_damage(50)
	failures += _check("further damage while teammate down is a no-op", teammate.health == 0)

	teammate.revive()
	failures += _check("teammate revive clears is_down", not teammate.is_down)
	failures += _check("teammate revive restores health to REVIVE_HEAL", teammate.health == teammate.REVIVE_HEAL)

	print("")
	if failures == 0:
		print("ALL INCAPACITATION TESTS PASSED")
	else:
		print("%d INCAPACITATION TEST(S) FAILED" % failures)
	quit()

func _check(label: String, condition: bool) -> int:
	if condition:
		print("  PASS  ", label)
		return 0
	else:
		print("  FAIL  ", label)
		return 1
