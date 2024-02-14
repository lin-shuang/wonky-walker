extends CharacterBody3D

# VARIABLES ---------------------------

# states
var active = true
var idle = false
var walking = false
var sprinting = false
var crouching = false
var falling = false
var landing = false
var rolling = false
var free_looking = false
var sliding = false

# movement
var push_force = 1.0
var speed_current = 0.0
const speed_walk = 5.0
const speed_sprint = 8.0
const speed_crouch = 3.0
var jump_velocity_current = 5.0
var velocity_prev = Vector3.ZERO
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var anim_jump = $neck/head/eyes/anim_jump

# smooth movement
var speed_lerp = 7.5
var speed_lerp_air = 1.0
var direction = Vector3.ZERO

# camera
var mouse_sens = 0.25
var free_look_tilt = 1.0
@onready var head = $neck/head
@onready var neck = $neck
@onready var camera_3d = $neck/head/eyes/camera_first

# view model
@onready var sub_viewport = $neck/head/eyes/camera_first/SubViewportContainer/SubViewport
@onready var view_model = $neck/head/eyes/camera_first/SubViewportContainer/SubViewport/view_model

# headbob
const headbob_speed_sprint = 20
const headbob_speed_walk = 15
const headbob_speed_crouch = 10
const headbob_intensity_sprint = 0.2 # in meters
const headbob_intensity_walk = 0.1
const headbob_intensity_crouch = 0.05
var headbob_intensity_current = 0.0
var headbob_vector = Vector2.ZERO # xy coords
var headbob_index = 0.0 # distance along sin
@onready var eyes = $neck/head/eyes

# crouching
var crouch_depth = -0.5
@onready var collision_standing = $collision_standing
@onready var collision_crouching = $collision_crouching
@onready var ray_cast_3d = $RayCast3D
@onready var ray_interact = $neck/head/eyes/camera_first/ray_interact

# sliding
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 7.5

# FUNCTIONS ---------------------------

# camera - capture mouse inputs
func _ready():
	sub_viewport.size = DisplayServer.window_get_size()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
# camera - looking around
func _input(e):
	if e is InputEventMouseMotion && active:
		if free_looking:
			neck.rotate_y(deg_to_rad(-e.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-150), deg_to_rad(150))
		else:
			rotate_y(deg_to_rad(-e.relative.x * mouse_sens))
			head.rotate_x(deg_to_rad(-e.relative.y * mouse_sens))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			view_model.sway(Vector2(e.relative.x, e.relative.y))

# game physics
func _physics_process(delta):
	
	# check if player controller is active
	if active:
		# set up view model
		camera_3d.make_current()
		sub_viewport.global_canvas_transform = camera_3d.global_transform
		
		# get movement input
		var input_dir = Input.get_vector("leftward", "rightward", "forward", "backward")
		
		# Handle movement states
		# crouching check
		if Input.is_action_pressed("crouch") || sliding:
			
			# sliding check
			if sprinting && input_dir != Vector2.ZERO:
				sliding = true
				free_looking = true
				slide_timer = slide_timer_max
				slide_vector = input_dir
			
			walking = false
			sprinting = false
			crouching = true
			speed_current = lerp(speed_current, speed_crouch, delta*speed_lerp)
			head.position.y = lerp(head.position.y, crouch_depth, delta*speed_lerp)
			collision_standing.disabled = true
			collision_crouching.disabled = false
		elif !ray_cast_3d.is_colliding():
			collision_standing.disabled = false
			collision_crouching.disabled = true
			head.position.y = lerp(head.position.y, 0.0, delta*speed_lerp)
			
			# sprinting check
			if Input.is_action_pressed("sprint"):
				walking = false
				sprinting = true
				crouching = false
				speed_current = lerp(speed_current, speed_sprint, delta*speed_lerp)
			
			# walking check
			else:
				walking = true
				sprinting = false
				crouching = false
				speed_current = lerp(speed_current, speed_walk, delta*speed_lerp)
				
		# Handle free-looking
		if Input.is_action_pressed("free_look") || sliding:
			free_looking = true
			# sliding free-look
			if sliding:
				eyes.rotation.z = lerp(camera_3d.rotation.z, deg_to_rad(-5.0), delta*15)
			# normal free-look
			else:
				eyes.rotation.z = deg_to_rad(neck.rotation.y * free_look_tilt)
		else:
			free_looking = false
			eyes.rotation.z = lerp(camera_3d.rotation.z, 0.0, delta*25)
			neck.rotation.y = lerp(neck.rotation.y, 0.0, delta*25)
		
		# Handle sliding
		if sliding:
			slide_timer -= delta
			if slide_timer <= 0:
				sliding = false
				free_looking = false
				
		# Handle headbob
		# check headbob state
		if sprinting:
			headbob_intensity_current = headbob_intensity_sprint
			headbob_index += delta*headbob_speed_sprint
		elif walking:
			headbob_intensity_current = headbob_intensity_walk
			headbob_index += delta*headbob_speed_walk
		elif crouching:
			headbob_intensity_current = headbob_intensity_crouch
			headbob_index += delta*headbob_speed_crouch
		# update headbob
		if is_on_floor() && !sliding && input_dir!=Vector2.ZERO:
			headbob_vector.y = sin(headbob_index)
			headbob_vector.x = sin(headbob_index/2)+0.5
			eyes.position.y = lerp(eyes.position.y, headbob_vector.y*(headbob_intensity_current/2), delta*10) # divide by 2 to get more horizontal bob
			eyes.position.x = lerp(eyes.position.x, headbob_vector.x*(headbob_intensity_current), delta*10)
		else:
			eyes.position.y = lerp(eyes.position.y, 0.0, delta*10)
			eyes.position.x = lerp(eyes.position.x, 0.0, delta*10)
			
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta

		# Handle jump
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = jump_velocity_current
			sliding = false
			anim_jump.play("jumping")
			
		# Handle falling
		if !is_on_floor():
			falling = true
		else:
			falling = false
			
		# Handle landing
		if is_on_floor() && velocity_prev.y  < 0.0:
			if velocity_prev.y < -12.0:
				anim_jump.play("rolling")
			else:
				anim_jump.play("landing")

		# Get the input direction and handle the movement/deceleration.
		# ground movement
		if is_on_floor():
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*speed_lerp)
		# mid-air movement
		else:
			if input_dir!=Vector2.ZERO:
				direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*speed_lerp_air)
		
		
		# sliding direction
		if sliding:
			direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
			# sliding movement - add 0.25 to never stop moving
			speed_current = (slide_timer + 0.25) * slide_speed
			speed_current = (slide_timer + 0.25) * slide_speed
		
		# current movement
		if direction:
			velocity.x = direction.x * speed_current
			velocity.z = direction.z * speed_current
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
		collision_crouching.disabled = true
