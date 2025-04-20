class_name PopupDialog
extends CanvasLayer

# Signal, wenn der primäre (rechte) Button gedrückt wird
signal confirmed
# Signal, wenn der sekundäre (linke) Button gedrückt wird
signal canceled

# UI-Elemente
var dimmer
var dialog_panel
var title_label
var message_label
var button_container
var cancel_button
var confirm_button

# Standardwerte
var _title_text = "Bestätigung"
var _message_text = "Möchtest du fortfahren?"
var _cancel_text = "Abbrechen"
var _confirm_text = "Bestätigen"
var _confirm_color = Color(0.7, 0.2, 0.2, 1)  # Rot
var _auto_hide = true

func _init():
	# Erstelle alle UI-Elemente programmatisch
	_create_ui()

func _ready():
	# Bei Start nicht anzeigen
	hide()
	
	# Verbinde Button-Signale
	cancel_button.pressed.connect(_on_cancel_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)

# Erstellt die komplette UI-Struktur
func _create_ui():
	# Dimmer (Hintergrund-Verdunkelung)
	dimmer = ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.color = Color(0, 0, 0, 0.6)  # Halbtransparentes Schwarz
	add_child(dimmer)
	
	# DialogPanel
	dialog_panel = Panel.new()
	dialog_panel.name = "DialogPanel"
	
	# Panel-Design
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.15, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.6, 0.6, 1.0, 0.7)
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.shadow_color = Color(0, 0, 0, 0.3)
	panel_style.shadow_size = 8
	dialog_panel.add_theme_stylebox_override("panel", panel_style)
	dimmer.add_child(dialog_panel)
	
	# Titel
	title_label = Label.new()
	title_label.name = "Title"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	dialog_panel.add_child(title_label)
	
	# Nachricht
	message_label = Label.new()
	message_label.name = "Message"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	dialog_panel.add_child(message_label)
	
	# Buttons-Container
	button_container = HBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 20)
	dialog_panel.add_child(button_container)
	
	# Button-Style vorbereiten
	var button_style_normal = StyleBoxFlat.new()
	button_style_normal.bg_color = Color(0.2, 0.2, 0.25, 1)
	button_style_normal.border_width_left = 0
	button_style_normal.border_width_top = 0
	button_style_normal.border_width_right = 0
	button_style_normal.border_width_bottom = 0
	button_style_normal.corner_radius_top_left = 8
	button_style_normal.corner_radius_top_right = 8
	button_style_normal.corner_radius_bottom_left = 8
	button_style_normal.corner_radius_bottom_right = 8
	
	var button_style_hover = StyleBoxFlat.new()
	button_style_hover.bg_color = Color(0.25, 0.25, 0.3, 1)
	button_style_hover.border_width_left = 0
	button_style_hover.border_width_top = 0
	button_style_hover.border_width_right = 0
	button_style_hover.border_width_bottom = 0
	button_style_hover.corner_radius_top_left = 8
	button_style_hover.corner_radius_top_right = 8
	button_style_hover.corner_radius_bottom_left = 8
	button_style_hover.corner_radius_bottom_right = 8
	
	var button_style_pressed = StyleBoxFlat.new()
	button_style_pressed.bg_color = Color(0.15, 0.15, 0.2, 1)
	button_style_pressed.border_width_left = 0
	button_style_pressed.border_width_top = 0
	button_style_pressed.border_width_right = 0
	button_style_pressed.border_width_bottom = 0
	button_style_pressed.corner_radius_top_left = 8
	button_style_pressed.corner_radius_top_right = 8
	button_style_pressed.corner_radius_bottom_left = 8
	button_style_pressed.corner_radius_bottom_right = 8
	
	# Abbrechen-Button
	cancel_button = Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.add_theme_font_size_override("font_size", 18)
	cancel_button.add_theme_stylebox_override("normal", button_style_normal.duplicate())
	cancel_button.add_theme_stylebox_override("hover", button_style_hover.duplicate())
	cancel_button.add_theme_stylebox_override("pressed", button_style_pressed.duplicate())
	button_container.add_child(cancel_button)
	
	# Bestätigen-Button
	confirm_button = Button.new()
	confirm_button.name = "ConfirmButton"
	confirm_button.add_theme_font_size_override("font_size", 18)
	
	# Rote Button-Stile
	var confirm_style_normal = button_style_normal.duplicate()
	confirm_style_normal.bg_color = Color(0.7, 0.2, 0.2, 1)
	var confirm_style_hover = button_style_hover.duplicate()
	confirm_style_hover.bg_color = Color(0.8, 0.3, 0.3, 1)
	var confirm_style_pressed = button_style_pressed.duplicate()
	confirm_style_pressed.bg_color = Color(0.6, 0.15, 0.15, 1)
	
	confirm_button.add_theme_stylebox_override("normal", confirm_style_normal)
	confirm_button.add_theme_stylebox_override("hover", confirm_style_hover)
	confirm_button.add_theme_stylebox_override("pressed", confirm_style_pressed)
	button_container.add_child(confirm_button)

