class_name GoblinArcher
extends BaseEnemy

## Goblin Archer - Ranged enemy that shoots arrows/stones at the player
## Maintains distance and reloads after a certain number of shots

# Archer-specific attributes
@export_group("Archer Properties")
@export var projectile_scene: PackedScene = preload("res://scenes/core/projectiles/rock.tscn")
@export var quiver_size: int = 5  # Number of arrows before reload
@export var reload_time: float = 2.0  # Time to reload in seconds
@export var shooting_accuracy: float = 0.9  # 1.0 = perfect, lower = less accurate
@export var optimal_distance: float = 150.0  # Optimal distance to player

# Archer state tracking
var arrows_remaining: int
var is_reloading: bool = false

# Projectile pool for arrows
var projectile_pool: ObjectPool

# Signals specific to archer
signal arrow_shot
signal quiver_empty
signal reload_complete

func _ready():
	# Call parent ready
	super._ready()
	
	# Set default values
	max_health = 70.0
	current_health = max_health
	speed = 60.0  # Etwas schneller für bessere Positionierung
	chase_speed = 60.0
	attack_damage = 50.0  # Ensuring this gives 0.5 damage after scaling
	attack_cooldown = 1.0
	detection_radius = 350.0
	attack_radius = 300.0
	
	# Initialize arrows
	arrows_remaining = quiver_size
	
	# Connect signals
	damaged.connect(_on_damaged)
	died.connect(_on_died)
	
	# Make sure this node is in the enemy group
	if not is_in_group("enemy"):
		add_to_group("enemy")
	
	# Initialize projectile pool
	_setup_projectile_pool()
	
	# Setup the state machine with archer states
	setup_state_machine()
	_setup_archer_states()

# Initialize projectile pool
func _setup_projectile_pool():
	# Check if projectile_scene is valid
	if projectile_scene == null:
		push_error("GoblinArcher: projectile_scene is null. Trying direct load...")
		projectile_scene = load("res://scenes/core/projectiles/rock.tscn")
		
	if projectile_scene == null:
		push_error("GoblinArcher: Could not load projectile_scene. Pool not created.")
		return
		
	# Create projectile pool for better performance
	projectile_pool = ObjectPool.new(projectile_scene, 10, true)
	projectile_pool.name = "ProjectilePool"
	add_child(projectile_pool)

# Improved setup for archer-specific states
func _setup_archer_states():
	# Add all states to the state machine - KEINE CHASE STATE!
	state_machine.add_state(PatrolState.new())
	state_machine.add_state(PositioningState.new())  # Neuer Positionierungsstate statt Chase
	state_machine.add_state(ShootState.new())
	state_machine.add_state(RetreatState.new())
	state_machine.add_state(ReloadState.new())
	state_machine.add_state(HurtState.new())
	state_machine.add_state(DeathState.new())
	
	# Configure the specialized state machine behavior for archer
	_configure_state_machine()
	
	# Initialize with patrol state
	state_machine.initialize("Patrol")
	print(name + " initialized with archer state machine")

# Configure specialized transitions for archer state machine
func _configure_state_machine():
	# Connect to key state machine signals
	state_machine.player_detected.connect(_on_player_detected)
	state_machine.player_lost.connect(_on_player_lost)
	
	# Override the default attack range to ensure it works for shooting
	state_machine.attack_range = attack_radius
	
	# Update the state machine to use the specialized attack state
	var machine = state_machine as EnemyStateMachine
	if machine:
		machine.attack_state_name = "Shoot"

# Handle player detection specifically for archer
func _on_player_detected(player):
	if not state_machine:
		return
		
	var distance = global_position.distance_to(player.global_position)
	
	# Logische Entscheidung basierend auf der Situation
	if distance <= attack_radius and arrows_remaining > 0:
		state_machine.change_state("Shoot")
	elif distance < optimal_distance * 0.7:  # Too close
		state_machine.change_state("Retreat")
	else:
		# Anstatt Chase verwenden wir nun Positioning
		state_machine.change_state("Positioning")

# Handle player lost
func _on_player_lost():
	if state_machine:
		state_machine.change_state("Patrol")

