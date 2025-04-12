class_name BaseEnemy
extends CharacterBody2D

## Base class for all enemies in the game
## Provides basic attributes and functionality only

# Enemy properties - attributes only
@export_category("Stats")
@export var max_health: float = 100.0
@export var speed: float = 80.0
@export var chase_speed: float = 100.0
@export var attack_damage: float = 50.0  # Geändert für konsistenten Schaden (0.5 Herzen)
@export var attack_cooldown: float = 1.0
@export var detection_radius: float = 200.0
@export var attack_radius: float = 75.0
@export var patrol_distance: float = 100.0

# Current state - public attributes that states can modify
var current_health: float
var is_dead: bool = false
var is_invulnerable: bool = false
var can_attack: bool = true  # Can this enemy currently attack

# Components (to be assigned by extending classes)
var animated_sprite: AnimatedSprite2D
var collision_shape: CollisionShape2D
var state_machine: EnemyStateMachine

# Signals - communicate with states instead of direct calls
signal damaged(amount, attacker)
signal died
signal attack_executed(target, damage)
signal attack_completed
signal animation_finished(anim_name)

func _ready():
	# Initialize health
	current_health = max_health
	
	# Find key components
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	collision_shape = get_node_or_null("CollisionShape2D")
	
	# Connect to animation finished
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Make sure we're in the enemy group
	if not is_in_group("enemy"):
		add_to_group("enemy")
	
	# State machine now managed explicitly by child classes
	state_machine = get_node_or_null("StateMachine") as EnemyStateMachine
	
	print(name + " initialized with " + str(current_health) + " health")

func _physics_process(delta):
	# Apply gravity if not on floor
	if not is_on_floor():
		velocity.y += calculate_gravity() * delta
	
	# Core movement - states will set velocity.x
	move_and_slide()

func calculate_gravity():
	return ProjectSettings.get_setting("physics/2d/default_gravity")

# Animation interface - states call this
func play_animation(anim_name: String):
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	elif animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
		print("Animation not found for " + name + ": " + anim_name + ", using idle instead")

# Handle animation completion - Notify states through signals
func _on_animation_finished():
	if animated_sprite:
		emit_signal("animation_finished", animated_sprite.animation)

# Damage interface - states handle effects of damage
func take_damage(amount, attacker = null):
	if is_dead or is_invulnerable:
		return
	
	current_health -= amount
	emit_signal("damaged", amount, attacker)
	
	print(name + " took " + str(amount) + " damage, health: " + str(current_health))
	
	if current_health <= 0 and not is_dead:
		is_dead = true
		emit_signal("died")

# Attack interface - Actual behavior in attack states
func execute_attack(target, damage_amount = null):
	var actual_damage = damage_amount if damage_amount != null else attack_damage
	emit_signal("attack_executed", target, actual_damage)
	
	# Direkten Schaden auf Spieler anwenden
	if target.is_in_group("player") and target.has_method("take_damage"):
		target.take_damage(actual_damage)
	
	# HUD aktualisieren
	if target.is_in_group("player"):
		var hud = get_tree().get_root().find_child("HUD", true, false)
		if hud and hud.has_method("change_life"):
			hud.change_life(-actual_damage / 100)  # Skalierung für HUD (0.5 für halbes Herz)
	
	# Let states know when attack completes through signal
	can_attack = false
	get_tree().create_timer(attack_cooldown).timeout.connect(func():
		can_attack = true
		emit_signal("attack_completed")
	)

# Hilfsmethode zum Einrichten einer neuen State Machine
func setup_state_machine():
	if state_machine:
		return  # Bereits vorhanden
		
	state_machine = EnemyStateMachine.new()
	state_machine.name = "StateMachine"
	add_child(state_machine)
	
	# Konfiguriere Erkennungsbereiche
	state_machine.detection_range = detection_radius
	state_machine.attack_range = attack_radius
	state_machine.patrol_range = patrol_distance
