class_name Heart
extends Area2D

# Heart-spezifische Eigenschaften
var power_up_name: String = "Heart"
var description: String = "+1 Health"
var destroy_on_pickup: bool = true

# Animationsparameter
var bounce_height: float = 6.0
var bounce_speed: float = 2.0
var rotation_speed: float = 1.0

# Variablen für Animation
var animation_time: float = 0.0
var spawn_position: Vector2
var is_position_initialized: bool = false

# Signale
signal heart_collected(heart, player)

func _ready():
	# Kollisionssignal verbinden
	body_entered.connect(_on_heart_body_entered)
	
	# Warten auf nächsten Frame für korrekte Positionsinitialisierung
	call_deferred("_init_position")

func _init_position():
	# Auf einen Frame warten, um sicherzustellen, dass die Position korrekt ist
	await get_tree().process_frame
	spawn_position = global_position
	is_position_initialized = true

func _process(delta):
	# Nur animieren, wenn Position initialisiert wurde
	if is_position_initialized:
		animate(delta)

func animate(delta):
	animation_time += delta
	
	# Bounce-Animation
	var bounce_offset = sin(animation_time * bounce_speed) * bounce_height
	global_position.y = spawn_position.y + bounce_offset
	
	# Rotations-Animation
	if rotation_speed > 0 and has_node("Sprite2D"):
		var sprite = get_node("Sprite2D")
		sprite.rotation += rotation_speed * delta

func _on_heart_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		collect_heart(body)

func collect_heart(player):
	# Kollision deaktivieren
	set_collision_mask_value(1, false)
	
	# Signal senden
	emit_signal("heart_collected", self, player)
	
	# Einsammel-Animation abspielen, falls vorhanden
	if has_node("AnimationPlayer"):
		var anim_player = get_node("AnimationPlayer")
		if anim_player.has_animation("collect"):
			anim_player.play("collect")
			await anim_player.animation_finished
	
	# Gesundheit erhöhen
	apply_effect(player)
	
	# Objekt zerstören, falls gewünscht
	if destroy_on_pickup:
		queue_free()

func apply_effect(player):
	# Gesundheit erhöhen über GlobalHUD
	GlobalHUD.change_life(1.0)
