class_name MageBall
extends BaseProjectile

## Magical projectile used by mage enemies

@export var particle_effect: PackedScene
@export var hit_sound: AudioStream

func _ready():
	# Set projectile properties
	speed = 50.0
	damage = 10.0
	lifetime = 5.0
	gravity_affected = false
	
	# Call parent ready method
	super._ready()
	
	# Set up animation
	if has_node("Ball"):
		$Ball.play("flying")

func _physics_process(delta):
	# Implement base projectile physics
	super._physics_process(delta)
	
	# Add magical effect (optional particle trail)
	if particle_effect and randf() < 0.3:  # 30% chance per frame
		var particles = particle_effect.instantiate()
		particles.global_position = global_position
		get_tree().current_scene.add_child(particles)
		particles.emitting = true
		
		# Auto-remove particles after their lifetime
		await get_tree().create_timer(particles.lifetime).timeout
		if is_instance_valid(particles):
			particles.queue_free()

func _on_hit_player(player):
	# Call parent implementation
	super._on_hit_player(player)
	
	# Add magical effect (status effect, screen shake, etc.)
	var hud = get_node_or_null("../HUD")
	if hud and hud.has_method("change_life"):
		hud.change_life(-damage/100.0)  # Assuming HUD uses 0-1 scale
	
	# Play hit sound
	if hit_sound:
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = hit_sound
		audio_player.volume_db = -10.0
		get_tree().current_scene.add_child(audio_player)
		audio_player.play()
		
		# Auto-remove audio player after sound finishes
		await audio_player.finished
		audio_player.queue_free()

# Connect the hit zone to our hit methods
func _on_hit_zone_body_entered(body):
	if body.name == "Player":
		_on_hit_player(body)