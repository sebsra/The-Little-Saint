class_name PlayerAttackState
extends PlayerState

var attack_timer: float = 0.0
var attack_duration: float = 0.5  # Duration of attack animation
var has_checked_for_enemies: bool = false
var attack_damage: float = 100.0  # Default damage - enough to kill most enemies

func enter():
	if not Global.has_sword:
		return
	player.current_animation = player.attack_animation
	player.play_attack_animation = true
	attack_timer = 0.0
	has_checked_for_enemies = false
	
	# Play attack sound if available
	if player.has_node("AttackSound"):
		player.get_node("AttackSound").play()

func physics_process(delta: float):
	# Only check for enemies once per attack
	if not has_checked_for_enemies and Global.has_sword:
		_check_for_enemies()
		has_checked_for_enemies = true
	
	# Apply gravity
	var velocity = get_velocity()
	velocity.y += player.GRAVITY * delta
	
	# Reduce movement during attack
	velocity.x = velocity.x * 0.98
	
	set_velocity(velocity)
	player.move_and_slide()
	
	# Update timer
	attack_timer += delta
	
	# Update outfit
	update_outfit()

func _check_for_enemies():
	# Search for enemies around the player
	var player_pos = player.global_position
	
	# Create attack area in front of the player
	var attack_range = 70.0  # Increased attack range
	var attack_width = 40.0  # Width of attack hitbox
	
	# Determine player's facing direction 
	# NOTE: Your sprite system might use flip_h differently - check if this matches your character
	var sprite_node = player.get_node_or_null("character_sprites/bodies")
	if not sprite_node:
		print("Warning: character_sprites/bodies not found. Check player sprite path.")
		return
		
	var player_facing_right = sprite_node.flip_h
	
	# Debug what's happening
	print("Player attack: facing right = ", player_facing_right)
	
	# Create attack rectangle in front of player
	var attack_center = player_pos
	attack_center.x += attack_range/2 * (1 if player_facing_right else -1)
	
	# Direct visual feedback of attack area (debug)
	_show_attack_area(attack_center, Vector2(attack_range, attack_width))
	
	# Check all enemies in the scene
	var enemies = get_tree().get_nodes_in_group("enemy")
	print("Found ", enemies.size(), " enemies in 'enemy' group")
	
	var hit_count = 0
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
			
		# Check distance to enemy (simple rectangular hitbox)
		var enemy_pos = enemy.global_position
		var distance_x = abs(enemy_pos.x - attack_center.x)
		var distance_y = abs(enemy_pos.y - attack_center.y)
		
		# Debug enemy detection
		print("Checking enemy at distance: dx=", distance_x, ", dy=", distance_y)
		
		# Check if enemy is in attack rectangle
		if distance_x <= attack_range/2 and distance_y <= attack_width/2:
			print("Enemy in attack range: ", enemy.name)
			# Damage enemy
			if enemy.has_method("take_damage"):
				print("Attempting to damage enemy: ", enemy.name)
				# Pass both required parameters: damage amount and attacker (self)
				var hit_success = enemy.take_damage(attack_damage, player)
				print("Attack hit success: ", hit_success)
				hit_count += 1
				
				# Visual feedback
				_show_hit_effect(enemy_pos)
			else:
				print("Enemy missing take_damage method: ", enemy.name)
	
	print("Hit ", hit_count, " enemies with attack")

# Debug visualization of attack area
func _show_attack_area(center: Vector2, size: Vector2):
	# Only in debug builds
	if not OS.has_feature("debug"):
		return
		
	# Create a debug rectangle showing the attack area
	var debug_rect = ColorRect.new()
	debug_rect.size = size
	debug_rect.position = center - size/2
	debug_rect.color = Color(1, 0, 0, 0.3)
	get_tree().current_scene.add_child(debug_rect)
	
	# Remove after a short delay
	await get_tree().create_timer(0.3).timeout
	if debug_rect and is_instance_valid(debug_rect):
		debug_rect.queue_free()

# Show a visual hit effect
func _show_hit_effect(position):
	# Create hit particles
	var particles = CPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 8
	particles.lifetime = 0.4
	particles.direction = Vector2(0, -1)
	particles.spread = 90
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 60
	particles.color = Color(1.0, 0.7, 0.2)
	
	get_tree().current_scene.add_child(particles)
	
	# Remove after lifetime
	await get_tree().create_timer(particles.lifetime * 1.5).timeout
	if particles and is_instance_valid(particles):
		particles.queue_free()

func get_next_state() -> String:
	# Check state transitions
	var life_state = check_life()
	if life_state:
		return life_state
	
	# Return to appropriate state after animation ends
	if attack_timer >= attack_duration:
		player.play_attack_animation = false
		
		if player.is_on_floor():
			var x_input = Input.get_axis("left", "right")
			if x_input != 0:
				return "PlayerWalkState"
			else:
				return "PlayerIdleState"
		else:
			return "PlayerFallState"
	
	# Stay in attack state
	return ""
	
func handle_input(event: InputEvent):
	check_menu_input(event)
