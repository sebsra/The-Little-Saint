class_name GoblinMage
extends BaseEnemy

## Goblin Mage - Caster enemy with teleportation and shield abilities
## Focuses on unique attributes and setup, delegates behavior to state machine

# Mage-specific attributes
@export_group("Magic Properties")
@export var projectile_scene: PackedScene = preload("res://scenes/core/projectiles/mage_ball.tscn")
@export var max_mana: float = 100.0
@export var mana_regen_rate: float = 8.0  # Mana per second
@export var spell_mana_cost: float = 20.0  # Mana cost per spell
@export var teleport_mana_cost: float = 30.0  # Mana cost for teleportation
@export var shield_mana_cost: float = 40.0  # Mana cost for shield

# Mage state tracking
var current_mana: float
var is_teleporting: bool = false
var is_shielding: bool = false
var teleport_cooldown: float = 3.0
var last_teleport_time: float = 0.0

# Projectile pool for spell casting
var projectile_pool: ObjectPool

# Signals specific to mage
signal spell_cast(spell_name)
signal mana_depleted
signal teleported
signal shield_activated
signal shield_deactivated

func _ready():
	# Call parent ready
	super._ready()
	
	# Set default values
	max_health = 60.0
	current_health = max_health
	speed = 50.0
	chase_speed = 50.0
	attack_damage = 50.0  # For consistent 0.5 heart damage
	attack_cooldown = 2.0
	detection_radius = 350.0
	attack_radius = 300.0
	patrol_distance = 80.0
	
	# Initialize mana
	current_mana = max_mana
	
	# Make sure this node is in the enemy group
	if not is_in_group("enemy"):
		add_to_group("enemy")
	
	# Connect signals
	damaged.connect(_on_damaged)
	died.connect(_on_died)
	
	# Initialize projectile pool
	_setup_projectile_pool()
	
	# Setup the state machine with mage states
	setup_state_machine()
	_setup_mage_states()

func _physics_process(delta):
	# Parent physics first
	super._physics_process(delta)
	
	# Mana regeneration
	if current_mana < max_mana:
		current_mana = min(current_mana + mana_regen_rate * delta, max_mana)
	
	# Teleport cooldown update
	if last_teleport_time > 0:
		last_teleport_time = max(0, last_teleport_time - delta)

# Initialize projectile pool
func _setup_projectile_pool():
	# Check if projectile_scene is valid
	if projectile_scene == null:
		push_error("GoblinMage: projectile_scene is null. Trying direct load...")
		projectile_scene = load("res://scenes/core/projectiles/mage_ball.tscn")
		
	if projectile_scene == null:
		push_error("GoblinMage: Could not load projectile_scene. Pool not created.")
		return
		
	# Create projectile pool for better performance
	projectile_pool = ObjectPool.new(projectile_scene, 8, true)
	projectile_pool.name = "ProjectilePool"
	add_child(projectile_pool)

# Verbesserte Einrichtung der Mage-spezifischen States
func _setup_mage_states():
	if not state_machine:
		push_error("No state machine found for " + name)
		return
	
	# KEIN Chase-State mehr! Stattdessen MagePositioningState
	state_machine.add_state(PatrolState.new())
	state_machine.add_state(MagePositioningState.new())  # Neuer State statt Chase
	state_machine.add_state(CastState.new())
	state_machine.add_state(TeleportState.new())
	state_machine.add_state(ShieldState.new())
	state_machine.add_state(HurtState.new())
	state_machine.add_state(DeathState.new())
	
	# Configure the specialized state machine behavior for mage
	_configure_state_machine()
	
	# Initialize with patrol state
	state_machine.initialize("Patrol")
	print(name + " initialized with mage state machine")

# Configure specialized transitions for mage state machine
func _configure_state_machine():
	# Connect to key state machine signals
	state_machine.player_detected.connect(_on_player_detected)
	state_machine.player_lost.connect(_on_player_lost)
	
	# Override the default attack range to ensure it works for casting
	state_machine.attack_range = attack_radius
	
	# Update the state machine to use the specialized attack state
	var machine = state_machine as EnemyStateMachine
	if machine:
		machine.attack_state_name = "Cast"

