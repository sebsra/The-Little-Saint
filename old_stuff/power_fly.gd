class_name PowerFly
extends BasePowerUp

## Power-up that gives the player temporary flying ability

func _ready():
	# Set power-up properties
	power_up_name = "Angel Wings"
	description = "Grants temporary flying ability"
	effect_duration = 20.0  # 20 seconds of flight
	destroy_on_pickup = true
	
	# Set animation properties
	bounce_height = 8.0
	bounce_speed = 1.5
	rotation_speed = 0.5
	
	# Call parent ready method
	super._ready()

func apply_effect(player):
	# Call the parent implementation for signals
	super.apply_effect(player)
	
	# Set the player's movement mode
	if player.has_method("set_movement_mode"):
		player.set_movement_mode("fly")
	else:
		# Fallback for current implementation
		player.mode = "fly"
		
	print("Player gained flight ability")
	
	# Show notification to player
	#var popup_manager = get_node_or_null("/root/PopupManager")
	#if popup_manager:
		#popup_manager.info("New Ability", "You've acquired angel wings! You can now fly for " + str(effect_duration) + " seconds.")
	
	# Add a visible timer to the HUD if available
	var hud = get_node_or_null("../../HUD")
	if hud and hud.has_method("show_ability_timer"):
		hud.show_ability_timer("Flight", effect_duration)

func remove_effect(player):
	# Set the player's movement mode back to normal
	if player.has_method("set_movement_mode"):
		player.set_movement_mode("normal")
	else:
		# Fallback for current implementation
		player.mode = "normal"
		
	# Reset player's flight timer
	player.passed_fly_time = 0.0
	
	# Let the player know the effect has ended
	var popup_manager = get_node_or_null("/root/PopupManager")
	if popup_manager:
		popup_manager.info("Ability Expired", "Your angel wings have disappeared.")
	
	# Call the parent implementation for signals
	super.remove_effect(player)
