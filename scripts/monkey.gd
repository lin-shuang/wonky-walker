extends CharacterBody3D

@export var heightOffset = 0.0

@onready var L = $armature/target_L
@onready var R = $armature/target_R
@onready var ray_l = $step_targets/target_step_L/RayCast3D
@onready var ray_r = $step_targets/target_step_R/RayCast3D
@onready var camera = $camera
@onready var camera_3d = $camera/Camera3D
@onready var collision_standing = $collision_standing
@onready var collision_crouching = $collision_crouching
@onready var ray_height = $ray_height

# movement
var mouse_sens = 0.25
var push_force = 1.0
var mass = 5.0
var speed_current = 0.0
const speed_walk = 2.0
var speed_sprint = 5.0
const speed_crouch = 1.0
var jump_velocity_current = 5.0
var velocity_prev = Vector3.ZERO
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# smooth movement
var speed_lerp = 7.5
var speed_lerp_air = 1.0
var direction = Vector3.ZERO

# states
var active = true
var idle = false
var walking = false
var sprinting = false
var crouching = false
var crouch_depth = -0.5
var falling = false

# camera - capture mouse inputs
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
# camera - looking around
func _input(e):
	if e is InputEventMouseMotion && active:
		rotate_y(deg_to_rad(-e.relative.x * mouse_sens))
		camera.rotate_x(deg_to_rad(-e.relative.y * mouse_sens))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

# game physics
func _physics_process(delta):
	# check if player controller is active
	if active:
		# set up view model
		camera_3d.make_current()
		
		# get movement input
		var input_dir = Input.get_vector("leftward", "rightward", "forward", "backward")
		
		# Handle movement states
		# crouching check
		if Input.is_action_pressed("crouch"):
			
			walking = false
			crouching = true
			speed_current = lerp(speed_current, speed_crouch, delta*speed_lerp)
			camera.position.y = lerp(camera.position.y, crouch_depth, delta*speed_lerp)
			collision_standing.disabled = true
			collision_crouching.disabled = false
		elif !ray_height.is_colliding():
			collision_standing.disabled = false
			collision_crouching.disabled = true
			camera.position.y = lerp(camera.position.y, 0.0, delta*speed_lerp)
			
			# sprinting check
			if sprinting:
				walking = false
				crouching = false
				speed_current = lerp(speed_current, speed_sprint, delta*speed_lerp)
			
			# walking check
			else:
				walking = true
				crouching = false
				speed_current = lerp(speed_current, speed_walk, delta*speed_lerp)
				
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta

		# Handle jump
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = jump_velocity_current
			#anim_jump.play("jumping")
			
		# Handle falling
		if !is_on_floor():
			falling = true
		else:
			falling = false
			
		# Handle landing
		if is_on_floor() && velocity_prev.y  < 0.0:
			if velocity_prev.y < -12.0:
				#anim_jump.play("rolling")
				pass
			else:
				#anim_jump.play("landing")
				pass

		# Get the input direction and handle the movement/deceleration.
		# ground movement
		if is_on_floor():
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*speed_lerp)
		# mid-air movement
		else:
			if input_dir!=Vector2.ZERO:
				direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*speed_lerp_air)
		
		# current movement
		if direction:
			velocity.x = -direction.x * speed_current
			velocity.z = -direction.z * speed_current
		else:
			velocity.x = move_toward(velocity.x, 0, speed_current)
			velocity.z = move_toward(velocity.z, 0, speed_current)
		
		# update velocity
		velocity_prev = velocity;
		
		# Handle idle
		if input_dir == Vector2.ZERO && is_on_floor():
			idle = true
		else:
			idle = false
			
		# activate moving
		move_and_slide()
		
		# handle collision w/ items
		for i in get_slide_collision_count():
			var c = get_slide_collision(i)
			if c.get_collider() is RigidBody3D:
				c.get_collider().apply_central_impulse(-c.get_normal()*push_force)
			
	# player controller inactive
	else:
		hide()
		collision_standing.disabled = true

# handle physics doll
func _process(delta):
	var plane1 = Plane(L.global_position, L.global_position+Vector3(0,0,0.15), R.global_position)
	var plane2 = Plane(R.global_position, L.global_position+Vector3(0,0,0.15), L.global_position)
	var avgNormal = ((plane1.normal + plane2.normal) / 2).normalized()
	
	# basis
	#var targetBasis = basis_from_normal(avgNormal)
	#transform.basis = lerp(transform.basis, targetBasis, speedMove * delta).orthonormalized()
	
	# adjust body height
	var avg = (L.position + R.position) / 2
	var targetPos = avg + transform.basis.y * heightOffset
	var distance = transform.basis.y.dot(targetPos - position)
	position = lerp(position, position + transform.basis.y * distance, speed_walk * delta)

func basis_from_normal(normal: Vector3) -> Basis:
	var result = Basis()
	result.x = normal.cross(transform.basis.z)
	result.y = normal
	result.z = transform.basis.x.cross(normal)
	
	result = result.orthonormalized()
	result.x *= scale.x
	result.y *= scale.y
	result.z *= scale.z
	return result
