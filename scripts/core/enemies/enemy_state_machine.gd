class_name EnemyStateMachine
extends StateMachine

## Eine verbesserte State Machine speziell für Gegner
## Verbesserte Version mit besserer Target-Erkennung und Zustandsübergängen

# Signals for key events
signal player_detected(player)
signal player_lost()
signal action_completed(action_name)

# Enemy sensing properties - used by all states
var detection_range: float = 200.0
var attack_range: float = 50.0
var patrol_range: float = 100.0
var can_see_through_walls: bool = false

# Current target
var target = null

# Original position for patrols
var initial_position: Vector2

# Target tracking properties
var target_visible_time: float = 0.0
var target_lost_time: float = 0.0
var minimum_detection_time: float = 0.1  # Time to confirm detection
var maximum_lost_time: float = 0.5  # Time before target is considered lost

# Enemy type-specific attributes
var attack_state_name: String = "Attack"  # Default, will be overridden by specialized enemies
var use_specialized_states: bool = false
var specialized_enemy_type: String = "Generic"

# Verbessertes Targeting
var last_known_position: Vector2
var prediction_enabled: bool = true  # Bewegungsvorhersage für Fernkampf
var memory_duration: float = 3.0  # Wie lange der Gegner sich die letzte Position merkt

func _ready():
	super._ready()
	
	# Set initial position for patrol patterns
	initial_position = owner_node.global_position
	last_known_position = initial_position
	
	# Update range values from the owner
	_update_ranges_from_owner()
	
	# Connect to owner signals
	if owner_node is BaseEnemy:
		owner_node.damaged.connect(_on_owner_damaged)
		owner_node.died.connect(_on_owner_died)
	
	# Check for specialized enemy types and set appropriate attack state
	_detect_specialized_enemy_type()
	
	# Enable debug mode in development builds only
	debug_mode = OS.has_feature("debug")
	print("EnemyStateMachine initialized for: " + owner_node.name + " with type: " + specialized_enemy_type)

func _physics_process(delta):
	super._physics_process(delta)
	
	# Check for target consistently
	_update_target_detection(delta)

# Transfer configuration from owner to state machine
func _update_ranges_from_owner():
	var enemy = owner_node as BaseEnemy
	if enemy:
		detection_range = enemy.detection_radius
		attack_range = enemy.attack_radius
		patrol_range = enemy.patrol_distance

# Detect what kind of enemy we're attached to and configure accordingly
func _detect_specialized_enemy_type():
	if owner_node is GoblinArcher:
		specialized_enemy_type = "Archer"
		attack_state_name = "Shoot"
		use_specialized_states = true
		# Bogenschützen haben bessere Vorhersage
		prediction_enabled = true
		memory_duration = 4.0
	elif owner_node is GoblinMage:
		specialized_enemy_type = "Mage"
		attack_state_name = "Cast"
		use_specialized_states = true
		# Magier haben längere Erinnerung
		memory_duration = 5.0
	elif owner_node is GoblinMelee:
		specialized_enemy_type = "Melee"
		attack_state_name = "Attack"  # Standard attack for melee
		use_specialized_states = true
		# Nahkämpfer haben kürzere Erinnerung
		memory_duration = 2.0
		
	print("Detected enemy type: " + specialized_enemy_type + " with attack state: " + attack_state_name)

# Initialize the state machine with the starting state
func initialize(initial_state_name: String = ""):
	# Default to first state if none specified
	if initial_state_name.is_empty() and states.size() > 0:
		initial_state_name = states.keys()[0]
	# Change to initial state
	if states.has(initial_state_name):
		change_state(initial_state_name)
	else:
		push_error("State machine could not initialize with state: " + initial_state_name)

