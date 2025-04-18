class_name ShootState
extends ArcherState

# Diese Werte werden nun vom GoblinArcher überschrieben
var shoot_duration: float = 0.6  # Time for the complete shoot action
var shoot_cooldown: float = 0.5  # Time between shots
var max_shots: int = 3  # Maximum shots per attack sequence

var shoot_timer: float = 0.0
var current_cooldown: float = 0.0
var shots_fired: int = 0
var has_aimed: bool = false
var is_firing: bool = false

func _init():
	name = "Shoot"

func enter():
	super.enter()
	play_animation("attack")
	
	# Werte vom Archer einlesen, falls nicht bereits gesetzt
	var archer = enemy as GoblinArcher
	if archer:
		if archer.shoot_duration > 0:
			shoot_duration = archer.shoot_duration
		if archer.shoot_cooldown > 0:
			shoot_cooldown = archer.shoot_cooldown
		if archer.max_shots > 0:
			max_shots = archer.max_shots
	
	# Reset state variables
	shoot_timer = 0.0
	current_cooldown = 0.0
	shots_fired = 0
	has_aimed = false
	is_firing = false
	
	# Stop movement when shooting
	enemy.velocity.x = 0
	
	# Face the target
	flip_to_target()
	
	print(enemy.name + " entered shoot state with duration=" + str(shoot_duration) + 
		  ", cooldown=" + str(shoot_cooldown) + ", max_shots=" + str(max_shots))

func physics_process(delta: float):
	shoot_timer += delta
	
	# Update target tracking
	update_target()
	
	# Aim at target (slight delay before first shot)
	if not has_aimed and shoot_timer >= shoot_duration * 0.3:
		# Face the target
		flip_to_target()
		has_aimed = true
	
	# Manage cooldown between shots
	if current_cooldown > 0:
		current_cooldown -= delta
	
	# Fire sequence
	if has_aimed and current_cooldown <= 0 and shots_fired < max_shots:
		if not is_firing:
			is_firing = true
			_fire_projectile()
			
			# Reset for next shot
			current_cooldown = shoot_cooldown
			shots_fired += 1
			is_firing = false

func _fire_projectile():
	var archer = enemy as GoblinArcher
	if not archer:
		return
	
	# Call the archer's shoot method
	var success = archer.shoot()
	
	if success:
		# Play shoot sound if available
		if enemy.has_node("ShootSound"):
			var sound = enemy.get_node("ShootSound")
			sound.play()
		
		print(enemy.name + " fired a projectile at " + target.name + " (shot " + str(shots_fired + 1) + "/" + str(max_shots) + ")")

func get_next_state() -> String:
	var next = super.get_next_state()
	if next:
		return next
	
	# Return to patrol if target lost
	if not target:
		return "Patrol"
	
	# Check if we need to reload
	var archer = enemy as GoblinArcher
	if archer and archer.arrows_remaining <= 0:
		return "Reload"
	
	# Complete shooting sequence after max shots or if target out of range
	if shots_fired >= max_shots or not is_target_in_attack_range():
		# Check distance to determine next state
		var distance = get_distance_to_target()
		
		if archer and distance < archer.optimal_distance * 0.7:
			return "Retreat"  # Too close, back up
		elif not is_target_in_attack_range():
			return "Positioning"  # Not in range, reposition
		else:
			# Could transition back to positioning or stay in shoot based on arrow count
			if archer and archer.arrows_remaining <= 1:
				return "Reload"  # Almost out of arrows, reload now
			elif distance >= archer.optimal_distance * 0.8 and distance <= archer.optimal_distance * 1.2:
				return ""  # Stay in shoot state if at optimal distance with arrows left
			else:
				return "Positioning"  # Reposition for better shot
	
	return ""  # Stay in shoot state if none of the above conditions are met
