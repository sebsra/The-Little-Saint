class_name PatrolBehavior
extends Node

## A modular component for enemy patrol behavior

# Patrol modes
enum PatrolMode {
	BACK_AND_FORTH,  # Move between start and end points
	LOOP,            # Move in a loop through all points
	RANDOM           # Choose random points to patrol to
}

# Patrol points - Vector2 positions for the patrol path
@export var patrol_points: Array[Vector2] = []
# Current patrol mode
@export var mode: PatrolMode = PatrolMode.BACK_AND_FORTH
# Speed while patrolling
@export var patrol_speed: float = 60.0
# Wait time at each patrol point (seconds)
@export var wait_time: float = 1.0
# Whether to use global coordinates or local coordinates
@export var use_global_coordinates: bool = true
# Whether the enemy should flip when changing direction
@export var flip_on_direction_change: bool = true
# Flip method (sprite or node)
@export var flip_method: String = "sprite" # "sprite" or "node"
# Whether patrol is currently active
@export var is_active: bool = true

# Reference to the owner character
var character = null
# Current target patrol point index
var current_point_index: int = 0
# Direction of travel for back-and-forth mode (1 = forwards, -1 = backwards)
var travel_direction: int = 1
# Whether we're currently waiting at a patrol point
var is_waiting: bool = false
# Wait timer
var wait_timer: float = 0.0
# Path to the animated sprite (if not direct child)
@export var animated_sprite_path: String = "AnimatedSprite2D"
# Animation to play while patrolling
@export var patrol_animation: String = "walk"

# Signals
signal point_reached(point_index)
signal patrol_completed()
signal direction_changed(new_direction)

func _ready():
	# Get the owner character (parent node)
	character = get_parent()
	
	# Initialize with first patrol point if available
	if patrol_points.size() > 0:
		current_point_index = 0
	else:
		# Add the character's current position as the first patrol point
		if use_global_coordinates:
			patrol_points.append(character.global_position)
		else:
			patrol_points.append(character.position)

func _physics_process(delta):
	if not is_active or patrol_points.size() < 2:
		return
	
	if is_waiting:
		# Handle waiting at patrol points
		wait_timer -= delta
		if wait_timer <= 0:
			is_waiting = false
			_move_to_next_point()
		return
	
	# Get current target point
	var target_position = patrol_points[current_point_index]
	if use_global_coordinates:
		target_position = target_position
	
	# Get current position
	var current_position = character.global_position if use_global_coordinates else character.position
	
	# Check if we've reached the target point
	var distance_to_target = current_position.distance_to(target_position)
	if distance_to_target < 10.0:  # Within 10 pixels considered as "reached"
		_on_point_reached()
		return
	
	# Move towards the target point
	var direction = (target_position - current_position).normalized()
	
	# Apply movement
	if "velocity" in character:
		character.velocity.x = direction.x * patrol_speed
	
	# Handle animation and flipping
	_update_animation(direction)

## Start patrolling
func start():
	is_active = true
	is_waiting = false

## Stop patrolling
func stop():
	is_active = false
	if "velocity" in character:
		character.velocity.x = 0

## Add a new patrol point
func add_patrol_point(point: Vector2):
	patrol_points.append(point)

## Clear all patrol points
func clear_patrol_points():
	patrol_points.clear()
	current_point_index = 0

## Set new patrol points
func set_patrol_points(points: Array[Vector2]):
	patrol_points = points
	current_point_index = 0

## Set the patrol mode
func set_patrol_mode(new_mode: PatrolMode):
	mode = new_mode
	
## Get the current patrol target position
func get_current_target() -> Vector2:
	if patrol_points.size() > current_point_index:
		return patrol_points[current_point_index]
	return Vector2.ZERO

## Called when a patrol point is reached
func _on_point_reached():
	emit_signal("point_reached", current_point_index)
	
	# Start waiting
	is_waiting = true
	wait_timer = wait_time
	
	# Stop horizontal movement
	if "velocity" in character:
		character.velocity.x = 0

## Move to the next patrol point based on the patrol mode
func _move_to_next_point():
	match mode:
		PatrolMode.BACK_AND_FORTH:
			# Change direction at endpoints
			if current_point_index == patrol_points.size() - 1:
				travel_direction = -1
				emit_signal("direction_changed", travel_direction)
			elif current_point_index == 0:
				travel_direction = 1
				emit_signal("direction_changed", travel_direction)
			
			current_point_index += travel_direction
			
		PatrolMode.LOOP:
			# Move to next point, wrap around to beginning
			current_point_index = (current_point_index + 1) % patrol_points.size()
			
			if current_point_index == 0:
				emit_signal("patrol_completed")
				
		PatrolMode.RANDOM:
			# Choose a random point different from the current one
			var new_index = current_point_index
			while new_index == current_point_index and patrol_points.size() > 1:
				new_index = randi() % patrol_points.size()
			current_point_index = new_index

## Update character animation and direction based on movement
func _update_animation(direction: Vector2):
	# Play patrol animation
	if character.has_method("play_animation"):
		character.play_animation(patrol_animation)
	
	# Handle flipping
	if flip_on_direction_change:
		var sprite = null
		
		if flip_method == "sprite":
			sprite = character.get_node_or_null(animated_sprite_path)
			if sprite and "flip_h" in sprite:
				sprite.flip_h = direction.x < 0
		elif flip_method == "node":
			# Flip the entire character node
			character.scale.x = abs(character.scale.x) * sign(direction.x)
