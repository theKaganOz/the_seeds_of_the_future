extends CharacterBody3D

# First squad teammate. Autonomous follow/engage baseline, plus a real
# incapacitation/revive loop: reviving the DOWNED PLAYER is an AI decision
# that runs through the actual ComplianceEngine (scarcity derived from the
# live shared ammo pool, morale a static default -- no morale arc exists
# yet since that's a narrative-driven system, not built). Reviving a downed
# TEAMMATE is the player's own direct action (see player.gd's "revive"
# input), not a compliance decision, matching the locked design: compliance
# governs AI willingness, not the player's own choices.

const CharacterStateScript := preload("res://scripts/character_state.gd")
const ComplianceEngineScript := preload("res://scripts/compliance_engine.gd")

const SPEED := 5.0
const FOLLOW_DISTANCE := 4.0
const STOP_DISTANCE := 2.0
const ENGAGE_RANGE := 15.0
const ATTACK_DAMAGE := 20
const ATTACK_COOLDOWN := 0.8
const MAX_HEALTH := 80

# Revive AI tuning. These are defaults I'm choosing now, not values we've
# explicitly locked -- flag if they should be different once you've felt
# them in play.
const REVIVE_RANGE := 2.5
const REVIVE_CHANNEL_TIME := 1.5
const REVIVE_HEAL := 60
const REVIVE_RECONSIDER_INTERVAL := 2.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 18.0)
var player: Node3D
var can_attack := true
var current_target: Node3D = null
var health := MAX_HEALTH
var is_down := false

var committed_to_revive := false
var revive_channel_progress := 0.0

# Present now so future systems (compliance-driven commands, morale arc)
# read from real per-teammate state instead of being retrofitted.
var state = CharacterStateScript.new()

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var attack_timer: Timer = $AttackCooldown
@onready var attack_ray: RayCast3D = $AttackRay
@onready var revive_decision_timer: Timer = $ReviveDecisionTimer

func _ready() -> void:
	add_to_group("teammate")
	state.id = "teammate_1"
	call_deferred("_find_player")

	attack_timer.wait_time = ATTACK_COOLDOWN
	attack_timer.one_shot = true
	attack_timer.timeout.connect(func(): can_attack = true)

	revive_decision_timer.wait_time = REVIVE_RECONSIDER_INTERVAL
	revive_decision_timer.timeout.connect(_consider_revive)
	revive_decision_timer.start()

	var capsule := CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	mesh.mesh = capsule

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.45, 0.75)
	mesh.material_override = mat

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_down:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()
		return

	if committed_to_revive and player and is_instance_valid(player) and player.get("is_down"):
		_pursue_revive(delta)
		move_and_slide()
		return
	elif committed_to_revive:
		# Player got revived by other means, or is gone -- stand down.
		committed_to_revive = false
		revive_channel_progress = 0.0

	current_target = _find_target()

	if current_target:
		_engage(current_target)
	elif player and is_instance_valid(player):
		_follow(player)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _pursue_revive(delta: float) -> void:
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0
	var dist := to_player.length()

	if dist > REVIVE_RANGE:
		var dir := to_player.normalized()
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		if dir.length() > 0.01:
			look_at_from_position(global_position, global_position + dir, Vector3.UP)
		revive_channel_progress = 0.0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		revive_channel_progress += delta
		if revive_channel_progress >= REVIVE_CHANNEL_TIME:
			player.revive()
			committed_to_revive = false
			revive_channel_progress = 0.0

# Reconsideration: reused ComplianceEngine, is_revive=true, exactly the
# same machinery combat commands use. Scarcity is derived from the live
# shared ammo pool rather than a dummy value -- this is a real reading of
# actual game state, not a stub.
func _consider_revive() -> void:
	if is_down or committed_to_revive:
		return
	if not player or not is_instance_valid(player) or not player.get("is_down"):
		return

	state.scarcity = 1.0 - (float(SquadInventory.ammo) / float(SquadInventory.MAX_AMMO))

	var danger := 0.0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			danger = 0.8
			break

	if ComplianceEngineScript.roll_compliance(state, danger, "player", true):
		committed_to_revive = true

func _find_target() -> Node3D:
	var best: Node3D = null
	var best_dist := ENGAGE_RANGE
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist > best_dist:
			continue
		if not _has_line_of_sight(enemy):
			continue
		best = enemy
		best_dist = dist
	return best

func _has_line_of_sight(target: Node3D) -> bool:
	var from: Vector3 = global_position + Vector3(0, 0.9, 0)
	var to: Vector3 = target.global_position + Vector3(0, 0.9, 0)
	attack_ray.global_position = from
	attack_ray.target_position = attack_ray.to_local(to)
	attack_ray.force_raycast_update()
	if not attack_ray.is_colliding():
		return true
	return attack_ray.get_collider() == target

func _engage(target: Node3D) -> void:
	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)
	look_at_from_position(global_position, Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)

	if can_attack and SquadInventory.try_consume(1):
		can_attack = false
		attack_timer.start()
		if target.has_method("take_damage"):
			# Fresh raycast toward the actual chosen target -- _find_target's
			# scan loop may have left attack_ray pointing at a different
			# candidate it checked last, not necessarily this one.
			var headshot := false
			if _has_line_of_sight(target) and target.has_method("is_headshot_at"):
				headshot = target.is_headshot_at(attack_ray.get_collision_point())
			target.take_damage(ATTACK_DAMAGE, self, headshot)

func _follow(target: Node3D) -> void:
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0
	var dist := to_target.length()

	if dist > FOLLOW_DISTANCE:
		var dir := to_target.normalized()
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		if dir.length() > 0.01:
			look_at_from_position(global_position, global_position + dir, Vector3.UP)
	elif dist < STOP_DISTANCE:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func is_headshot_at(hit_point: Vector3) -> bool:
	# Fixed 1.8 capsule (no crouch for teammates), centered at
	# global_position as CollisionShape3D's default position -- spans
	# roughly -0.9..+0.9.
	return (hit_point.y - global_position.y) > 0.5

func take_damage(amount: int, attacker: Node3D = null, headshot: bool = false) -> void:
	if is_down:
		return
	if headshot:
		# HEV-style helmet absorbs the lethal portion -- forces
		# incapacitation regardless of remaining health, but doesn't kill
		# outright, per the locked no-permadeath design.
		health = 0
		_go_down()
		return
	health = max(0, health - amount)
	if health == 0:
		_go_down()
		return
	mesh.material_override.albedo_color = Color(0.6, 0.65, 0.95)
	get_tree().create_timer(0.08).timeout.connect(func():
		if is_instance_valid(self) and not is_down:
			mesh.material_override.albedo_color = Color(0.2, 0.45, 0.75)
	)

func _go_down() -> void:
	is_down = true
	committed_to_revive = false
	mesh.material_override.albedo_color = Color(0.25, 0.25, 0.3)

func revive() -> void:
	is_down = false
	health = REVIVE_HEAL
	mesh.material_override.albedo_color = Color(0.2, 0.45, 0.75)
