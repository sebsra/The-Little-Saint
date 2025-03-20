class_name ArditEnemy
extends BaseEnemy

## Simple patrol enemy that walks back and forth

@export var patrol_distance: float = 100.0
@export var direction: int = 1  # 1 = right, -1 = left

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft

var start_position: Vector2
var is_patrolling: bool = true

func _ready():
	# Set base enemy properties
	max_health = 50.0
	speed = 60.0
	chase_speed = 80.0
	attack_damage = 15.0
	attack_cooldown = 1.0
	
	# Set references
	animated_sprite = $AnimatedSprite2D
	collision_shape = $CollisionShape2D
	
	# Store starting position for patrol
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
	if is_patrolling and not is_chasing and not is_attacking and not is_dead:
		patrol()

func patrol():
	# Check wall collisions
	if ray_cast_right and ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = false
	elif ray_cast_left and ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = true
	
	# Check patrol distance limits
	if abs(global_position.x - start_position.x) > patrol_distance:
		direction *= -1
		animated_sprite.flip_h = direction > 0
	
	# Set movement velocity
	velocity.x = direction * speed
	
	# Play walk animation
	play_animation("walk")

func chase_target(target_node):
	# Stop patrolling when chasing
	is_patrolling = false
	
	# Call parent implementation
	super.chase_target(target_node)

func stop_chase():
	# Resume patrolling when chase ends
	is_patrolling = true
	
	# Call parent implementation
	super.stop_chase()

# Overridden to properly handle player jumping on enemy
func _on_top_checker_body_entered(body):
	if body.name == "Player" and not is_dead:
		# Player jumped on top, take damage
		take_damage(current_health)  # Instant kill when jumped on
		
		# Give player an upward boost if it has the method
		if body.has_method("bounce"):
			body.bounce()