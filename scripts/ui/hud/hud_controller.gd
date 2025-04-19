class_name HUDController
extends CanvasLayer

# HUD Components reference
@onready var hearts_full = $HeartsFull
@onready var coins_label = $LabelCoinSum
@onready var x_label = $x
@onready var normal_coin = $Coin
@onready var heaven_coin = $HeavenCoin
@onready var bottle = $bottle
@onready var elixir_fill = $elixir
@onready var initial_heart_size = $HeartsFull.size
@onready var initial_heart_position = $HeartsFull.position
@onready var message_display = $MessageDisplay if has_node("MessageDisplay") else null

# Optional components
@onready var objective_display = $ObjectiveTracker if has_node("ObjectiveTracker") else null
@onready var ability_timer_display = $AbilityTimer if has_node("AbilityTimer") else null
@onready var notification_container = $NotificationContainer if has_node("NotificationContainer") else null

# Colors for different coin types
var normal_coin_color = Color(1, 0.776471, 0, 1)  # Current gold color
var heaven_coin_color = Color(0, 0.5, 1, 1)       # Blue color for heavenly coins

# Message variables
var message_queue = []
var is_showing_message = false

signal coin_removal_completed

# UI Theme reference
var ui_theme = null

func _ready():
	# Initialize UI theme
	ui_theme = get_node_or_null("/root/UITheme")
	if ui_theme:
		_apply_theme()
		ui_theme.theme_changed.connect(_on_theme_changed)
	
	# Register with GlobalHUD
	if get_node_or_null("/root/GlobalHUD"):
		GlobalHUD.register_hud(self)
		
		# Connect to GlobalHUD signals
		GlobalHUD.health_changed.connect(_on_global_health_changed)
		GlobalHUD.coins_changed.connect(_on_global_coins_changed)
		GlobalHUD.heaven_coins_changed.connect(_on_global_heaven_coins_changed)
		GlobalHUD.elixir_changed.connect(_on_global_elixir_changed)
		GlobalHUD.power_up_activated.connect(_on_global_power_up_activated)
		GlobalHUD.power_up_deactivated.connect(_on_global_power_up_deactivated)
		GlobalHUD.new_message.connect(_on_global_new_message)
		
	# Initialize coin display based on current type
	update_coin_type_display()

# --- VISUAL UPDATE METHODS ---
# These don't modify game state, only update the visual representation

func update_health_display(current_health: float, max_health: float) -> void:
	if hearts_full:
		hearts_full.size.x = current_health * initial_heart_size.x
		hearts_full.position.x = initial_heart_position.x - ((current_health-1) * initial_heart_size.x)

func update_coins_display(amount: int) -> void:
	if coins_label:
		coins_label.text = str(amount)

func update_coin_type_display() -> void:
	if get_node_or_null("/root/Global"):
		# Show the appropriate coin texture based on current type
		var is_heavenly = Global.current_coin_type == Global.CoinType.HEAVENLY
		
		# Update visibility
		if heaven_coin:
			heaven_coin.visible = is_heavenly
		if normal_coin:
			normal_coin.visible = !is_heavenly
		
		# Update colors
		var coin_color = heaven_coin_color if is_heavenly else normal_coin_color
		if coins_label:
			coins_label.add_theme_color_override("font_color", coin_color)
		if x_label:
			x_label.add_theme_color_override("font_color", coin_color)

func update_elixir_display(fill_level: float) -> void:
	if elixir_fill and bottle:
		# Enable region clipping for partial display
		elixir_fill.region_enabled = true
		
		# Get texture size (unscaled)
		var tex_size = elixir_fill.texture.get_size()
		
		# Calculate visible height based on fill level
		var visible_height = tex_size.y * fill_level
		
		# Set the region rect (clip from bottom)
		elixir_fill.region_rect = Rect2(
			Vector2(0, tex_size.y - visible_height),
			Vector2(tex_size.x, visible_height)
		)
		
		# Position the fill inside the bottle
		var bottle_texture_size = bottle.texture.get_size()
		var elixir_texture_size = elixir_fill.texture.get_size()
		
		var bottle_scale = bottle.scale
		var elixir_scale = elixir_fill.scale
		
		var bottle_size = bottle_texture_size.y * bottle_scale.y
		var elixir_size = visible_height * elixir_scale.y
		
		# Center the elixir horizontally and position it at the bottom of bottle
		elixir_fill.position.x = bottle.position.x
		elixir_fill.position.y = bottle.position.y + ((bottle_size - elixir_size) / 2)

