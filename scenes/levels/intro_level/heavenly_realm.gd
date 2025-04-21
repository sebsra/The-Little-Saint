extends Node2D

# Referenzen zu Komponenten in der Szene
@onready var player = $Player
@onready var hud = $HUD

# Variablen für die Interaktion mit Screenshots
var screenshot_areas = []
var active_screenshot = null
var screenshot_displays = []
var coin_prefab = preload("res://scenes/core/items/heavenly_coin.tscn")  # Pfad zur heavenly_coin Szene

# Zustand der Szene
enum HeavenSceneState {INTRO, COINS_DISSOLVING, SHOWING_MEMORIES, EXPLORING, COMPLETED}
var current_state = HeavenSceneState.INTRO

# UI-Elemente
var dialog_panel: PanelContainer
var dialog_content: VBoxContainer
var intro_text: RichTextLabel
var continue_button: Button

# Theme-Ressourcen 
var heavenly_theme: Theme
var glow_shader: Shader
var glow_material: ShaderMaterial

# Screenshot-Kategorien und Informationen
var memory_categories = {
	"sword_collections": {
		"title": "Das Wort Gottes",
		"description": "Du hast das Schwert des Geistes erhalten, das Wort Gottes. Eine Waffe gegen die Mächte der Finsternis.",
		"position": Vector2(0.25, 0.4)  # Relative Positionierung (Prozent des Viewports)
	},
	"child_helped": {
		"title": "Barmherzigkeit",
		"description": "Was ihr getan habt einem meiner geringsten Brüder, das habt ihr mir getan. Deine Hilfe für das Kind bleibt unvergessen.",
		"position": Vector2(0.5, 0.4)  # Relative Positionierung (Prozent des Viewports)
	},
	"sack_drops": {
		"title": "Der abgelegte Mammon",
		"description": "Du hast erkannt, dass man nicht Gott und dem Mammon dienen kann. Du hast dich für das Höhere entschieden.",
		"position": Vector2(0.75, 0.4)  # Relative Positionierung (Prozent des Viewports)
	}
}

func _ready():
	# Initialisiere das Theme und Shader für himmlische Effekte
	setup_heavenly_visuals()
	
	# Boden richtig positionieren (falls er durch scale-Werte verschoben ist)
	adjust_floor_position()
	
	# Starte in der Intro-Phase
	# Warte einen Frame, damit Viewport-Größe korrekt initialisiert ist
	await get_tree().process_frame
	setup_intro_phase()
	
	# Debug-Informationen ausgeben
	print("HeavenlyRealm wurde initialisiert")
	print("Viewport-Größe: ", get_viewport_rect().size)

func _process(delta):
	# Keine Eingabeüberprüfung mehr nötig, da alles über Kollisionen läuft
	pass

# Initialisiere visuelle Elemente für himmlisches Erscheinungsbild
func setup_heavenly_visuals():
	# Theme erstellen
	heavenly_theme = Theme.new()
	
	# Shader für Glüheffekte erstellen
	glow_shader = Shader.new()
	glow_shader.code = """
	shader_type canvas_item;
	
	uniform vec4 glow_color : source_color = vec4(0.7, 0.8, 1.0, 0.5);
	uniform float glow_intensity : hint_range(0.0, 2.0) = 0.5;
	uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;
	
	void fragment() {
		vec4 current_color = texture(TEXTURE, UV);
		float pulse = (sin(TIME * pulse_speed) + 1.0) * 0.5 * glow_intensity;
		vec4 glow = glow_color * pulse;
		COLOR = mix(current_color, glow, glow.a * pulse);
	}
	"""
	
	glow_material = ShaderMaterial.new()
	glow_material.shader = glow_shader

