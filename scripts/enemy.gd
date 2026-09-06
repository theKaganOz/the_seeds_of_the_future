extends CharacterBody3D

const SPEED := 3.2
const MAX_HEALTH := 60
const ATTACK_RANGE := 1.6
const ATTACK_DAMAGE := 12
const ATTACK_COOLDOWN := 1.1
const SIGHT_RANGE := 22.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 18.0)
var health := MAX_HEALTH
var can_attack := true
var player: Node3D

@onready var attack_timer: Timer = $AttackCooldown
@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	attack_timer.wait_time = ATTACK_COOLDOWN
	attack_timer.one_shot = true
	attack_timer.timeout.connect(func(): can_attack = true)

	var capsule := CapsuleMesh.new()
	capsule.radius = 0.45
	capsule.height = 1.9
	mesh.mesh = capsule

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.05, 0.05)
	mesh.material_override = mat

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if player and is_instance_valid(player):
		var to_player := player.global_position - global_position
		var dist := to_player.length()

		if dist <= SIGHT_RANGE:
			var dir := to_player.normalized()
			if dist > ATTACK_RANGE:
				velocity.x = dir.x * SPEED
				velocity.z = dir.z * SPEED
				look_at_from_position(global_position, Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
			else:
				velocity.x = 0
				velocity.z = 0
				if can_attack:
					_attack()
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _attack() -> void:
	can_attack = false
	attack_timer.start()
	if player.has_method("take_damage"):
		player.take_damage(ATTACK_DAMAGE)

func take_damage(amount: int) -> void:
	health -= amount
	mesh.material_override.albedo_color = Color(1, 0.4, 0.4)
	get_tree().create_timer(0.08).timeout.connect(func():
		if is_instance_valid(self):
			mesh.material_override.albedo_color = Color(0.7, 0.05, 0.05)
	)
	if health <= 0:
		queue_free()
