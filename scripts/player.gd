extends CharacterBody3D

@export_category("Info")
var nickname := ""

@export_category("Stats")
@export var gold := 0 :set = set1
@export var silver := 0 :set = set2
@export var health := 100 :set = set3
@export var health_max := 100 :set = set4

@export_category("PREF")
@export var bar_nickname: Label
@export var bar_health: ProgressBar
@export var hud: CanvasLayer

signal sets(a,v)
func set1(v: int):
	gold = v
	
	emit_signal("sets", 1,v)
func set2(v: int):
	silver = v
	
	emit_signal("sets", 2,v)
func set3(v: int):
	health = v
	
	bar_health.value = health
	bar_health.get_node("Label").text = str(health) + "/" + str(health_max)
	emit_signal("sets", 3,v)
func set4(v: int):
	health_max = v
	
	bar_health.max_value = health_max
	bar_health.get_node("Label").text = str(health) + "/" + str(health_max)
	emit_signal("sets", 4,v)

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.004

#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

#fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

@onready var head = $Head
@onready var camera = $Head/Camera3D

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	
	if is_multiplayer_authority():
		nickname = Global_Self.nickname
		rpc("sync_nickname", nickname)

@rpc("any_peer", "call_local", "reliable")
func sync_nickname(value: String):
	nickname = value
	if bar_nickname:
		bar_nickname.text = nickname

func _ready():
	
	if not is_multiplayer_authority():
		hud.queue_free();
		
		return
	
	print(nickname, bar_nickname.text)
	bar_health.get_node("Label").text = str(health) + "/" + str(health_max)
	$InfoBar/Health.visible = false
	
	camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	## setting hud
	connect("sets", Callable(hud, "changed"))
	set1(gold)
	set2(silver)
	set3(health)
	set4(health_max)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	if not is_multiplayer_authority(): return
	
	
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	
	
	if Input.is_action_just_pressed("test"):
		health -= 10
		gold += 500
		print("test, " + str(health))


func _physics_process(delta):
	
	
	set_multiplayer_authority(str(name).to_int())
	if not is_multiplayer_authority(): return
	
	
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle Sprint.
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


#func death():
	#print("dead")
	#
	#health = health_max
