class_name BaseProjectile
extends CharacterBody2D

## Enhanced base class for all projectiles in the game
## Supports object pooling, various trajectories, and collision effects

# Projectile properties
@export_group("Basic Properties")
@export var speed: float = 150.0
@export var damage: float = 0.25  # Equivalent to 25 before scaling
@export var lifetime: float = 5.0  # Time until automatic destruction
@export var gravity_affected: bool = false  # Whether the projectile is affected by gravity

@export_group("Behavior")
@export var bounce: bool = false  # Whether the projectile can bounce
@export var bounce_factor: float = 0.5  # How much velocity is retained when bouncing
@export var penetration: bool = false  # Whether the projectile can penetrate multiple targets
@export var max_penetrations: int = 0  # Max number of penetrations (0 = no limit)

@export_group("Effects")
@export var hit_effect_scene: PackedScene  # Effect on hit
@export var trail_effect: bool = false  # Whether to display a movement path

# Internal variables
var direction: Vector2 = Vector2.ZERO
var source_node = null  # Who fired the projectile
var spawn_position: Vector2
var spawn_rotation: float
var time_alive: float = 0.0
var has_hit: bool = false
var is_from_pool: bool = false  # Whether this projectile is from a pool
var penetration_count: int = 0  # Number of targets penetrated

# For trails/particles
var trail: Line2D = null
var particles: GPUParticles2D = null

# Signals
signal projectile_hit(projectile, target, hit_position)
signal projectile_expired(projectile)
signal projectile_bounce(projectile, collision_point, collision_normal)

func _ready():
	# Start lifetime timer
	if lifetime > 0:
		get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_expired)
	
	# Set up animation if available
	var animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite and animated_sprite.sprite_frames.has_animation("flying"):
		animated_sprite.play("flying")
	
	# Create trail if enabled
	if trail_effect:
		_setup_trail()

func _physics_process(delta):
	time_alive += delta
	
	# Apply gravity if enabled
	if gravity_affected:
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
	
	# Implementiere Raycast für schnelle Projektile, um Tunneleffekt zu vermeiden
	var start_pos = global_position
	
	# Move the projectile
	var collision = move_and_collide(velocity * delta)
	
	# Zusätzlicher Raycast für schnelle Projektile, die möglicherweise Objekte "überspringen"
	if not collision and velocity.length() > 0: # Temporary fix cause collisions not registered for unnkown reason
		var space_state = get_world_2d().direct_space_state
		var end_pos = start_pos + velocity * delta
		var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
		query.exclude = [self]  # Exclude self from collision
		
		# Set collision mask to match this object's mask
		query.collision_mask = collision_mask
		
		var result = space_state.intersect_ray(query)
		if result:
			# Manually create a collision object
			collision = KinematicCollision2D.new()
			# Unfortunately we can't fully construct a KinematicCollision2D manually,
			# so we'll handle this collision directly
			_on_raycast_collision(result)
	
	# Update trail if available
	if trail:
		trail.add_point(position)
		# Limit trail length
		while trail.get_point_count() > 20:
			trail.remove_point(0)
	
	# Process collision
	if collision and not has_hit:
		_on_collision(collision)

# Handle collisions detected by raycast
func _on_raycast_collision(result):
	var collider = result.collider
	
	# Set hit flag if not penetrating
	if not penetration:
		has_hit = true
	else:
		penetration_count += 1
		if max_penetrations > 0 and penetration_count >= max_penetrations:
			has_hit = true
	
	# Verify collider has the proper methods
	var is_player = collider.is_in_group("player") if collider.has_method("is_in_group") else false
	var is_enemy = collider.is_in_group("enemy") if collider.has_method("is_in_group") else false
	
	# Process different collision types
	if is_player and source_node != collider:
		_on_hit_player(collider, result.position)
	elif is_enemy and source_node != collider:
		_on_hit_enemy(collider, result.position)
	else:
		_on_hit_environment(collider, result.position)
	
	# If we're not penetrating or have reached the limit, recycle
	if has_hit:
		_recycle_or_free()

# Initialize the projectile with direction and start position
func setup(dir: Vector2, spawn_pos: Vector2, spawn_rot: float = 0.0, source = null):
	direction = dir.normalized()
	spawn_position = spawn_pos
	spawn_rotation = spawn_rot
	source_node = source
	
	# Set start position and rotation
	global_position = spawn_position
	global_rotation = spawn_rotation
	
	# Set velocity
	velocity = direction * speed
	
	# Reset status
	has_hit = false
	time_alive = 0.0
	penetration_count = 0
	
	return self  # For method chaining

# Create a visual trail for the projectile
func _setup_trail():
	trail = Line2D.new()
	trail.name = "Trail"
	trail.width = 3.0
	trail.default_color = Color(1, 0.7, 0.2, 0.5)  # Adjust based on projectile
	add_child(trail)

