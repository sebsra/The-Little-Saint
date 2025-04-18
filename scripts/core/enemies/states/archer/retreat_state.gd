class_name RetreatState
extends ArcherState

# Diese Werte werden nun vom GoblinArcher überschrieben
var retreat_duration: float = 1.5
var optimal_distance: float = 150.0

var retreat_timer: float = 0.0

func _init():
	name = "Retreat"

func enter():
	super.enter()
	play_animation("walk")
	retreat_timer = 0.0
	
	# Werte vom Archer einlesen, falls nicht bereits gesetzt
	var archer = enemy as GoblinArcher
	if archer:
		if archer.retreat_duration > 0:
			retreat_duration = archer.retreat_duration
		if archer.optimal_distance > 0:
			optimal_distance = archer.optimal_distance
	
	print(enemy.name + " entered retreat state with duration=" + str(retreat_duration) + 
		  ", optimal_distance=" + str(optimal_distance))

func physics_process(delta: float):
	retreat_timer += delta
	
	# Update target reference
	update_target()
	
	if not target:
		return
	
	var distance = get_distance_to_target()
	var direction = enemy.global_position.x - target.global_position.x
	var normalized_dir = sign(direction)
	
	# Move away if too close
	if distance < optimal_distance:
		enemy.velocity.x = normalized_dir * enemy.speed
		
		if enemy.animated_sprite:
			enemy.animated_sprite.flip_h = normalized_dir < 0
	else:
		enemy.velocity.x = 0
		
		# Face player but don't move
		var look_dir = target.global_position.x - enemy.global_position.x
		if enemy.animated_sprite:
			enemy.animated_sprite.flip_h = look_dir > 0

func get_next_state() -> String:
	var next = super.get_next_state()
	if next:
		return next
		
	# Return to patrol if no target
	if not target:
		return "Patrol"
	
	# After retreat time, shoot
	if retreat_timer >= retreat_duration:
		var archer = enemy as GoblinArcher
		var distance = get_distance_to_target()
		
		if archer and distance >= optimal_distance and archer.arrows_remaining > 0:
			return "Shoot"
		elif archer and archer.arrows_remaining <= 0:
			return "Reload"
		else:
			return "Positioning"  # Reposition if conditions not right for shooting
	
	return ""
