class_name HitEffect
extends Node2D

## Visual and audio effects for combat hits
## Creates temporary visual effects at hit locations

# Effect properties
@export var lifetime: float = 0.5
@export var scale_multiplier: float = 1.0
@export var effect_color: Color = Color(1, 1, 1, 1)
@export var hit_sound: AudioStream = null
@export var hit_sound_volume: float = 0.0  # in dB

# Effect type
enum HitEffectType {
	NORMAL,
	CRITICAL,
	BLOCK,
	HEAL,
	MAGIC
}

@export var effect_type: HitEffectType = HitEffectType.NORMAL

# Animation properties
@export var animation_speed: float = 1.0
@export var sprite_frames: SpriteFrames = null

# Animation node
var animated_sprite: AnimatedSprite2D = null

# Whether audio has been played
var audio_played: bool = false

# Signal when effect is finished
signal effect_finished()

# Initialize the hit effect
func _ready():
	# Create animated sprite if not already a child
	if not has_node("AnimatedSprite2D"):
		animated_sprite = AnimatedSprite2D.new()
		animated_sprite.name = "AnimatedSprite2D"
		add_child(animated_sprite)
	else:
		animated_sprite = $AnimatedSprite2D
	
	# Set up animation
	if sprite_frames:
		animated_sprite.sprite_frames = sprite_frames
	
	# Apply settings
	animated_sprite.modulate = effect_color
	scale = Vector2(scale_multiplier, scale_multiplier)
	animated_sprite.speed_scale = animation_speed
	
	# Determine which animation to play
	var anim_name = "normal" # Default animation
	match effect_type:
		HitEffectType.CRITICAL:
			anim_name = "critical"
		HitEffectType.BLOCK:
			anim_name = "block"
		HitEffectType.HEAL:
			anim_name = "heal"
		HitEffectType.MAGIC:
			anim_name = "magic"
	
	# Check if animation exists
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	else:
		# Use first available animation
		var animations = animated_sprite.sprite_frames.get_animation_names()
		if animations.size() > 0:
			animated_sprite.play(animations[0])
	
	# Play hit sound
	if hit_sound and not audio_played:
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = hit_sound
		audio_player.volume_db = hit_sound_volume
		audio_player.name = "HitSound"
		add_child(audio_player)
		audio_player.play()
		audio_player.finished.connect(func(): audio_player.queue_free())
		audio_played = true
	
	# Connect to animation finished
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Set up backup timeout
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.name = "LifetimeTimer"
	add_child(timer)
	timer.timeout.connect(_on_timeout)
	timer.start()

# Process function for manual animation logic if needed
func _process(delta):
	# Add optional particle effects or additional animations
	pass

# Create and play a one-shot hit effect at a position
static func create_hit_effect(
	effect_scene: PackedScene,
	position: Vector2,
	type: HitEffectType = HitEffectType.NORMAL,
	parent: Node = null
) -> HitEffect:
	# Instance the effect
	var effect_instance = effect_scene.instantiate()
	
	# Set effect properties
	effect_instance.global_position = position
	effect_instance.effect_type = type
	
	# Find parent to add to
	var target_parent = parent
	if not target_parent:
		target_parent = Engine.get_main_loop().current_scene
	
	# Add to scene
	target_parent.add_child(effect_instance)
	
	return effect_instance

# Animation finished handler
func _on_animation_finished():
	queue_free()
	emit_signal("effect_finished")

# Backup timeout handler (in case animation doesn't finish)
func _on_timeout():
	queue_free()
	emit_signal("effect_finished")

# Apply a screen shake effect
func apply_screen_shake(camera: Camera2D, intensity: float = 5.0, duration: float = 0.2) -> void:
	if camera:
		var original_offset = camera.offset
		
		# Create a tween for the shake
		var tween = create_tween()
		
		# Add multiple shake steps
		var shake_steps = 10
		var time_per_step = duration / shake_steps
		
		for i in range(shake_steps):
			var random_offset = Vector2(
				randf_range(-intensity, intensity),
				randf_range(-intensity, intensity)
			)
			
			# Reduce intensity over time
			random_offset *= 1.0 - (float(i) / shake_steps)
			
			tween.tween_property(camera, "offset", original_offset + random_offset, time_per_step)
		
		# Reset to original position
		tween.tween_property(camera, "offset", original_offset, time_per_step)
