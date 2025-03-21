class_name ChaseBehavior
extends Node

## A modular component for enemy chase behavior

# Reference to the character this behavior belongs to
var character = null
# The target being chased
var target = null
# Speed while chasing
@export var chase_speed: float = 100.0
# Maximum chase distance before giving up
@export var max_chase_distance: float = 300.0
# Minimum distance to maintain from target
@export var min_distance: float = 10.0
# Whether to use prediction for moving targets
@export var use_prediction: bool = false
# How far ahead to predict target movement (0-1)
@export var prediction_factor: float = 0.5
# Whether to check for line of sight
@export var check_line_of_sight: bool = true
# Collision layer to check for line of sight (walls, obstacles)
@export_flags_2d_physics var line_of_sight_mask: int = 1
# Animation to play while chasing
@export var chase_animation: String = "walk"
# Path to the animated sprite (if not direct child)
@export var animated_sprite_path: String = "AnimatedSprite2D"
# Whether the chase is currently active
@export var is_active: bool = false

# Last known position of the target
var last_known_position: Vector2 = Vector2.ZERO
# Direction to the target
var chase_direction: Vector2 = Vector2.ZERO
# Time spent chasing without line of sight
var lost_sight_time: float = 0.0
# Maximum time to chase without line of sight
@export var max_lost_sight_time: float = 2.0

# Signals
signal chase_started(target)
signal chase_ended()
signal chase_target_reached(target)
signal target_lost()
signal line_of_sight_lost()
signal line_of_sight_regained()

func _ready():
	# Get the owner character (parent node)
	character = get_parent()

func _physics_process(delta):
	if not is_active or not target:
		return
	
	if not is_instance_valid(target):
		end_chase()
		return
	
	# Get positions
	var character_pos = character.global_position
	var target_pos = target.global_position
	
	# Check max chase distance
	var distance_to_target = character_pos.distance_to(target_pos)
	if distance_to_target > max_chase_distance:
		emit_signal("target_lost")
		end_chase()
		return
	
	# Check line of sight if needed
	var has_line_of_sight = true
	if check_line_of_sight:
		has_line_of_sight = _check_line_of_sight(target)
		
		if not has_line_of_sight:
			lost_sight_time += delta
			if lost_sight_time > max_lost_sight_time:
				emit_signal("target_lost")
				end_chase()
				return
		else:
			if lost_sight_time > 0:
				emit_signal("line_of_sight_regained")
			lost_sight_time = 0
			last_known_position = target_pos
	
	# Calculate target position (with prediction if enabled)
	var chase_target_pos = target_pos
	if use_prediction and "velocity" in target and target.velocity.length() > 0:
		chase_target_pos += target.velocity * prediction_factor
	
	# Calculate direction and distance
	chase_direction = (chase_target_pos - character_pos).normalized()
	
	# Check if we've reached minimum distance
	if distance_to_target <= min_distance:
		emit_signal("chase_target_reached", target)
		if "velocity" in character:
			character.velocity.x = 0
		return
	
	# Apply movement
	if "velocity" in character:
		character.velocity.x = chase_direction.x * chase_speed
	
	# Update animation and facing
	_update_animation(chase_direction)

## Start chasing a target
func start_chase(new_target) -> bool:
	if not new_target:
		return false
	
	target = new_target
	is_active = true
	lost_sight_time = 0
	last_known_position = target.global_position
	
	emit_signal("chase_started", target)
	return true

## End the current chase
func end_chase():
	if is_active:
		emit_signal("chase_ended")
	
	is_active = false
	target = null
	lost_sight_time = 0
	
	# Stop movement
	if "velocity" in character:
		character.velocity.x = 0

## Check if the character has line of sight to the target
func _check_line_of_sight(check_target) -> bool:
	if not check_target:
		return false
	
	var space_state = character.get_world_2d().direct_space_state
	var params = PhysicsRayQueryParameters2D.new()
	params.from = character.global_position
	params.to = check_target.global_position
	params.collision_mask = line_of_sight_mask
	params.exclude = [character]
	
	var result = space_state.intersect_ray(params)
	
	if result and result.collider != check_target:
		if lost_sight_time == 0:
			emit_signal("line_of_sight_lost")
		return false
	return true

## Get the current distance to the target
func get_distance_to_target() -> float:
	if not target:
		return INF
	return character.global_position.distance_to(target.global_position)

## Update character animation and direction based on movement
func _update_animation(direction: Vector2):
	# Play chase animation
	if character.has_method("play_animation"):
		character.play_animation(chase_animation)
	
	# Handle sprite flipping
	var sprite = character.get_node_or_null(animated_sprite_path)
	if sprite and "flip_h" in sprite:
		sprite.flip_h = direction.x < 0
