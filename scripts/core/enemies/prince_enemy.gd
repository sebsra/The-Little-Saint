class_name PrinceEnemy
extends BaseEnemy

## Simple patrol enemy that walks back and forth (used in prince levels)

@export var direction: int = 1  # 1 = right, -1 = left
@export var damage_on_touch: float = 10.0  # Damage dealt when touching player

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft

var start_position: Vector2
var is_patrolling: bool = true

func _ready():
	# Set base enemy properties
	max_health = 40.0
	speed = 60.0
	chase_speed = speed  # Same as normal speed since this enemy doesn't chase
	attack_damage = damage_on_touch
	
	# Set references
	animated_sprite = $AnimatedSprite2D
	collision_shape = $CollisionShape2D
	
	# Store starting position
	start_position = global_position
	
	# Initialize raycasts if not already set
	if not ray_cast_right:
		ray_cast_right = $RayCastRight if has_node("RayCastRight") else null
		
	if not ray_cast_left:
		ray_cast_left = $RayCastLeft if has_node("RayCastLeft") else null
	
	# Call parent ready method
	super._ready()
	
	# Start patrol behavior
	play_animation("walk")

func _physics_process(delta):
	# Call parent implementation for gravity and movement
	super._physics_process(delta)
	
	# Handle patrol logic if not chasing or attacking
	if is_patrolling and not is_dead:
		patrol()

func patrol():
	# Check wall collisions
	if ray_cast_right and ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = false
	elif ray_cast_left and ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = true
	
	# Set movement velocity
	velocity.x = direction * speed
	
	# Play walk animation
	play_animation("walk")

# Override to handle damage-on-touch behavior
func _on_body_entered(body):
	if body.name == "Player" and not is_dead:
		# Deal damage to player
		if body.has_method("take_damage"):
			body.take_damage(damage_on_touch)
		
		# Update HUD
		if hud and hud.has_method("change_life"):
			hud.change_life(-damage_on_touch/100.0)  # Assuming health is on 0-1 scale for HUD