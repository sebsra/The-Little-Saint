class_name SackOfGold
extends Area2D
# sack_of_gold-spezifische Eigenschaften
var power_up_name: String = "Sack of Gold"
var description: String = "+100 Coins"
var destroy_on_pickup: bool = false  # Changed to false so it follows instead

# Animationsparameter
var bounce_height: float = 6.0
var bounce_speed: float = 2.0
# Variablen für Animation
var animation_time: float = 0.0
var spawn_position: Vector2
var is_position_initialized: bool = false

# Variablen für das Folgen des Spielers
var is_following: bool = false
var following_player = null
var follow_offset: Vector2 = Vector2(0, -30)  # Offset über dem Spieler
var follow_smoothing: float = 10.0  # Höhere Werte bedeuten glattere Bewegung

# Signale
signal sack_of_gold_collected(sack_of_gold, player)

func _ready():
	# Kollisionssignal verbinden
	body_entered.connect(_on_sack_of_gold_body_entered)
	
	# Warten auf nächsten Frame für korrekte Positionsinitialisierung
	call_deferred("_init_position")

func _init_position():
	# Auf einen Frame warten, um sicherzustellen, dass die Position korrekt ist
	await get_tree().process_frame
	spawn_position = global_position
	is_position_initialized = true

func _process(delta):
	if is_following and following_player:
		# Dem Spieler folgen mit einem Offset
		var target_position = following_player.global_position + follow_offset
		global_position = global_position.lerp(target_position, delta * follow_smoothing)
	# Nur animieren, wenn Position initialisiert wurde und nicht folgt
	elif is_position_initialized and not is_following:
		animate(delta)

func animate(delta):
	animation_time += delta
	
	# Bounce-Animation
	var bounce_offset = sin(animation_time * bounce_speed) * bounce_height
	global_position.y = spawn_position.y + bounce_offset
	
func _on_sack_of_gold_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		collect_sack_of_gold(body)

func collect_sack_of_gold(player):
	# Kollision deaktivieren
	set_collision_mask_value(1, false)
	
	# Signal senden
	emit_signal("sack_of_gold_collected", self, player)  # Korrigiert von "connected" zu "collected"
	
	# Gesundheit erhöhen
	apply_effect(player)
	
	# Dem Spieler folgen
	is_following = true
	following_player = player
	
	# Objekt zerstören, falls gewünscht
	if destroy_on_pickup:
		queue_free()

func apply_effect(player):
	# Gesundheit erhöhen über GlobalHUD
	GlobalHUD.add_coins(100)
