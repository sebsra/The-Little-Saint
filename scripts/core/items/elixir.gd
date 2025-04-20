class_name Elixir
extends Area2D

# Elixir-spezifische Eigenschaften
var power_up_name: String = "Magic Elixir"
var description: String = "Grants temporary flying ability"
var effect_duration: float = 5.0  # 5 Sekunden Flugzeit
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
signal power_up_collected(power_up, player)
signal power_up_effect_started(power_up, player)
signal power_up_effect_ended(power_up, player)

func _ready():
	# Kollisionssignal verbinden
	body_entered.connect(_on_elixir_body_entered)
	
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

func _on_elixir_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		collect_power_up(body)

func collect_power_up(player):
	# Kollision deaktivieren
	set_collision_mask_value(1, false)
	
	# Signal senden
	emit_signal("power_up_collected", self, player)
	
	# Einsammel-Animation abspielen, falls vorhanden
	if has_node("AnimationPlayer"):
		var anim_player = get_node("AnimationPlayer")
		if anim_player.has_animation("collect"):
			anim_player.play("collect")
			await anim_player.animation_finished
	
	# Effekt anwenden
	apply_effect(player)
	
	# Objekt zerstören, falls gewünscht
	if destroy_on_pickup:
		queue_free()

func apply_effect(player):
	# Effekt-Signal senden
	emit_signal("power_up_effect_started", self, player)
	
	# Spieler-Flugmodus aktivieren
	if player.has_method("set_movement_mode"):
		player.set_movement_mode("fly")
	else:
		player.mode = "fly"
	
	print("Player gained flight ability via Elixir")
	
	# HUD aktualisieren
	var hud = get_tree().get_root().find_child("HUD", true, false)
	if hud:
		hud.collect_softpower()  # Fügt 25% Elixier hinzu
	
	# Timer für Effektende starten, falls temporär
	if effect_duration > 0:
		# Timer im HUD anzeigen, falls verfügbar
		if hud and hud.has_method("show_ability_timer"):
			hud.show_ability_timer("Flight", effect_duration)
			
		await get_tree().create_timer(effect_duration).timeout
		remove_effect(player)

func remove_effect(player):
	# Spieler-Bewegungsmodus zurücksetzen
	if player.has_method("set_movement_mode"):
		player.set_movement_mode("normal")
	else:
		player.mode = "normal"
	
	player.passed_fly_time = 0.0
	
	# Benachrichtigung über Effektende
	var popup_manager = get_node_or_null("/root/PopupManager")
	if popup_manager:
		popup_manager.info("Elixir Expired", "The elixir's magic has worn off. You can't fly anymore.")
	
	# Effekt-Ende-Signal senden
	emit_signal("power_up_effect_ended", self, player)
