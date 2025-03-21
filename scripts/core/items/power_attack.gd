class_name PowerAttack
extends BasePowerUp

## Power-up that gives the player an axe attack ability

func _ready():
	# Set power-up properties
	power_up_name = "Battle Axe"
	description = "Grants the ability to attack with a powerful axe"
	destroy_on_pickup = true
	
	# Set animation properties
	bounce_height = 5.0
	bounce_speed = 2.0
	rotation_speed = 1.0
	
	# Call parent ready method
	super._ready()

func apply_effect(player):
	# Call the parent implementation for signals
	super.apply_effect(player)
	
	# Set the player's attack animation
	if player.has_method("set_attack_animation"):
		player.set_attack_animation("walking6")
	else:
		# Fallback for current implementation
		player.attack_animation = "walking6"
		
	# Enable attack ability if player has the method
	if player.has_method("enable_attack"):
		player.enable_attack(true)
	
	print("Player gained axe attack ability")
	
	# Show notification to player
	var popup_manager = get_node_or_null("/root/PopupManager")
	if popup_manager:
		popup_manager.info("New Ability", "You've acquired a battle axe! Press the attack button to use it.")
