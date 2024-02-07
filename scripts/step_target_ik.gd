extends Marker3D

@export var stepTarget: Node3D
@export var stepDist = 0.75
@export var adjacentTarget: Node3D
#@export var oppositeTarget: Node3D
var stepping = false

func _process(delta):
	if !stepping && !adjacentTarget.stepping && abs(global_position.distance_to(stepTarget.global_position)) > stepDist:
		step()
		#oppositeTarget.step()

func step():
	var targetPos = stepTarget.global_position
	var halfWay = (global_position+stepTarget.global_position) / 2
	stepping = true
	
	var t = get_tree().create_tween()
	t.tween_property(self, "global_position", halfWay+owner.basis.y, 0.1)
	t.tween_property(self, "global_position", targetPos, 0.1)
	t.tween_callback(func(): stepping = false)
