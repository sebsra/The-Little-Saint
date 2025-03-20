class_name GoblinMage
extends BaseEnemy

## Goblin Mage - Ranged magical enemy that attacks with spell projectiles

@export var projectile_scene: PackedScene
@export var mana: float = 100.0
@export var mana_regen_rate: float = 5.0
@export var spell_mana_cost: float = 20.0
@export var attack_delay: float = 1.0

var current_mana: float
var can_cast: bool = true

func _ready():
	# Set base enemy properties
	max_health = 60.0
	speed = 40.0
	chase_speed = 50.0
	attack_damage = 15.0
	attack_cooldown = 3.0
	
	# Initialize goblin mage specific properties
	current_mana = mana
	
	# Set references
	animated_sprite = $AnimatedSprite2D
	collision_shape = $CollisionShape2D
	
	# Call parent ready method
	super._ready()

func _process(delta):
	# Regenerate mana
	if current_mana < mana:
		current_mana = min(current_mana + mana_regen_rate * delta, mana)

func attack():
	if is_dead or not can_attack or not target or current_mana < spell_mana_cost:
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
	
	# Wait for animation to finish
	await animated_sprite.animation_finished
	
	is_attacking = false
	
	# Start cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func spawn_projectile():
	# Make sure we have a projectile scene
	if not projectile_scene:
		projectile_scene = load("res://scenes/core/projectiles/mage_ball.tscn")
	
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
	
	# Consume mana
	current_mana -= spell_mana_cost

# Connection to detection radius (override parent implementation)
func _on_detection_radius_2_body_entered(body):
	if body.name == "Player" and not is_dead:
		chase_target(body)

func _on_detection_radius_2_body_exited(body):
	if body.name == "Player":
		stop_chase()

# Connection to attack zone (override parent implementation)
func _on_attackzone_2_body_entered(body):
	if body.name == "Player":
		is_chasing = false
		attack()

func _on_attackzone_2_body_exited(body):
	if body.name == "Player":
		is_chasing = true
		chase_target(body)

# Connection to death zone (override parent implementation)
func _on_death_zone_2_body_entered(body):
	if body.name == "Player":
		take_damage(current_health)  # Instant death