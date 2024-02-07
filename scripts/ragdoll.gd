extends Skeleton3D

@export var targetSkeleton: Skeleton3D
@export var linearSpringStiffness = 1200.0
@export var linearSpringDamping = 40.0
@export var angularSpringStiffness = 4000.0
@export var angularSpringDamping = 80.0
var physicsBones

# Called when the node enters the scene tree for the first time.
func _ready():
	physical_bones_start_simulation()
	physicsBones = get_children().filter(func(x): return x is PhysicalBone3D)

func _physics_process(delta):
	for b in physicsBones:
		var targetTransform: Transform3D = targetSkeleton.global_transform * targetSkeleton.get_bone_global_pose((b.get_bone_id()))
		var currentTransform: Transform3D = global_transform * get_bone_global_pose(b.get_bone_id())
		
		# position
		var positionDiff: Vector3 = targetTransform.origin - currentTransform.origin
		var force: Vector3 = hookes_law(positionDiff, b.linear_velocity, linearSpringStiffness, linearSpringDamping)
		b.linear_velocity += (force*delta)
		
		# rotation
		var rotationDiff: Basis = (targetTransform.basis * currentTransform.basis.inverse())
		var torque = hookes_law(rotationDiff.get_euler(), b.angular_velocity, angularSpringStiffness, angularSpringDamping)
		b.angular_velocity += (force*delta)
		
func hookes_law(displacement: Vector3, currentVelocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness*displacement) - (damping*currentVelocity)
