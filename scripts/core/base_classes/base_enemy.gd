class_name BaseEnemy
extends CharacterBody2D

## Base class for all enemies in the game

# Enemy properties
@export var max_health: float = 100.0
@export var speed: float = 80.0
@export var chase_speed: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var detection_radius: float = 200.0
@export var attack_radius: float = 75.0

# Current state
var current_health: float
var is_dead: bool = false
var is_chasing: bool = false
var is_attacking: bool = false
var can_attack: bool = true
var target = null

# Nodes (to be assigned by extending classes)
var animated_sprite: AnimatedSprite2D
var collision_shape: CollisionShape2D
var hud = null

# Emitted when enemy dies
signal enemy_died(enemy)
# Emitted when enemy takes damage
signal enemy_damaged(enemy, amount)

func _ready():
	# Initialize health
	current_health = max_health
	
	# Set default animation
	if animated_sprite:
		animated_sprite.play("idle")
	
	# Get HUD reference (if needed)
	hud = get_node_or_null("../../HUD")

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += calculate_gravity() * delta
	
	# Core movement
	move_and_slide()

func calculate_gravity():
	# Can be overridden by child classes
	return ProjectSettings.get_setting("physics/2d/default_gravity")

func take_damage(amount):
	if is_dead:
		return
		
	current_health -= amount
	emit_signal("enemy_damaged", self, amount)
	
	if current_health <= 0:
		die()
	else:
		play_animation("hurt")

func die():
	is_dead = true
	is_chasing = false
	is_attacking = false
	
	# Disable collision
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# Play death animation
	play_animation("death")
	
	# Emit signal
	emit_signal("enemy_died", self)
	
	# Wait for animation to finish before removing
	await animated_sprite.animation_finished
	queue_free()

func play_animation(anim_name: String):
	if animated_sprite and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)

func chase_target(target_node):
	if is_dead or is_attacking:
		return
		
	target = target_node
	is_chasing = true
	
	var direction = (target.global_position - global_position).normalized()
	
	# Face the correct direction
	if animated_sprite:
		animated_sprite.flip_h = direction.x > 0
	
	# Set velocity
	velocity.x = direction.x * (chase_speed if is_chasing else speed)
	
	# Play animation
	play_animation("walk")

func stop_chase():
	is_chasing = false
	velocity.x = 0
	play_animation("idle")
	target = null

func attack():
	if is_dead or not can_attack or not target:
		return
		
	is_attacking = true
	can_attack = false
	velocity.x = 0
	
	play_animation("attack")
	
	# Wait for animation to finish
	await animated_sprite.animation_finished
	
	is_attacking = false
	
	# Start cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# Called when a player or other entity enters detection radius
func _on_detection_radius_body_entered(body):
	if body.name == "Player" and not is_dead:
		chase_target(body)

# Called when a player or other entity exits detection radius
func _on_detection_radius_body_exited(body):
	if body.name == "Player":
		stop_chase()

# Called when a player enters attack range
func _on_attack_radius_body_entered(body):
	if body.name == "Player" and not is_dead:
		is_chasing = false
		attack()

# Called when a player exits attack range
func _on_attack_radius_body_exited(body):
	if body.name == "Player" and not is_dead:
		is_chasing = true
