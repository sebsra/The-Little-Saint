class_name PlayerState
extends State

# Base functions shared by all player states
var player: Player

func _ready():
	# Set player reference during initialization
	player = owner_node as Player

# Function to update the outfit based on the current state
func update_outfit():
	var player_outfit = player.player_outfit
	var player_animations = player.player_animations
	var current_animation = player.current_animation

	for outfit in player_outfit:
		var animated_sprite = player.get_node("character_sprites/" + outfit)
		var selected_outfit = player_outfit[outfit]

		if str(selected_outfit) == "none":
			animated_sprite.visible = false
		else:
			animated_sprite.visible = true
			animated_sprite.play(str(selected_outfit))
			animated_sprite.speed_scale = 2.0

			# Set direction based on movement
			var x_input = Input.get_axis("left", "right")
			if x_input != 0:
				animated_sprite.flip_h = x_input > 0

			# Frame management
			if current_animation in player_animations:
				if animated_sprite.frame < player_animations[current_animation][0] or animated_sprite.frame >= player_animations[current_animation][-1]:
					animated_sprite.frame = player_animations[current_animation][0]

# Function to check life and handle death
func check_life():
	# Check for player health in the HUD
	if player.hud:
		var health_value = 0
		
		# Try to get health using the current API or the legacy API
		if "current_health" in player.hud:
			health_value = player.hud.current_health
		elif "lifes" in player.hud:
			health_value = player.hud.lifes
			
		if health_value <= 0:
			return "PlayerDeathState"
	
	return ""

# Function to check menu input
func check_menu_input(event):
	if event is InputEvent and event.is_action_pressed("Menu"):
		get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")
		if player.has_method("save_settings"):
			player.save_settings()
