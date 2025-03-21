class_name HUDController
extends CanvasLayer

## A modular HUD manager that handles in-game UI elements
## Supports various gameplay elements like health, coins, and power-ups

# Health system variables
@export var max_health: float = 3.0
@export var initial_health: float = 3.0
var current_health: float = 3.0

# Legacy properties and accessor methods
func get_lifes() -> float:
	return current_health
	
func set_lifes(value: float) -> void:
	current_health = value
	_update_health_display()

# Make sure legacy code can access lifes directly
var lifes: float:
	get: return get_lifes()
	set(value): set_lifes(value)

# Currency/Collectible tracking
var coins: int = 0

# Power-up and ability tracking
var elixir_fill_level: float = 0.0
var active_power_ups: Array = []
var power_up_timers: Dictionary = {}

# HUD Components reference
@onready var health_display = $HeartsFull
@onready var coins_label = $LabelCoinSum
@onready var elixir_container = $bottle
@onready var elixir_fill = $elixir

# Optional components
@onready var objective_display = $ObjectiveTracker if has_node("ObjectiveTracker") else null
@onready var ability_timer_display = $AbilityTimer if has_node("AbilityTimer") else null

# Notification components
@onready var notification_container = $NotificationContainer if has_node("NotificationContainer") else null

# UI Theme reference
var ui_theme = null

# Signals
signal health_changed(new_health, max_health)
signal coins_changed(new_amount)
signal elixir_changed(new_level)
signal power_up_activated(power_up_name, duration)
signal power_up_deactivated(power_up_name)
signal objective_updated(objective_id, progress, total)
signal notification_shown(message, type)

func _ready():
	# Initialize health display
	current_health = initial_health
	lifes = current_health  # Update legacy property
	
	if health_display:
		_update_health_display()
	
	# Initialize coins display
	if coins_label:
		coins_label.text = str(coins)
	
	# Initialize elixir display
	if elixir_container and elixir_fill:
		set_elixir_fill(elixir_fill_level)
	
	# Get UI theme if available
	ui_theme = get_node_or_null("/root/UITheme")
	if ui_theme:
		_apply_theme()
		ui_theme.theme_changed.connect(_on_theme_changed)
	
	# Connect to game manager if available
	var game_manager = get_node_or_null("/root/Global")
	if game_manager:
		game_manager.coin_collected.connect(_on_global_coin_collected)
		game_manager.state_changed.connect(_on_game_state_changed)

func _process(delta):
	# Update power-up timers
	for power_up_name in power_up_timers.keys():
		var timer_data = power_up_timers[power_up_name]
		timer_data.time_remaining -= delta
		
		# Update UI timer if available
		if ability_timer_display:
			ability_timer_display.update_timer(power_up_name, timer_data.time_remaining, timer_data.duration)
		
		# Check if power-up has expired
		if timer_data.time_remaining <= 0:
			_on_power_up_expired(power_up_name)

# Health Management
func set_max_health(new_max: float) -> void:
	max_health = max(1.0, new_max)
	current_health = min(current_health, max_health)
	_update_health_display()
	emit_signal("health_changed", current_health, max_health)

func change_health(amount: float) -> void:
	var old_health = current_health
	current_health = clamp(current_health + amount, 0, max_health)
	
	if current_health != old_health:
		_update_health_display()
		emit_signal("health_changed", current_health, max_health)
		
		# Handle death
		if current_health <= 0:
			_on_player_death()
		# Handle healing effects
		elif amount > 0:
			_show_healing_effect()
		# Handle damage effects
		elif amount < 0:
			_show_damage_effect()

func _update_health_display() -> void:
	if health_display:
		# Scale heart display based on current health
		health_display.size.x = (current_health / max_health) * health_display.texture.get_width()

# Coin Management
func add_coins(amount: int = 1) -> void:
	coins += amount
	if coins_label:
		coins_label.text = str(coins)
	emit_signal("coins_changed", coins)
	
	# Show collection effect
	if amount > 0:
		_show_coin_collect_effect()

