extends CharacterBody3D

# --- Tunables ---
const RUN_SPEED := 6.0
const WALK_SPEED := 3.0
const CROUCH_SPEED := 2.5
const JUMP_VELOCITY := 6.5
const MOUSE_SENSITIVITY := 0.0025
const MAX_HEALTH := 100
const SHOOT_DAMAGE := 34
const SHOOT_RANGE := 40.0
const SHOOT_COOLDOWN := 0.25

const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.0
const STAND_CAM_Y := 0.7
const CROUCH_CAM_Y := 0.25
const CROUCH_LERP_SPEED := 10.0

# Incapacitation/revive. REVIVE_RANGE and REVIVE_HEAL are defaults I'm
# choosing now, not values we've explicitly locked -- flag if they should
# be different once you've felt them in play.
const REVIVE_RANGE := 2.5
const REVIVE_HEAL := 60

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 18.0)
var health := MAX_HEALTH
var can_shoot := true
var is_crouching := false
var is_down := false
var teammate: Node3D

@onready var camera: Camera3D = $Camera3D
@onready var muzzle_ray: RayCast3D = $Camera3D/MuzzleRay
@onready var shoot_timer: Timer = $ShootCooldown
@onready var hud: CanvasLayer = get_tree().get_first_node_in_group("hud")
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ceiling_check: RayCast3D = $CeilingCheck

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	shoot_timer.wait_time = SHOOT_COOLDOWN
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(func(): can_shoot = true)
	collision_shape.shape = collision_shape.shape.duplicate()
	call_deferred("_update_hud")
	call_deferred("_find_teammate")

func _find_teammate() -> void:
	teammate = get_tree().get_first_node_in_group("teammate")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("shoot") and can_shoot and not is_down:
		_fire()

	if event.is_action_pressed("revive") and not is_down:
		_try_revive_teammate()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_down:
		velocity.x = move_toward(velocity.x, 0, RUN_SPEED)
		velocity.z = move_toward(velocity.z, 0, RUN_SPEED)
		move_and_slide()
		_check_all_down()
		return

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY

	_update_crouch(delta)

	var speed := RUN_SPEED
	if is_crouching:
		speed = CROUCH_SPEED
	elif Input.is_action_pressed("walk"):
		speed = WALK_SPEED

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func _update_crouch(delta: float) -> void:
	var wants_crouch := Input.is_action_pressed("crouch")

	if wants_crouch:
		is_crouching = true
	elif is_crouching:
		# Only stand back up if there's clearance overhead — otherwise stay
		# crouched until the player moves somewhere with room.
		ceiling_check.force_raycast_update()
		if not ceiling_check.is_colliding():
			is_crouching = false

	var target_height := CROUCH_HEIGHT if is_crouching else STAND_HEIGHT
	var target_cam_y := CROUCH_CAM_Y if is_crouching else STAND_CAM_Y

	var capsule := collision_shape.shape as CapsuleShape3D
	capsule.height = lerp(capsule.height, target_height, CROUCH_LERP_SPEED * delta)
	# Keep the capsule's bottom fixed at its original ground-contact point
	# (position.y = 0 when height == STAND_HEIGHT, matching the original,
	# already-validated standing collision exactly) and only let the top
	# come down as the capsule shrinks for crouch.
	collision_shape.position.y = (capsule.height - STAND_HEIGHT) / 2.0
	camera.position.y = lerp(camera.position.y, target_cam_y, CROUCH_LERP_SPEED * delta)
	ceiling_check.position.y = capsule.height + collision_shape.position.y

func _fire() -> void:
	if not SquadInventory.try_consume(1):
		return
	can_shoot = false
	shoot_timer.start()

	muzzle_ray.force_raycast_update()
	if muzzle_ray.is_colliding():
		var target := muzzle_ray.get_collider()
		if target and target.has_method("take_damage"):
			var headshot := false
			if target.has_method("is_headshot_at"):
				headshot = target.is_headshot_at(muzzle_ray.get_collision_point())
			target.take_damage(SHOOT_DAMAGE, self, headshot)

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
	_update_hud()
	if health == 0:
		_go_down()

func is_headshot_at(hit_point: Vector3) -> bool:
	var capsule := collision_shape.shape as CapsuleShape3D
	var center_y := global_position.y + collision_shape.position.y
	return (hit_point.y - center_y) > (capsule.height / 2.0) * 0.55

func _go_down() -> void:
	is_down = true
	print("Player is down. Needs a revive.")
	_update_hud()

func revive() -> void:
	is_down = false
	health = REVIVE_HEAL
	print("Player revived.")
	_update_hud()

func _try_revive_teammate() -> void:
	if not teammate or not is_instance_valid(teammate):
		return
	if not teammate.get("is_down"):
		return
	if global_position.distance_to(teammate.global_position) > REVIVE_RANGE:
		return
	teammate.revive()

func _check_all_down() -> void:
	if not teammate or not is_instance_valid(teammate):
		return
	if is_down and teammate.get("is_down"):
		print("Whole squad down. Restarting level.")
		get_tree().reload_current_scene()

func _update_hud() -> void:
	if hud and hud.has_method("set_health"):
		hud.set_health(health)
	if hud and hud.has_method("set_down_status"):
		hud.set_down_status(is_down)
