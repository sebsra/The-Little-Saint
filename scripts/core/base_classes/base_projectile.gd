class_name BaseProjectile
extends CharacterBody2D

## Base class for all projectiles in the game
## Now supports object pooling

# Projectile properties
@export var speed: float = 100.0
@export var damage: float = 10.0
@export var lifetime: float = 5.0  # Time before auto-destruction
@export var gravity_affected: bool = false
@export var bounce: bool = false
@export var bounce_factor: float = 0.5  # How much velocity is retained when bouncing

# Internal variables
var direction: Vector2 = Vector2.ZERO
var source_node = null  # Who fired this projectile
var spawn_position: Vector2
var spawn_rotation: float
var time_alive: float = 0.0
var has_hit: bool = false
var is_from_pool: bool = false  # Whether this projectile came from a pool

# Signals
signal projectile_hit(projectile, target)
signal projectile_expired(projectile)

func _ready():
	# Start lifetime timer
	if lifetime > 0:
		get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_expired)
	
	# Setup animation if available
	if has_node("AnimatedSprite2D"):
		var sprite = get_node("AnimatedSprite2D")
		if sprite.sprite_frames.has_animation("flying"):
			sprite.play("flying")

func _physics_process(delta):
	time_alive += delta
	
	# Apply gravity if enabled
	if gravity_affected:
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
	
	# Move the projectile
	var collision = move_and_collide(velocity * delta)
	
	# Handle collision
	if collision and not has_hit:
		_on_collision(collision)

func setup(dir: Vector2, spawn_pos: Vector2, spawn_rot: float = 0.0, source = null):
	direction = dir.normalized()
	spawn_position = spawn_pos
	spawn_rotation = spawn_rot
	source_node = source
	
	# Set initial position and rotation
	global_position = spawn_position
	global_rotation = spawn_rotation
	
	# Set initial velocity
	velocity = direction * speed
	
	# Reset state
	has_hit = false
	time_alive = 0.0
	
	return self  # For method chaining

func _on_collision(collision):
	var collider = collision.get_collider()
	
	# Check if we should bounce
	if bounce and not (collider.is_in_group("Player") or collider.is_in_group("Enemy")):
		var reflection = collision.get_remainder().bounce(collision.get_normal())
		velocity = velocity.bounce(collision.get_normal()) * bounce_factor
		global_position += reflection
		return
	
	has_hit = true
	
	# Handle different collision types
	if collider.is_in_group("Player") and source_node != collider:
		_on_hit_player(collider)
	elif collider.is_in_group("Enemy") and source_node != collider:
		_on_hit_enemy(collider)
	else:
		_on_hit_environment(collider)

func _on_hit_player(player):
	emit_signal("projectile_hit", self, player)
	
	# Apply damage
	if player.has_method("take_damage"):
		player.take_damage(damage)
	
	# Get HUD reference
	var hud = get_node_or_null("../HUD")
	if hud and hud.has_method("change_life"):
		hud.change_life(-damage/100.0)  # Assuming HUD uses 0-1 scale
	
	# Play hit effect if available
	play_hit_effect()
	
	_recycle_or_free()

func _on_hit_enemy(enemy):
	emit_signal("projectile_hit", self, enemy)
	
	# Apply damage
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	
	# Play hit effect if available
	play_hit_effect()
	
	_recycle_or_free()

func _on_hit_environment(object):
	emit_signal("projectile_hit", self, object)
	
	# Play hit effect if available
	play_hit_effect()
	
	_recycle_or_free()

func _on_lifetime_expired():
	if not has_hit:
		emit_signal("projectile_expired", self)
		_recycle_or_free()

func play_hit_effect():
	# If we have an AnimatedSprite2D, try to play the hit animation
	if has_node("AnimatedSprite2D"):
		var sprite = get_node("AnimatedSprite2D")
		if sprite.sprite_frames.has_animation("hit"):
			# Disconnect from physics process
			set_physics_process(false)
			
			# Stop motion
			velocity = Vector2.ZERO
			
			# Play hit animation
			sprite.play("hit")
			
			# Wait for animation to finish
			await sprite.animation_finished

# Called when spawned from an object pool
func _on_spawn_from_pool():
	is_from_pool = true
	visible = true
	set_physics_process(true)
	
	# Reset state
	has_hit = false
	time_alive = 0.0

# Called when returned to an object pool
func _on_recycle_to_pool():
	# Reset state
	has_hit = false
	time_alive = 0.0
	velocity = Vector2.ZERO
	source_node = null
	
	# Reset animation if needed
	if has_node("AnimatedSprite2D"):
		var sprite = get_node("AnimatedSprite2D")
		if sprite.sprite_frames.has_animation("flying"):
			sprite.play("flying")
			sprite.frame = 0

# Either recycle to pool or free based on whether we're using pooling
func _recycle_or_free():
	if is_from_pool:
		# Find the object pool that owns this projectile
		var scene_root = get_tree().get_root()
		var pool = null
		
		# First check if our source has a projectile pool
		if source_node and source_node.has_node("ProjectilePool"):
			pool = source_node.get_node("ProjectilePool")
		
		# Otherwise look in the scene root
		if not pool:
			pool = scene_root.find_child("ProjectilePool", true, false)
		
		if pool and pool is ObjectPool:
			# Return to pool
			pool.recycle(self)
		else:
			# Fall back to queue_free
			queue_free()
	else:
		# Not from pool, just free it
		queue_free()
