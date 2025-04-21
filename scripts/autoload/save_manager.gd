extends Node

## SaveManager handles all game saving and loading operations
## It manages player data, settings, and outfit configurations
## Now with auto-save functionality

# Current save data instance
var current_save_data: SaveData = null
# Alias for GameManager compatibility
var game_data: SaveData = null

# Auto-save settings
var auto_save_enabled: bool = false
var auto_save_interval: float = 300.0  # Default: save every 5 minutes
var time_since_last_save: float = 0.0

# Signals
signal save_completed(success, message)
signal load_completed(success, message)
signal settings_saved(success)
signal settings_loaded(success)
signal outfit_saved(success, outfit_name)
signal auto_save_performed(success)

# Initialize on ready
func _ready():
	print("Save Manager initialized")
	# Create default save data at startup
	current_save_data = SaveData.new()
	# Set the game_data alias for GameManager compatibility
	game_data = current_save_data
	# Load settings immediately on startup
	load_settings()
	# Initialize auto-save
	_init_auto_save()

func _process(delta):
	# Handle auto-save timer
	if auto_save_enabled:
		time_since_last_save += delta
		
		if time_since_last_save >= auto_save_interval:
			perform_auto_save()

# Initialize auto-save
func _init_auto_save():
	# Default is disabled
	auto_save_enabled = false
	time_since_last_save = 0.0
	# Ensure process is called
	set_process(true)

# Toggle auto-save functionality
func toggle_auto_save(enabled: bool) -> void:
	auto_save_enabled = enabled
	time_since_last_save = 0.0
	print("Auto-save " + ("enabled" if enabled else "disabled"))

# Set auto-save interval (in seconds)
func set_auto_save_interval(interval: float) -> void:
	if interval < 10.0:
		push_warning("Auto-save interval set too low (< 10 seconds). Using 10 seconds.")
		auto_save_interval = 10.0
	else:
		auto_save_interval = interval

# Perform an auto-save operation
func perform_auto_save() -> bool:
	print("Performing auto-save...")
	time_since_last_save = 0.0
	
	var success = save_game()
	emit_signal("auto_save_performed", success)
	return success

# Capture active scene state
func capture_active_scene_state() -> Dictionary:
	var scene_state = {}
	var current_scene = get_tree().current_scene
	
	if current_scene:
		# Store basic scene info
		scene_state["scene_name"] = current_scene.name
		scene_state["scene_path"] = current_scene.scene_file_path
		
		# Add additional scene-specific state here if needed
		# This could be extended to save specific node states
		
	return scene_state

# Save the full game state
func save_game() -> bool:
	if not current_save_data:
		current_save_data = SaveData.new()
		game_data = current_save_data

	# Update data before saving
	_update_save_data()

	# Try to save the resource file
	var dir = DirAccess.open("user://")
	if not dir:
		push_error("Failed to open user:// directory")
		emit_signal("save_completed", false, "Failed to access save directory")
		return false

	var success = ResourceSaver.save(current_save_data, Constants.SAVE_FILE_PATH)

	if success == OK:
		print("Game saved successfully to: ", Constants.SAVE_FILE_PATH)
		emit_signal("save_completed", true, "Game saved successfully")
		return true
	else:
		push_error("Failed to save game. Error code: " + str(success))
		emit_signal("save_completed", false, "Failed to save game")
		return false

# Load the full game state
func load_game() -> bool:
	if ResourceLoader.exists(Constants.SAVE_FILE_PATH):
		var loaded_data = ResourceLoader.load(Constants.SAVE_FILE_PATH)

		if loaded_data is SaveData:
			current_save_data = loaded_data
			game_data = current_save_data

			# Apply loaded data to game state
			_apply_save_data()

			print("Game loaded successfully from: ", Constants.SAVE_FILE_PATH)
			emit_signal("load_completed", true, "Game loaded successfully")
			return true
		else:
			push_error("Loaded resource is not a SaveData resource")
	else:
		print("No save file found at: ", Constants.SAVE_FILE_PATH)

	# If we get here, loading failed
	emit_signal("load_completed", false, "No save data found or data corrupted")
	return false

