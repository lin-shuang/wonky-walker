extends Node3D

@export var offset = 10.0
@onready var parent = get_parent_node_3d()
@onready var prevPos = parent.global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var velocity = parent.global_position - prevPos
	global_position = parent.global_position + velocity * offset
	prevPos = parent.global_position
