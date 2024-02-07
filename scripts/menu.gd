extends Control

var maxRoom = 1 # update to max room num
var room = "start"

func _on_outside_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	
func _on_room_pressed():
	room = "res://scenes/starts/" + room + str(randi_range(1,maxRoom)) + ".tscn"
	# change scene to random starter room num
	print(room)
	get_tree().change_scene_to_file(room)
	room = "start"
	
func _on_options_pressed():
	pass # change scene to options menu

func _on_quit_pressed():
	get_tree().quit()