# Richte die Intro-Phase mit Text ein
func setup_intro_phase():
	# Entferne alte Dialog-Panels falls vorhanden
	if dialog_panel != null and is_instance_valid(dialog_panel):
		dialog_panel.queue_free()
	
	# Erstelle ein Canvas Layer für UI-Elemente
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)
	
	# Verwende einen CenterContainer für perfekte Zentrierung
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(center_container)
	
	# Erstelle das Dialog-Panel mit schönem Styling - wird automatisch zentriert
	dialog_panel = PanelContainer.new()
	dialog_panel.custom_minimum_size = Vector2(600, 200) # Verwende minimum_size statt size
	dialog_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dialog_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_container.add_child(dialog_panel)
	
	# Erstelle stylischen Hintergrund mit Blur/Unschärfe für das Panel
	var bg_blur = ColorRect.new()
	bg_blur.color = Color(0.2, 0.3, 0.8, 0.2)
	bg_blur.size = Vector2(650, 250)
	bg_blur.position = Vector2(-25, -25) # Positioniere relativ zum Panel
	bg_blur.show_behind_parent = true # Stelle sicher, dass es hinter dem Panel angezeigt wird
	dialog_panel.add_child(bg_blur)
	
	# Einfaches stilvolles Panel erstellen mit Seitenleiste
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.12, 0.25, 0.9)
	style_box.border_width_left = 5
	style_box.border_width_top = 5
	style_box.border_width_right = 5
	style_box.border_width_bottom = 5
	style_box.border_color = Color(0.8, 0.9, 1.0, 0.8)
	style_box.corner_radius_top_left = 15
	style_box.corner_radius_top_right = 15
	style_box.corner_radius_bottom_right = 15
	style_box.corner_radius_bottom_left = 15
	style_box.shadow_color = Color(0, 0.5, 1.0, 0.3)
	style_box.shadow_size = 10
	dialog_panel.add_theme_stylebox_override("panel", style_box)
	
	# Erstelle ein VBoxContainer für vertikale Anordnung von Inhalt
	dialog_content = VBoxContainer.new()
	dialog_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_content.add_theme_constant_override("separation", 15)
	dialog_panel.add_child(dialog_content)
	
	# Margin um Inhalt
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_top", 20)
	margin_container.add_theme_constant_override("margin_right", 20)
	margin_container.add_theme_constant_override("margin_bottom", 20)
	dialog_content.add_child(margin_container)
	
	# Erstelle einen Container für den Text
	var text_container = VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin_container.add_child(text_container)
	
	# Intro-Text erstellen mit RichTextLabel für bessere Formatierung
	intro_text = RichTextLabel.new()
	intro_text.bbcode_enabled = true
	intro_text.text = "[center][wave amp=20 freq=2][color=#FFD700]Herzlichen Glückwunsch[/color][/wave], du bist am Ziel angelangt![/center]\n\n[color=#FF6B6B]Doch oh Schreck[/color], alle deine irdischen Schätze sind nichts mehr wert..."
	intro_text.fit_content = true
	intro_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	intro_text.add_theme_font_size_override("normal_font_size", 20)
	intro_text.add_theme_font_size_override("bold_font_size", 24)
	intro_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_container.add_child(intro_text)
	
	# "Weiter"-Button erstellen mit schönem Styling
	var button_container = HBoxContainer.new()
	button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	text_container.add_child(button_container)
	
	continue_button = Button.new()
	continue_button.text = "Weiter"
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_button.custom_minimum_size = Vector2(150, 40)
	
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.4, 0.8, 0.9)
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color(0.7, 0.85, 1.0, 0.8)
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_right = 10
	button_style.corner_radius_bottom_left = 10
	continue_button.add_theme_stylebox_override("normal", button_style)
	continue_button.add_theme_stylebox_override("hover", button_style.duplicate())
	continue_button.add_theme_stylebox_override("pressed", button_style.duplicate())
	continue_button.get_theme_stylebox("hover").bg_color = Color(0.3, 0.5, 0.9, 0.9)
	continue_button.get_theme_stylebox("pressed").bg_color = Color(0.1, 0.3, 0.7, 0.9)
	
	continue_button.add_theme_font_size_override("font_size", 18)
	continue_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	continue_button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.8))
	
	button_container.add_child(continue_button)
	continue_button.pressed.connect(_on_intro_next_pressed)
	
	# Effektvolle Animation beim Erscheinen
	dialog_panel.modulate.a = 0
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(dialog_panel, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(dialog_panel, "position:y", dialog_panel.position.y - 20, 0.5)

# Starte die Coin-Dissolve-Animation
func start_coin_dissolve():
	current_state = HeavenSceneState.COINS_DISSOLVING
	
	# Dialog-Panel ausblenden mit Animation
	var panel_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	panel_tween.tween_property(dialog_panel, "modulate", Color(1,1,1,0), 0.5)
	panel_tween.parallel().tween_property(dialog_panel, "position:y", dialog_panel.position.y + 50, 0.5)
	
	# HUD-Münzen-Animation starten
	if has_node("HUD") and hud.has_method("animate_coin_removal"):
		# Connect signal für die Fertigstellung
		if hud.has_signal("coin_removal_completed"):
			if not hud.coin_removal_completed.is_connected(_on_coins_dissolved):
				hud.coin_removal_completed.connect(_on_coins_dissolved)
		
		# Animation starten
		hud.transition_to_heavenly_coins()
	else:
		# Fallback, wenn animate_coin_removal nicht verfügbar ist
		print("HUD hat keine animate_coin_removal Methode")
		await get_tree().create_timer(2.0).timeout
		_on_coins_dissolved()

# Wenn die Münzen verschwunden sind
func _on_coins_dissolved():
	# Stelle sicher, dass diese Funktion nur einmal aufgerufen wird
	if current_state != HeavenSceneState.COINS_DISSOLVING:
		return
	
	current_state = HeavenSceneState.SHOWING_MEMORIES
	
	# Alte UI-Elemente sauber entfernen
	if dialog_panel != null and is_instance_valid(dialog_panel):
		dialog_panel.queue_free()
	
	# Erstelle ein Canvas Layer für UI-Elemente
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)
	
	# Verwende einen CenterContainer für perfekte Zentrierung
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(center_container)
	
	# Erstelle das Dialog-Panel mit schönem Styling - wird automatisch zentriert
	dialog_panel = PanelContainer.new()
	dialog_panel.custom_minimum_size = Vector2(600, 200)
	dialog_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dialog_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_container.add_child(dialog_panel)
	
	# Erstelle stylischen Hintergrund mit Blur/Unschärfe für das Panel
	var bg_blur = ColorRect.new()
	bg_blur.color = Color(0.2, 0.3, 0.8, 0.2)
	bg_blur.size = Vector2(650, 250)
	bg_blur.position = Vector2(-25, -25) # Positioniere relativ zum Panel
	bg_blur.show_behind_parent = true # Stelle sicher, dass es hinter dem Panel angezeigt wird
	dialog_panel.add_child(bg_blur)
	
	# Einfaches stilvolles Panel mit Lichteffekt
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.12, 0.25, 0.9)
	style_box.border_width_left = 5
	style_box.border_width_top = 5
	style_box.border_width_right = 5
	style_box.border_width_bottom = 5
	style_box.border_color = Color(0.8, 0.9, 1.0, 0.8)
	style_box.corner_radius_top_left = 15
	style_box.corner_radius_top_right = 15
	style_box.corner_radius_bottom_right = 15
	style_box.corner_radius_bottom_left = 15
	style_box.shadow_color = Color(0, 0.5, 1.0, 0.3)
	style_box.shadow_size = 10
	dialog_panel.add_theme_stylebox_override("panel", style_box)
	
	# Erstelle ein VBoxContainer für vertikale Anordnung von Inhalt
	dialog_content = VBoxContainer.new()
	dialog_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_content.add_theme_constant_override("separation", 15)
	dialog_panel.add_child(dialog_content)
	
	# Margin um Inhalt
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_top", 20)
	margin_container.add_theme_constant_override("margin_right", 20)
	margin_container.add_theme_constant_override("margin_bottom", 20)
	dialog_content.add_child(margin_container)
	
	# Erstelle einen Container für den Text
	var text_container = VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin_container.add_child(text_container)
	
	# Nachdissolve-Text erstellen mit RichTextLabel für bessere Formatierung
	var dissolve_text = RichTextLabel.new()
	dissolve_text.bbcode_enabled = true
	dissolve_text.text = "[center]...doch es gibt [wave amp=20 freq=0.3][color=#4DA6FF]andere [color=#E0E5FF]Schätze[/color][/color][/wave], die du in deinem Leben gesammelt hast.[/center]\n\n[wave amp=15 freq=1]Entdecke sie und erinnere dich...[/wave]"
	dissolve_text.fit_content = true
	dissolve_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dissolve_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dissolve_text.add_theme_font_size_override("normal_font_size", 20)
	dissolve_text.add_theme_font_size_override("bold_font_size", 24)
	dissolve_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_container.add_child(dissolve_text)
	
	# "Weiter"-Button erstellen mit schönem Styling
	var button_container = HBoxContainer.new()
	button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	text_container.add_child(button_container)
	
	var next_button = Button.new()
	next_button.text = "Schätze entdecken"
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_button.custom_minimum_size = Vector2(200, 40)
	
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.4, 0.8, 0.9)
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color(0.7, 0.85, 1.0, 0.8)
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_right = 10
	button_style.corner_radius_bottom_left = 10
	next_button.add_theme_stylebox_override("normal", button_style)
	next_button.add_theme_stylebox_override("hover", button_style.duplicate())
	next_button.add_theme_stylebox_override("pressed", button_style.duplicate())
	next_button.get_theme_stylebox("hover").bg_color = Color(0.3, 0.5, 0.9, 0.9)
	next_button.get_theme_stylebox("pressed").bg_color = Color(0.1, 0.3, 0.7, 0.9)
	
	next_button.add_theme_font_size_override("font_size", 18)
	next_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	next_button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.8))
	
	button_container.add_child(next_button)
	next_button.pressed.connect(_on_show_memories_pressed)
	
	# Effektvolle Animation beim Erscheinen
	dialog_panel.modulate.a = 0
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(dialog_panel, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(dialog_panel, "position:y", dialog_panel.position.y - 20, 0.5)

# Zeige die Miniatur-Erinnerungen im Level
func show_memory_miniatures():
	current_state = HeavenSceneState.EXPLORING
	
	# Dialog-Panel ausblenden mit Animation
	var panel_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	panel_tween.tween_property(dialog_panel, "modulate", Color(1,1,1,0), 0.5)
	panel_tween.parallel().tween_property(dialog_panel, "position:y", dialog_panel.position.y + 50, 0.5)
	panel_tween.tween_callback(func(): dialog_panel.queue_free())
	
	# Erinnerungen platzieren
	place_memory_miniatures()
	
	# Himmlischen Coin-Typ im Global aktivieren
	if get_node_or_null("/root/Global"):
		Global.set_coin_type(Global.CoinType.HEAVENLY)

# Platziere die Miniatur-Erinnerungen im Level
func place_memory_miniatures():
	# Lösche vorhandene Screenshot-Bereiche
	for area in screenshot_areas:
		if is_instance_valid(area):
			area.queue_free()
	
	screenshot_areas.clear()
	
	# Viewport-Größe für die Positionierung abrufen
	var viewport_size = get_viewport_rect().size
	
	# Für jede Kategorie prüfen, ob Screenshots vorhanden sind und Miniatur platzieren
	for category in memory_categories.keys():
		if category in Global.memorable_screenshots and Global.memorable_screenshots[category].size() > 0:
			var screenshot_id = Global.memorable_screenshots[category][Global.memorable_screenshots[category].size() - 1]
			
			if ScreenshotManager.has_screenshot(screenshot_id):
				# Berechne die Position basierend auf dem Verhältnis zum Viewport
				var relative_pos = memory_categories[category]["position"]
				var absolute_pos = Vector2(
					viewport_size.x * relative_pos.x,
					viewport_size.y * relative_pos.y
				)
				
				create_memory_miniature(category, screenshot_id, absolute_pos)
			else:
				print("Screenshot nicht gefunden für Kategorie: ", category)
		else:
			print("Keine Screenshots verfügbar für Kategorie: ", category)

# Erstelle eine Miniatur-Erinnerung mit Interaktionsbereich
func create_memory_miniature(category, screenshot_id, position):
	# Erstelle ein Container-Node für die Miniatur
	var memory_container = Node2D.new()
	memory_container.position = position
	add_child(memory_container)
	
	# Erstelle die visuelle Darstellung des Screenshots
	var texture_rect = ScreenshotManager.create_texture_rect_from_screenshot(screenshot_id)
	if texture_rect:
		# Skaliere die Miniatur
		texture_rect.scale = Vector2(0.3, 0.3)  # Kleinere Darstellung
		texture_rect.position = Vector2(-texture_rect.size.x * 0.15, -texture_rect.size.y * 0.15)  # Zentrieren
		memory_container.add_child(texture_rect)
		
		# Erstelle einen animierten Rahmen für bessere Sichtbarkeit
		var frame = ColorRect.new()
		frame.color = Color(1, 1, 1, 0.8)
		frame.size = texture_rect.size * 0.3 + Vector2(10, 10)
		frame.position = Vector2(-frame.size.x/2 - 5, -frame.size.y/2 - 5)
		memory_container.add_child(frame)
		frame.show_behind_parent = true
		
		# Pulsierenden Rahmen-Effekt hinzufügen
		var frame_tween = create_tween()
		frame_tween.set_loops()
		frame_tween.tween_property(frame, "color", Color(0.5, 0.7, 1.0, 0.8), 1.0)
		frame_tween.tween_property(frame, "color", Color(1, 1, 1, 0.8), 1.0)
		
		# Erstelle ein funkelndes Partikeleffekt
		create_sparkle_effect(memory_container)
		
		# Erstelle einen Interaktionsbereich
		var area = Area2D.new()
		area.position = Vector2(0, 0)
		memory_container.add_child(area)
		
		# Kollisionsform für den Interaktionsbereich
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 50  # Interaktionsradius
		collision.shape = shape
		area.add_child(collision)
		
		# Speichere Kategorie und ID für spätere Verwendung
		area.set_meta("category", category)
		area.set_meta("screenshot_id", screenshot_id)
		
		# Verbinde Signale
		area.body_entered.connect(_on_memory_body_entered.bind(area))
		area.body_exited.connect(_on_memory_body_exited.bind(area))
		
		# Speichere Referenz
		screenshot_areas.append(area)
		
		print("Miniatur erstellt für Kategorie: ", category)
	else:
		print("Konnte TextureRect für Screenshot nicht erstellen: ", screenshot_id)

# Erstelle einen funkelnden Partikeleffekt für die Miniatur
func create_sparkle_effect(parent_node):
	var particles = GPUParticles2D.new()
	parent_node.add_child(particles)
	
	# Partikel-Material erstellen
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 30.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 45.0
	material.gravity = Vector3(0, 10, 0)
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 30.0
	material.scale_min = 1.0
	material.scale_max = 3.0
	
	# Farben für das Funkeln (himmlisches Blau)
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([Color(0.5, 0.8, 1.0, 1.0), Color(0.7, 0.9, 1.0, 0.0)])
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	particles.process_material = material
	particles.amount = 15
	particles.lifetime = 2.0
	particles.explosiveness = 0.1
	particles.randomness = 0.5
	
	# Partikel einschalten
	particles.emitting = true

# Wenn der Spieler einen Erinnerungsbereich betritt - JETZT: sofort anzeigen
func _on_memory_body_entered(body, area):
	if body.name == "Player" or body.is_in_group("Player"):
		print("Spieler hat Erinnerung betreten")
		
		# Speichern für _on_memory_body_exited
		active_screenshot = area
		
		# Erinnerung sofort anzeigen, ohne auf Tastendruck zu warten
		show_memory_fullscreen(area)

# Wenn der Spieler einen Erinnerungsbereich verlässt
func _on_memory_body_exited(body, area):
	if body.name == "Player" or body.is_in_group("Player") and active_screenshot == area:
		print("Spieler hat Erinnerung verlassen")
		active_screenshot = null
		
		# Wenn die Erinnerung noch angezeigt wird, nicht schließen
		# Der Spieler muss auf den "Himmlischen Schatz empfangen"-Button klicken

# Keine Überprüfung mehr nötig, da automatisch beim Betreten aufgerufen
# func check_player_screenshot_interactions():
#    pass  # Diese Funktion wird nicht mehr benötigt

# Zeige eine Erinnerung im Vollbild an
func show_memory_fullscreen(area):
	# Kategorie und Screenshot-ID extrahieren
	var category = area.get_meta("category")
	var screenshot_id = area.get_meta("screenshot_id")
	
	# Falls diese Erinnerung bereits abgeschlossen wurde, nicht nochmal anzeigen
	if "completed" in memory_categories[category] and memory_categories[category]["completed"]:
		return
	
	# Erstelle ein Canvas Layer mit einem schicken Blur-Effekt
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)
	
	# Erstelle ein vollständiges Overlay mit Animation
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0.1, 0.2, 0)  # Starte transparent für Animation
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(overlay)
	
	# Erstelle ein CenterContainer für garantierte Zentrierung
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center_container)
	
	# Animiere das Overlay
	var tween = create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(overlay, "color", Color(0, 0.1, 0.2, 0.8), 0.5)
	
	# Panel für den Inhalt mit schönem Design - wird automatisch mittig platziert
	var content_panel = PanelContainer.new()
	content_panel.custom_minimum_size = Vector2(650, 500)
	center_container.add_child(content_panel)
	
	# Stilisiere das Panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.1, 0.2, 0.95)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.6, 0.8, 1.0, 0.8)
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.shadow_color = Color(0, 0.3, 0.6, 0.3)
	panel_style.shadow_size = 15
	content_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Margin für den Inhalt
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	content_panel.add_child(margin)
	
	# VBox für vertikale Anordnung
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	# Titel der Erinnerung
	var title = RichTextLabel.new()
	title.bbcode_enabled = true
	title.fit_content = true
	title.text = "[center][wave amp=10 freq=0.5][color=#FFD700]" + memory_categories[category]["title"] + "[/color][/wave][/center]"
	title.add_theme_font_size_override("normal_font_size", 28)
	title.add_theme_font_size_override("bold_font_size", 32)
	vbox.add_child(title)
	
	# Trennlinie
	var separator = HSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color(0.6, 0.8, 1.0, 0.6)
	sep_style.thickness = 2
	separator.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(separator)
	
	# Beschreibung der Erinnerung
	var description = RichTextLabel.new()
	description.bbcode_enabled = true
	description.fit_content = true
	description.text = "[center]" + memory_categories[category]["description"] + "[/center]"
	description.add_theme_font_size_override("normal_font_size", 18)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(description)
	
	# Screenshot im Großformat mit schönem Rahmen
	var screenshot_container = PanelContainer.new()
	screenshot_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screenshot_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(screenshot_container)
	
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.2, 0.3, 0.4, 0.4)
	frame_style.border_width_left = 2
	frame_style.border_width_top = 2
	frame_style.border_width_right = 2
	frame_style.border_width_bottom = 2
	frame_style.border_color = Color(0.7, 0.85, 1.0, 0.7)
	frame_style.corner_radius_top_left = 5
	frame_style.corner_radius_top_right = 5
	frame_style.corner_radius_bottom_right = 5
	frame_style.corner_radius_bottom_left = 5
	screenshot_container.add_theme_stylebox_override("panel", frame_style)
	
	var texture_rect = ScreenshotManager.create_texture_rect_from_screenshot(screenshot_id)
	if texture_rect:
		texture_rect.expand = true
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		screenshot_container.add_child(texture_rect)
	
	# "Schatz empfangen"-Button
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_container)
	
	var receive_button = Button.new()
	receive_button.text = "Himmlischen Schatz empfangen"
	receive_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	receive_button.custom_minimum_size = Vector2(250, 50)
	button_container.add_child(receive_button)
	
	# Button styling
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.4, 0.8, 0.9)
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color(0.7, 0.85, 1.0, 0.8)
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_right = 10
	button_style.corner_radius_bottom_left = 10
	receive_button.add_theme_stylebox_override("normal", button_style)
	receive_button.add_theme_stylebox_override("hover", button_style.duplicate())
	receive_button.add_theme_stylebox_override("pressed", button_style.duplicate())
	receive_button.get_theme_stylebox("hover").bg_color = Color(0.3, 0.5, 0.9, 0.9) 
	receive_button.get_theme_stylebox("pressed").bg_color = Color(0.1, 0.3, 0.7, 0.9)
	
	receive_button.add_theme_font_size_override("font_size", 18)
	receive_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	receive_button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.8))
	
	# Button-Glühen-Animation
	var button_tween = create_tween()
	button_tween.set_loops()
	button_tween.tween_property(receive_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0)
	button_tween.tween_property(receive_button, "modulate", Color(0.8, 0.9, 1.2, 1.0), 1.0)
	
	receive_button.pressed.connect(_on_receive_treasure_pressed.bind(canvas_layer, category))
	
	# Speichere für späteren Zugriff
	screenshot_displays.append(canvas_layer)
	
	# Animation: Panel kommt von oben
	content_panel.modulate.a = 0
	content_panel.position.y -= 50
	var panel_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	panel_tween.tween_property(content_panel, "modulate:a", 1.0, 0.5)
	panel_tween.parallel().tween_property(content_panel, "position:y", content_panel.position.y + 50, 0.5)

