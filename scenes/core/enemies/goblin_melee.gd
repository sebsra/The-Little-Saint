class_name GoblinMelee
extends BaseEnemy

## Goblin Melee - Aggressive melee enemy that becomes enraged when wounded
## Gains combat bonuses in rage mode

# Melee-specific attributes
@export_group("Rage Properties")
@export var rage_threshold: float = 0.3  # Rage at 30% health
@export var rage_damage_bonus: float = 1.5  # 50% more damage in rage
@export var rage_speed_bonus: float = 1.3  # 30% more speed in rage

# State-specific attributes for difficulty scaling
@export_group("Charge State Properties")
@export var charge_duration: float = 0.75
@export var charge_speed_multiplier: float = 2.0

@export_group("Rage State Properties")
@export var rage_attack_duration: float = 0.8

# Rage state tracking
var is_enraged: bool = false
var base_speed: float
var base_attack_damage: float

# Signal for rage mode
signal entered_rage_mode

func _ready():
	# Set default values for EASY mode
	max_health = 100.0
	current_health = max_health
	speed = 60.0
	chase_speed = 80.0
	attack_damage = 50.0  # For 0.5 heart damage
	attack_cooldown = 1.5
	detection_radius = 150.0
	attack_radius = 40.0
	patrol_distance = 120.0
	
	# Store base values for rage calculations
	base_speed = speed
	base_attack_damage = attack_damage
	
	# Call parent ready which will apply difficulty scaling 
	super._ready()
	
	# After scaling, update base values for rage calculations
	base_speed = speed
	base_attack_damage = attack_damage
	
	# Connect signals to handle damage
	damaged.connect(_on_damaged)
	
	# EXPLICIT STATE MACHINE SETUP - new approach
	setup_state_machine()
	_setup_melee_states()

# Override apply_difficulty_scaling to handle melee-specific attributes
func apply_difficulty_scaling():
	# Call parent implementation to handle base attributes
	super.apply_difficulty_scaling()
	
	if not Global:
		return
		
	var difficulty = Global.get_difficulty()
	
	# Scale melee-specific attributes based on difficulty
	match difficulty:
		Global.Difficulty.EASY:
			# Base values already set
			rage_threshold = 0.3
			rage_damage_bonus = 1.5
			rage_speed_bonus = 1.3
			
			# State-specific values for EASY
			charge_duration = 0.75
			charge_speed_multiplier = 2.0
			rage_attack_duration = 0.8
			
		Global.Difficulty.NORMAL:
			rage_threshold = 0.4  # Enrages earlier
			rage_damage_bonus = 1.6
			rage_speed_bonus = 1.4
			
			# State-specific values for NORMAL
			charge_duration = 0.7
			charge_speed_multiplier = 2.2
			rage_attack_duration = 0.75
			
		Global.Difficulty.HARD:
			rage_threshold = 0.5  # Enrages at half health
			rage_damage_bonus = 1.8
			rage_speed_bonus = 1.5
			
			# State-specific values for HARD
			charge_duration = 0.6
			charge_speed_multiplier = 2.4
			rage_attack_duration = 0.7
			
		Global.Difficulty.NIGHTMARE:
			rage_threshold = 0.7  # Enrages at 70% health
			rage_damage_bonus = 2.0  # Double damage in rage
			rage_speed_bonus = 1.8  # 80% speed boost
			
			# State-specific values for NIGHTMARE
			charge_duration = 0.5  # Faster charge
			charge_speed_multiplier = 2.8  # Much faster charge
			rage_attack_duration = 0.6  # Faster attack animation
	
	# If already enraged, update current stats
	if is_enraged:
		speed = base_speed * rage_speed_bonus
		chase_speed = speed * 1.2
		attack_damage = base_attack_damage * rage_damage_bonus

# Explicit setup of melee-specific states
func _setup_melee_states():
	if not state_machine:
		push_error("No state machine found for " + name)
		return
	
	# Add melee-specific states with difficulty-scaled parameters
	var patrol_state = PatrolState.new()
	var chase_state = ChaseState.new()
	var attack_state = AttackState.new()
	
	var rage_state = RageState.new()
	rage_state.rage_duration = rage_attack_duration
	
	var rage_chase_state = RageChaseState.new()
	
	var charge_state = ChargeState.new()
	charge_state.charge_duration = charge_duration
	charge_state.charge_speed_multiplier = charge_speed_multiplier
	
	var hurt_state = HurtState.new()
	var death_state = DeathState.new()
	
	# Add all states to the state machine
	state_machine.add_state(patrol_state)
	state_machine.add_state(chase_state)
	state_machine.add_state(attack_state)
	state_machine.add_state(rage_state)
	state_machine.add_state(rage_chase_state)
	state_machine.add_state(charge_state)
	state_machine.add_state(hurt_state)
	state_machine.add_state(death_state)
	
	# Initialize with the first state
	state_machine.initialize("Patrol")

# Handle damage events - check for rage threshold
func _on_damaged(amount, attacker):
	# Check if rage threshold reached
	if not is_enraged and current_health <= max_health * rage_threshold:
		enter_rage_mode()

# Rage mode activation - applies attribute bonuses
func enter_rage_mode():
	if is_enraged:
		return
		
	is_enraged = true
	
	# Apply stat bonuses
	speed = base_speed * rage_speed_bonus
	chase_speed = speed * 1.2
	attack_damage = base_attack_damage * rage_damage_bonus
	
	# Visual effect
	modulate = Color(1.3, 0.7, 0.7)
	
	# Create rage particles if needed
	if not has_node("RageParticles"):
		var particles = CPUParticles2D.new()
		particles.name = "RageParticles"
		particles.amount = 10
		particles.lifetime = 0.5
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 10.0
		particles.gravity = Vector2(0, -20)
		particles.initial_velocity_min = 10.0
		particles.initial_velocity_max = 20.0
		particles.color = Color(1.0, 0.3, 0.1, 0.7)
		add_child(particles)
		particles.emitting = true
	
	# Emit signal - states listen for this
	emit_signal("entered_rage_mode")
	
	print(name + " entered rage mode!")
