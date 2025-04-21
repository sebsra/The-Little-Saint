extends Node

## Global handles game state, scene transitions, and global events
## Serves as the central controller for the game
# Game state
var current_state: Constants.GameState = Constants.GameState.MENU
var previous_state: Constants.GameState = Constants.GameState.MENU

# Difficulty settings - simple enum and current level only
enum Difficulty {EASY, NORMAL, HARD, NIGHTMARE}
var current_difficulty: Difficulty = Difficulty.EASY

enum CoinType {NORMAL, HEAVENLY}
var current_coin_type: CoinType = CoinType.NORMAL

# Player reference
var player: Player = null

# Player Name
var player_name = ""

# markiert, ob der Spieler das Schwert hat
var has_sword: bool = true

# Current level
var current_level: String = ""
var current_level_node = null
var next_level: String = ""

# Game progress
var collected_coins: int = 0
var unlocked_levels: Array = []
var completed_quests: Array = []

# Resource preloading
var resource_preloader = null
var is_preloading: bool = false
var preload_progress: float = 0.0


# Events
signal state_changed(new_state, old_state)
signal level_started(level_name)
signal level_completed(level_name)
signal player_died()
signal coin_collected(total_coins)
signal game_saved()
signal game_loaded()
signal resources_loading_progress(progress, total)
signal resources_loaded()
signal difficulty_changed(new_difficulty, old_difficulty)
signal coin_type_changed(new_type)
signal sword_collected 


# Initialization
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Game manager should run even when paused
	print("Game Manager initialized with difficulty: ", Difficulty.keys()[current_difficulty])
	
	# Initialize the resource preloader
	resource_preloader = GameResourcePreloader.new()
	resource_preloader.name = "GameResourcePreloader"
	add_child(resource_preloader)
	
	# Connect resource preloader signals
	resource_preloader.loading_progress.connect(_on_loading_progress)
	resource_preloader.all_resources_loaded.connect(_on_all_resources_loaded)

# Variable zum Speichern des letzten Goldsack-Screenshot-IDs
var last_sack_drop_screenshot: String = ""

# Dictionary für verschiedene Screenshot-Arten
var memorable_screenshots = {
	"sack_drops": [],
	"deaths": [],
	"victories": [],
	"special_moments": []
}

# Funktion zum Hinzufügen eines Screenshots zum Dictionary
func add_memorable_screenshot(category: String, screenshot_id: String) -> void:
	if memorable_screenshots.has(category):
		if not screenshot_id in memorable_screenshots[category]:
			memorable_screenshots[category].append(screenshot_id)
	else:
		memorable_screenshots[category] = [screenshot_id]

# Funktion zum Abrufen aller Screenshots einer Kategorie
func get_memorable_screenshots(category: String) -> Array:
	if memorable_screenshots.has(category):
		return memorable_screenshots[category]
	return []
	
# State management
func change_state(new_state: Constants.GameState) -> void:
	if new_state == current_state:
		return

	previous_state = current_state
	current_state = new_state

	match new_state:
		Constants.GameState.PAUSED:
			get_tree().paused = true
		Constants.GameState.PLAYING, Constants.GameState.MENU:
			get_tree().paused = false
		Constants.GameState.LOADING:
			# Loading state is handled by the loading screen
			pass

	emit_signal("state_changed", current_state, previous_state)
	print("Game state changed to: ", Constants.GameState.keys()[current_state])

func is_state(state: Constants.GameState) -> bool:
	return current_state == state

func resume_previous_state() -> void:
	change_state(previous_state)

# Difficulty management - simple getters and setters
func set_difficulty(difficulty: int) -> void:
	# Clamp the difficulty value to ensure it's between 0 and 3
	difficulty = clamp(difficulty, 0, Difficulty.values().size() - 1)

	if difficulty != current_difficulty:
		var old_difficulty = current_difficulty
		current_difficulty = difficulty  # Assign the valid difficulty
		emit_signal("difficulty_changed", current_difficulty, old_difficulty)
		print("Game difficulty changed to: ", Difficulty.keys()[current_difficulty])



func get_difficulty() -> int:
	return current_difficulty

func get_difficulty_name() -> String:
	return Difficulty.keys()[current_difficulty]
	
func set_coin_type(type: CoinType) -> void:
	if type != current_coin_type:
		current_coin_type = type
		emit_signal("coin_type_changed", current_coin_type)
		print("Coin type changed to: ", CoinType.keys()[current_coin_type])
		
func get_coin_type() -> int:
	return current_coin_type

func get_coin_type_name() -> String:
	return CoinType.keys()[current_coin_type]

