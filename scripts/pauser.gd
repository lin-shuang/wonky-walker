extends Node3D

@onready var menu = $Pause

var paused = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func _process(delta):
	if Input.is_action_just_pressed("menu"):
		pauseMenu()
		
func pauseMenu():
	if !paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		menu.show()
		get_tree().paused = true
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		menu.hide()
		get_tree().paused = false
	paused = !paused

