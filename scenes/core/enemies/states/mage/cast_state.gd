class_name CastState
extends MageState

# Diese Werte werden nun vom GoblinMage überschrieben
var cast_duration: float = 0.8  # Time for the complete cast action
var cast_cooldown: float = 1.2   # Time between spell casts
var max_spells: int = 2  # Maximum spells per cast sequence

var cast_timer: float = 0.0
var current_cooldown: float = 0.0
var spells_cast: int = 0
var is_charging: bool = false
var charge_complete: bool = false
var is_casting: bool = false
var spell_type: String = "fireball"  # Default spell type

# Visual effects
var charge_particles: CPUParticles2D = null
var cast_effect_active: bool = false

func _init():
	name = "Cast"

func enter():
	super.enter()
	play_animation("cast")
	
	# Werte vom Magier einlesen, falls nicht bereits gesetzt
	var mage = enemy as GoblinMage
	if mage:
		if mage.cast_duration > 0:
			cast_duration = mage.cast_duration
		if mage.cast_cooldown > 0:
			cast_cooldown = mage.cast_cooldown
		if mage.max_spells > 0:
			max_spells = mage.max_spells
	
	# Reset state variables
	cast_timer = 0.0
	current_cooldown = 0.0
	spells_cast = 0
	is_charging = false
	charge_complete = false
	is_casting = false
	cast_effect_active = false
	
	# Stop movement when casting
	enemy.velocity.x = 0
	
	# Face the target
	flip_to_target()
	
	# Begin charging spell
	_start_spell_charge()
	
	print(enemy.name + " entered cast state with duration=" + str(cast_duration) + 
		  ", cooldown=" + str(cast_cooldown) + ", max_spells=" + str(max_spells))

func exit():
	super.exit()
	
	# Clean up any active effects
	_cleanup_effects()

func physics_process(delta: float):
	cast_timer += delta
	
	# Update target tracking
	update_target()
	
	# Charge spell (visual buildup before first cast)
	if is_charging and not charge_complete and cast_timer >= cast_duration * 0.5:
		charge_complete = true
		_complete_spell_charge()
	
	# Manage cooldown between casts
	if current_cooldown > 0:
		current_cooldown -= delta
	
	# Cast sequence
	if charge_complete and current_cooldown <= 0 and spells_cast < max_spells:
		if not is_casting:
			is_casting = true
			_cast_spell()
			
			# Reset for next cast
			current_cooldown = cast_cooldown
			spells_cast += 1
			is_casting = false

func _start_spell_charge():
	is_charging = true
	
	# Create charge-up effect
	var mage = enemy as GoblinMage
	if not mage:
		return
	
	# Create magical charging particles
	charge_particles = CPUParticles2D.new()
	charge_particles.name = "ChargeParticles"
	charge_particles.emitting = true
	charge_particles.amount = 16
	charge_particles.lifetime = 0.5
	charge_particles.explosiveness = 0.3
	charge_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	charge_particles.emission_sphere_radius = 12.0
	charge_particles.direction = Vector2(0, -1)
	charge_particles.spread = 180.0
	charge_particles.gravity = Vector2(0, -20)
	charge_particles.initial_velocity_min = 5.0
	charge_particles.initial_velocity_max = 15.0
	charge_particles.color = Color(0.5, 0.2, 0.9, 0.7)  # Purple magic color
	
	enemy.add_child(charge_particles)
	cast_effect_active = true

func _complete_spell_charge():
	# Visual effect for completed charge
	if charge_particles:
		# Pulse effect
		var tween = enemy.create_tween()
		tween.tween_property(charge_particles, "scale", Vector2(1.5, 1.5), 0.2)
		tween.tween_property(charge_particles, "scale", Vector2(0.8, 0.8), 0.1)
		
		# Change particle color
		charge_particles.color = Color(0.7, 0.3, 1.0, 0.8)  # Brighter magic color

func _cast_spell():
	var mage = enemy as GoblinMage
	if not mage:
		return
	
	# Call the mage's cast_spell method
	var success = mage.cast_spell(spell_type)
	
	if success:
		# Visual feedback
		if charge_particles:
			charge_particles.emitting = false
			
			# Create new emission burst
			var burst = CPUParticles2D.new()
			burst.name = "SpellBurst"
			burst.emitting = true
			burst.one_shot = true
			burst.explosiveness = 1.0
			burst.amount = 24
			burst.lifetime = 0.5
			burst.direction = Vector2(0, -1)
			burst.spread = 180.0
			burst.initial_velocity_min = 30.0
			burst.initial_velocity_max = 60.0
			burst.color = Color(0.7, 0.3, 1.0, 0.8)
			
			enemy.add_child(burst)
			
			# Remove after effect completes
			await enemy.get_tree().create_timer(burst.lifetime * 1.5).timeout
			if is_instance_valid(burst):
				burst.queue_free()
		
		print(enemy.name + " cast a spell at " + target.name + " (spell " + str(spells_cast) + "/" + str(max_spells) + ")")

func _cleanup_effects():
	# Remove any active particles
	if charge_particles and is_instance_valid(charge_particles):
		charge_particles.queue_free()
		charge_particles = null
	
	cast_effect_active = false

func get_next_state() -> String:
	var next = super.get_next_state()
	if next:
		return next
	
	# Return to patrol if target lost
	if not target:
		return "Patrol"
	
	# Check mana
	var mage = enemy as GoblinMage
	if mage and mage.current_mana < mage.spell_mana_cost:
		# Not enough mana for another spell
		return "MagePositioning"  # Reposition and wait for mana regen
	
	# Complete casting sequence after max spells or if target out of range
	if spells_cast >= max_spells or not is_target_in_attack_range():
		# Check distance to determine next state
		var distance = get_distance_to_target()
		
		if distance < 80:
			# Too close, try teleport or shield
			if mage.current_mana >= mage.teleport_mana_cost and mage.last_teleport_time <= 0:
				return "Teleport"
			elif mage.current_mana >= mage.shield_mana_cost:
				return "Shield"
			else:
				return "MagePositioning"
		elif not is_target_in_attack_range():
			return "MagePositioning"  # Not in range, reposition
		else:
			# Could stay in cast state if we have enough mana for another sequence
			if mage and mage.current_mana >= mage.spell_mana_cost * 2:
				return ""  # Stay in cast state with enough mana
			else:
				return "MagePositioning"  # Reposition and regenerate mana
	
	return ""  # Stay in cast state if none of the above conditions are met
