class_name PatrolState
extends EnemyState

var patrol_timer: float = 0.0
var wait_time: float = 1.0
var is_waiting: bool = false
var direction: int = 1
var patrol_points: Array = []

func _init():
	name = "Patrol"

func enter():
	super.enter()
	play_animation("idle")
	
	# Set up patrol points if needed
	if patrol_points.size() == 0 and enemy_machine:
		var start_pos = enemy_machine.initial_position
		patrol_points = [
			start_pos,
			start_pos + Vector2(enemy.patrol_distance, 0)
		]
	
	patrol_timer = 0.0
	is_waiting = false
	print(enemy.name + " entered patrol state")

func physics_process(delta: float):
	patrol_timer += delta
	
	# Check for player - handled by state machine automatically
	update_target()
	
	if is_waiting:
		# Wait at patrol point
		if patrol_timer >= wait_time:
			is_waiting = false
			patrol_timer = 0.0
			# Reverse direction
			direction *= -1
			if enemy.animated_sprite:
				enemy.animated_sprite.flip_h = direction > 0
		return
	
	# Apply patrol movement
	enemy.velocity.x = enemy.speed * direction
	
	# Play walk animation
	play_animation("walk")
	
	# Check if patrol points are set up
	if patrol_points.size() < 2:
		return
		
	# Check if we've reached a boundary
	if direction > 0 and enemy.global_position.x >= patrol_points[1].x:
		enemy.global_position.x = patrol_points[1].x
		handle_patrol_point_reached()
	elif direction < 0 and enemy.global_position.x <= patrol_points[0].x:
		enemy.global_position.x = patrol_points[0].x
		handle_patrol_point_reached()

func handle_patrol_point_reached():
	enemy.velocity.x = 0
	play_animation("idle")
	is_waiting = true
	patrol_timer = 0.0

func get_next_state() -> String:
	var next = super.get_next_state()
	if next:
		return next
		
	# Transition to chase if target detected - handled automatically by state machine
	if target:
		return "Chase"
	
	return ""