func set_coins(amount: int) -> void:
	coins = max(0, amount)
	if coins_label:
		coins_label.text = str(coins)
	emit_signal("coins_changed", coins)

# Elixir/Power Meter Management
func set_elixir_fill(fill_level: float) -> void:
	elixir_fill_level = clamp(fill_level, 0.0, 1.0)
	
	if elixir_fill and elixir_container:
		# Update the visual representation
		_update_elixir_display()
	
	emit_signal("elixir_changed", elixir_fill_level)

func update_elixir_fill(amount: float) -> void:
	set_elixir_fill(elixir_fill_level + amount)

func collect_softpower(amount: float = 0.25) -> void:
	update_elixir_fill(amount)
	# Show collection effect
	_show_elixir_collect_effect()

func use_softpower(amount: float = 0.25) -> bool:
	if elixir_fill_level >= amount:
		update_elixir_fill(-amount)
		return true
	return false

func _update_elixir_display() -> void:
	var elixir = elixir_fill
	var bottle = elixir_container
	
	# Enable region clipping for partial display
	elixir.region_enabled = true
	
	# Get texture size (unscaled)
	var tex_size = elixir.texture.get_size()
	
	# Calculate visible height based on fill level
	var visible_height = tex_size.y * elixir_fill_level
	
	# Set the region rect (clip from bottom)
	elixir.region_rect = Rect2(
		Vector2(0, tex_size.y - visible_height),
		Vector2(tex_size.x, visible_height)
	)
	
	# Position the fill inside the bottle
	var bottle_texture_size = bottle.texture.get_size()
	var elixir_texture_size = elixir.texture.get_size()
	
	var bottle_scale = bottle.scale
	var elixir_scale = elixir.scale
	
	var bottle_size = bottle_texture_size.y * bottle_scale.y
	var elixir_size = visible_height * elixir_scale.y
	
	# Center the elixir horizontally and position it at the bottom of bottle
	elixir.position.x = bottle.position.x
	elixir.position.y = bottle.position.y + ((bottle_size - elixir_size) / 2)

# Power-up Management
func activate_power_up(name: String, duration: float = 0.0) -> void:
	# Add to active power-ups
	if not active_power_ups.has(name):
		active_power_ups.append(name)
	
	# Set up timer if it has a duration
	if duration > 0:
		power_up_timers[name] = {
			"duration": duration,
			"time_remaining": duration
		}
		
		# Show timer UI if available
		if ability_timer_display:
			ability_timer_display.show_timer(name, duration)
	
	emit_signal("power_up_activated", name, duration)
	
	# Show activation effect
	_show_power_up_effect(name)

func deactivate_power_up(name: String) -> void:
	if active_power_ups.has(name):
		active_power_ups.erase(name)
	
	if power_up_timers.has(name):
		power_up_timers.erase(name)
		
		# Hide timer UI if available
		if ability_timer_display:
			ability_timer_display.hide_timer(name)
	
	emit_signal("power_up_deactivated", name)

func has_power_up(name: String) -> bool:
	return active_power_ups.has(name)

func get_power_up_remaining_time(name: String) -> float:
	if power_up_timers.has(name):
		return power_up_timers[name].time_remaining
	return 0.0

func _on_power_up_expired(name: String) -> void:
	deactivate_power_up(name)
	_show_power_up_expiry_effect(name)

# Objective System
func update_objective(objective_id: String, progress: int, total: int, description: String = "") -> void:
	if objective_display:
		objective_display.update_objective(objective_id, progress, total, description)
	
	emit_signal("objective_updated", objective_id, progress, total)

func complete_objective(objective_id: String) -> void:
	if objective_display:
		objective_display.complete_objective(objective_id)
	
	emit_signal("objective_updated", objective_id, 1, 1)
	
	# Show completion effect
	_show_objective_complete_effect()

