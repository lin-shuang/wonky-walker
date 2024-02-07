extends Node3D

var interactable = false
var state = false # f = closed, t = open

func _input(e):
	if interactable && Input.is_action_just_pressed("use") && !$AnimationPlayer.is_playing():
		if !state:
			print("OPENING")
			$AnimationPlayer.play("door_open")
		else:
			print("CLOSING")
			$AnimationPlayer.play("door_close")
		state = !state

func _on_area_default_body_entered(body) -> void:
	if body.name == "player":
		print("In range!")
		interactable = true

func _on_area_default_body_exited(body) -> void:
	if body.name == "player":
		print("Out of range!")
		interactable = false
