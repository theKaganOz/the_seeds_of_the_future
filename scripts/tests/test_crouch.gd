extends SceneTree

# Run: godot --headless --path . --script scripts/tests/test_crouch.gd
# Instantiates the real Player scene, simulates crouch input over real
# physics steps, and checks the numeric behavior actually converges the
# way the design intends — not just that it compiles.

var player: CharacterBody3D
var capsule: CapsuleShape3D
var failures := 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var player_scene := load("res://scenes/Player.tscn")
	player = player_scene.instantiate()
	get_root().add_child(player)
	capsule = player.get_node("CollisionShape3D").shape

	_check(
		"standing collision position starts at y=0 (unchanged from pre-crouch baseline)",
		_approx(player.get_node("CollisionShape3D").position.y, 0.0)
	)
	_check("standing capsule height starts at 1.8", _approx(capsule.height, 1.8))
	_check("standing camera y starts at 0.7", _approx(player.get_node("Camera3D").position.y, 0.7))

	print("")
	print("Pressing crouch and stepping physics...")
	Input.action_press("crouch")
	for i in range(60):
		player._update_crouch(1.0 / 60.0)

	print("  capsule height -> %.3f (target 1.0)" % capsule.height)
	print("  collision y    -> %.3f (target -0.4)" % player.get_node("CollisionShape3D").position.y)
	print("  camera y       -> %.3f (target 0.25)" % player.get_node("Camera3D").position.y)
	_check("capsule height converged near crouch target", _approx(capsule.height, 1.0))
	_check("collision offset converged near -0.4 (bottom stayed fixed)", abs(player.get_node("CollisionShape3D").position.y - (-0.4)) < 0.01)
	_check("camera converged near crouch eye height", abs(player.get_node("Camera3D").position.y - 0.25) < 0.01)

	print("")
	print("Releasing crouch (no ceiling above) and stepping physics...")
	Input.action_release("crouch")
	for i in range(60):
		player._update_crouch(1.0 / 60.0)

	print("  capsule height -> %.3f (target 1.8)" % capsule.height)
	print("  collision y    -> %.3f (target 0.0)" % player.get_node("CollisionShape3D").position.y)
	print("  camera y       -> %.3f (target 0.7)" % player.get_node("Camera3D").position.y)
	_check("capsule height returned to standing", _approx(capsule.height, 1.8))
	_check("collision offset returned to 0 (matches original baseline exactly)", _approx(player.get_node("CollisionShape3D").position.y, 0.0))
	_check("camera returned to standing eye height", _approx(player.get_node("Camera3D").position.y, 0.7))

	print("")
	if failures == 0:
		print("ALL CROUCH TESTS PASSED")
	else:
		print("%d TEST(S) FAILED" % failures)
	quit()

func _check(label: String, condition: bool) -> void:
	if condition:
		print("  PASS  ", label)
	else:
		print("  FAIL  ", label)
		failures += 1

func _approx(a: float, b: float, tolerance: float = 0.05) -> bool:
	return abs(a - b) < tolerance
