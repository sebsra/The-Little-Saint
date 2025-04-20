extends CharacterBody2D
class_name BaseEnemy

# Base stats
var max_health: float = 100.0
var current_health: float = 100.0
var speed: float = 60.0
var chase_speed: float = 80.0
var attack_damage: float = 10.0
var attack_cooldown: float = 1.0
var detection_radius: float = 200.0
var attack_radius: float = 50.0
var patrol_distance: float = 100.0
var has_been_initialized: bool = false

# Patrol state variables 
var patrol_points: Array = []
var patrol_direction: int = 1
var patrol_wait_time: float = 1.0
var patrol_is_waiting: bool = false
var patrol_timer: float = 0.0

# Player collision handling
var bounce_strength: float = -250.0
var player_knockback: float = 200.0
var hover_check_distance: float = 50.0
var hover_check_timer: float = 0.0
var hover_check_interval: float = 0.05
var jump_off_player_strength: float = -350.0
var on_player_check_interval: float = 0.05
var on_player_check_timer: float = 0.0
var player_head_detection_width: float = 30.0

# Cooldown tracking
var can_attack: bool = true
var attack_timer: float = 0.0

# State
var is_dead: bool = false
var is_invulnerable: bool = false
var is_attacking: bool = false

# Components
var state_machine = null
var collision_shape = null
var animated_sprite = null

enum DropType {NONE, COIN, ELIXIR, HEART}
var drop_chance: float = 0.8 #Chance to drop anything
var drop_type_chances = {
	DropType.COIN: 0.5,   # 50% chance for coin
	DropType.ELIXIR: 0.25, # 25% chance for elixir
	DropType.HEART: 0.25
}

# Signals
signal damaged(amount, attacker)
signal died()
signal attack_executed(target, damage)

const DEFEAT_MESSAGES: PackedStringArray = [
	"Der Schatten fiel, verbrannt im Strahl des Lichtes.",
	"Ein weiterer Thron der Finsternis wurde gestürzt.",
	"Dein Schwert sang – und Stille hüllte den Abgrund ein.",
	"Die Fesseln des Bösen zersplitterten unter heiligem Stahl.",
	"Ein Echo hallt: ‚Es ist vollbracht.'",
	"Die Nacht wich vor dem Wort, das stärker ist als Stahl.",
	"Kein Dunkel trotzt dem Feuer des Glaubens.",
	"Der Sturm der Verdammnis brach an deiner Festung.",
	"Ein Siegel löste sich; das Licht strömte hervor.",
	"Die Schlange verstummte vor dem Löwen Judahs.",
	"Staub blieb, wo einst ein Schrecken thronte.",
	"Die Mauern des Abgrunds erzitterten bei deinem Schritt.",
	"Ein verlorener Name wurde aus dem Buch der Schatten getilgt.",
	"Die Ketten klirrten – und fielen.",
	"Die Glocken zogen Krieg, doch Frieden triumphierte.",
	"Das Schwert des Geistes schnitt bis in Mark und Bein.",
	"Die Flamme des Altars verschlang den letzten Zweifel.",
	"Ein letztes Heulen – dann Stille zwischen den Sternen.",
	"Die Himmel öffneten sich, während der Feind zerfiel.",
	"Ewiges Licht überragt nun die gefallene Bastion."
]

@onready var _rng := RandomNumberGenerator.new()

## Wählt zufällig eine Meldung aus, blendet die Münz‑Transition ein
## und zeigt den Text auf dem GlobalHUD an.
##
## @param duration Sekunden, die der Text sichtbar bleibt (Standard 3 Sek.)
func show_random_defeat_message(duration: float = 10.0) -> void:
	var msg := DEFEAT_MESSAGES[_rng.randi() % DEFEAT_MESSAGES.size()]
	var space = "          "
	msg = space + msg + space
	GlobalHUD.add_message(msg, duration)
	
func _ready():
	# Get nodes
	collision_shape = get_node_or_null("CollisionShape2D")
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	add_to_group("enemy") 
	
	# Initialize with proper difficulty settings
	apply_difficulty_scaling()
	has_been_initialized = true
	
	# Connect to difficulty changes
	if Global:
		Global.difficulty_changed.connect(_on_difficulty_changed)

