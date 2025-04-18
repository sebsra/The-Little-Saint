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

# Signals
signal damaged(amount, attacker)
signal died()
signal attack_executed(target, damage)

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
	
	# Apply movement
	if "velocity" in self:
		move_and_slide()

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
	
	# Set appropriate state
	if state_machine:
		state_machine.change_state("Death")

# Play animation if it exists
func play_animation(anim_name: String):
	if animated_sprite and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