# Update save_game function in game_manager.gd
func save_game() -> void:
	if SaveManager:
		SaveManager.save_game()
		emit_signal("game_saved")

# Update load_game function in game_manager.gd
func load_game() -> void:
	if SaveManager:
		SaveManager.load_game()
		emit_signal("game_loaded")
		
# Resource preloading
func preload_resources_for_level(level_name: String) -> void:
	if is_preloading:
		push_warning("Already preloading resources!")
		return
	
	# Enter loading state
	change_state(Constants.GameState.LOADING)
	is_preloading = true
	preload_progress = 0.0
	
	# Start preloading
	var success = resource_preloader.preload_level_resources(level_name)
	if success:
		resource_preloader.load_queued_resources()
	else:
		# No specific resources to preload, just continue
		is_preloading = false
		_finish_level_change()

func _on_loading_progress(loaded: int, total: int) -> void:
	preload_progress = float(loaded) / max(total, 1)
	emit_signal("resources_loading_progress", loaded, total)

func _on_all_resources_loaded() -> void:
	is_preloading = false
	emit_signal("resources_loaded")
	
	# Continue with level change if we were changing levels
	if next_level != "":
		_finish_level_change()

# Scene management with preloading
func change_scene(scene_path: String) -> void:
	# Store the next level path
	next_level = scene_path
	
	# Clear any popups or overlays
	if PopupManager:
		PopupManager.close_all_dialogs()
	
	# Store reference to current level if it's a level scene
	if scene_path.begins_with("res://scenes/levels/"):
		current_level = scene_path
		
		# Extract level name for preloading
		var level_name = scene_path.get_file().get_basename()
		preload_resources_for_level(level_name)
	else:
		# If it's not a level, just preload based on the scene name
		var scene_name = scene_path.get_file().get_basename()
		preload_resources_for_level(scene_name)

func _finish_level_change() -> void:
	if next_level.is_empty():
		return
	
	# Actual scene change
	get_tree().change_scene_to_file(next_level)
	
	# After scene change, set appropriate state
	if next_level == Constants.MAIN_MENU_SCENE:
		change_state(Constants.GameState.MENU)
	elif next_level.begins_with("res://scenes/levels/"):
		change_state(Constants.GameState.PLAYING)
		emit_signal("level_started", next_level)
	
	# Clear next level
	var loaded_level = next_level
	next_level = ""
	
	# Unload resources from previous level if not needed
	if resource_preloader and loaded_level != Constants.MAIN_MENU_SCENE:
		# Keep UI resources but unload previous level resources
		resource_preloader.unload_unused_resources(["ui", "audio"])

# Level management
func restart_level() -> void:
	if current_level:
		change_scene(current_level)

func go_to_main_menu() -> void:
	change_scene(Constants.MAIN_MENU_SCENE)

# Player-related functions
func register_player(player_instance) -> void:
	player = player_instance
	print("Player registered with Game Manager")

func collect_coin() -> void:
	collected_coins += 1
	emit_signal("coin_collected", collected_coins)
	
func collect_sword() -> void:
	has_sword = true
	emit_signal("sword_collected")
	PopupManager.info("Schwert aufgesammelt!", "Man nennt es auch das Wort Gottes. Keine Klinge Schärfer als diese. Benutze es über drücken von 'U'")
	
	print("Schwert eingesammelt!")

func player_death() -> void:
	change_state(Constants.GameState.GAME_OVER)
	emit_signal("player_died")

# Event handling
func notify_level_completed() -> void:
	if current_level and not unlocked_levels.has(current_level):
		unlocked_levels.append(current_level)
	emit_signal("level_completed", current_level)

# Debug helpers
func toggle_debug_mode() -> void:
	get_node("/root").get_tree().get_root().set_debug_enabled(not get_node("/root").get_tree().get_root().is_debug_enabled())

# Resource management helpers
func get_resource(type: String, id: String) -> Resource:
	if resource_preloader:
		return resource_preloader.get_resource(type, id)
	return null

func has_resource(type: String, id: String) -> bool:
	if resource_preloader:
		return resource_preloader.has_resource(type, id)
	return false

func load_resource(path: String, type: String = "other", id: String = "") -> Resource:
	if resource_preloader:
		return resource_preloader.load_resource(path, type, id)
	return ResourceLoader.load(path)

# System functions
func quit_game() -> void:
	save_game()
	get_tree().quit()

# Input handling

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Save game before allowing close
		print("Game closing - saving data...")
		SaveManager.save_game()
		SaveManager.save_settings()
		get_tree().quit()
