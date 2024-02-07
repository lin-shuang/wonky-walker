extends Timer

# Declare the AnimationPlayer and Timer nodes
@onready var animation_player = $"../dayNightAnim"
@onready var timer = $"."


# Called when the node enters the scene tree for the first time
func _ready():
	pass

# Called when the Timer node times out
func _on_Timer_timeout():
	# Play the animation in the AnimationPlayer node
	animation_player.play("day night cycle")
	
	# Set the timer to run for 24 minutes
	timer.set_wait_time(1440)
	timer.start()
