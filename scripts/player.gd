extends CharacterBody3D

# --- Tunables ---
const SPEED := 6.0
const JUMP_VELOCITY := 6.5
const MOUSE_SENSITIVITY := 0.0025
const MAX_HEALTH := 100
const SHOOT_DAMAGE := 34
const SHOOT_RANGE := 40.0
const SHOOT_COOLDOWN := 0.25

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 18.0)
var health := MAX_HEALTH
var can_shoot := true

@onready var camera: Camera3D = $Camera3D
@onready var muzzle_ray: RayCast3D = $Camera3D/MuzzleRay
@onready var shoot_timer: Timer = $ShootCooldown
@onready var hud: CanvasLayer = get_tree().get_first_node_in_group("hud")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	shoot_timer.wait_time = SHOOT_COOLDOWN
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(func(): can_shoot = true)
	call_deferred("_update_hud")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("shoot") and can_shoot:
		_fire()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _fire() -> void:
	can_shoot = false
	shoot_timer.start()

	muzzle_ray.force_raycast_update()
	if muzzle_ray.is_colliding():
		var target := muzzle_ray.get_collider()
		if target and target.has_method("take_damage"):
			target.take_damage(SHOOT_DAMAGE)

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	_update_hud()
	if health == 0:
		_die()

func _update_hud() -> void:
	if hud and hud.has_method("set_health"):
		hud.set_health(health)

func _die() -> void:
	print("Player died. Reload level.")
	get_tree().reload_current_scene()