# Process collisions
func _on_collision(collision):
	var collider = collision.get_collider()
	if collider == null:
		return
	
	# Zusätzliche Prüfung auf gültige Gruppen
	var is_player = collider.is_in_group("player") if collider.has_method("is_in_group") else false
	var is_enemy = collider.is_in_group("enemy") if collider.has_method("is_in_group") else false
	
	# Check for bounce
	if bounce and not (is_player or is_enemy):
		var reflection = collision.get_remainder().bounce(collision.get_normal())
		velocity = velocity.bounce(collision.get_normal()) * bounce_factor
		global_position += reflection
		
		emit_signal("projectile_bounce", self, collision.get_position(), collision.get_normal())
		_spawn_bounce_effect(collision.get_position(), collision.get_normal())
		return
	
	# Set hit flag if not penetrating
	if not penetration:
		has_hit = true
	else:
		penetration_count += 1
		if max_penetrations > 0 and penetration_count >= max_penetrations:
			has_hit = true
	
	# Process different collision types
	if is_player and source_node != collider:
		_on_hit_player(collider, collision.get_position())
	elif is_enemy and source_node != collider:
		_on_hit_enemy(collider, collision.get_position())
	else:
		_on_hit_environment(collider, collision.get_position())
	
	# If we're not penetrating or have reached the limit, recycle
	if has_hit:
		_recycle_or_free()

# On collision with player
func _on_hit_player(player, hit_position):
	emit_signal("projectile_hit", self, player, hit_position)
	
	# Debug-Ausgabe für Schadenserkennung
	print("Projektil traf Spieler an Position: ", hit_position)
	
	# Apply damage based on Damage System if available
	var damage_system = get_node_or_null("/root/DamageSystem")
	if damage_system and source_node:
		damage_system.process_attack(source_node, player, damage * 100)  # Scaling for DamageSystem
		print("Schaden via DamageSystem: ", damage * 100)
	elif player.has_method("take_damage"):
		player.take_damage(damage * 100)  # Scaling for Player class
		print("Schaden direkt an Spieler: ", damage * 100)
	else:
		print("FEHLER: Spieler hat keine take_damage Methode!")
	
	# Update HUD if available
	var hud = get_tree().get_root().find_child("HUD", true, false)
	hud.change_life(-damage)  # Keine Skalierung - HUD erwartet bereits den richtigen Wert (0.5 für halbes Herz)
	print("HUD aktualisiert mit Schaden: ", damage)

	# Spawn hit effect if available
	_spawn_hit_effect(hit_position)

# On collision with enemy
func _on_hit_enemy(enemy, hit_position):
	emit_signal("projectile_hit", self, enemy, hit_position)
	
	# Apply damage
	var damage_system = get_node_or_null("/root/DamageSystem")
	if damage_system and source_node:
		damage_system.process_attack(source_node, enemy, damage * 100)
	elif enemy.has_method("take_damage"):
		enemy.take_damage(damage * 100)
	
	# Spawn hit effect if available
	_spawn_hit_effect(hit_position)

# On collision with environment
func _on_hit_environment(object, hit_position):
	emit_signal("projectile_hit", self, object, hit_position)
	
	# Spawn hit effect if available
	_spawn_hit_effect(hit_position)

# When lifetime expires
func _on_lifetime_expired():
	if not has_hit:
		emit_signal("projectile_expired", self)
		_recycle_or_free()

# Spawn hit effect
func _spawn_hit_effect(hit_position):
	if hit_effect_scene:
		var effect = hit_effect_scene.instantiate()
		effect.global_position = hit_position
		get_tree().current_scene.add_child(effect)
	else:
		# Fallback if no scene is set
		var sprite = get_node_or_null("AnimatedSprite2D")
		if sprite and sprite.sprite_frames.has_animation("hit"):
			# Separate physics process
			set_physics_process(false)
			
			# Stop movement
			velocity = Vector2.ZERO
			
			# Play hit animation
			sprite.play("hit")
			
			# Wait for animation to finish
			await sprite.animation_finished

# Spawn bounce effect
func _spawn_bounce_effect(hit_position, normal):
	# Just a few small particles
	var particles = CPUParticles2D.new()
	particles.position = hit_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 5
	particles.explosiveness = 1.0
	particles.direction = Vector2(-normal.x, -normal.y)
	particles.spread = 30.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 40.0
	particles.lifetime = 0.3
	get_tree().current_scene.add_child(particles)
	
	# Auto-remove after short time
	await get_tree().create_timer(0.5).timeout
	particles.queue_free()

# When spawned from an Object Pool
func _on_spawn_from_pool():
	is_from_pool = true
	visible = true
	set_physics_process(true)
	
	# Reset status
	has_hit = false
	time_alive = 0.0
	penetration_count = 0
	
	# Reset trail if available
	if trail:
		trail.clear_points()

# When returned to an Object Pool
func _on_recycle_to_pool():
	# Reset status
	has_hit = false
	time_alive = 0.0
	velocity = Vector2.ZERO
	source_node = null
	penetration_count = 0
	
	# Reset trail if available
	if trail:
		trail.clear_points()
	
	# Reset animation if needed
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite and sprite.sprite_frames.has_animation("flying"):
		sprite.play("flying")
		sprite.frame = 0

# Either recycle to pool or delete based on whether we use pooling
func _recycle_or_free():
	if is_from_pool:
		# Find the Object Pool that owns this projectile
		var pool = null
		
		# First check if our source has a projectile pool
		if source_node and source_node.has_node("ProjectilePool"):
			pool = source_node.get_node("ProjectilePool")
		
		# Otherwise look in scene root
		if not pool:
			pool = get_tree().get_root().find_child("ProjectilePool", true, false)
		
		if pool and pool is ObjectPool:
			# Return to pool
			pool.recycle(self)
		else:
			# Fallback to queue_free
			queue_free()
	else:
		# Not from pool, just delete
		queue_free()