# Handle player detection specifically for mage
func _on_player_detected(player):
	if not state_machine:
		return
		
	var distance = global_position.distance_to(player.global_position)
	
	# Verbesserte Entscheidungslogik
	if distance <= attack_radius and current_mana >= spell_mana_cost:
		# Cast spell if in range and has mana
		state_machine.change_state("Cast")
	elif distance < 80:  # Too close
		# Teleport if too close
		if current_mana >= teleport_mana_cost and last_teleport_time <= 0:
			state_machine.change_state("Teleport")
		elif current_mana >= shield_mana_cost:
			# Shield if can't teleport
			state_machine.change_state("Shield")
		else:
			# Positionieren anstatt Chase
			state_machine.change_state("MagePositioning")
	else:
		# Positionieren anstatt Chase
		state_machine.change_state("MagePositioning")

# Handle player lost
func _on_player_lost():
	if state_machine:
		state_machine.change_state("Patrol")

# Cast a spell - called by Cast state
func cast_spell(spell_name: String = "fireball") -> bool:
	if is_dead or current_mana < spell_mana_cost:
		print(name + " can't cast: " + 
			("is dead" if is_dead else "not enough mana (" + str(current_mana) + "/" + str(spell_mana_cost) + ")"))
		emit_signal("mana_depleted")
		return false
	
	# Get target through state machine
	var target = state_machine.target
	if not target:
		print(name + " can't cast: no target")
		return false
	
	# Determine direction - targeting slightly ahead of player for prediction
	var target_pos = target.global_position
	if "velocity" in target and target.velocity.length() > 0:
		# Simple prediction - add a fraction of target's velocity
		target_pos += target.velocity * 0.5
	
	var direction = (target_pos - global_position).normalized()
	
	# Determine spawn position - offset in front of the mage
	var spawn_pos = global_position
	spawn_pos.y -= 8  # Slightly above the enemy
	var facing_direction = 1 if animated_sprite.flip_h else -1
	spawn_pos.x += facing_direction * 20  # Offset in facing direction
	
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
	
	# Make sure projectile is visible and active
	projectile.visible = true
	if "process_mode" in projectile:
		projectile.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Move to correct position before setup
	projectile.global_position = spawn_pos
	
	# Configure projectile
	if projectile.has_method("setup"):
		projectile.setup(direction, spawn_pos, 0, self)
	else:
		# Direct property setting as fallback
		if "direction" in projectile:
			projectile.direction = direction
		if "velocity" in projectile:
			projectile.velocity = direction * (projectile.speed if "speed" in projectile else 200.0)
		if "source_node" in projectile:
			projectile.source_node = self
		
		# For mage ball specific properties
		if projectile is MageBall:
			if "homing_strength" in projectile:
				projectile.homing_strength = 0.3  # Enable slight homing for magic
	
	# Make sure the projectile is in the scene tree
	if not projectile.is_inside_tree():
		get_tree().current_scene.add_child.call_deferred(projectile)
	
	# Visual and audio feedback
	_show_cast_effect(spawn_pos)
	
	# Reduce mana and emit signal
	current_mana -= spell_mana_cost
	emit_signal("spell_cast", spell_name)
	
	print(name + " successfully cast " + spell_name + ", remaining mana: " + str(current_mana))
	return true
# Teleport to a new position - called by Teleport state
func teleport() -> bool:
	if is_dead or current_mana < teleport_mana_cost or last_teleport_time > 0:
		print(name + " can't teleport: " + 
			("is dead" if is_dead else 
			"not enough mana" if current_mana < teleport_mana_cost else
			"on cooldown"))
		return false
	
	is_teleporting = true
	
	# Find target position
	var teleport_pos = _find_teleport_position()
	
	# Fade-out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	
	# Wait for tween to finish
	await tween.finished
	
	# Teleport
	global_position = teleport_pos
	
	# Fade-in effect
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	# Reduce mana
	current_mana -= teleport_mana_cost
	
	# Set cooldown
	last_teleport_time = teleport_cooldown
	
	# Signal
	emit_signal("teleported")
	
	is_teleporting = false
	print(name + " teleported to " + str(teleport_pos))
	
	# Überarbeitete State-Übergänge nach Teleport
	if state_machine.target:
		var distance = global_position.distance_to(state_machine.target.global_position)
		if distance <= attack_radius and current_mana >= spell_mana_cost:
			state_machine.change_state("Cast")
		else:
			state_machine.change_state("MagePositioning")
			
	return true

