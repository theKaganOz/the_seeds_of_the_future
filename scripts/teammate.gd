extends CharacterBody3D

# First squad teammate. For now this implements only the locked baseline
# behavior: autonomous follow, no command response yet (the typed-command
# parser doesn't exist). It carries a CharacterState so that when commands
# and combat-sharing exist, this node needs new *behavior*, not a new data
# model bolted on afterward.

const CharacterStateScript := preload("res://scripts/character_state.gd")

const SPEED := 5.0
const FOLLOW_DISTANCE := 4.0
const STOP_DISTANCE := 2.0
const ENGAGE_RANGE := 15.0
const ATTACK_DAMAGE := 20
const ATTACK_COOLDOWN := 0.8
const MAX_HEALTH := 80

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 18.0)
var player: Node3D
var can_attack := true
var current_target: Node3D = null
var health := MAX_HEALTH

# Present now so future systems (compliance-driven commands, revive,
# morale) read from real per-teammate state instead of being retrofitted.
var state = CharacterStateScript.new()

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var attack_timer: Timer = $AttackCooldown
@onready var attack_ray: RayCast3D = $AttackRay

func _ready() -> void:
	add_to_group("teammate")
	state.id = "teammate_1"
	call_deferred("_find_player")

	attack_timer.wait_time = ATTACK_COOLDOWN
	attack_timer.one_shot = true
	attack_timer.timeout.connect(func(): can_attack = true)

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

	current_target = _find_target()

	if current_target:
		_engage(current_target)
	elif player and is_instance_valid(player):
		_follow(player)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

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
			target.take_damage(ATTACK_DAMAGE, self)

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

# Health tracking only -- NOT incapacitation. The locked design calls for
# no permanent death, teammates go down and are revivable, with all-four-
# down triggering a level restart. That whole system doesn't exist yet;
# this just stops health going negative and gives a visible hit reaction
# so enemy aggro switching to the teammate isn't a dead-end interaction.
func take_damage(amount: int, attacker: Node3D = null) -> void:
	health = max(0, health - amount)
	mesh.material_override.albedo_color = Color(0.6, 0.65, 0.95)
	get_tree().create_timer(0.08).timeout.connect(func():
		if is_instance_valid(self):
			mesh.material_override.albedo_color = Color(0.2, 0.45, 0.75)
	)