func _physics_process(delta):
	# Update attack cooldown
	if not can_attack:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			can_attack = true
			attack_timer = 0.0
	
	# Handle physics based on gravity
	if not is_on_floor() and "velocity" in self:
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
		
		# Proactive check for player collision when falling
		if velocity.y > 0:  # Only when falling downward
			hover_check_timer += delta
			if hover_check_timer >= hover_check_interval:
				hover_check_timer = 0.0
				prevent_player_landing()
	
	# Check if we're standing on player's head
	on_player_check_timer += delta
	if on_player_check_timer >= on_player_check_interval:
		on_player_check_timer = 0.0
		check_if_on_player_head()
	
	# Apply movement
	if "velocity" in self:
		move_and_slide()
		
		# Additional check immediately after movement
		if not is_on_floor() and velocity.y > 0:
			var player = get_player()
			if player and is_overlapping_player(player):
				# Force immediate bounce if overlapping
				emergency_bounce(player)

# Get player reference
func get_player():
	return get_tree().get_first_node_in_group("player")

# Check if about to land on player using physics raycast
func prevent_player_landing():
	var player = get_player()
	if not player:
		return
		
	# Calculate potential landing spot
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,  # Start from current position
		global_position + Vector2(0, hover_check_distance),  # Check below
		1,  # Collision mask (adjust to your collision layer setup)
		[get_rid()]  # Exclude self from the check
	)
	
	var result = space_state.intersect_ray(query)
	
	# If we're about to hit the player, bounce off
	if result and result.collider == player:
		# Determine horizontal direction away from player
		var direction = sign(global_position.x - player.global_position.x)
		if direction == 0:
			direction = 1
			
		# Apply bounce with horizontal movement
		velocity.y = bounce_strength * 1.2  # Extra bounce strength
		velocity.x = direction * player_knockback * 1.5
		
		# Also apply knockback to player if possible
		if "velocity" in player:
			player.velocity.x = -direction * player_knockback * 0.5

# Emergency handling for direct overlaps
func is_overlapping_player(player):
	# Simple AABB overlap check
	var enemy_rect = Rect2(global_position - Vector2(10, 20), Vector2(20, 40))
	var player_rect = Rect2(player.global_position - Vector2(10, 20), Vector2(20, 40))
	return enemy_rect.intersects(player_rect)

# Handle immediate bounce if already overlapping
func emergency_bounce(player):
	var direction = sign(global_position.x - player.global_position.x)
	if direction == 0:
		direction = 1
		
	# Strong bounce to force separation
	velocity.y = bounce_strength * 1.5
	velocity.x = direction * player_knockback * 2
	
	# Move the enemy up slightly to prevent getting stuck
	global_position.y -= 5
	
	# Apply stronger knockback to player
	if "velocity" in player:
		player.velocity.x = -direction * player_knockback

# New function to detect standing on player's head
func check_if_on_player_head():
	var player = get_player()
	if not player:
		return
		
	# Check if we're approximately on the player's head
	var horizontal_distance = abs(global_position.x - player.global_position.x)
	var vertical_distance = global_position.y - player.global_position.y
	
	# Conditions for being on player's head:
	if horizontal_distance < player_head_detection_width and vertical_distance < -30 and vertical_distance > -50 and is_on_floor():
		jump_off_player_head(player)
		
	# Additionally, check for almost direct overlap regardless of floor status
	if horizontal_distance < 15 and vertical_distance < -20 and vertical_distance > -45:
		jump_off_player_head(player)

# Function to jump off player's head
func jump_off_player_head(player):
	# Strong jump upward
	velocity.y = jump_off_player_strength
	
	# Also move horizontally away from player
	var direction = sign(global_position.x - player.global_position.x)
	if direction == 0:
		direction = 1  # Default direction if perfectly aligned
	
	velocity.x = direction * 150  # Horizontal movement away
	
	# Restart collision checks
	on_player_check_timer = 0.0
	
	print(name + " jumped off player's head")

