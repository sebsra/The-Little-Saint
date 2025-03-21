class_name Rock
extends BaseProjectile

## Rock projectile used by archer enemies
## Now supports object pooling

@export var bounce_count: int = 1  # How many times the rock can bounce
@export var hit_sound: AudioStream

var bounces_remaining: int = 0

func _ready():
	# Set projectile properties
	speed = 120.0
	damage = 8.0
	lifetime = 5.0
	gravity_affected = true
	bounce = true
	bounce_factor = 0.6
	
	# Set remaining bounces
	bounces_remaining = bounce_count
	
	# Call parent ready method
	super._ready()
	
	# Set up animation
	if has_node("rock"):
		$rock.play("flying")

func setup(dir: Vector2, spawn_pos: Vector2, spawn_rot: float = 0.0, source = null):
	# Call parent setup
	super.setup(dir, spawn_pos, spawn_rot, source)
	
	# Reset bounce count
	bounces_remaining = bounce_count
	
	return self

func _on_collision(collision):
	var collider = collision.get_collider()
	
	# Check if we should bounce
	if bounce and bounces_remaining > 0 and not collider.is_in_group("Player") and not collider.is_in_group("Enemy"):
		bounces_remaining -= 1
		
		var reflection = collision.get_remainder().bounce(collision.get_normal())
		velocity = velocity.bounce(collision.get_normal()) * bounce_factor
		global_position += reflection
		
		# Play bounce sound if available
		if hit_sound:
			var audio_player = AudioStreamPlayer.new()
			audio_player.stream = hit_sound
			audio_player.volume_db = -15.0
			get_tree().current_scene.add_child(audio_player)
			audio_player.play()
			
			# Auto-remove audio player after sound finishes
			audio_player.finished.connect(func(): 
				audio_player.queue_free()
			)
		
		return
	
	# If no more bounces or hit player/enemy, use default behavior
	has_hit = true
	
	# Handle different collision types
	if collider.is_in_group("Player") and source_node != collider:
		_on_hit_player(collider)
	elif collider.is_in_group("Enemy") and source_node != collider:
		_on_hit_enemy(collider)
	else:
		_on_hit_environment(collider)

func _on_hit_player(player):
	# Call parent implementation
	super._on_hit_player(player)
	
	# Update HUD
	var hud = get_node_or_null("../HUD")
	if hud and hud.has_method("change_life"):
		hud.change_life(-damage/100.0)  # Assuming HUD uses 0-1 scale

# Reset state when recycled to pool
func _on_recycle_to_pool():
	super._on_recycle_to_pool()
	
	# Reset bounce count
	bounces_remaining = bounce_count

# Connect the hit zone to our hit methods if we have one
func _on_hit_zone_body_entered(body):
	if body.name == "Player":
		_on_hit_player(body)
