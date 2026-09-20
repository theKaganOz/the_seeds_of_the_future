extends SceneTree

# Run: godot --headless --path . --script scripts/tests/test_revive_ai.gd
# Tests the revive decision deterministically via the probability function
# itself (avoiding RNG flakiness), then tests the actual pursue/channel
# mechanics with the decision forced, since those are deterministic once
# the AI has committed.

const ComplianceEngineScript := preload("res://scripts/compliance_engine.gd")

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	var main: Node = main_scene.instantiate()
	get_root().add_child(main)

	var player: Node = main.get_node("Player")
	var teammate = main.get_node("Teammate")
	teammate.player = player

	var failures := 0

	# --- Decision: low danger should make reviving very likely ---
	teammate.state.scarcity = 0.0
	var p_low_danger: float = ComplianceEngineScript.compliance_probability(teammate.state, 0.1, "player", true)
	print("Compliance probability, low danger: %.3f" % p_low_danger)
	failures += _check("low-danger revive probability is high", p_low_danger > 0.8)

	# --- Decision: high danger + high scarcity should meaningfully lower it ---
	teammate.state.scarcity = 1.0
	var p_high_danger: float = ComplianceEngineScript.compliance_probability(teammate.state, 0.9, "player", true)
	print("Compliance probability, high danger + high scarcity: %.3f" % p_high_danger)
	failures += _check("high-danger/scarcity probability is meaningfully lower", p_high_danger < p_low_danger)

	# --- Scarcity is actually read from the live ammo pool, not a stub ---
	get_root().get_node("SquadInventory").ammo = get_root().get_node("SquadInventory").MAX_AMMO
	player.is_down = true
	teammate.committed_to_revive = false
	teammate._consider_revive()  # direct call is fine; this just recomputes state.scarcity + rolls
	failures += _check("scarcity reflects full ammo pool (0.0)", is_equal_approx(teammate.state.scarcity, 0.0))

	get_root().get_node("SquadInventory").ammo = 0
	teammate.committed_to_revive = false
	teammate._consider_revive()
	failures += _check("scarcity reflects empty ammo pool (1.0)", is_equal_approx(teammate.state.scarcity, 1.0))
	get_root().get_node("SquadInventory").ammo = get_root().get_node("SquadInventory").MAX_AMMO

	# --- Full pursue-and-channel mechanics, decision forced to isolate from RNG ---
	player.global_position = Vector3(10, 1, 10)
	teammate.global_position = Vector3(0, 1, 0)
	player.is_down = true
	teammate.is_down = false
	teammate.committed_to_revive = true
	teammate.revive_channel_progress = 0.0

	# --- Approach: confirm real movement toward the player over physics
	# steps (matching the same "distance decreases" standard used in
	# test_teammate_follow.gd -- move_and_slide() uses the engine's actual
	# physics delta internally regardless of what we pass manually, so
	# manually-stepped movement magnitude is approximate, not exact;
	# direction/progress is the honest thing to assert here).
	var initial_dist: float = teammate.global_position.distance_to(player.global_position)
	for i in range(120):
		teammate._physics_process(1.0 / 60.0)
	var after_approach_dist: float = teammate.global_position.distance_to(player.global_position)
	print("Revive approach distance: %.2f -> %.2f" % [initial_dist, after_approach_dist])
	failures += _check("teammate closed distance toward downed player", after_approach_dist < initial_dist)

	# --- Channel completion: teleport into range directly and confirm the
	# channel-and-complete logic itself works, decoupled from approach speed.
	teammate.global_position = player.global_position + Vector3(1, 0, 0)
	teammate.revive_channel_progress = 0.0
	for i in range(200):
		teammate._physics_process(1.0 / 60.0)

	failures += _check("player was actually revived (is_down cleared)", not player.is_down)
	failures += _check("player health restored on revive", player.health == player.REVIVE_HEAL)
	failures += _check("teammate's commitment cleared after completing revive", not teammate.committed_to_revive)

	print("")
	if failures == 0:
		print("ALL REVIVE AI TESTS PASSED")
	else:
		print("%d REVIVE AI TEST(S) FAILED" % failures)
	quit()

func _check(label: String, condition: bool) -> int:
	if condition:
		print("  PASS  ", label)
		return 0
	else:
		print("  FAIL  ", label)
		return 1

func is_equal_approx(a: float, b: float, tolerance: float = 0.01) -> bool:
	return abs(a - b) < tolerance
