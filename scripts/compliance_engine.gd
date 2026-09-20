class_name ComplianceEngine

## Pure, stateless compliance logic — every function here takes state in and
## returns a value out, with no node/scene dependency, which is what makes
## it testable headless without any level, player, or squad actually
## existing. Reused identically for combat commands, revives, and (with a
## different state source) enemy faction-loyalty behavior after a leader kill.

const W_COMMAND := 1.8      # baseline willingness to follow a low-risk order
const W_SCARCITY := 1.8     # how hard personal scarcity suppresses compliance
const W_BOND := 2.4         # how hard a relationship bond overrides that suppression
const W_MORALE := 0.6       # steady lift from accumulated morale/hope
const REVIVE_PRIORITY := 1.2  # flat boost for revive — top priority, not absolute

## command_risk: 0.0 (routine, e.g. "hold position" in a cleared room) to
## 1.0 (extremely dangerous, e.g. "push aggressively" into a live firefight).
## target_id: who the command concerns, if anyone (a revive target, or who
## an "aggressive"/"defend" order is meant to protect/engage near).
static func compliance_probability(
	state: CharacterState,
	command_risk: float,
	target_id: String = "",
	is_revive: bool = false
) -> float:
	var bond := state.bond_to(target_id) if target_id != "" else 0.1

	var x := 0.0
	x += W_COMMAND * (1.0 - command_risk)
	x += W_MORALE * state.morale
	x -= W_SCARCITY * state.scarcity * command_risk
	x += W_BOND * bond * command_risk
	if is_revive:
		x += REVIVE_PRIORITY

	return _sigmoid(x)

static func roll_compliance(
	state: CharacterState,
	command_risk: float,
	target_id: String = "",
	is_revive: bool = false
) -> bool:
	return randf() < compliance_probability(state, command_risk, target_id, is_revive)

static func _sigmoid(x: float) -> float:
	return 1.0 / (1.0 + exp(-x))
