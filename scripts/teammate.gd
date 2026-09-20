extends CharacterBody3D

# First squad teammate. For now this implements only the locked baseline
# behavior: autonomous follow, no command response yet (the typed-command
# parser doesn't exist). It carries a CharacterState so that when commands
# and combat-sharing exist, this node needs new *behavior*, not a new data
# model bolted on afterward.

const SPEED := 5.0
const FOLLOW_DISTANCE := 4.0
const STOP_DISTANCE := 2.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 18.0)
var player: Node3D

# Present now so future systems (compliance-driven commands, revive,
# morale) read from real per-teammate state instead of being retrofitted.
var state := CharacterState.new()

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	add_to_group("teammate")
	state.id = "teammate_1"
	call_deferred("_find_player")

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

	if player and is_instance_valid(player):
		var to_player: Vector3 = player.global_position - global_position
		to_player.y = 0
		var dist := to_player.length()

		if dist > FOLLOW_DISTANCE:
			var dir := to_player.normalized()
			velocity.x = dir.x * SPEED
			velocity.z = dir.z * SPEED
			if dir.length() > 0.01:
				look_at_from_position(global_position, global_position + dir, Vector3.UP)
		elif dist < STOP_DISTANCE:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		# Between STOP_DISTANCE and FOLLOW_DISTANCE: hold current velocity
		# (naturally decelerates via move_and_slide's friction-less coast
		# here being minimal — fine for a first pass).
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
