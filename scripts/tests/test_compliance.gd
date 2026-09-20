extends SceneTree

# Run: godot --headless --path . --script scripts/test_compliance.gd
# (project must have been opened/scanned once already so global class_name
# registration exists — see .godot/global_script_class_cache.cfg)
# Asserts the actual numeric behavior of the compliance model against every
# design decision we've locked, not just that the code executes.

func _initialize() -> void:
	var failures := 0
	failures += _test_low_risk_orders_almost_always_followed()
	failures += _test_high_scarcity_suppresses_risky_orders()
	failures += _test_partner_bond_overrides_scarcity()
	failures += _test_stranger_bond_does_not_override_scarcity()
	failures += _test_revive_harder_to_suppress_than_ordinary_order()
	failures += _test_revive_still_suppressible_under_extreme_scarcity()
	failures += _test_morale_growth_lifts_compliance()

	print("")
	if failures == 0:
		print("ALL COMPLIANCE ENGINE TESTS PASSED")
	else:
		print("%d TEST(S) FAILED" % failures)
	quit()

func _make_state(scarcity: float, morale: float, bonds: Dictionary = {}) -> CharacterState:
	var s := CharacterState.new()
	s.scarcity = scarcity
	s.morale = morale
	s.bonds = bonds
	return s

func _check(label: String, condition: bool, detail: String) -> int:
	if condition:
		print("  PASS  ", label)
		return 0
	else:
		print("  FAIL  ", label, "  (", detail, ")")
		return 1

func _test_low_risk_orders_almost_always_followed() -> int:
	print("Low-risk orders should be followed almost regardless of scarcity:")
	var desperate := _make_state(0.9, 0.5)
	var p := ComplianceEngine.compliance_probability(desperate, 0.1)
	return _check("routine order, desperate teammate", p > 0.85, "p=%.3f" % p)

func _test_high_scarcity_suppresses_risky_orders() -> int:
	print("High scarcity should suppress compliance with a risky order (no bond):")
	var comfortable := _make_state(0.1, 0.5)
	var desperate := _make_state(0.9, 0.5)
	var p_comfortable := ComplianceEngine.compliance_probability(comfortable, 0.8)
	var p_desperate := ComplianceEngine.compliance_probability(desperate, 0.8)
	return _check(
		"desperate < comfortable under risky order",
		p_desperate < p_comfortable and p_desperate < 0.5,
		"comfortable=%.3f desperate=%.3f" % [p_comfortable, p_desperate]
	)

func _test_partner_bond_overrides_scarcity() -> int:
	print("Partner-tier bond should override scarcity under a risky order concerning them:")
	var desperate_partner := _make_state(0.9, 0.5, {"partner": 1.0})
	var p := ComplianceEngine.compliance_probability(desperate_partner, 0.8, "partner")
	return _check("desperate but partner in danger", p > 0.75, "p=%.3f" % p)

func _test_stranger_bond_does_not_override_scarcity() -> int:
	print("Low bond should NOT override scarcity the way a partner bond does:")
	var desperate_stranger := _make_state(0.9, 0.5, {})
	var p := ComplianceEngine.compliance_probability(desperate_stranger, 0.8, "stranger")
	return _check("desperate, no real bond, stays low", p < 0.5, "p=%.3f" % p)

func _test_revive_harder_to_suppress_than_ordinary_order() -> int:
	print("Revive should be harder to suppress than an equivalent-risk ordinary order:")
	var state := _make_state(0.6, 0.5)
	var p_order := ComplianceEngine.compliance_probability(state, 0.7, "", false)
	var p_revive := ComplianceEngine.compliance_probability(state, 0.7, "", true)
	return _check(
		"revive probability > ordinary order at same risk/scarcity",
		p_revive > p_order,
		"order=%.3f revive=%.3f" % [p_order, p_revive]
	)

func _test_revive_still_suppressible_under_extreme_scarcity() -> int:
	print("Revive should still be suppressible under extreme scarcity + extreme risk (not a hard guarantee):")
	var extreme := _make_state(1.0, 0.2)
	var p := ComplianceEngine.compliance_probability(extreme, 1.0, "", true)
	return _check("extreme case keeps revive probability below near-certain", p < 0.9, "p=%.3f" % p)

func _test_morale_growth_lifts_compliance() -> int:
	print("Rising morale over the campaign should modestly lift compliance, all else equal:")
	var early := _make_state(0.5, 0.2)
	var late := _make_state(0.5, 0.8)
	var p_early := ComplianceEngine.compliance_probability(early, 0.5)
	var p_late := ComplianceEngine.compliance_probability(late, 0.5)
	return _check("late-campaign morale > early-campaign morale", p_late > p_early, "early=%.3f late=%.3f" % [p_early, p_late])
