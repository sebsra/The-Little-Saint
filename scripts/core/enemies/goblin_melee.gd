class_name GoblinMelee
extends BaseEnemy

## Goblin Melee - Close combat enemy that attacks directly

@export var rage_threshold: float = 0.3  # Percentage of health that triggers rage mode
@export var rage_speed_multiplier: float = 1.5
@export var rage_damage_multiplier: float = 1.2

var is_enraged: bool = false
var base_speed: float
var base_chase_speed: float
var base_attack_damage: float

func _ready():
	# Set base enemy properties
	max_health = 100.0
	speed = 80.0
	chase_speed = 100.0
	attack_damage = 20.0
	attack_cooldown = 1.0
	
	# Store base values for rage mode
	base_speed = speed
	base_chase_speed = chase_speed
	base_attack_damage = attack_damage
	
	# Set references
	animated_sprite = $AnimatedSprite2D
	collision_shape = $CollisionShape2D
	
	# Call parent ready method
	super._ready()

func take_damage(amount):
	super.take_damage(amount)
	
	# Check if we should enter rage mode
	if not is_enraged and current_health <= max_health * rage_threshold:
		enter_rage_mode()

func enter_rage_mode():
	is_enraged = true
	
	# Increase stats
	speed = base_speed * rage_speed_multiplier
	chase_speed = base_chase_speed * rage_speed_multiplier
	attack_damage = base_attack_damage * rage_damage_multiplier
	
	# Visual indication of rage if available
	if animated_sprite.sprite_frames.has_animation("rage"):
		animated_sprite.play("rage")
	
	# Play a sound if available
	if has_node("AudioStreamPlayer"):
		var audio = get_node("AudioStreamPlayer")
		audio.play()

func attack():
	if is_dead or not can_attack or not target:
		return
		
	is_attacking = true
	can_attack = false
	velocity.x = 0
	
	# Use rage attack animation if available and enraged
	if is_enraged and animated_sprite.sprite_frames.has_animation("rage_attack"):
		play_animation("rage_attack")
	else:
		play_animation("attack")
	
	# Apply damage to player
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	
	# Update HUD
	if hud and hud.has_method("change_life"):
		hud.change_life(-attack_damage/100.0)  # Assuming health is on 0-1 scale for HUD
	
	# Wait for animation to finish
	await animated_sprite.animation_finished
	
	is_attacking = false
	
	# Start cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# Connection to detection radius (override parent implementation)
func _on_detection_radius_body_entered(body):
	if body.name == "Player" and not is_dead:
		chase_target(body)

func _on_detection_radius_body_exited(body):
	if body.name == "Player":
		stop_chase()

# Connection to attack zone (override parent implementation)
func _on_attackzone_body_entered(body):
	if body.name == "Player":
		is_chasing = false
		attack()

func _on_attackzone_body_exited(body):
	if body.name == "Player":
		is_chasing = true
		chase_target(body)

# Connection to death zone (override parent implementation)
func _on_deathzone_body_entered(body):
	if body.name == "Player":
		take_damage(current_health)  # Instant death