func _update_save_data() -> void:
	# Get player reference from GameManager
	var player = null
	if get_node_or_null("/root/Global") and get_node("/root/Global").player:
		player = get_node("/root/Global").player

	# Check if GlobalHUD exists
	var global_hud = get_node_or_null("/root/GlobalHUD")

	# Capture the active scene state
	current_save_data.active_scene_state = capture_active_scene_state()

	if player:
		# Update player data
		if global_hud:
			# Use GlobalHUD for health and coins
			current_save_data.health = global_hud.current_health
			current_save_data.coins = global_hud.coins
			current_save_data.heaven_coins = global_hud.heaven_coins
		else:
			# Fallback to player's HUD
			current_save_data.health = GlobalHUD.lifes if GlobalHUD else Constants.PLAYER_DEFAULT_MAX_HEALTH
			current_save_data.coins = GlobalHUD.coins if GlobalHUD else 0
			current_save_data.heaven_coins = GlobalHUD.heaven_coins if GlobalHUD else 0
			
		current_save_data.player_position = player.global_position
		current_save_data.current_level = get_node("/root/Global").current_level

		# Update player stats and settings
		current_save_data.player_speed = player.SPEED
		current_save_data.player_jump_velocity = player.JUMP_VELOCITY
		current_save_data.player_fly_velocity = player.FLY_VELOCITY
		current_save_data.player_gravity = player.GRAVITY
		current_save_data.player_mode = player.mode
		current_save_data.player_passed_fly_time = player.passed_fly_time
		current_save_data.player_jump_counter = player.jump_counter
		current_save_data.player_ready_for_jump = player.ready_for_jump
		current_save_data.player_allowed_jumps = player.allowed_jumps

		# Get outfit data - ensure we have a deep copy
		if player.player_outfit:
			current_save_data.player_outfit = player.player_outfit.duplicate(true)

		# Update timestamp
		current_save_data.save_date = Time.get_datetime_string_from_system(false, true)
		
		current_save_data.memorable_screenshots = Global.memorable_screenshots

	# Add global game state
	if get_node_or_null("/root/Global"):
		var global = get_node("/root/Global")
		current_save_data.collected_coins = global.collected_coins
		current_save_data.collected_heaven_coins = global.collected_heaven_coins if "collected_heaven_coins" in global else 0
		current_save_data.unlocked_levels = global.unlocked_levels.duplicate()
		current_save_data.completed_quests = global.completed_quests.duplicate()
		
		# Save game difficulty and coin type
		current_save_data.difficulty = global.current_difficulty
		current_save_data.coin_type = global.current_coin_type
	
	# Save message history if GlobalHUD has it
	if global_hud and "message_history" in global_hud:
		current_save_data.message_history = global_hud.message_history.duplicate(true)
		
	# Update playtime
	current_save_data.playtime_seconds += 1  # Add at least 1 second each time

# Update to SaveManager._apply_save_data method
func _apply_save_data() -> void:
	if not current_save_data:
		return
		
	# Update GameManager data
	if get_node_or_null("/root/Global"):
		var global = get_node("/root/Global")
		global.collected_coins = current_save_data.collected_coins
		global.collected_heaven_coins = current_save_data.collected_heaven_coins
		global.unlocked_levels = current_save_data.unlocked_levels.duplicate()
		global.completed_quests = current_save_data.completed_quests.duplicate()
		global.current_level = current_save_data.current_level
		global.memorable_screenshots = current_save_data.memorable_screenshots
		
		# Set game difficulty and coin type
		global.current_difficulty = current_save_data.difficulty
		global.current_coin_type = current_save_data.coin_type
		
		# Emit signals for the changes
		global.emit_signal("difficulty_changed", global.current_difficulty, global.current_difficulty)
		global.emit_signal("coin_type_changed", global.current_coin_type)

	# Update GlobalHUD if available
	var global_hud = get_node_or_null("/root/GlobalHUD")
	if global_hud:
		global_hud.current_health = current_save_data.health
		global_hud.coins = current_save_data.coins
		global_hud.heaven_coins = current_save_data.heaven_coins
		
		# Restore message history if available
		if "message_history" in current_save_data and current_save_data.message_history.size() > 0:
			global_hud.message_history = current_save_data.message_history.duplicate(true)
		
		# Notify the HUD about all values
		global_hud.notify_hud_of_all_values()
		
