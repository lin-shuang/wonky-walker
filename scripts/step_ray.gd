extends RayCast3D

@export var step_target: Node3D

func _physics_process(delta):
	if is_colliding():
		#print("Hit!")
		print(get_collider())
		step_target.global_position = get_collision_point()