func update_power_up_display(power_up_name: String, duration: float) -> void:
	if ability_timer_display:
		ability_timer_display.show_timer(power_up_name, duration)

func hide_power_up_display(power_up_name: String) -> void:
	if ability_timer_display:
		ability_timer_display.hide_timer(power_up_name)

# --- MESSAGE DISPLAY SYSTEM ---

func show_message(text: String, duration: float = 5.0, color: Color = Color.WHITE) -> void:
	# Add message to queue
	message_queue.append({
		"text": text,
		"duration": duration,
		"color": color
	})
	
	# Start displaying messages if not already showing
	if !is_showing_message:
		_process_next_message()
		
func _process_next_message() -> void:
	if message_queue.size() == 0:
		is_showing_message = false
		return
	
	is_showing_message = true
	var message_data = message_queue.pop_front()
	
	# Get references to our nodes
	var message_container = $MessageContainer
	var message_display = $MessageContainer/MessageDisplay
	
	if message_container and message_display:
		# Set text and color
		message_display.text = message_data.text
		message_display.add_theme_color_override("font_color", message_data.color)
		
		# Make sure everything is visible
		message_container.visible = true
		message_display.visible = true
		
		# Reset scroll position
		message_container.scroll_horizontal = 0
		
		# Calculate scroll limits
		var max_scroll = message_display.size.x - message_container.size.x
		if max_scroll > 0:
			# Create tween for scrolling
			var tween = create_tween()
			var scroll_duration = message_data.duration * 0.8
			
			# Scroll the container from left to right
			tween.tween_property(message_container, "scroll_horizontal", max_scroll, scroll_duration)
			
			# Once complete, hide and process next message
			await tween.finished
		else:
			# For short messages, just display for the duration
			await get_tree().create_timer(message_data.duration).timeout
		
		# Hide the container
		message_container.visible = false
		
		# Small delay before next message
		await get_tree().create_timer(0.5).timeout
		
		# Process next message
		_process_next_message()
func clear_messages() -> void:
	message_queue.clear()
	if message_display:
		message_display.visible = false
	is_showing_message = false

# --- VISUAL EFFECTS ---

func play_damage_effect() -> void:
	var canvas_modulate = get_node_or_null("DamageEffect")
	if canvas_modulate:
		var tween = create_tween()
		canvas_modulate.color = Color(1, 0, 0, 0.3)
		canvas_modulate.visible = true
		tween.tween_property(canvas_modulate, "color:a", 0.0, 0.5)
		tween.tween_callback(func(): canvas_modulate.visible = false)

func play_healing_effect() -> void:
	var canvas_modulate = get_node_or_null("HealEffect")
	if canvas_modulate:
		var tween = create_tween()
		canvas_modulate.color = Color(0, 1, 0, 0.3)
		canvas_modulate.visible = true
		tween.tween_property(canvas_modulate, "color:a", 0.0, 0.5)
		tween.tween_callback(func(): canvas_modulate.visible = false)

func play_coin_effect() -> void:
	if coins_label:
		var tween = create_tween()
		# Get appropriate highlight color based on current coin type
		var highlight_color = Color(1, 1, 0, 1)  # Default yellow flash
		if get_node_or_null("/root/Global") and Global.current_coin_type == Global.CoinType.HEAVENLY:
			highlight_color = Color(0.5, 0.8, 1, 1)  # Blue-ish flash for heavenly
		
		tween.tween_property(coins_label, "modulate", highlight_color, 0.1)
		tween.tween_property(coins_label, "modulate", Color(1, 1, 1, 1), 0.2)

func play_elixir_effect() -> void:
	if elixir_fill:
		var tween = create_tween()
		tween.tween_property(elixir_fill, "modulate", Color(1.5, 1.5, 1.5, 1), 0.1)
		tween.tween_property(elixir_fill, "modulate", Color(1, 1, 1, 1), 0.2)

# --- SIGNAL HANDLERS ---

