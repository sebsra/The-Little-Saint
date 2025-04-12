class_name GoblinMelee
extends BaseEnemy

## Goblin Melee - Aggressive melee enemy that becomes enraged when wounded
## Gains combat bonuses in rage mode

# Melee-specific attributes
@export_group("Rage Properties")
@export var rage_threshold: float = 0.3  # Rage at 30% health
@export var rage_damage_bonus: float = 1.5  # 50% more damage in rage
@export var rage_speed_bonus: float = 1.3  # 30% more speed in rage

# Rage state tracking
var is_enraged: bool = false
var base_speed: float
var base_attack_damage: float

# Signal for rage mode
signal entered_rage_mode

func _ready():
	# Call parent ready FIRST
	super._ready()
	
	# Set default values
	max_health = 100.0
	current_health = max_health
	speed = 60.0
	chase_speed = 80.0
	attack_damage = 50.0  # Für 0.5 Herzen Schaden
	attack_cooldown = 1.5
	detection_radius = 150.0
	attack_radius = 40.0
	patrol_distance = 120.0
	
	# Store base values for rage calculations
	base_speed = speed
	base_attack_damage = attack_damage
	
	# Connect signals to handle damage
	damaged.connect(_on_damaged)
	died.connect(_on_died)
	
	# EXPLIZITES SETUP DER STATE MACHINE - neuer Ansatz
	setup_state_machine()
	_setup_melee_states()

# Explizite Einrichtung der Melee-spezifischen States
func _setup_melee_states():
	if not state_machine:
		push_error("No state machine found for " + name)
		return
	
	# Füge Melee-spezifische States hinzu
	var patrol_state = PatrolState.new()
	var chase_state = ChaseState.new()
	var attack_state = AttackState.new()
	var rage_state = RageState.new()
	var rage_chase_state = RageChaseState.new()
	var charge_state = ChargeState.new()
	var hurt_state = HurtState.new()
	var death_state = DeathState.new()
	
	# Füge alle States zur State Machine hinzu
	state_machine.add_state(patrol_state)
	state_machine.add_state(chase_state)
	state_machine.add_state(attack_state)
	state_machine.add_state(rage_state)
	state_machine.add_state(rage_chase_state)
	state_machine.add_state(charge_state)
	state_machine.add_state(hurt_state)
	state_machine.add_state(death_state)
	
	# Initialisiere mit dem ersten State
	state_machine.initialize("Patrol")

# Handle damage events - check for rage threshold
func _on_damaged(amount, attacker):
	# Check if rage threshold reached
	if not is_enraged and current_health <= max_health * rage_threshold:
		enter_rage_mode()

# Rage mode activation - just sets attributes
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

# Handle death
func _on_died():
	_drop_loot()

# Drop random loot
func _drop_loot():
	# Loot table
	var loot_table = [
		{"item": "res://scenes/core/items/coins.tscn", "chance": 0.7},
		{"item": "res://scenes/core/items/elixir.tscn", "chance": 0.1},
		{"item": "res://scenes/core/items/power_attack.tscn", "chance": 0.05}
	]
	
	randomize()
	
	for loot in loot_table:
		if randf() <= loot.chance:
			var item_scene = load(loot.item)
			if item_scene:
				var item = item_scene.instantiate()
				item.global_position = global_position
				get_tree().current_scene.add_child(item)
				break