# Apply save data to the player (called when player is instantiated)
func apply_save_data_to_player(player) -> void:
	if not current_save_data or not player:
		return

	# Set player stats from constants if they're not valid in save data
	player.SPEED = current_save_data.player_speed if current_save_data.player_speed > 0 else Constants.PLAYER_DEFAULT_SPEED
	player.JUMP_VELOCITY = current_save_data.player_jump_velocity if current_save_data.player_jump_velocity < 0 else Constants.PLAYER_DEFAULT_JUMP_VELOCITY
	player.FLY_VELOCITY = current_save_data.player_fly_velocity if current_save_data.player_fly_velocity < 0 else Constants.PLAYER_DEFAULT_FLY_VELOCITY
	player.GRAVITY = current_save_data.player_gravity if current_save_data.player_gravity > 0 else Constants.PLAYER_DEFAULT_GRAVITY
	player.mode = current_save_data.player_mode
	player.passed_fly_time = current_save_data.player_passed_fly_time
	player.jump_counter = current_save_data.player_jump_counter
	player.ready_for_jump = current_save_data.player_ready_for_jump
	player.allowed_jumps = current_save_data.player_allowed_jumps

	# Apply outfit if available
	if current_save_data.player_outfit:
		player.player_outfit = current_save_data.player_outfit.duplicate(true)

		# If there's a resource-based outfit, update that too
		if player.current_outfit:
			player.current_outfit.from_dictionary(current_save_data.player_outfit)

	# Set position if available and valid
	if current_save_data.player_position != Vector2.ZERO:
		player.global_position = current_save_data.player_position

	# Set HUD data if available
	var global_hud = get_node_or_null("/root/GlobalHUD")
	if global_hud:
		global_hud.current_health = current_save_data.health
		global_hud.coins = current_save_data.coins
		global_hud.heaven_coins = current_save_data.heaven_coins
		global_hud.notify_hud_of_all_values()