# Setzt Text-Inhalte und Farben
func setup(title: String = "", message: String = "", 
		   cancel_text: String = "", confirm_text: String = "",
		   confirm_button_color: Color = Color(0.7, 0.2, 0.2, 1)):
	
	# Setze nur nicht-leere Werte
	if title:
		_title_text = title
	if message:
		_message_text = message
	if cancel_text:
		_cancel_text = cancel_text
	if confirm_text:
		_confirm_text = confirm_text
		
	_confirm_color = confirm_button_color
	
	return self  # Für Methoden-Verkettung

# Einstellen, ob das Popup sich automatisch schließen soll
func set_auto_hide(value: bool):
	_auto_hide = value
	return self  # Für Methoden-Verkettung

# Zeigt den Dialog an
func popup():
	# Fenstergröße aktualisieren
	var viewport_size = get_viewport().get_visible_rect().size
	dimmer.size = viewport_size
	
	var dialog_width = min(500, viewport_size.x * 0.8)
	var dialog_height = 230
	dialog_panel.size = Vector2(dialog_width, dialog_height)
	dialog_panel.position = (viewport_size - dialog_panel.size) / 2
	dialog_panel.pivot_offset = dialog_panel.size / 2
	
	# Layout aktualisieren
	title_label.position = Vector2(0, 20)
	title_label.size = Vector2(dialog_width, 30)
	
	message_label.position = Vector2(20, 60)
	message_label.size = Vector2(dialog_width - 40, 60)
	
	button_container.position = Vector2(20, dialog_height - 80)
	button_container.size = Vector2(dialog_width - 40, 60)
	
	cancel_button.custom_minimum_size = Vector2(dialog_width * 0.35, 60)
	confirm_button.custom_minimum_size = Vector2(dialog_width * 0.35, 60)
	
	# Aktualisiere UI
	title_label.text = _title_text
	message_label.text = _message_text
	cancel_button.text = _cancel_text
	confirm_button.text = _confirm_text
	
	# Setze Button-Farbe
	var normal_style = confirm_button.get_theme_stylebox("normal").duplicate()
	var hover_style = confirm_button.get_theme_stylebox("hover").duplicate()
	var pressed_style = confirm_button.get_theme_stylebox("pressed").duplicate()
	
	normal_style.bg_color = _confirm_color
	hover_style.bg_color = _confirm_color.lightened(0.1)
	pressed_style.bg_color = _confirm_color.darkened(0.1)
	
	confirm_button.add_theme_stylebox_override("normal", normal_style)
	confirm_button.add_theme_stylebox_override("hover", hover_style)
	confirm_button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Dialog anzeigen mit Animation
	show()
	dimmer.modulate = Color(1, 1, 1, 0)
	
	var tween = create_tween()
	tween.tween_property(dimmer, "modulate", Color(1, 1, 1, 1), 0.3).set_ease(Tween.EASE_OUT)
	
	# Dialog-Panel Animation (Skalierung)
	dialog_panel.scale = Vector2(0.9, 0.9)
	tween.parallel().tween_property(dialog_panel, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT)
	
	return self  # Für Methoden-Verkettung

# Schließt den Dialog
func close():
	var tween = create_tween()
	tween.tween_property(dimmer, "modulate", Color(1, 1, 1, 0), 0.2).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(dialog_panel, "scale", Vector2(0.9, 0.9), 0.2).set_ease(Tween.EASE_IN)
	
	# Warte auf das Ende der Animation
	await tween.finished
	hide()

# Button-Handling
func _on_cancel_pressed():
	emit_signal("canceled")
	if _auto_hide:
		close()

func _on_confirm_pressed():
	emit_signal("confirmed")
	if _auto_hide:
		close()