func add_objective(objective_id: String, description: String, total: int = 1) -> void:
	if objective_display:
		objective_display.add_objective(objective_id, description, total)
	
	emit_signal("objective_updated", objective_id, 0, total)
	
	# Show new objective effect
	_show_new_objective_effect()

# Notification System
func show_notification(message: String, type: String = "info", duration: float = 3.0) -> void:
	if notification_container:
		notification_container.show_notification(message, type, duration)
	
	emit_signal("notification_shown", message, type)

# Visual Effects
func _show_damage_effect() -> void:
	# Simple screen flash for now
	var canvas_modulate = get_node_or_null("DamageEffect")
	if canvas_modulate:
		var tween = create_tween()
		canvas_modulate.color = Color(1, 0, 0, 0.3)
		canvas_modulate.visible = true
		tween.tween_property(canvas_modulate, "color:a", 0.0, 0.5)
		tween.tween_callback(func(): canvas_modulate.visible = false)

func _show_healing_effect() -> void:
	# Simple green flash for healing
	var canvas_modulate = get_node_or_null("HealEffect")
	if canvas_modulate:
		var tween = create_tween()
		canvas_modulate.color = Color(0, 1, 0, 0.3)
		canvas_modulate.visible = true
		tween.tween_property(canvas_modulate, "color:a", 0.0, 0.5)
		tween.tween_callback(func(): canvas_modulate.visible = false)

func _show_coin_collect_effect() -> void:
	# Animate the coin counter
	if coins_label:
		var tween = create_tween()
		tween.tween_property(coins_label, "modulate", Color(1, 1, 0, 1), 0.1)
		tween.tween_property(coins_label, "modulate", Color(1, 1, 1, 1), 0.2)

func _show_elixir_collect_effect() -> void:
	# Flash the elixir
	if elixir_fill:
		var tween = create_tween()
		tween.tween_property(elixir_fill, "modulate", Color(1.5, 1.5, 1.5, 1), 0.1)
		tween.tween_property(elixir_fill, "modulate", Color(1, 1, 1, 1), 0.2)

func _show_power_up_effect(power_up_name: String) -> void:
	# This could be customized per power-up
	show_notification("Power-up activated: " + power_up_name, "power_up")

func _show_power_up_expiry_effect(power_up_name: String) -> void:
	show_notification("Power-up expired: " + power_up_name, "warning")

func _show_objective_complete_effect() -> void:
	show_notification("Objective completed!", "success")

func _show_new_objective_effect() -> void:
	show_notification("New objective added", "info")

# Theme management
func _apply_theme() -> void:
	if ui_theme:
		# Apply theme to various HUD elements
		if coins_label:
			coins_label.add_theme_color_override("font_color", ui_theme.get_color("accent"))
		
		# Add more theme customizations as needed
		pass

func _on_theme_changed(theme_name: String) -> void:
	_apply_theme()

# Event handlers
func _on_player_death() -> void:
	var game_manager = get_node_or_null("/root/Global")
	if game_manager:
		game_manager.player_death()

func _on_global_coin_collected(_total_coins) -> void:
	# Update HUD to match global state
	set_coins(get_node("/root/Global").collected_coins)

func _on_game_state_changed(new_state, _old_state) -> void:
	# Adjust HUD visibility based on game state
	if new_state == Constants.GameState.PAUSED:
		# Find the container to adjust visibility
		var container = get_node_or_null("Container")
		if container:
			container.modulate.a = 0.5
	else:
		var container = get_node_or_null("Container")
		if container:
			container.modulate.a = 1.0

# Legacy API for backward compatibility
func change_life(amount: float) -> void:
	change_health(amount)

func load_hearts() -> void:
	_update_health_display()

func coin_collected() -> void:
	add_coins(1)

func _update_coin_display() -> void:
	if coins_label:
		coins_label.text = str(coins)