# Shoot a projectile - called by Shoot state
func shoot() -> bool:
	if is_dead or is_reloading or arrows_remaining <= 0:
		print(name + " can't shoot: " + 
			("is dead" if is_dead else 
			"is reloading" if is_reloading else 
			"no arrows left"))
		emit_signal("quiver_empty")
		return false
	
	# Get target through state machine
	var target = state_machine.target
	if not target:
		print(name + " can't shoot: no target")
		return false
	
	# Determine direction with accuracy variation
	var direction = (target.global_position - global_position).normalized()
	if shooting_accuracy < 1.0:
		# Add random deviation
		var deviation = (1.0 - shooting_accuracy) * 0.2  # Max 20% deviation
		direction = direction.rotated(randf_range(-deviation, deviation))
	
	# Determine spawn position - slightly offset in front of the enemy
	var spawn_pos = global_position
	spawn_pos.y -= 5  # Slightly above the enemy
	var facing_direction = 1 if animated_sprite.flip_h else -1
	spawn_pos.x += facing_direction * 15  # Offset in facing direction
	
	# Get projectile from pool or create a new one
	var projectile = null
	if projectile_pool:
		projectile = projectile_pool.get_object()
	
	# If no projectile from pool, instantiate directly
	if projectile == null:
		if projectile_scene:
			projectile = projectile_scene.instantiate()
			get_tree().current_scene.add_child(projectile)
		else:
			print(name + " ERROR: Could not create projectile!")
			return false
	
	# Stelle sicher, dass das Projektil ordnungsgemäß aus dem Pool zurückgesetzt wurde
	projectile.set_physics_process(true)
	
	# Configure projectile - Make sure it's visible and active first
	projectile.visible = true
	if "process_mode" in projectile:
		projectile.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Move to correct position before setting up
	projectile.global_position = spawn_pos
	
	# Configure using setup method if available
	if projectile.has_method("setup"):
		projectile.setup(direction, spawn_pos, 0, self)
		
		# Stelle sicher, dass die Geschwindigkeit korrekt ist
		if "speed" in projectile:
			projectile.velocity = direction * projectile.speed
	else:
		# Direct property setting as fallback
		if "direction" in projectile:
			projectile.direction = direction
		if "velocity" in projectile:
			projectile.velocity = direction * (projectile.speed if "speed" in projectile else 200.0)
		if "source_node" in projectile:
			projectile.source_node = self
	
	# Make sure the projectile is in the scene tree
	if not projectile.is_inside_tree():
		get_tree().current_scene.add_child.call_deferred(projectile)
	
	# Visual and audio feedback
	_play_shoot_effects(spawn_pos)
	
	# Reduce arrows and emit signal
	arrows_remaining -= 1
	emit_signal("arrow_shot")
	
	# Start reloading if no arrows left
	if arrows_remaining <= 0:
		start_reloading()
	
	print(name + " successfully shot a projectile with speed: " + str(projectile.velocity.length()))
	return true

# Add visual/audio effects for shooting
func _play_shoot_effects(position):
	# Small particle burst
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 5
	particles.lifetime = 0.3
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 40.0
	particles.color = Color(0.7, 0.7, 0.5, 0.7)  # Dust color
	
	get_tree().current_scene.add_child(particles)
	particles.global_position = position
	
	# Remove after lifetime
	await get_tree().create_timer(particles.lifetime * 1.5).timeout
	if is_instance_valid(particles):
		particles.queue_free()
		
# Start reloading process
func start_reloading():
	if is_reloading:
		return
		
	is_reloading = true
	
	# Play reload animation if available
	if animated_sprite and animated_sprite.sprite_frames.has_animation("reload"):
		animated_sprite.play("reload")
	else:
		play_animation("idle")
	
	# Emit signal
	emit_signal("quiver_empty")
	print(name + " started reloading...")
	
	# Create timer to finish reloading
	get_tree().create_timer(reload_time).timeout.connect(_reload_complete)

# Reloading completed
func _reload_complete():
	is_reloading = false
	arrows_remaining = quiver_size
	
	# Emit signal
	emit_signal("reload_complete")
	print(name + " reloading complete, arrows: " + str(arrows_remaining))
	
	# Nach dem Nachladen Entscheidung für nächsten State
	if state_machine.target:
		var distance = global_position.distance_to(state_machine.target.global_position)
		
		if distance <= attack_radius:
			state_machine.change_state("Shoot")
		elif distance < optimal_distance * 0.7:
			state_machine.change_state("Retreat") 
		else:
			state_machine.change_state("Positioning")

# Handle damage
func _on_damaged(amount, attacker):
	# Archers might want to retreat when damaged
	if state_machine and state_machine.target and randf() > 0.3:  # 70% chance to retreat when hit
		state_machine.change_state("Retreat")

# Handle death
func _on_died():
	_drop_loot()

# Drop random loot
func _drop_loot():
	# Loot table
	var loot_table = [
		{"item": "res://scenes/core/items/coins.tscn", "chance": 0.8},
		{"item": "res://scenes/core/items/power_jump.tscn", "chance": 0.2}
	]
	
	randomize()
	
	for loot in loot_table:
		if randf() <= loot.chance:
			var item_scene = load(loot.item)
			if item_scene:
				var item = item_scene.instantiate()
				item.global_position = global_position
				get_tree().current_scene.add_child(item)
				break
