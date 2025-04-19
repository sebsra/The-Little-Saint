class_name ChaseState
extends EnemyState

func _init():
	name = "Chase"
	
func enter():
	super.enter()
	play_animation("walk")
	print(enemy.name + " entered chase state")

func physics_process(delta: float):
	# Update target
	update_target()
	
	if not target:
		enemy.velocity.x = 0
		return
	
	# Direction to player
	var direction = target.global_position.x - enemy.global_position.x
	var normalized_dir = sign(direction)
	
	# Set velocity using chase speed
	enemy.velocity.x = normalized_dir * enemy.chase_speed
	
	# Flip sprite
	if enemy.animated_sprite:
		enemy.animated_sprite.flip_h = normalized_dir > 0

func get_next_state() -> String:
	var next = super.get_next_state()
	if next:
		return next
		
	# Return to patrol if no target
	if not target:
		return "Patrol"
	
	# Switch to attack if in range
	if is_target_in_attack_range() and enemy.can_attack:
		return "Attack"
	
	return ""
