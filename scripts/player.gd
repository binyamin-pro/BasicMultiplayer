extends CharacterBody3D

@export_category("PREF")
@export var world: Node
@export var bar_nickname: Label
@export var bar_health: ProgressBar

var hud: CanvasLayer
signal hud_ready

@export_category("Movement")
@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var PUSH_FORCE = 4.5

@export_category("Camera")
@export var head :Node3D
@export var camera :Camera3D
@export var mouse_sensitivity := 0.002
@export var camera_limit := 90
var pitch := 0.0


@export_category("Info")
@export var nickname :String :
	set(v):
		nickname = v
		emit_signal("_sync_nick")
		
		bar_nickname.text = nickname
signal _sync_nick

@export var health = 0:
	set(v):
		health = v
		hud.health = v
		
		bar_health.value = health
		bar_health.get_node("Label").text = str(health) + "/" + str(health_max)

@export var health_max = 0:
	set(v):
		health_max = v
		hud.health_max = v
		
		bar_health.max_value = health_max
		bar_health.get_node("Label").text = str(health) + "/" + str(health_max)





func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	
	if is_multiplayer_authority():
		nickname = Global_self.nickname
	

func _ready():
	
	if not is_multiplayer_authority():
		#hud.queue_free();
		return
	
	
	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	await hud_ready
	health = 100
	health_max = 100

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			c.get_collider().apply_central_impulse(-c.get_normal() * PUSH_FORCE)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and !Global_self.input_blocked:
		velocity.y = JUMP_VELOCITY
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if Global_self.input_blocked: input_dir = Vector2.ZERO
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if Global_self.input_blocked: return
	
	if event is InputEventMouseMotion:
		# Yaw (left/right)
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Pitch (up/down)
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-camera_limit), deg_to_rad(camera_limit))
		head.rotation.x = pitch