# Find a good teleport position
func _find_teleport_position() -> Vector2:
	var target = state_machine.target
	var possible_positions = []
	
	# If no target, teleport randomly around current position
	if not target:
		for i in range(4):
			var angle = randf() * 2 * PI
			var distance = randf_range(80, 120)
			possible_positions.append(global_position + Vector2(cos(angle), sin(angle)) * distance)
	else:
		# Teleport to positions with optimal distance from player
		for i in range(4):
			var angle = randf() * 2 * PI
			var distance = randf_range(120, 180)  # Vergrößerte Teleport-Distanz
			possible_positions.append(target.global_position + Vector2(cos(angle), sin(angle)) * distance)
	
	# Choose random position
	return possible_positions[randi() % possible_positions.size()]

# Activate magic shield - called by Shield state
func activate_shield() -> bool:
	if is_dead or current_mana < shield_mana_cost or is_shielding:
		print(name + " can't activate shield: " + 
			("is dead" if is_dead else 
			"not enough mana" if current_mana < shield_mana_cost else
			"shield already active"))
		return false
	
	is_shielding = true
	
	# Create shield effect
	var shield = Node2D.new()
	shield.name = "MagicShield"
	add_child(shield)
	
	# Create shield sprite
	var shield_sprite = Sprite2D.new()
	shield_sprite.texture = load("res://icon.png")  # Replace with actual shield texture
	shield_sprite.scale = Vector2(1.5, 1.5)
	shield_sprite.modulate = Color(0.3, 0.7, 1.0, 0.5)
	shield.add_child(shield_sprite)
	
	# Reduce mana
	current_mana -= shield_mana_cost
	
	# Signal
	emit_signal("shield_activated")
	
	# Make enemy temporarily invulnerable
	is_invulnerable = true
	
	print(name + " activated shield")
	return true

# Deactivate shield
func deactivate_shield():
	if not is_shielding:
		return
	
	is_shielding = false
	
	# Remove shield node
	if has_node("MagicShield"):
		$MagicShield.queue_free()
	
	# Disable invulnerability
	is_invulnerable = false
	
	# Signal
	emit_signal("shield_deactivated")
	print(name + " deactivated shield")

# Show cast effect
func _show_cast_effect(position):
	# Create spell circle effect
	var effect = CPUParticles2D.new()
	effect.position = position - global_position  # Relative to mage position
	effect.emitting = true
	effect.one_shot = true
	effect.explosiveness = 0.8
	effect.amount = 16
	effect.lifetime = 0.5
	effect.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	effect.emission_sphere_radius = 5.0
	effect.color = Color(0.5, 0.1, 0.9, 0.8)
	add_child(effect)
	
	# Remove after lifetime
	get_tree().create_timer(effect.lifetime * 1.5).timeout.connect(func():
		effect.queue_free()
	)

# Override damage to check for shield
func _on_damaged(amount, attacker):
	# If shield active, absorb damage and continue
	if is_shielding:
		return
	
	# Low health behavior
	if current_health < max_health * 0.3:
		# Try to teleport away if hurt badly
		if current_mana >= teleport_mana_cost and last_teleport_time <= 0:
			state_machine.change_state("Teleport")
		# Or activate shield
		elif current_mana >= shield_mana_cost and not is_shielding:
			state_machine.change_state("Shield")

# Handle death
func _on_died():
	_drop_loot()
	_create_death_explosion()

# Create death explosion effect
func _create_death_explosion():
	# Create particle explosion
	var explosion = CPUParticles2D.new()
	explosion.position = global_position
	explosion.emitting = true
	explosion.one_shot = true
	explosion.explosiveness = 1.0
	explosion.amount = 32
	explosion.lifetime = 0.8
	explosion.spread = 180.0
	explosion.initial_velocity_min = 50.0
	explosion.initial_velocity_max = 100.0
	explosion.color = Color(0.8, 0.2, 0.9, 0.8)
	get_tree().current_scene.add_child(explosion)
	
	# Remove after animation
	get_tree().create_timer(explosion.lifetime * 1.5).timeout.connect(func():
		explosion.queue_free()
	)

# Drop random loot
func _drop_loot():
	# Loot table
	var loot_table = [
		{"item": "res://scenes/core/items/coins.tscn", "chance": 0.7},
		{"item": "res://scenes/core/items/elixir.tscn", "chance": 0.3},
		{"item": "res://scenes/core/items/power_fly.tscn", "chance": 0.1}
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