# Wenn der "Schatz empfangen"-Button gedrückt wird
func _on_receive_treasure_pressed(canvas_layer, category):
	# Kategorie und Screenshot-ID abrufen für Positionsbestimmung
	var category_data = memory_categories[category]
	var viewport_size = get_viewport_rect().size
	var memory_position = Vector2(viewport_size.x * category_data["position"].x, viewport_size.y * category_data["position"].y)
	
	# Blauer Lichteffekt
	var blue_flash = ColorRect.new()
	blue_flash.color = Color(0, 0.5, 1.0, 0.0)  # Starte transparent
	blue_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(blue_flash)
	
	# Animation des blauen Lichts
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(blue_flash, "color:a", 0.8, 0.5)
	tween.tween_property(blue_flash, "color:a", 0.0, 1.0)
	
	# Himmlischer Sound-Effekt abspielen wenn verfügbar
	if has_node("HeavenlySound"):
		var sound = get_node("HeavenlySound")
		if sound is AudioStreamPlayer:
			sound.play()
	
	# Münzen spawnen BEI DER POSITION DER ERINNERUNG (nicht beim Spieler)
	await get_tree().create_timer(0.7).timeout
	spawn_heavenly_coins_at_memory(memory_position)
	
	# Nach der Animation das Overlay entfernen
	await tween.finished
	if is_instance_valid(canvas_layer):
		screenshot_displays.erase(canvas_layer)
		canvas_layer.queue_free()
	
	# Markiere diese Kategorie als abgeschlossen
	memory_categories[category]["completed"] = true
	
	# Prüfe, ob alle Erinnerungen abgeschlossen sind
	check_all_memories_completed()