func _on_global_health_changed(new_health, _max_health):
	update_health_display(new_health, _max_health)

func _on_global_coins_changed(new_amount):
	update_coins_display(new_amount)
	
func _on_global_heaven_coins_changed(new_amount):
	# If current coin type is heavenly, update the display
	if get_node_or_null("/root/Global") and Global.current_coin_type == Global.CoinType.HEAVENLY:
		update_coins_display(new_amount)

func _on_global_elixir_changed(new_level):
	update_elixir_display(new_level)

func _on_global_power_up_activated(power_up_name, duration):
	update_power_up_display(power_up_name, duration)

func _on_global_power_up_deactivated(power_up_name):
	hide_power_up_display(power_up_name)

func _on_global_new_message(text, duration, color):
	show_message(text, duration, color)

func _on_theme_changed(_theme_name):
	_apply_theme()

func _apply_theme() -> void:
	if ui_theme:
		# Apply theme to various HUD elements, but preserve coin type coloring
		update_coin_type_display()
			
func animate_coin_removal() -> void:
	var coin_to_animate = normal_coin if normal_coin.visible else heaven_coin
	var x_node = $x
	var label_coin_sum = $LabelCoinSum
	
	# Originalwerte speichern
	var original_scale = coin_to_animate.scale
	var original_position = coin_to_animate.position
	var original_modulate = coin_to_animate.modulate
	
	# Andere UI-Elemente ausblenden
	x_node.visible = false
	label_coin_sum.visible = false
	
	# Bildschirmmitte berechnen
	var viewport_size = get_viewport().size
	var center_position = Vector2(viewport_size.x / 2, viewport_size.y / 2) - Vector2(100, 100)
	
	# SCHRITT 1: Münze in einer Kurve zur Mitte bewegen
	var move_tween = create_tween()
	
	# Bezier-Kurve mit Kontrollpunkten erstellen für gebogene Bewegung
	var start_pos = coin_to_animate.position
	var end_pos = center_position
	var control_point = Vector2(
		start_pos.x + (end_pos.x - start_pos.x) * 0.5,
		start_pos.y - 150 # Höherer Bogen
	)
	
	# Bewegung entlang der Kurve (in mehreren Schritten für eine glattere Kurve)
	move_tween.tween_method(
		func(t: float):
			# Bezier-Kurvenberechnung
			var pos = start_pos.lerp(control_point, t).lerp(control_point.lerp(end_pos, t), t)
			coin_to_animate.position = pos
				,
				0.0,
				1.0,
				2.0
			).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	# SCHRITT 2: Nach Erreichen der Mitte gleichzeitig wachsen, vibrieren und dunkler werden
	await move_tween.finished
	
	var grow_tween = create_tween().set_parallel(true)
	
	# Münze auf 4x wachsen lassen mit Wackeleffekt - langsamer am Anfang
	var final_scale = original_scale * 4.0
	
	# Wachstumsanimation mit Wackeln - EASE_IN für langsameren Start
	grow_tween.tween_property(coin_to_animate, "scale:x", final_scale.x * 1.2, 4.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_ELASTIC)
	grow_tween.tween_property(coin_to_animate, "scale:y", final_scale.y * 0.9, 4.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_ELASTIC)
	
	# Gleichzeitig die Münze dunkler werden lassen (auf 80% Dunkelheit)
	var dark_color = Color(original_modulate.r * 0.2, original_modulate.g * 0.2, 
						  original_modulate.b * 0.2, original_modulate.a)
	grow_tween.tween_property(coin_to_animate, "modulate", dark_color, 4.0).set_ease(Tween.EASE_IN)
	
	# Vibrationseffekt während des Wachstums - intensiver und früher beginnend
	for i in range(40): # Mehr Vibrationen für intensiveren Effekt
		var vibration_time = 0.1
		var vibration_strength = 2.0 + i * 0.2 # Stärker werdende Vibration
		var delay_time = i * 0.1 # Engere Abstände für schnelleres Vibrieren
		
		# Zufällige Richtung für jede Vibration
		var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * vibration_strength
		
		# Sub-Tween für jede Vibration erstellen
		var vibration_tween = create_tween()
		vibration_tween.set_parallel(false)
		vibration_tween.tween_property(coin_to_animate, "position", center_position + random_direction, vibration_time / 2.0).set_delay(delay_time)
		vibration_tween.tween_property(coin_to_animate, "position", center_position, vibration_time / 2.0)
	
	# SCHRITT 3: Nach Wachstum und Verdunkelung, Partikel erstellen und Münze entfernen
	await grow_tween.finished
	
	# Endposition der Münze für genaue Partikelplatzierung speichern
	var final_coin_position = coin_to_animate.global_position
	var final_coin_size = Vector2(coin_to_animate.texture.get_width() * coin_to_animate.scale.x, 
								 coin_to_animate.texture.get_height() * coin_to_animate.scale.y)
	
	# Partikeleffekt AN DER EXAKTEN POSITION der Münze erstellen
	var particles = GPUParticles2D.new()
	add_child(particles)
	particles.global_position = final_coin_position + (final_coin_size / 2)
	
	# Partikelsystem mit VIEL MEHR Partikeln einrichten
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 150.0  # Größerer Radius
	particle_material.direction = Vector3(0, 0, 0)    # In alle Richtungen emittieren
	particle_material.spread = 180.0
	particle_material.initial_velocity_min = 200.0    # Schnellere Partikel
	particle_material.initial_velocity_max = 500.0    # Viel höhere Maximalgeschwindigkeit
	particle_material.gravity = Vector3(0, 100, 0)    # Weniger Schwerkraft für längere Flugzeit
	particle_material.damping_min = 5.0               # Verlangsamen mit der Zeit
	particle_material.damping_max = 10.0
	particle_material.scale_min = 3.0                 # Größere Partikel
	particle_material.scale_max = 8.0
	particle_material.color = Color(0, 0, 0, 1)       # Schwarze Partikel
	
	# Korrektur für Farbverlauf - Gradient in Godot 4 richtig erstellen
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.1, 0.1, 0.1, 1.0),
		Color(0.05, 0.05, 0.05, 0.9),
		Color(0, 0, 0, 0.7),
		Color(0, 0, 0, 0)
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	particle_material.color_ramp = gradient_texture
	
	particles.process_material = particle_material
	particles.amount = 500                            # VIEL MEHR Partikel
	particles.lifetime = 3.0                          # Längere Lebensdauer
	particles.one_shot = true
	particles.explosiveness = 0.95                    # Explosiver
	
	# Münze unmittelbar vor dem Emittieren von Partikeln ausblenden
	coin_to_animate.visible = false
	
	# Partikel starten
	particles.emitting = true
	
	# Partikel entfernen, nachdem sie fertig sind
	await get_tree().create_timer(particles.lifetime + 0.5).timeout
	particles.queue_free()
	
	# Signal, dass die Animation abgeschlossen ist
	coin_removal_completed.emit()