# Create and setup state machine - called by child classes
func setup_state_machine():
	state_machine = EnemyStateMachine.new()
	add_child(state_machine)
	# No need to call setup() - EnemyStateMachine will get owner_node in its _ready()

# Apply difficulty scaling - will be called on init and when difficulty changes
func apply_difficulty_scaling():
	if not Global:
		return
		
	var difficulty = Global.get_difficulty()
	
	# This function adjusts base attributes based on difficulty
	match difficulty:
		Global.Difficulty.EASY:
			# The base values are already set for EASY (default in your code)
			pass
			
		Global.Difficulty.NORMAL:
			max_health *= 1.3
			attack_damage *= 1.2
			speed *= 1.1
			chase_speed *= 1.1
			detection_radius *= 1.2
			attack_cooldown *= 0.9  # Lower is faster
			
		Global.Difficulty.HARD:
			max_health *= 1.7
			attack_damage *= 1.5
			speed *= 1.3
			chase_speed *= 1.3
			detection_radius *= 1.5
			attack_radius *= 1.1
			attack_cooldown *= 0.7
			
		Global.Difficulty.NIGHTMARE:
			max_health *= 2.5
			attack_damage *= 2.0
			speed *= 1.5
			chase_speed *= 1.5
			detection_radius *= 2.0
			attack_radius *= 1.3
			attack_cooldown *= 0.5
	
	# Update current health to match new max health
	if not has_been_initialized:
		current_health = max_health
	else:
		# For existing enemies, maintain health percentage
		var health_percent = current_health / max_health
		current_health = max_health * health_percent

# Handles difficulty changes during gameplay
func _on_difficulty_changed(new_difficulty, old_difficulty):
	# Re-apply scaling when difficulty changes
	apply_difficulty_scaling()

# Take damage from an attack
func take_damage(amount: float, attacker = null):
	if is_dead or is_invulnerable:
		return false
	
	current_health -= amount
	emit_signal("damaged", amount, attacker)
	
	# Check for death
	if current_health <= 0:
		die()
		return true
	
	return true

# Execute attack on a target
func execute_attack(target, damage: float = -1):
	if is_dead:
		return false
	
	# Use default damage if none specified
	if damage < 0:
		damage = attack_damage
	
	is_attacking = true
	
	# Reset attack cooldown
	can_attack = false
	attack_timer = 0
	
	# Deal damage if target has health system
	var hit = false
	if target and target.has_method("take_damage"):
		hit = target.take_damage(damage, self)
	
	emit_signal("attack_executed", target, damage)
	is_attacking = false
	
	return hit

# Die function
func die():
	if is_dead:
		return
		
	is_dead = true
	emit_signal("died")

# Play animation if it exists
func play_animation(anim_name: String):
	if animated_sprite and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		
# Add this function to the file:
func drop_item():
	# First roll to see if we drop anything
	if randf() > drop_chance:
		return
	
	# Determine what to drop
	var drop_roll = randf()
	var cumulative_chance = 0.0
	var chosen_drop = DropType.NONE
	
	for drop_type in drop_type_chances.keys():
		cumulative_chance += drop_type_chances[drop_type]
		if drop_roll <= cumulative_chance:
			chosen_drop = drop_type
			break
	
	# If we're not dropping anything, exit
	if chosen_drop == DropType.NONE:
		return
	
	# Get the scene path based on drop type
	var scene_path = ""
	match chosen_drop:
		DropType.COIN:
			# Check Global for coin type
			if Global and Global.current_coin_type == Global.CoinType.HEAVENLY:
				scene_path = "res://scenes/core/items/heavenly_coin.tscn"
			else:
				scene_path = "res://scenes/core/items/coin.tscn"
		DropType.ELIXIR:
			scene_path = "res://scenes/core/items/elixir.tscn"			
		DropType.HEART:
			scene_path = "res://scenes/core/items/heart.tscn"
			
	
	# Instantiate the drop if we have a valid scene path
	if scene_path != "":
		var scene = load(scene_path)
		if scene:
			var drop_instance = scene.instantiate()
			get_parent().add_child(drop_instance)
			drop_instance.global_position = global_position
