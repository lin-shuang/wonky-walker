extends Camera3D

var free_looking = false
var equipped_hands = false
@onready var arms = $"Root Scene"
@onready var animation_player = $"Root Scene/RootNode/AnimationPlayer"
@onready var player = $"../../../../../../.."

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# player controller active
	if player.active:
		# CHECK FOR FREE LOOK - WIP
		arms.position.x = lerp(arms.position.x, 0.0, delta*5)
		arms.position.y = lerp(arms.position.y-0.04, 0.0, delta*5)
	# player controller inactive, hide all view models
	else:
		arms.visible = false
		equipped_hands = false

func sway(amount):
	arms.position.x += amount.x * 0.0005
	arms.position.y += amount.y * 0.0005

# Handle inputs
func _input(e):
	
	# equip & sheath
	if(e.is_action_pressed("equip_sheath")) && player.active:
		
		# check hands
		if(equipped_hands):
			animation_player.play("sheath") # BUG: CAN STILL ATTACK MID SHEATH
			await animation_player.animation_finished
			arms.visible = false
		else:
			arms.visible = true
			animation_player.play("equip")
			await animation_player.animation_finished
			
		# equips
		equipped_hands = !equipped_hands
		
	# attacks
	if(e.is_action_pressed("attack")):
		if(equipped_hands):
			animation_player.play("attack")
			await animation_player.animation_finished
