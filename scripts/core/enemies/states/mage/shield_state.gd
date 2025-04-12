class_name ShieldState
extends MageState

var shield_timer: float = 0.0
var shield_duration: float = 5.0

func _init():
	name = "Shield"

func enter():
	super.enter()
	play_animation("idle")
	shield_timer = 0.0
	
	var mage = enemy as GoblinMage
	if mage:
		mage.activate_shield()
		
	print(enemy.name + " entered shield state")

func exit():
	super.exit()
	
	# Deactivate shield on exit
	var mage = enemy as GoblinMage
	if mage:
		mage.deactivate_shield()

func physics_process(delta: float):
	shield_timer += delta
	
	# Update target
	update_target()
	
	# Move slowly toward player with shield active
	if target:
		var direction = target.global_position.x - enemy.global_position.x
		var normalized_dir = sign(direction)
		enemy.velocity.x = normalized_dir * (enemy.speed * 0.5)  # Slower with shield
		
		if enemy.animated_sprite:
			enemy.animated_sprite.flip_h = normalized_dir > 0
	else:
		enemy.velocity.x = 0

func get_next_state() -> String:
	var next = super.get_next_state()
	if next:
		return next
		
	if shield_timer >= shield_duration:
		var mage = enemy as GoblinMage
		if not mage:
			return "Patrol"
		
		# Cast if enough mana
		if target and mage.current_mana >= mage.spell_mana_cost:
			return "Cast"
		
		# Otherwise chase or patrol
		if target:
			return "Chase"
		else:
			return "Patrol"
	
	return ""
