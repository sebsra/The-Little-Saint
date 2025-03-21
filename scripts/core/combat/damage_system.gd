class_name DamageSystem
extends Node

## A centralized system for calculating and applying damage in the game

# Damage types
enum DamageType {
	PHYSICAL,
	MAGICAL,
	TRUE      # Ignores defenses
}

# Hit types
enum HitType {
	NORMAL,
	CRITICAL,
	MISS
}

# Damage result structure
class DamageResult:
	var damage: float = 0
	var hit_type: int = HitType.NORMAL
	var damage_type: int = DamageType.PHYSICAL
	var source = null
	var target = null
	
	func _init(dmg: float, type: int = HitType.NORMAL, dmg_type: int = DamageType.PHYSICAL, src = null, tgt = null):
		damage = dmg
		hit_type = type
		damage_type = dmg_type
		source = src
		target = tgt

# Default critical hit modifier
var critical_multiplier: float = 1.5
# Base chance for a critical hit (0-1)
var base_critical_chance: float = 0.1
# Base chance to miss (0-1)
var base_miss_chance: float = 0.05

# Signal emitted when damage is calculated
signal damage_calculated(result: DamageResult)
# Signal emitted when damage is applied
signal damage_applied(result: DamageResult)
# Signal emitted when a lethal hit is dealt
signal lethal_hit(target, source)

## Calculate raw damage based on attacker and defender stats
func calculate_damage(attacker, defender, base_damage: float, damage_type: int = DamageType.PHYSICAL) -> DamageResult:
	# Get attack power
	var attack_power = base_damage
	if attacker.has_method("get_attack_power"):
		attack_power = attacker.get_attack_power()
	elif "attack_damage" in attacker:
		attack_power = attacker.attack_damage
	
	# Get defense
	var defense = 0
	if defender.has_method("get_defense"):
		defense = defender.get_defense()
	elif "defense" in defender:
		defense = defender.defense
	
	# Determine hit type (miss, normal, critical)
	var hit_type = HitType.NORMAL
	var hit_chance = randf()
	
	# Check for miss
	var miss_chance = base_miss_chance
	if defender.has_method("get_dodge_chance"):
		miss_chance += defender.get_dodge_chance()
	
	if hit_chance < miss_chance:
		hit_type = HitType.MISS
		attack_power = 0
	else:
		# Check for critical hit
		var crit_chance = base_critical_chance
		if attacker.has_method("get_critical_chance"):
			crit_chance += attacker.get_critical_chance()
			
		if hit_chance > (1.0 - crit_chance):
			hit_type = HitType.CRITICAL
			attack_power *= critical_multiplier
	
	# Calculate damage based on type
	var final_damage = attack_power
	
	match damage_type:
		DamageType.PHYSICAL:
			# Physical damage reduced by defense
			final_damage = max(0, attack_power - defense)
		DamageType.MAGICAL:
			# Magical damage, different formula
			var magic_defense = defense * 0.5  # Example: magic defense is half of physical
			final_damage = max(0, attack_power - magic_defense)
		DamageType.TRUE:
			# True damage ignores defense
			final_damage = attack_power
	
	# Create the damage result
	var result = DamageResult.new(final_damage, hit_type, damage_type, attacker, defender)
	
	# Emit signal
	emit_signal("damage_calculated", result)
	
	return result

## Apply calculated damage to the target
func apply_damage(result: DamageResult) -> bool:
	if result.hit_type == HitType.MISS:
		# Missed attack
		if result.target.has_method("on_damage_missed"):
			result.target.on_damage_missed(result)
		return false
	
	# Apply damage to the target
	var was_lethal = false
	
	if result.target.has_method("take_damage"):
		was_lethal = result.target.take_damage(result.damage)
	elif "current_health" in result.target:
		result.target.current_health -= result.damage
		if result.target.current_health <= 0:
			was_lethal = true
	
	# Emit the damage applied signal
	emit_signal("damage_applied", result)
	
	# Handle lethal hit
	if was_lethal:
		emit_signal("lethal_hit", result.target, result.source)
	
	return was_lethal

## Process a direct attack from attacker to defender
func process_attack(attacker, defender, base_damage: float, damage_type: int = DamageType.PHYSICAL) -> bool:
	var result = calculate_damage(attacker, defender, base_damage, damage_type)
	return apply_damage(result)

## Helper function to get the appropriate text for a hit type
func get_hit_text(hit_type: int) -> String:
	match hit_type:
		HitType.MISS:
			return "Miss"
		HitType.CRITICAL:
			return "Critical"
		_:
			return "Hit"
