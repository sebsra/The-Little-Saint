class_name PatrolState
extends EnemyState

# For stuck detection
var previous_position: Vector2 = Vector2.ZERO
var stuck_timer: float = 0.0
var stuck_threshold: float = 0.5
var position_epsilon: float = 1.0  # Small threshold to detect actual movement

func _init():
	name = "Patrol"

func enter():
	super.enter()
	play_animation("idle")
	
	# Set up patrol points if needed
	if enemy.patrol_points.size() == 0 and enemy_machine:
		var start_pos = enemy_machine.initial_position
		enemy.patrol_points = [
			start_pos,
			start_pos + Vector2(enemy.patrol_distance, 0)
		]
	
	previous_position = enemy.global_position
	stuck_timer = 0.0
	print(enemy.name + " entered patrol state")

func physics_process(delta: float):
	enemy.patrol_timer += delta
	
	# Check for player - handled by state machine automatically
	update_target()
	
	if enemy.patrol_is_waiting:
		# Wait at patrol point
		if enemy.patrol_timer >= enemy.patrol_wait_time:
			enemy.patrol_is_waiting = false
			enemy.patrol_timer = 0.0
			# Reverse direction
			enemy.patrol_direction *= -1
			if enemy.animated_sprite:
				enemy.animated_sprite.flip_h = enemy.patrol_direction > 0
		return
	
	# Apply patrol movement
	enemy.velocity.x = enemy.speed * enemy.patrol_direction
	
	# Play walk animation
	play_animation("walk")
	
	# Check if we're stuck (not moving)
	if not enemy.patrol_is_waiting and enemy.global_position.distance_to(previous_position) < position_epsilon:
		stuck_timer += delta
		if stuck_timer >= stuck_threshold:
			# We're stuck, change direction with random wait time
			handle_stuck()
	else:
		# We moved, reset stuck timer
		stuck_timer = 0.0
	
	# Update previous position
	previous_position = enemy.global_position
	
	# Check if patrol points are set up
	if enemy.patrol_points.size() < 2:
		return
		
	# Check if we've reached a boundary
	if enemy.patrol_direction > 0 and enemy.global_position.x >= enemy.patrol_points[1].x:
		enemy.global_position.x = enemy.patrol_points[1].x
		handle_patrol_point_reached()
	elif enemy.patrol_direction < 0 and enemy.global_position.x <= enemy.patrol_points[0].x:
		enemy.global_position.x = enemy.patrol_points[0].x
		handle_patrol_point_reached()

func handle_patrol_point_reached():
	enemy.velocity.x = 0
	play_animation("idle")
	enemy.patrol_is_waiting = true
	enemy.patrol_timer = 0.0

# New function to handle when enemy is stuck
func handle_stuck():
	enemy.velocity.x = 0
	play_animation("idle")
	enemy.patrol_is_waiting = true
	enemy.patrol_timer = 0.0
	# Generate random wait time between 0 and 1 second
	enemy.patrol_wait_time = randf()  # Random value between 0 and 1
	# Reset stuck timer
	stuck_timer = 0.0
	# Will automatically change direction when wait time expires
	print(enemy.name + " is stuck, changing direction in " + str(enemy.patrol_wait_time) + " seconds")

func get_next_state() -> String:
	var next = super.get_next_state()
	if next:
		return next
		
	# Transition to chase if target detected - handled automatically by state machine
	if target:
		return "Chase"
	
	return ""