# A more reliable target detection system
func _update_target_detection(delta):
	var player = _find_player()
	var can_see_player = false
	
	if player:
		# Check distance
		var distance = owner_node.global_position.distance_to(player.global_position)
		
		if distance <= detection_range:
			# Line of sight check
			if can_see_through_walls or _has_line_of_sight(player):
				can_see_player = true
				
				# Tracking for consistent detection
				target_visible_time += delta
				target_lost_time = 0
				
				# Confirm detection after minimum time
				if target_visible_time >= minimum_detection_time:
					if target != player:
						print(owner_node.name + " detected player at distance " + str(distance))
						set_target(player)
					
					# Aktualisiere zuletzt bekannte Position
					last_known_position = player.global_position
			else:
				can_see_player = false
		else:
			can_see_player = false
	
	# Handle losing sight of target
	if !can_see_player and target:
		target_visible_time = 0
		target_lost_time += delta
		
		# Clear target after max lost time
		if target_lost_time >= maximum_lost_time:
			# Verbessertes Verhalten: Je nach Gegnertyp unterschiedliche Reaktionen
			if specialized_enemy_type == "Archer":
				# Archer behält Target länger für Schüsse auf letzte bekannte Position
				if target_lost_time >= maximum_lost_time * 2.0:
					clear_target()
			elif specialized_enemy_type == "Mage":
				# Mage hat ähnliches Verhalten wie Archer aber mit anderen Timing
				if target_lost_time >= maximum_lost_time * 1.5:
					clear_target()
			else:
				# Standard-Verhalten: Clear target after max lost time
				clear_target()

# Find player in the scene
func _find_player() -> Node:
	# First check the Global singleton for player reference
	if get_node_or_null("/root/Global") and get_node("/root/Global").has_method("get_player"):
		return get_node("/root/Global").get_player()
	
	# Alternative: check for player in groups
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# Last resort - search by name
		player = get_tree().get_root().find_child("Player", true, false)
	
	return player

# Check if there's a clear line of sight to the target
func _has_line_of_sight(to_node: Node) -> bool:
	if not is_instance_valid(to_node):
		return false
		
	# Setup raycast
	var space_state = owner_node.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		owner_node.global_position, 
		to_node.global_position,
		1, # Collision layer for obstacles 
		[owner_node] # Exclude self from collision check
	)
	
	var result = space_state.intersect_ray(query)
	
	# If nothing hit or hit the target, we have line of sight
	return !result or result.collider == to_node

# Set current target and notify states
func set_target(new_target):
	if new_target == target:
		return
		
	var had_no_target = (target == null)
	target = new_target
	
	if new_target and had_no_target:
		emit_signal("player_detected", new_target)
		
		# Force state change based on distance if in Patrol state
		if current_state and current_state.name == "Patrol":
			if is_target_in_attack_range():
				change_state(attack_state_name)  # Use appropriate attack state based on enemy type
			elif specialized_enemy_type == "Archer":
				change_state("Positioning")  # Archer goes to positioning
			elif specialized_enemy_type == "Mage":
				change_state("MagePositioning")  # Mage goes to positioning
			else:
				# Nahkämpfer verhalten sich wie bisher
				change_state("Chase")

# Clear current target
func clear_target():
	if target:
		print(owner_node.name + " lost sight of player")
		emit_signal("player_lost")
		
		# Return to patrol if we're in a state that needs a target
		if current_state:
			if specialized_enemy_type == "Archer":
				if current_state.name in ["Shoot", "Positioning", "Retreat"]:
					change_state("Patrol")
			elif specialized_enemy_type == "Mage":
				if current_state.name in ["Cast", "MagePositioning"]:
					change_state("Patrol")
			else:
				if current_state.name in ["Chase", "Attack"]:
					change_state("Patrol")
	
	target = null

# Is target within attack range?
func is_target_in_attack_range() -> bool:
	if not target:
		return false
	
	var distance = owner_node.global_position.distance_to(target.global_position)
	return distance <= attack_range

# Direction to current target
func get_direction_to_target() -> Vector2:
	if not target:
		return Vector2.ZERO
	
	return (target.global_position - owner_node.global_position).normalized()

# Direction to last known position
func get_direction_to_last_known_position() -> Vector2:
	return (last_known_position - owner_node.global_position).normalized()

# Handle owner taking damage
func _on_owner_damaged(amount, attacker):
	# Transition to hurt state if not dead
	if current_state and current_state.name != "Death" and current_state.name != "Hurt":
		change_state("Hurt")

# Handle owner death
func _on_owner_died():
	# Transition to death state
	change_state("Death")