# Settings management - Using player defaults from Constants
func save_settings() -> bool:
	var config = ConfigFile.new()

	# Get player for current settings
	var player = null
	if get_node_or_null("/root/Global") and get_node("/root/Global").player:
		player = get_node("/root/Global").player

	# Save constant values if player doesn't exist, otherwise save player values
	if player:
		# Save player settings
		config.set_value(Constants.SECTION_SETTINGS, "speed", player.SPEED)
		config.set_value(Constants.SECTION_SETTINGS, "jump_velocity", player.JUMP_VELOCITY)
		config.set_value(Constants.SECTION_SETTINGS, "fly_velocity", player.FLY_VELOCITY)
		config.set_value(Constants.SECTION_SETTINGS, "gravity", player.GRAVITY)
		config.set_value(Constants.SECTION_SETTINGS, "mode", player.mode)
		config.set_value(Constants.SECTION_SETTINGS, "passed_fly_time", player.passed_fly_time)
		config.set_value(Constants.SECTION_SETTINGS, "jump_counter", player.jump_counter)
		config.set_value(Constants.SECTION_SETTINGS, "ready_for_jump", player.ready_for_jump)
		config.set_value(Constants.SECTION_SETTINGS, "allowed_jumps", player.allowed_jumps)

		# Save outfit
		if player.player_outfit:
			config.set_value(Constants.SECTION_SETTINGS, "outfit", player.player_outfit)
	else:
		# If no player exists, use default constants or current save data
		config.set_value(Constants.SECTION_SETTINGS, "speed", current_save_data.player_speed)
		config.set_value(Constants.SECTION_SETTINGS, "jump_velocity", current_save_data.player_jump_velocity)
		config.set_value(Constants.SECTION_SETTINGS, "fly_velocity", current_save_data.player_fly_velocity)
		config.set_value(Constants.SECTION_SETTINGS, "gravity", current_save_data.player_gravity)
		config.set_value(Constants.SECTION_SETTINGS, "mode", current_save_data.player_mode)
		config.set_value(Constants.SECTION_SETTINGS, "passed_fly_time", current_save_data.player_passed_fly_time)
		config.set_value(Constants.SECTION_SETTINGS, "jump_counter", current_save_data.player_jump_counter)
		config.set_value(Constants.SECTION_SETTINGS, "ready_for_jump", current_save_data.player_ready_for_jump)
		config.set_value(Constants.SECTION_SETTINGS, "allowed_jumps", current_save_data.player_allowed_jumps)

		# Save outfit
		if current_save_data.player_outfit:
			config.set_value(Constants.SECTION_SETTINGS, "outfit", current_save_data.player_outfit)

	# Save game settings
	if get_node_or_null("/root/Global"):
		config.set_value(Constants.SECTION_SETTINGS, "difficulty", get_node("/root/Global").current_difficulty)
		config.set_value(Constants.SECTION_SETTINGS, "coin_type", get_node("/root/Global").current_coin_type)

	# Save audio settings
	var master_bus_idx = AudioServer.get_bus_index("Master")
	config.set_value(Constants.SECTION_SETTINGS, "master_volume", AudioServer.get_bus_volume_db(master_bus_idx))
	config.set_value(Constants.SECTION_SETTINGS, "master_mute", AudioServer.is_bus_mute(master_bus_idx))
	
	# Save auto-save settings
	config.set_value(Constants.SECTION_SETTINGS, "auto_save_enabled", auto_save_enabled)
	config.set_value(Constants.SECTION_SETTINGS, "auto_save_interval", auto_save_interval)

	# Save the config
	var err = config.save(Constants.SETTINGS_FILE_PATH)
	var success = (err == OK)

	if success:
		print("Settings saved successfully to: ", Constants.SETTINGS_FILE_PATH)
	else:
		push_error("Failed to save settings. Error code: " + str(err))

	emit_signal("settings_saved", success)
	return success

