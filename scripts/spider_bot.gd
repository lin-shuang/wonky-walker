extends Node3D

@export var speedMove = 5.0
@export var speedTurn = 1.0
@export var heightOffset = 3

@onready var FL = $Armature/target_FL
@onready var FR = $Armature/target_FR
@onready var BL = $Armature/target_BL
@onready var BR = $Armature/target_BR
@onready var ray_fl = $step_targets/target_step_FL/RayCast3D
@onready var ray_fr = $step_targets/target_step_FR/RayCast3D
@onready var ray_bl = $step_targets/target_step_BL/RayCast3D
@onready var ray_br = $step_targets/target_step_BR/RayCast3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var velocity = Vector3.ZERO
var mass = 10.0

# Called when the node enters the scene tree for the first time.
func _process(delta):
	var plane1 = Plane(BL.global_position, FL.global_position, FR.global_position)
	var plane2 = Plane(FR.global_position, BR.global_position, BL.global_position)
	var avgNormal = ((plane1.normal + plane2.normal) / 2).normalized()
	
	# basis
	var targetBasis = basis_from_normal(avgNormal)
	transform.basis = lerp(transform.basis, targetBasis, speedMove * delta).orthonormalized()
	
	# adjust body height
	var avg = (FL.position + FR.position + BL.position + BR.position) / 4
	var targetPos = avg + transform.basis.y * heightOffset
	var distance = transform.basis.y.dot(targetPos - position)
	position = lerp(position, position + transform.basis.y * distance, speedMove * delta)
	
	handle_gravity(delta)
	handle_movement(delta)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_movement(delta):
	var dir = Input.get_axis('backward', 'forward')
	translate(Vector3(0, 0, -dir) * speedMove * delta)
	
	var a_dir = Input.get_axis('rightward', 'leftward')
	rotate_object_local(Vector3.UP, a_dir * speedTurn * delta)

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

func handle_gravity(delta):
	if ray_fl.is_colliding() || ray_fr.is_colliding() || ray_bl.is_colliding() || ray_br.is_colliding():
		velocity.y = 0  # Reset vertical velocity when grounded
	else:
		velocity.y -= gravity * delta
		position += velocity * delta
		print(velocity)
