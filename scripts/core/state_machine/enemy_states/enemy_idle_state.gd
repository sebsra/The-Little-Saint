class_name EnemyIdleState
extends State

## Enemy idle state - when the enemy is standing still

@export var idle_animation: String = "idle"
@export var idle_min_time: float = 1.0
@export var idle_max_time: float = 3.0

var idle_timer: float = 0.0
var idle_duration: float = 0.0
var target = null

func enter():
	# Play idle animation
	play_animation(idle_animation)
	
	# Reset horizontal velocity
	var velocity = get_velocity()
	velocity.x = 0
	set_velocity(velocity)
	
	# Set random idle duration
	idle_duration = randf_range(idle_min_time, idle_max_time)
	idle_timer = 0.0

func physics_process(delta: float):
	# Apply gravity
	var velocity = get_velocity()
	var gravity = owner_node.get_gravity() if owner_node.has_method("get_gravity") else 980.0
	
	velocity.y += gravity * delta
	set_velocity(velocity)
	
	# Handle movement for character body
	if owner_node.has_method("move_and_slide"):
		owner_node.move_and_slide()
	
	# Update idle timer
	idle_timer += delta

func get_next_state() -> String:
	# Check if there's a player in detection range
	target = get_owner_property("target")
	if target != null:
		return "Chase"
	
	# Check if idle time has elapsed - transition to patrol
	if idle_timer >= idle_duration:
		return "Patrol"
	
	# No transition, stay in idle
	return ""

# Used by enemies to find nearby player
func check_for_player():
	var detection_radius = get_owner_property("detection_radius")
	if not detection_radius:
		return null
		
	var space_state = owner_node.get_world_2d().direct_space_state
	var player_detection_shape = CircleShape2D.new()
	player_detection_shape.radius = detection_radius
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.set_shape(player_detection_shape)
	query.transform = Transform2D(0, owner_node.global_position)
	query.collision_mask = 1  # Player layer
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var collider = result.collider
		if collider.name == "Player":
			return collider
	
	return null