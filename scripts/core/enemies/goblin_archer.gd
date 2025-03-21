class_name GoblinArcher
extends BaseEnemy

## Goblin Archer - Ranged enemy that attacks with arrows/rocks

@export var projectile_scene: PackedScene
@export var quiver_size: int = 5  # How many arrows before needing to reload
@export var reload_time: float = 1.5
@export var attack_delay: float = 0.5  # Time before arrow is fired after attack animation starts

var arrows_remaining: int
var is_reloading: bool = false

func _ready():
	# Set base enemy properties
	max_health = 70.0
	speed = 60.0
	chase_speed = 80.0
	attack_damage = 8.0
	attack_cooldown = 0.7
	
	# Initialize archer specific properties
	arrows_remaining = quiver_size
	
	# Set references
	animated_sprite = $AnimatedSprite2D
	collision_shape = $CollisionShape2D
	
	# Call parent ready method
	super._ready()

func attack():
	if is_dead or not can_attack or not target or is_reloading:
		return
	
	# Check if we need to reload
	if arrows_remaining <= 0:
		reload()
		return
		
	is_attacking = true
	can_attack = false
	velocity.x = 0
	
	play_animation("attack")
	
	# Wait for the right animation frame to spawn projectile
	await get_tree().create_timer(attack_delay).timeout
	
	# Spawn projectile if we still have a target
	if target and not is_dead:
		spawn_projectile()
		arrows_remaining -= 1
	
	# Wait for animation to finish
	await animated_sprite.animation_finished
	
	is_attacking = false
	
	# Start cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func reload():
	is_reloading = true
	
	# Play reload animation if available, otherwise just idle
	if animated_sprite.sprite_frames.has_animation("reload"):
		play_animation("reload")
	else:
		play_animation("idle")
	
	# Wait for reload time
	await get_tree().create_timer(reload_time).timeout
	
	# Refill quiver
	arrows_remaining = quiver_size
	is_reloading = false

func spawn_projectile():
	# Make sure we have a projectile scene
	if not projectile_scene:
		projectile_scene = load("res://scenes/core/projectiles/rock.tscn")
	
	# Create projectile instance
	var instance = projectile_scene.instantiate()
	
	# Get direction to target
	var direction = (target.global_position - global_position).normalized()
	
	# Setup the projectile
	if instance is BaseProjectile:
		instance.setup(
			direction,
			global_position,
			global_rotation,
			self
		)
	else:
		# Legacy fallback for existing implementation
		instance.direction = direction
		instance.spawn_position = global_position
		instance.spawn_rotation = global_rotation
		
	# Add projectile to the main scene
	var main = get_node("../../")
	main.add_child(instance)

# Connection to detection radius (override parent implementation)
func _on_detection_radius_3_body_entered(body):
	if body.name == "Player" and not is_dead:
		chase_target(body)

func _on_detection_radius_3_body_exited(body):
	if body.name == "Player":
		stop_chase()

# Connection to attack zone (override parent implementation)
func _on_attack_radius_3_body_entered(body):
	if body.name == "Player":
		is_chasing = false
		attack()
		
		# Setup continuous attack if in range
		var attack_timer = func():
			while is_attacking == false and can_attack and not is_dead and body and is_instance_valid(body):
				attack()
				await get_tree().create_timer(0.1).timeout
				
		attack_timer.call()

func _on_attack_radius_3_body_exited(body):
	if body.name == "Player":
		is_chasing = true
		chase_target(body)

# Connection to death zone (override parent implementation)
func _on_death_radius_3_body_entered(body):
	if body.name == "Player":
		take_damage(current_health)  # Instant death
