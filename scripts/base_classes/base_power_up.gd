class_name BasePowerUp
extends Area2D

## Base class for all power-ups in the game

# Power-up properties
@export var power_up_name: String = "Power Up"
@export var description: String = "A mysterious power-up"
@export var icon_texture: Texture2D
@export var effect_duration: float = 0.0  # 0 means permanent effect
@export var play_animation: bool = true
@export var destroy_on_pickup: bool = true

# Animation
@export var bounce_height: float = 5.0
@export var bounce_speed: float = 2.0
@export var rotation_speed: float = 0.0

# Internal variables
var original_position: Vector2
var animation_time: float = 0.0
var player_ref = null

# Signals
signal power_up_collected(power_up, player)
signal power_up_effect_started(power_up, player)
signal power_up_effect_ended(power_up, player)

func _ready():
	original_position = global_position
	
	# Set up collision
	if not has_node("CollisionShape2D"):
		push_error("Power-up " + name + " has no CollisionShape2D!")
	
	# Set up sprite/animation if enabled
	if play_animation and has_node("Sprite2D"):
		var sprite = get_node("Sprite2D")
		if icon_texture:
			sprite.texture = icon_texture
	
	# Connect signals
	body_entered.connect(_on_power_up_body_entered)

func _process(delta):
	if play_animation:
		animate_power_up(delta)

func animate_power_up(delta):
	animation_time += delta
	
	# Bouncing animation
	if bounce_height > 0:
		var bounce_offset = sin(animation_time * bounce_speed) * bounce_height
		global_position.y = original_position.y + bounce_offset
	
	# Rotation animation
	if rotation_speed > 0 and has_node("Sprite2D"):
		var sprite = get_node("Sprite2D")
		sprite.rotation += rotation_speed * delta

func _on_power_up_body_entered(body):
	if body.is_in_group("Player") or body.name == "Player":
		collect_power_up(body)

func collect_power_up(player):
	# Store reference to player
	player_ref = player
	
	# Disable collision
	set_collision_mask_value(1, false)
	
	# Emit collected signal
	emit_signal("power_up_collected", self, player)
	
	# Play collection animation if available
	if has_node("AnimationPlayer"):
		var anim_player = get_node("AnimationPlayer")
		if anim_player.has_animation("collect"):
			anim_player.play("collect")
			await anim_player.animation_finished
		
	# Apply effect
	apply_effect(player)
	
	# Destroy if set
	if destroy_on_pickup:
		queue_free()

func apply_effect(player):
	# Base implementation just emits signal
	# Override in child classes to implement specific effects
	emit_signal("power_up_effect_started", self, player)
	
	# If temporary effect, setup timer to end effect
	if effect_duration > 0:
		await get_tree().create_timer(effect_duration).timeout
		remove_effect(player)

func remove_effect(player):
	# Override in child classes to implement specific effect removal
	emit_signal("power_up_effect_ended", self, player)

# Optional methods for child classes to implement
func get_effect_description() -> String:
	return description

func get_icon() -> Texture2D:
	return icon_texture
