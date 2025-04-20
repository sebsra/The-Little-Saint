class_name ChargeState
extends MeleeState

# Diese Werte werden nun vom GoblinMelee überschrieben
var charge_duration: float = 0.75
var charge_speed_multiplier: float = 2.0

var charge_timer: float = 0.0
var has_started_charge: bool = false

func _init():
	name = "Charge"

func enter():
	super.enter()
	play_animation("walk")
	
	# Werte vom GoblinMelee einlesen, falls nicht bereits gesetzt
	var melee = enemy as GoblinMelee
	if melee:
		if melee.charge_duration > 0:
			charge_duration = melee.charge_duration
		if melee.charge_speed_multiplier > 0:
			charge_speed_multiplier = melee.charge_speed_multiplier
	
	charge_timer = 0.0
	has_started_charge = false
	
	# Brief pause before charging
	enemy.velocity.x = 0
		
	print(enemy.name + " entered charge state with duration=" + str(charge_duration) + 
		  ", speed_multiplier=" + str(charge_speed_multiplier))

func physics_process(delta: float):
	charge_timer += delta
	
	# Start charge after brief delay
	if not has_started_charge and charge_timer >= 0.2:
		_start_charge()
		has_started_charge = true
	
	# Update target
	update_target()

func _start_charge():
	if not target:
		return
		
	# Direction to player
	var direction = target.global_position.x - enemy.global_position.x
	var normalized_dir = sign(direction)
	
	# Apply charge speed
	enemy.velocity.x = normalized_dir * enemy.speed * charge_speed_multiplier
	
	# Flip sprite
	if enemy.animated_sprite:
		enemy.animated_sprite.flip_h = normalized_dir > 0

func get_next_state() -> String:
	var next = super.get_next_state()
	if next:
		return next
		
	# After charge completes
	if charge_timer >= charge_duration:
		# Attack immediately if in range
		if is_target_in_attack_range():
			var melee = enemy as GoblinMelee
			if melee and melee.is_enraged:
				return "Rage"
			else:
				return "Attack"
		else:
			# Otherwise continue chasing
			var melee = enemy as GoblinMelee
			if melee and melee.is_enraged:
				return "RageChase" 
			else:
				return "Chase"
	
	return ""
