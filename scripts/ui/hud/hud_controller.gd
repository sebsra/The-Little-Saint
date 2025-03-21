class_name HudController
extends CanvasLayer

var coins = 0
var max_lifes = 3
var lifes = max_lifes

# Elixir fill state (starts empty)
var elixir_fill_level := 0.0 # range: 0.0 (empty) to 1.0 (full)
var hud
var initial_heart_position
var inital_heart_size

func _ready():
	$HeartsFull.flip_h = true
	$LabelCoinSum.text = str(coins)
	initial_heart_position = $HeartsFull.position
	inital_heart_size = $HeartsFull.size
	$HeartsEmpty.position = initial_heart_position - Vector2(2 * inital_heart_size.x, 0)
	$HeartsEmpty.size = inital_heart_size + Vector2(2 * inital_heart_size.x, 0)

	load_hearts()
	update_elixir_fill(elixir_fill_level) # Start with empty elixir

	
	# Notify GameManager when coins are collected
	get_tree().create_timer(0.1).timeout.connect(func():
		Global.collected_coins = coins
	)

func coin_collected():
	coins += 1
	$LabelCoinSum.text = str(coins)
	
	# Notify GameManager
	Global.collect_coin()
	_update_coin_display()

# Function to update coin display
func _update_coin_display():
	$LabelCoinSum.text = str(coins)

func load_hearts():
	$HeartsFull.size.x = lifes * $HeartsFull.size.x / max_lifes

func change_life(amount):
	lifes = clamp(lifes + amount, 0, max_lifes)
	if lifes + amount < 0:
		lifes = 0
		
		# Notify GameManager of player death if health reaches 0
		if lifes <= 0:
			Global.player_death()
	elif lifes + amount > max_lifes:
		lifes = max_lifes
	else:
		lifes = lifes + amount
	
	load_hearts()

func update_elixir_fill(fill_level: float):
	elixir_fill_level = clamp(fill_level, 0.0, 1.0)
	var elixir = $elixir # Get the Sprite2D node for the elixir

	if not elixir.texture:
		print("Warning: Elixir node has no texture")
		return

	var full_size = elixir.texture.get_size()
	var visible_height = full_size.y * elixir_fill_level

	# Enable the region and adjust clipping
	elixir.region_enabled = true
	elixir.region_rect = Rect2(
		Vector2(0, full_size.y - visible_height), # Crop from the top
		Vector2(full_size.x, visible_height)
	)

	# Keep the elixir inside the bottle by adjusting relative to the bottle
	var bottle = $bottle # Ensure "bottle" is the correct node
	var bottle_height = bottle.texture.get_size().y # Get the bottle's texture size

	# Adjust only the Y position to prevent movement out of HUD
	elixir.position.y = bottle.position.y + bottle_height - visible_height


# ✅ Call this when the player collects a softpower
func collect_softpower():
	if elixir_fill_level < 1.0: # Only add if not already full
		elixir_fill_level += 0.25
		update_elixir_fill(elixir_fill_level)

func use_softpower():
	if elixir_fill_level > 0.0: # Only reduce if not empty
		elixir_fill_level -= 0.25
		update_elixir_fill(elixir_fill_level)

		if elixir_fill_level <= 0.0:
			print("Elixir empty! No more flying.")
			# Optional: Add UI warning when elixir is empty
	
	# Update SaveManager with new health value
	if SaveManager.current_save_data:
		SaveManager.current_save_data.health = lifes