func load_settings() -> bool:
	var config = ConfigFile.new()
	var err = config.load(Constants.SETTINGS_FILE_PATH)

	if err != OK:
		print("No settings file found or error loading settings. Using defaults.")
		emit_signal("settings_loaded", false)
		return false

	print("Loading settings from: ", Constants.SETTINGS_FILE_PATH)

	# Create default save data if not already created
	if not current_save_data:
		current_save_data = SaveData.new()
		game_data = current_save_data

	# Load settings into current_save_data for future use
	current_save_data.player_speed = config.get_value(Constants.SECTION_SETTINGS, "speed", Constants.PLAYER_DEFAULT_SPEED)
	current_save_data.player_jump_velocity = config.get_value(Constants.SECTION_SETTINGS, "jump_velocity", Constants.PLAYER_DEFAULT_JUMP_VELOCITY)
	current_save_data.player_fly_velocity = config.get_value(Constants.SECTION_SETTINGS, "fly_velocity", Constants.PLAYER_DEFAULT_FLY_VELOCITY)
	current_save_data.player_gravity = config.get_value(Constants.SECTION_SETTINGS, "gravity", Constants.PLAYER_DEFAULT_GRAVITY)
	current_save_data.player_mode = config.get_value(Constants.SECTION_SETTINGS, "mode", "normal")
	current_save_data.player_passed_fly_time = config.get_value(Constants.SECTION_SETTINGS, "passed_fly_time", 0.0)
	current_save_data.player_jump_counter = config.get_value(Constants.SECTION_SETTINGS, "jump_counter", 0)
	current_save_data.player_ready_for_jump = config.get_value(Constants.SECTION_SETTINGS, "ready_for_jump", true)
	current_save_data.player_allowed_jumps = config.get_value(Constants.SECTION_SETTINGS, "allowed_jumps", Constants.PLAYER_MAX_JUMPS)
	
	# Load difficulty and coin type
	#current_save_data.difficulty = config.get_value(Constants.SECTION_SETTINGS, "difficulty", 1) # Default: NORMAL
	#current_save_data.coin_type = config.get_value(Constants.SECTION_SETTINGS, "coin_type", 0) # Default: NORMAL

	# Apply game settings to Global if it exists
	if get_node_or_null("/root/Global"):
		get_node("/root/Global").current_difficulty = current_save_data.difficulty
		get_node("/root/Global").current_coin_type = current_save_data.coin_type
		
		# Emit signals for the changes
		get_node("/root/Global").emit_signal("difficulty_changed", current_save_data.difficulty, current_save_data.difficulty)
		get_node("/root/Global").emit_signal("coin_type_changed", current_save_data.coin_type)

	# Load outfit
	var saved_outfit = config.get_value(Constants.SECTION_SETTINGS, "outfit", null)
	if saved_outfit:
		current_save_data.player_outfit = saved_outfit.duplicate(true)

	# Apply audio settings
	var master_bus_idx = AudioServer.get_bus_index("Master")
	var volume = config.get_value(Constants.SECTION_SETTINGS, "master_volume", 0.0)
	var mute = config.get_value(Constants.SECTION_SETTINGS, "master_mute", false)

	AudioServer.set_bus_volume_db(master_bus_idx, volume)
	AudioServer.set_bus_mute(master_bus_idx, mute)
	
	# Load auto-save settings
	auto_save_enabled = config.get_value(Constants.SECTION_SETTINGS, "auto_save_enabled", false)
	auto_save_interval = config.get_value(Constants.SECTION_SETTINGS, "auto_save_interval", 300.0)

	print("Settings loaded successfully")
	emit_signal("settings_loaded", true)
	return true

# Outfit management
func save_outfit(outfit_config: Dictionary, name: String = "") -> bool:
	var favorites = load_favorite_outfits()

	if name.is_empty():
		name = "Outfit " + str(favorites.size() + 1)

	favorites[name] = outfit_config

	var config = ConfigFile.new()
	config.set_value(Constants.SECTION_FAVORITES, "outfits", favorites)
	var err = config.save(Constants.FAVORITES_FILE_PATH)
	var success = (err == OK)

	if success:
		print("Outfit saved successfully: ", name)
	else:
		push_error("Failed to save outfit. Error code: " + str(err))

	emit_signal("outfit_saved", success, name)
	return success

func load_favorite_outfits() -> Dictionary:
	var config = ConfigFile.new()
	var err = config.load(Constants.FAVORITES_FILE_PATH)

	if err == OK:
		return config.get_value(Constants.SECTION_FAVORITES, "outfits", {})
	else:
		return {}

func delete_outfit(name: String) -> bool:
	var favorites = load_favorite_outfits()

	if not favorites.has(name):
		return false

	favorites.erase(name)

	var config = ConfigFile.new()
	config.set_value(Constants.SECTION_FAVORITES, "outfits", favorites)
	var err = config.save(Constants.FAVORITES_FILE_PATH)

	return (err == OK)

# Helper functions
func save_exists() -> bool:
	return ResourceLoader.exists(Constants.SAVE_FILE_PATH)

func clear_save_data() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists(Constants.SAVE_FILE_PATH):
			dir.remove(Constants.SAVE_FILE_PATH)
			print("Save data cleared")
	current_save_data = SaveData.new()
	game_data = current_save_data

# Return a fresh instance of SaveData
func create_new_save_data() -> SaveData:
	return SaveData.new()

# Helper method for other scripts to add callback function when save completes
func connect_save_completed(target: Object, method: String, binds: Array = [], flags: int = 0) -> void:
	if not is_connected("save_completed", Callable(target, method)):
		connect("save_completed", Callable(target, method).bind(binds), flags)

# Called when player instance is being initialized
func _on_player_ready(player) -> void:
	call_deferred("apply_save_data_to_player", player)
