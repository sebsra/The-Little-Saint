class_name PowerJump
extends BasePowerUp

## Power-up that gives the player double jump ability

@export var extra_jumps: int = 1  # How many extra jumps to grant

func _ready():
	# Set power-up properties
	power_up_name = "Feather Boots"
	description = "Grants the ability to double jump"
	destroy_on_pickup = true
	
	# Set animation properties
	bounce_height = 10.0
	bounce_speed = 3.0
	rotation_speed = 0.0
	
	# Call parent ready method
	super._ready()

func apply_effect(player):
	# Call the parent implementation for signals
	super.apply_effect(player)
	
	# Increase player's allowed jumps
	if player.has_method("add_extra_jumps"):
		player.add_extra_jumps(extra_jumps)
	else:
		# Fallback for current implementation
		player.allowed_jumps += extra_jumps
		
	# Set the player's movement mode to normal (in case they were flying)
	if player.has_method("set_movement_mode"):
		player.set_movement_mode("normal")
	else:
		# Fallback for current implementation
		player.mode = "normal"
	
	print("Player gained double jump ability")
	
	# Show notification to player
	var popup_manager = get_node_or_null("/root/PopupManager")
	if popup_manager:
		if extra_jumps == 1:
			popup_manager.info("New Ability", "You've acquired Feather Boots! You can now double jump in mid-air.")
		else:
			popup_manager.info("New Ability", "You've acquired Feather Boots! You can now perform " + str(extra_jumps + 1) + " jumps in a row.")