# Function to animate the appearance of the heavenly coin
func animate_heavenly_coin_appearance() -> void:
	# Get the center position where the explosion occurred
	var viewport_size = get_viewport().size
	var center_position = Vector2(viewport_size.x / 2, viewport_size.y / 2) - Vector2(100, 100)
	
	# Hide the normal coin and x label temporarily
	normal_coin.visible = false
	x_label.visible = false
	coins_label.visible = false
	
	# Setup the heavenly coin at the explosion point
	heaven_coin.position = center_position
	heaven_coin.scale = Vector2(1.2, 0.9) * 4.0  # Same size as the normal coin at explosion
	heaven_coin.modulate = Color(1, 1, 1, 0)     # Fully transparent
	heaven_coin.visible = true
	
	# STEP 1: Fade in the heavenly coin at center
	var fade_tween = create_tween()
	fade_tween.tween_property(heaven_coin, "modulate", Color(1, 1, 1, 1), 1.0)
	
	await fade_tween.finished
	
	# STEP 2: Shrink the coin to final size
	var final_position = Vector2(925.0, 58.0)    # Original position from TSCN file
	var final_scale = Vector2(0.3, 0.3)          # Original scale from TSCN file
	
	var shrink_tween = create_tween()
	shrink_tween.tween_property(heaven_coin, "scale", final_scale, 1.5).set_ease(Tween.EASE_IN_OUT)
	
	await shrink_tween.finished
	
	# STEP 3: Move to final position and show the labels
	var move_tween = create_tween().set_parallel(true)
	move_tween.tween_property(heaven_coin, "position", final_position, 1.0).set_ease(Tween.EASE_IN_OUT)
	
	await move_tween.finished
	
	# STEP 4: Officially switch to heavenly coin mode and show everything
	switch_coin_type(true)
	x_label.visible = true
	coins_label.visible = true
	
	# Show a message about the coin type change
	if get_node_or_null("/root/GlobalHUD"):
		GlobalHUD.add_message("Heavenly Coins Activated!", 3.0, heaven_coin_color)

