class_name AttackBehavior
extends Node

## A modular component for enemy attack behavior

# Attack types
enum AttackType {
	MELEE,    # Close range attack
	RANGED,   # Projectile attack
	AREA      # Area of effect attack
}

# The type of attack
@export var attack_type: AttackType = AttackType.MELEE
# Base damage for the attack
@export var base_damage: float = 10.0
# Cooldown between attacks (seconds)
@export var cooldown: float = 1.0
# Range at which attack can be performed
@export var attack_range: float = 50.0
# For ranged attacks, the projectile scene
@export var projectile_scene: PackedScene = null
# For area attacks, the area shape
@export var area_shape: Shape2D = null
# For area attacks, the area size
@export var area_size: Vector2 = Vector2(100, 100)
# Animation to play when attacking
@export var attack_animation: String = "attack"
# Whether to face the target when attacking
@export var face_target: bool = true
# For ranged attacks, the spawn offset
@export var projectile_spawn_offset: Vector2 = Vector2(0, 0)
# Path to the animated sprite (if not direct child)
@export var animated_sprite_path: String = "AnimatedSprite2D"
# Whether this attack is currently available
@export var can_attack: bool = true

# Reference to the character this behavior belongs to
var character = null
# Current attack target
var target = null
# Current cooldown timer
var cooldown_timer: float = 0.0
# Reference to the damage system (optional)
var damage_system = null

# Signals
signal attack_started(target)
signal attack_finished(target, hit)
signal attack_cooldown_started(time)
signal attack_cooldown_finished()

func _ready():
	# Get the owner character (parent node)
	character = get_parent()
	
	# Try to get damage system reference
	damage_system = get_node_or_null("/root/DamageSystem")

func _process(delta):
	# Handle cooldown
	if not can_attack:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			can_attack = true
			emit_signal("attack_cooldown_finished")

## Check if a target is in attack range
func is_target_in_range(check_target) -> bool:
	if not check_target:
		return false
	
	var distance = character.global_position.distance_to(check_target.global_position)
	return distance <= attack_range

## Set a new attack target
func set_target(new_target):
	target = new_target

## Perform an attack against the current target
func attack() -> bool:
	if not can_attack or not target:
		return false
	
	if not is_target_in_range(target):
		return false
	
	# Face the target if enabled
	if face_target:
		_face_target(target)
	
	# Play attack animation
	if character.has_method("play_animation"):
		character.play_animation(attack_animation)
	elif character.has_node(animated_sprite_path):
		var sprite = character.get_node(animated_sprite_path)
		if sprite.has_method("play"):
			sprite.play(attack_animation)
	
	emit_signal("attack_started", target)
	
	# Handle different attack types
	var hit = false
	
	match attack_type:
		AttackType.MELEE:
			hit = _perform_melee_attack()
		AttackType.RANGED:
			hit = _perform_ranged_attack()
		AttackType.AREA:
			# This is a coroutine, so we need to use await
			hit = await _perform_area_attack()
	
	# Start cooldown
	can_attack = false
	cooldown_timer = cooldown
	emit_signal("attack_cooldown_started", cooldown)
	
	# Wait for animation to finish
	if character.has_node(animated_sprite_path):
		var sprite = character.get_node(animated_sprite_path)
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	
	emit_signal("attack_finished", target, hit)
	return hit

## Perform a melee attack
func _perform_melee_attack() -> bool:
	# If we have a damage system, use it
	if damage_system:
		return damage_system.process_attack(character, target, base_damage)
	
	# Otherwise use direct damage application
	if target.has_method("take_damage"):
		target.take_damage(base_damage)
		return true
	elif "current_health" in target:
		target.current_health -= base_damage
		return true
	
	return false

## Perform a ranged attack by spawning a projectile
func _perform_ranged_attack() -> bool:
	if not projectile_scene:
		push_error("Projectile scene is not set for ranged attack!")
		return false
	
	# Get spawn position
	var spawn_pos = character.global_position + projectile_spawn_offset
	
	# Get direction to target
	var direction = (target.global_position - spawn_pos).normalized()
	
	# Check if we have an object pool
	var projectile_pool = character.get_node_or_null("ProjectilePool")
	
	if projectile_pool and projectile_pool is ObjectPool:
		# Get a projectile from the pool
		var projectile = projectile_pool.get_object()
		if projectile:
			if projectile.has_method("setup"):
				projectile.setup(direction, spawn_pos, character.global_rotation, character)
			return true
	else:
		# Create a new projectile
		var projectile = projectile_scene.instantiate()
		get_tree().get_root().add_child(projectile)
		
		if projectile.has_method("setup"):
			projectile.setup(direction, spawn_pos, character.global_rotation, character)
		elif "direction" in projectile:
			projectile.direction = direction
			projectile.global_position = spawn_pos
			projectile.source_node = character
		
		return true
	
	return false

## Perform an area attack affecting all targets in an area
func _perform_area_attack() -> bool:
	var hit_something = false
	
	# Create area for attack
	var area = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	
	# Configure shape
	if area_shape:
		collision_shape.shape = area_shape
	else:
		# Default to rectangle
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = area_size
		collision_shape.shape = rect_shape
	
	area.add_child(collision_shape)
	character.add_child(area)
	
	# Check for bodies in the area
	await get_tree().process_frame
	var bodies = area.get_overlapping_bodies()
	
	for body in bodies:
		if body != character and body.is_in_group("damageable"):
			# If we have a damage system, use it
			if damage_system:
				damage_system.process_attack(character, body, base_damage)
			# Otherwise use direct damage application
			elif body.has_method("take_damage"):
				body.take_damage(base_damage)
			elif "current_health" in body:
				body.current_health -= base_damage
			
			hit_something = true
	
	# Clean up
	area.queue_free()
	return hit_something

## Face the character towards the target
func _face_target(face_target):
	if not face_target:
		return
	
	var direction = (face_target.global_position - character.global_position).normalized()
	
	# Handle sprite flipping
	var sprite = character.get_node_or_null(animated_sprite_path)
	if sprite and "flip_h" in sprite:
		sprite.flip_h = direction.x < 0
