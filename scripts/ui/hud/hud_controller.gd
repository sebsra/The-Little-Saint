class_name HUDController
extends CanvasLayer

# HUD Components reference
@onready var hearts_full = $HeartsFull
@onready var coins_label = $LabelCoinSum
@onready var bottle = $bottle
@onready var elixir_fill = $elixir
@onready var initial_heart_size = $HeartsFull.size
@onready var initial_heart_position = $HeartsFull.position

# Optional components
@onready var objective_display = $ObjectiveTracker if has_node("ObjectiveTracker") else null
@onready var ability_timer_display = $AbilityTimer if has_node("AbilityTimer") else null
@onready var notification_container = $NotificationContainer if has_node("NotificationContainer") else null

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
		GlobalHUD.elixir_changed.connect(_on_global_elixir_changed)
		GlobalHUD.power_up_activated.connect(_on_global_power_up_activated)
		GlobalHUD.power_up_deactivated.connect(_on_global_power_up_deactivated)

# --- VISUAL UPDATE METHODS ---
# These don't modify game state, only update the visual representation

func update_health_display(current_health: float, max_health: float) -> void:
	if hearts_full:
		hearts_full.size.x = current_health * initial_heart_size.x
		hearts_full.position.x = initial_heart_position.x - ((current_health-1) * initial_heart_size.x)

func update_coins_display(amount: int) -> void:
	if coins_label:
		coins_label.text = str(amount)

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
		tween.tween_property(coins_label, "modulate", Color(1, 1, 0, 1), 0.1)
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

func _on_global_elixir_changed(new_level):
	update_elixir_display(new_level)

func _on_global_power_up_activated(power_up_name, duration):
	update_power_up_display(power_up_name, duration)

func _on_global_power_up_deactivated(power_up_name):
	hide_power_up_display(power_up_name)

func _on_theme_changed(_theme_name):
	_apply_theme()

func _apply_theme() -> void:
	if ui_theme:
		# Apply theme to various HUD elements
		if coins_label:
			coins_label.add_theme_color_override("font_color", ui_theme.get_color("accent"))

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
		GlobalHUD.add_coins(amount)

func set_coins(amount: int) -> void:
	if get_node_or_null("/root/GlobalHUD"):
		GlobalHUD.set_coins(amount)

func coin_collected() -> void:
	if get_node_or_null("/root/GlobalHUD"):
		GlobalHUD.coin_collected()

func set_elixir_fill(level: float) -> void:
	if get_node_or_null("/root/GlobalHUD"):
		GlobalHUD.update_elixir_fill(level - GlobalHUD.elixir_fill_level)

func collect_softpower(amount: float = 0.25) -> void:
	if get_node_or_null("/root/GlobalHUD"):
		GlobalHUD.collect_softpower(amount)
