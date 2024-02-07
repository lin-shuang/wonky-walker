extends Control

@onready var scene = $"../"

func _on_resume_pressed():
	scene.pauseMenu()
	
func _on_options_pressed():
	pass # change scene to options menu

# back to main menu
func _on_endTrip_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/menu.tscn")