# Spawne himmlische Münzen direkt an der Erinnerungsposition mit Zerfallseffekt
func spawn_heavenly_coins_at_memory(memory_position):
	if coin_prefab:
		# Spieler-Position für sichere Platzierung
		var player_pos = player.global_position
		
		# Parameter für die Animation
		var coin_count = 100
		var max_distance = 300.0  # Maximale Entfernung vom Spieler
		var spawn_radius = 100.0  # Anfänglicher Radius um die Erinnerung
		
		for i in range(coin_count):
			var coin = coin_prefab.instantiate()
			add_child(coin)
			
			# Berechne eine Position in einem Kreis um die Erinnerung herum
			var angle = randf() * 2.0 * PI
			var distance = randf() * spawn_radius
			var offset = Vector2(cos(angle) * distance, sin(angle) * distance)
			
			# Startposition bei der Erinnerung
			var start_pos = memory_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
			coin.global_position = start_pos
			
			# Zielposition berechnen - in Richtung Spieler aber mit Beschränkung
			var dir_to_player = (player_pos - start_pos).normalized()
			var target_distance = min((player_pos - start_pos).length(), max_distance)
			var target_offset = dir_to_player * target_distance * randf_range(0.5, 1.0)
			var target_pos = start_pos + target_offset + offset * 0.5
			
			# Animation für "Zerfallen" der Erinnerung
			var coin_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
			
			# Etwas Verzögerung für natürlicheren Effekt
			coin_tween.tween_property(coin, "scale", Vector2(0.1, 0.1), 0.001)  # Start klein
			coin_tween.tween_interval(randf_range(0.0, 0.5))  # Zufällige Verzögerung
			coin_tween.tween_property(coin, "scale", Vector2(1, 1), 0.3)  # Wachsen
			coin_tween.parallel().tween_property(coin, "global_position", target_pos, randf_range(0.7, 1.5))
			
			# Kurze Verzögerung zwischen Münzen für flüssigen Effekt
			await get_tree().process_frame
	else:
		print("Himmlische Münze konnte nicht geladen werden!")
		
	# HUD aktualisieren (100 Münzen hinzufügen)
	if has_node("HUD") and hud.has_method("add_coins"):
		hud.add_coins(100)