# Function to handle the complete transition from normal to heavenly coins
func transition_to_heavenly_coins() -> void:
	# First animate the removal of the current coin
	var on_completed = func():
		animate_heavenly_coin_appearance()
	
	# Connect the signal for this transition only
	if coin_removal_completed.is_connected(on_completed):
		coin_removal_completed.disconnect(on_completed)
	
	coin_removal_completed.connect(on_completed, CONNECT_ONE_SHOT)
	
	# Start the animation sequence
	animate_coin_removal()

# Function to switch between coin types
func switch_coin_type(to_heavenly: bool) -> void:
	if get_node_or_null("/root/Global"):
		# Set the appropriate coin type in the Global singleton
		Global.current_coin_type = Global.CoinType.HEAVENLY if to_heavenly else Global.CoinType.NORMAL
		
		# Update the display
		update_coin_type_display()
		
		# Play a short transition effect if desired
		var tween = create_tween()
		var target_color = heaven_coin_color if to_heavenly else normal_coin_color
		
		if coins_label:
			tween.tween_property(coins_label, "modulate", Color(1.5, 1.5, 1.5, 1), 0.2)
			tween.tween_property(coins_label, "modulate", Color(1, 1, 1, 1), 0.2)
		
		if x_label:
			tween.tween_property(x_label, "modulate", Color(1.5, 1.5, 1.5, 1), 0.2)
			tween.tween_property(x_label, "modulate", Color(1, 1, 1, 1), 0.2)

# --- LEGACY API (Forwards to GlobalHUD) ---

func set_lifes(value: float) -> void:
	if get_node_or_null("/root/GlobalHUD"):
		var change_amount = value - GlobalHUD.current_health
		GlobalHUD.change_health(change_amount)

func get_lifes() -> float:
	if get_node_or_null("/root/GlobalHUD"):
		return GlobalHUD.current_health
	return 0.0

var lifes: float:
	get: return get_lifes()
	set(value): set_lifes(value)

func change_life(amount: float) -> void:
	if get_node_or_null("/root/GlobalHUD"):
		GlobalHUD.change_health(amount)

func change_health(amount: float) -> void:
	if get_node_or_null("/root/GlobalHUD"):
		GlobalHUD.change_health(amount)

func add_coins(amount: int = 1) -> void:
	if get_node_or_null("/root/GlobalHUD"):
		# Add to the appropriate counter based on current coin type
		if get_node_or_null("/root/Global") and Global.current_coin_type == Global.CoinType.HEAVENLY:
			GlobalHUD.add_heaven_coins(amount)
		else:
			GlobalHUD.add_coins(amount)
		
func set_coins(amount: int) -> void:
	if get_node_or_null("/root/GlobalHUD"):
		# Set the appropriate counter based on current coin type
		if get_node_or_null("/root/Global") and Global.current_coin_type == Global.CoinType.HEAVENLY:
			GlobalHUD.set_heaven_coins(amount)
		else:
			GlobalHUD.set_coins(amount)
		
func coin_collected() -> void:
	if get_node_or_null("/root/GlobalHUD"):
		# Add to the appropriate counter based on current coin type
		if get_node_or_null("/root/Global") and Global.current_coin_type == Global.CoinType.HEAVENLY:
			GlobalHUD.heaven_coin_collected()
		else:
			GlobalHUD.coin_collected()

func set_elixir_fill(level: float) -> void:
	if get_node_or_null("/root/GlobalHUD"):
		GlobalHUD.update_elixir_fill(level - GlobalHUD.elixir_fill_level)

func collect_softpower(amount: float = 0.25) -> void:
	if get_node_or_null("/root/GlobalHUD"):
		GlobalHUD.collect_softpower(amount)
