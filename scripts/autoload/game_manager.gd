extends Node

## Game Manager handles game state, scene transitions, and global events
## Serves as the central controller for the game

# Game state
var current_state: Constants.GameState = Constants.GameState.MENU
var previous_state: Constants.GameState = Constants.GameState.MENU

# Player reference
var player = null

# Current level
var current_level: String = ""
var current_level_node = null

# Game progress
var collected_coins: int = 0
var unlocked_levels: Array = []
var completed_quests: Array = []

# Events
signal state_changed(new_state, old_state)
signal level_started(level_name)
signal level_completed(level_name)
signal player_died()
signal coin_collected(total_coins)
signal game_saved()
signal game_loaded()

# Initialization
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Game manager should run even when paused
	print("Game Manager initialized")

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
	
	emit_signal("state_changed", current_state, previous_state)
	print("Game state changed to: ", Constants.GameState.keys()[current_state])

func is_state(state: Constants.GameState) -> bool:
	return current_state == state

func resume_previous_state() -> void:
	change_state(previous_state)

# Scene management
func change_scene(scene_path: String) -> void:
	call_deferred("_deferred_change_scene", scene_path)

func _deferred_change_scene(scene_path: String) -> void:
	# Clear any popups or overlays
	if PopupManager:
		PopupManager.close_all_dialogs()
	
	# Store reference to current level if it's a level scene
	if scene_path.begins_with("res://scenes/levels/"):
		current_level = scene_path
	
	# Transition animation could be added here
	get_tree().change_scene_to_file(scene_path)
	
	# After scene change, set appropriate state
	if scene_path == Constants.MAIN_MENU_SCENE:
		change_state(Constants.GameState.MENU)
	elif scene_path.begins_with("res://scenes/levels/"):
		change_state(Constants.GameState.PLAYING)
		emit_signal("level_started", scene_path)

# Level management
func restart_level() -> void:
	if current_level:
		change_scene(current_level)

func go_to_main_menu() -> void:
	change_scene(Constants.MAIN_MENU_SCENE)

# Save and load through SaveManager
func save_game() -> void:
	if SaveManager:
		SaveManager.save_game()
		emit_signal("game_saved")

func load_game() -> void:
	if SaveManager:
		SaveManager.load_game()
		emit_signal("game_loaded")

# Player-related functions
func register_player(player_instance) -> void:
	player = player_instance
	print("Player registered with Game Manager")

func collect_coin() -> void:
	collected_coins += 1
	emit_signal("coin_collected", collected_coins)

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

# System functions
func quit_game() -> void:
	save_game()
	get_tree().quit()

# Input handling
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(Constants.INPUT_MENU):
		if current_state == Constants.GameState.PLAYING:
			change_state(Constants.GameState.PAUSED)
		elif current_state == Constants.GameState.PAUSED:
			change_state(Constants.GameState.PLAYING)
			
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Save game before allowing close
		print("Game closing - saving data...")
		SaveManager.save_game()
		SaveManager.save_settings()
		get_tree().quit()