# Prüfe, ob alle Erinnerungen abgeschlossen sind
func check_all_memories_completed():
	var all_completed = true
	
	for category in memory_categories.keys():
		if category in Global.memorable_screenshots and Global.memorable_screenshots[category].size() > 0:
			if not "completed" in memory_categories[category] or not memory_categories[category]["completed"]:
				all_completed = false
				break
	
	if all_completed:
		show_completion_message()

# Zeige eine Abschlussnachricht an
func show_completion_message():
	current_state = HeavenSceneState.COMPLETED
	
	# Canvas Layer erstellen
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 11  # Über allem anderen
	add_child(canvas_layer)
	
	# Hintergrund-Effekt (Schimmerndes Licht)
	var bg_effect = ColorRect.new()
	bg_effect.color = Color(0.1, 0.2, 0.4, 0.7)
	bg_effect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(bg_effect)
	
	# Animiere den Hintergrund
	var bg_tween = create_tween().set_loops()
	bg_tween.tween_property(bg_effect, "color", Color(0.2, 0.3, 0.5, 0.7), 2.0)
	bg_tween.tween_property(bg_effect, "color", Color(0.1, 0.2, 0.4, 0.7), 2.0)
	
	# Hauptcontainer - nutzt CenterContainer für garantierte Zentrierung
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(center_container)
	
	# Panel für die Abschlussnachricht - wird durch CenterContainer automatisch zentriert
	var final_panel = PanelContainer.new()
	final_panel.custom_minimum_size = Vector2(650, 250)
	center_container.add_child(final_panel)
	
	# Stilisiere das Panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.1, 0.2, 0.95)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.7, 0.85, 1.0, 0.8)
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.shadow_color = Color(0, 0.5, 1.0, 0.4)
	panel_style.shadow_size = 20
	final_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Margin für den Inhalt
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	final_panel.add_child(margin)
	
	# VBox für vertikale Anordnung
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Abschlusstext
	var final_text = RichTextLabel.new()
	final_text.bbcode_enabled = true
	final_text.fit_content = true
	final_text.text = "[center][wave amp=10 freq=0.3][color=#FFD700]Nun hast du verstanden:[/color][/wave][/center]\n\n[center][wave amp=20 freq=0.2][color=#4DA6FF]\"Sammelt euch Schätze im Himmel, wo weder Motten noch Rost sie fressen[/color] [color=#E0E5FF]und wo Diebe nicht einbrechen und stehlen.\"[/color][/wave][/center]\n\n[right][color=#90CAF9]- Matthäus 6:20[/color][/right]"
	final_text.add_theme_font_size_override("normal_font_size", 22)
	final_text.add_theme_font_size_override("bold_font_size", 26)
	final_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(final_text)
	
	# Button-Container
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_container)
	
	# Weiter-Button zur Hauptwelt
	var continue_button = Button.new()
	continue_button.text = "Weiter zur himmlischen Welt"
	continue_button.custom_minimum_size = Vector2(250, 50)
	button_container.add_child(continue_button)
	
	# Button styling
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.4, 0.8, 0.9)
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color(0.7, 0.85, 1.0, 0.8)
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_right = 10
	button_style.corner_radius_bottom_left = 10
	continue_button.add_theme_stylebox_override("normal", button_style)
	continue_button.add_theme_stylebox_override("hover", button_style.duplicate())
	continue_button.add_theme_stylebox_override("pressed", button_style.duplicate())
	continue_button.get_theme_stylebox("hover").bg_color = Color(0.3, 0.5, 0.9, 0.9)
	continue_button.get_theme_stylebox("pressed").bg_color = Color(0.1, 0.3, 0.7, 0.9)
	
	continue_button.add_theme_font_size_override("font_size", 18)
	continue_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	continue_button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.8))
	
	# Button-Glühen-Animation
	var button_tween = create_tween()
	button_tween.set_loops()
	button_tween.tween_property(continue_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0)
	button_tween.tween_property(continue_button, "modulate", Color(0.8, 0.9, 1.2, 1.0), 1.0)
	
	continue_button.pressed.connect(_on_continue_to_main_world)
	
	# Animation: Panel erscheint mit Skalierungseffekt
	final_panel.scale = Vector2(0.5, 0.5)
	final_panel.modulate.a = 0
	var panel_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	panel_tween.tween_property(final_panel, "scale", Vector2(1, 1), 0.7)
	panel_tween.parallel().tween_property(final_panel, "modulate:a", 1.0, 0.5)

# Wenn der "Weiter zur himmlischen Welt"-Button gedrückt wird
func _on_continue_to_main_world():
		# Fallback, falls Global nicht verfügbar ist
		get_tree().change_scene_to_file("res://scenes/levels/adventure_mode/base_level.tscn")

# Button-Handler für die Intro-Phase
func _on_intro_next_pressed():
	start_coin_dissolve()

# Button-Handler für die Erinnerungsanzeige
func _on_show_memories_pressed():
	show_memory_miniatures()

# Passe den Boden an die richtige Position an
func adjust_floor_position():
	if has_node("StaticBody2D"):
		# Hier könnten Anpassungen vorgenommen werden, falls nötig
		pass
