extends Node

## Global constants for The Little Saint game

# Game States
enum GameState {
	MENU,           # In main menu
	PLAYING,        # Actively playing
	PAUSED,         # Game paused
	GAME_OVER,      # Player died or level failed
	CUTSCENE,       # In a cutscene
	DIALOGUE,       # In dialogue
	LOADING         # Loading screen
}

# Player Movement
const PLAYER_DEFAULT_SPEED: float = 200.0
const PLAYER_DEFAULT_JUMP_VELOCITY: float = -250.0
const PLAYER_DEFAULT_FLY_VELOCITY: float = -150.0
const PLAYER_DEFAULT_GRAVITY: float = 300.0
const PLAYER_MAX_JUMPS: int = 2

# Player Status
const PLAYER_DEFAULT_MAX_HEALTH: float = 3.0
const PLAYER_INVULNERABILITY_TIME: float = 1.0
const PLAYER_DEFAULT_FLY_TIME: float = 4.0

# File Paths
const SETTINGS_FILE_PATH: String = "user://settings.cfg"
const SAVE_FILE_PATH: String = "user://save_data.tres"
const OUTFIT_FILE_PATH: String = "user://outfits.tres"
const FAVORITES_FILE_PATH: String = "user://favorites.cfg"

# Config Sections
const SECTION_SETTINGS: String = "settings"
const SECTION_PLAYER: String = "player"
const SECTION_OUTFITS: String = "outfits"
const SECTION_FAVORITES: String = "favorites"

# Physics
const DEFAULT_GRAVITY: float = 980.0

# Animation
const ANIMATION_IDLE: String = "idle"
const ANIMATION_WALKING: String = "walking"
const ANIMATION_ATTACK: String = "attack_knife_right"  # Current attack animation
const ANIMATION_HURT: String = "hurt"
const ANIMATION_DEATH: String = "dead"
const ANIMATION_JUMP: String = "animation4"  # May need to be updated

# Layers
enum Layer {
	PLAYER = 1,
	PORTS = 2,
	ITEM = 3,
	ENEMY = 4
}

# Input Action Names
const INPUT_RIGHT: String = "right"
const INPUT_LEFT: String = "left"
const INPUT_UP: String = "up"
const INPUT_DOWN: String = "down"
const INPUT_ATTACK: String = "attack"
const INPUT_DEFEND: String = "defend"

# Scene paths
const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu/main_menu.tscn"
const ADVENTURE_LEVEL_SCENE: String = "res://scenes/levels/adventure_mode/adventure_level.tscn"
const SETTINGS_MENU_SCENE: String = "res://scenes/ui/settings/settings_menu.tscn"
const CUSTOMIZER_SCENE: String = "res://scenes/ui/character_customizer/customizer.tscn"
const AUDIO_SETTINGS_SCENE: String = "res://scenes/ui/settings/audio_settings.tscn"

# Debug
const DEBUG_ENABLED: bool = false
