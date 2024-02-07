extends VehicleBody3D

# initialize car variables
const max_steer = 0.8
const engine_power = 300.0
var handbrake_power = 0.0
var reversing = false
var parked = false
var active =  false # player is active first, before entering car
var interactable = false
@onready var player = $"../player"

# initialize camera variables
var mouse_sens = 0.25
var free_look_tilt = 1.0
var pov = 3
var look_at = Vector3.ZERO
# third-person
@onready var pivot_camera_third = $pivot_camera_third
@onready var camera_third = $pivot_camera_third/camera_third
@onready var camera_third_reverse = $pivot_camera_third/camera_third_reverse
# first-person
@onready var head = $neck/head
@onready var neck = $neck
@onready var eyes = $neck/head/eyes
@onready var camera_first = $neck/head/eyes/camera_first

# camera - capture mouse inputs
func _ready():
	if active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		look_at = global_position
	
# camera - looking around
func _input(e):
	# mouse look in first-person
	if e is InputEventMouseMotion && pov==1 && active:
		neck.rotate_y(deg_to_rad(-e.relative.x * mouse_sens))
		neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-150), deg_to_rad(150))
		head.rotate_x(deg_to_rad(-e.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-30), deg_to_rad(30))
	# reset first-person camera if not in use
	elif pov != 1:
		neck.rotation.y = 0.0
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	# check if car controller is active
	if active:
		# movements - lerp for accel/decel
		steering = move_toward(steering, Input.get_axis("rightward", "leftward")*max_steer, delta*2.5)
		engine_force = lerp(engine_force, Input.get_axis("backward", "forward")*engine_power, delta*2.5)
		
		# braking
		if Input.is_action_pressed("ui_accept") && get_linear_velocity().length() > 0.2: # 0.2 = parking threshold
			handbrake_power = 3.0
		else:
			handbrake_power = 0.0
		set_brake(handbrake_power)
		
		# park car, slow car down to a compelte stop
		if get_linear_velocity().length() < 0.2:
			set_brake(lerp(brake, 3.0, delta*5))
			parked = true
		else:
			parked = false
		
		# smooth camera
		pivot_camera_third.global_position = pivot_camera_third.global_position.lerp(global_position, delta*50.0)
		pivot_camera_third.transform = pivot_camera_third.transform.interpolate_with(transform, delta*5.0)
		look_at = look_at.lerp(global_position+linear_velocity, delta*5.0)
		
		# set cameras to look
		camera_third.look_at(look_at)
		camera_third_reverse.look_at(look_at)
		if pov==3:
			check_reverse()
		
		# check pov change
		if Input.is_action_just_pressed("pov"):
			if camera_first.current:
				pov = 3
			elif camera_third.current || camera_third_reverse.current:
				pov = 1
			check_pov()
			
		# check exit car
		exit_check()
	# car controller inactive
	else:
		enter_check()
		pass
		
func check_reverse():
	# check moving backwards by angle, bcuz linear_velocity is relation to world, not self
	if linear_velocity.dot(transform.basis.z) > 2:
		reversing = false
		camera_third_reverse.current = true
		camera_third.current = false
	else:
		reversing = true
		camera_third.current = true
		camera_third_reverse.current = false

func check_pov():
	if pov == 1:
		camera_first.current = !camera_first.current
	elif pov == 3:
		camera_third.current = !camera_third.current
		camera_third_reverse.current = false
		
# Handle car enter/exit/interactions
func _on_interaction_zone_body_entered(body) -> void:
	if body.name == "player":
		interactable = true
		
func _on_interaction_zone_body_exited(body) -> void:
	if body.name == "player":
		interactable = false
		
func enter_check():
	if Input.is_action_just_pressed("use") && interactable:
		player.active = false
		active = true # car is active now
		camera_third.make_current()

func exit_check():
	if Input.is_action_just_pressed("use") && active && parked:
		player.active = true
		active = false
		player.global_transform.origin = global_transform.origin - 2*global_transform.basis.x
