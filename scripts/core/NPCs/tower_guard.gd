class_name TowerGuard
extends Node

# Referenz zum character_sprites Node
@onready var character_sprites = $character_sprites

# Aktuelle Animation und Richtung
var current_animation: String = "idle"
var direction: int = 1

# Bewegungszustände
var is_jumping: bool = false
var is_walking: bool = false

# Outfit-Konfiguration für den Burgwächter
var guard_outfit = {
	"beard": 3,
	"lipstick": "none",
	"eyes": 1,
	"shoes": 2,
	"earrings": "none",
	"hats": 4,  # Wächterhelm
	"glasses": "none",
	"clothes_down": 3,
	"clothes_up": 5,
	"clothes_complete": "none",
	"bodies": 1,
	"hair": 2
}

# Bewegungsparameter
var jump_height: float = 200.0
var jump_duration: float = 1.0
var walk_distance: float = 100.0
var walk_duration: float = 2.0

# Timer
var jump_timer: float = 0.0
var walk_timer: float = 0.0

# Startposition
var start_position: Vector2

func _ready():
	# Warte bis zum nächsten Frame, um sicherzustellen dass character_sprites bereit ist
	await get_tree().process_frame
	
	# Speichere Startposition
	start_position = character_sprites.position
	
	# Initialisiere Outfit
	update_outfit()

func _process(delta):
	# Sprung-Logik
	if is_jumping:
		jump_timer += delta
		var progress = jump_timer / jump_duration
		
		if progress <= 1.0:
			# Parabelförmiger Sprung
			var height = sin(progress * PI) * jump_height
			character_sprites.position.y = start_position.y - height
		else:
			# Beende Sprung
			is_jumping = false
			jump_timer = 0.0
			character_sprites.position.y = start_position.y
			current_animation = "idle"
			update_outfit()
	
	# Lauf-Logik
	if is_walking:
		walk_timer += delta
		var progress = walk_timer / walk_duration
		
		if progress <= 1.0:
			# Laufe hin und her
			var position_x = start_position.x + sin(progress * 2 * PI) * walk_distance
			character_sprites.position.x = position_x
			
			# Aktualisiere Richtung
			var new_direction = 1 if sin(progress * 2 * PI + PI/2) > 0 else -1
			if new_direction != direction:
				direction = new_direction
				update_outfit()
		else:
			# Beende Laufen
			is_walking = false
			walk_timer = 0.0
			character_sprites.position.x = start_position.x
			current_animation = "idle"
			update_outfit()

# Funktion für einen Sprung
func jump():
	if not is_jumping and not is_walking:
		is_jumping = true
		jump_timer = 0.0
		current_animation = "animation14"  # Verwende animation14 für Sprung
		update_outfit()

# Funktion zum Hin- und Herlaufen
func walk():
	if not is_jumping and not is_walking:
		is_walking = true
		walk_timer = 0.0
		current_animation = "walking"  # Verwende walking Animation
		update_outfit()

# Funktion zum Aktualisieren des Outfits (adaptiert von PlayerState)
func update_outfit():
	for outfit_part in guard_outfit:
		var animated_sprite = character_sprites.get_node(outfit_part)
		var selected_outfit = guard_outfit[outfit_part]
		
		if str(selected_outfit) == "none":
			animated_sprite.visible = false
		else:
			animated_sprite.visible = true
			animated_sprite.play(str(selected_outfit))
			animated_sprite.speed_scale = 2.0
			
			# Setze Richtung basierend auf aktueller Richtung
			animated_sprite.flip_h = direction > 0
			
			# Frame-Management mit animation_frames von character_sprites
			if current_animation in character_sprites.animation_frames:
				var frames = character_sprites.animation_frames[current_animation]
				if animated_sprite.frame < frames[0] or animated_sprite.frame >= frames[-1]:
					animated_sprite.frame = frames[0]
