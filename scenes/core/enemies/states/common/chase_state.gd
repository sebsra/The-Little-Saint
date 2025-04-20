class_name ChaseState
extends EnemyState

# Jump settings
var jump_strength: float = -550.0
var jump_cooldown: float = 1.5
var can_jump: bool = true
var jump_timer: float = 0.0
var height_threshold: float = 50.0

# Direction control
var flip_deadzone: float = 15.0  # Minimum distance to change direction
var last_direction: int = 0      # Track last direction

func _init():
	name = "Chase"
	
func enter():
	super.enter()
	play_animation("walk")
	can_jump = true
	jump_timer = 0.0
	# Initialize direction
	last_direction = 0
	print(enemy.name + " entered chase state")

func physics_process(delta: float):
	# Update target
	update_target()
	
	if not target:
		# Set new patrol points before transitioning to patrol
		update_patrol_points()
		enemy.velocity.x = 0
		return
	
	# Direction to player
	var direction = target.global_position.x - enemy.global_position.x
	var normalized_dir = sign(direction)
	
	# Update jump cooldown
	if not can_jump:
		jump_timer += delta
		if jump_timer >= jump_cooldown:
			can_jump = true
			jump_timer = 0.0
	
	# Apply deadzone to prevent rapid flipping
	if abs(direction) <= flip_deadzone:
		# Too close to player - maintain previous direction for movement
		# but don't change sprite direction
		if last_direction != 0:
			normalized_dir = last_direction
	else:
		# We're far enough away, update the last direction
		last_direction = normalized_dir
	
	# Set velocity using chase speed
	enemy.velocity.x = normalized_dir * enemy.chase_speed
	
	# Check if we should jump - improved conditions
	if can_jump and enemy.is_on_floor():
		var height_diff = enemy.global_position.y - target.global_position.y
		
		# Only jump if:
		# 1. Target is above us (negative height diff)
		# 2. Target is not falling (check if target is on floor)
		# 3. We're within a reasonable horizontal distance to make the jump useful
		if height_diff < -height_threshold and is_target_on_platform() and abs(direction) < 150:
			perform_jump()
		
		# Jump over obstacles in our path
		elif abs(direction) > 20 and enemy.velocity.x != 0 and enemy.is_on_wall():
			perform_jump()
	
	# Handle animations
	if enemy.is_on_floor():
		play_animation("walk")
	else:
		play_animation("jump")
	
	# Flip sprite - only update when outside deadzone
	if enemy.animated_sprite and abs(direction) > flip_deadzone:
		enemy.animated_sprite.flip_h = normalized_dir > 0

# Update patrol points based on current position before transitioning to patrol
func update_patrol_points():
	var current_pos = enemy.global_position
	
	# Create new patrol points centered around current position
	enemy.patrol_points = [
		Vector2(current_pos.x - enemy.patrol_distance / 2, current_pos.y),
		Vector2(current_pos.x + enemy.patrol_distance / 2, current_pos.y)
	]
	
	# Set initial direction based on sprite orientation
	if enemy.animated_sprite:
		enemy.patrol_direction = 1 if enemy.animated_sprite.flip_h else -1
	
	# Reset patrol state variables
	enemy.patrol_is_waiting = false
	enemy.patrol_timer = 0.0
	
	print(enemy.name + " updated patrol points: ", enemy.patrol_points)

# Check if the target is on a stable platform
func is_target_on_platform() -> bool:
	# If target has is_on_floor() method, use it
	if target.has_method("is_on_floor") and target.is_on_floor():
		return true
	
	# If target has velocity, check if they're not falling
	if "velocity" in target and target.velocity.y < 10:
		return true
		
	return false

func perform_jump():
	enemy.velocity.y = jump_strength
	can_jump = false
	jump_timer = 0.0
	play_animation("jump")
	print(enemy.name + " jumped to chase target")

func get_next_state() -> String:
	var next = super.get_next_state()
	if next:
		return next
		
	# Return to patrol if no target
	if not target:
		# Make sure patrol points are updated before transitioning
		update_patrol_points()
		return "Patrol"
	
	# Switch to attack if in range
	if is_target_in_attack_range() and enemy.can_attack:
		return "Attack"
	
	return ""
