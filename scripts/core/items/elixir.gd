class_name Elixir
extends BasePowerUp

## Power-up that gives the player temporary flying ability via a magical elixir

func _ready():
	# Set power-up properties
	power_up_name = "Magic Elixir"
	description = "Grants temporary flying ability"
	effect_duration = 5.0  # 20 seconds of flight
	destroy_on_pickup = true
	
	# Set animation properties (optional: tweak to differentiate visually from Angel Wings)
	bounce_height = 6.0
	bounce_speed = 2.0
	rotation_speed = 1.0
	
	# Call parent ready method
	super._ready()

func apply_effect(player):
	# Call the parent implementation for signals
	super.apply_effect(player)
	
	# Set the player's movement mode
	if player.has_method("set_movement_mode"):
		player.set_movement_mode("fly")
	else:
		player.mode = "fly"
		
	print("Player gained flight ability via Elixir")

	# Update the Elixir fill in HUD
	var hud = get_tree().get_root().find_child("HUD", true, false)
	if hud:
		hud.collect_softpower()  # This will add 25% elixir

	# Show notification to player
	#var popup_manager = get_node_or_null("/root/PopupManager")
	#if popup_manager:
	#	popup_manager.info("Elixir Power", "You've drunk the magic elixir! You can fly for " + str(effect_duration) + " seconds.")
	
	# Add a visible timer to the HUD if available
	if hud and hud.has_method("show_ability_timer"):
		hud.show_ability_timer("Flight", effect_duration)

func remove_effect(player):
	# Set the player's movement mode back to normal
	if player.has_method("set_movement_mode"):
		player.set_movement_mode("normal")
	else:
		player.mode = "normal"
		
	player.passed_fly_time = 0.0
	
	# Let the player know the effect has ended
	var popup_manager = get_node_or_null("/root/PopupManager")
	if popup_manager:
		popup_manager.info("Elixir Expired", "The elixir's magic has worn off. You can't fly anymore.")
	
	super.remove_effect(player)
