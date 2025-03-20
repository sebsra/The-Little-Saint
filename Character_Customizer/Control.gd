# UI.gd
extends Control

# Spieler-Outfit-Eigenschaften
var body
var player_outfit
var selected_outfit_category = ""
var player_animations
var options_per_category = {}
var config_path = "user://settings.cfg"
var has_unsaved_changes = false  # Neue Variable für ungespeicherte Änderungen

# Signal für Debugging
signal debug_message(message)

func _ready():
	randomize() # Initialisiere den Zufallsgenerator
	get_node("character_sprites/masks").visible = false
	player_outfit = get_node("character_sprites").default_outfit
	player_animations = get_node("character_sprites").animation_frames
	PopupManager.dialog_confirmed.connect(_on_dialog_confirmed)
	
	# UI-Elemente für jede Outfit-Kategorie erstellen
	setup_outfit_categories()
	
	# Versuche, gespeicherte Outfits zu laden
	load_saved_outfit()
	
	# Bei Programmstart gibt es keine ungespeicherten Änderungen
	has_unsaved_changes = false

# Erstellt UI-Elemente für alle Outfit-Kategorien
func setup_outfit_categories():
	for category in player_outfit:
		var category_button = Button.new()
		var items_container = ScrollContainer.new()
		var item_container_grid = GridContainer.new()

		# Kategorie-Button einrichten
		category_button.text = category
		category_button.pressed.connect(_on_category_button_pressed.bind(category))
		$Outfit_Category_Picker/GridContainer.add_child(category_button)

		# Container für Items einrichten
		items_container.size = Vector2(620, 400)
		items_container.position = Vector2(600, 200)
		items_container.add_child(item_container_grid)
		items_container.name = category
		add_child(items_container)
		items_container.hide()
		
		# Grid für Items einrichten
		item_container_grid.columns = 6
		var current_item = 0
		var button_size = Vector2(100, 100)
		
		# Leeren Button für optionale Kategorien hinzufügen
		if category != "bodies":
			var empty_button = Button.new()
			empty_button.custom_minimum_size = button_size
			empty_button.pressed.connect(_on_item_button_pressed.bind("none"))
			item_container_grid.add_child(empty_button)
			
			var animated_sprite = get_node("character_sprites/" + category)
			animated_sprite.visible = false
			player_outfit[category] = "none"
			
		# Alle verfügbaren Items für diese Kategorie hinzufügen
		while true:
			current_item += 1
			var texture = get_node("character_sprites/"+category).sprite_frames.get_frame_texture(str(current_item), 1)
			if texture == null:
				break
				
			var item_texture = TextureRect.new()
			item_texture.texture = texture
			item_texture.custom_minimum_size = button_size
			item_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			var item_button = Button.new()
			item_button.custom_minimum_size = button_size
			item_button.add_child(item_texture)
			item_button.pressed.connect(_on_item_button_pressed.bind(str(current_item)))
			item_container_grid.add_child(item_button)
			
		options_per_category[category] = current_item - 1

# Aktualisiert die Animations-Frames basierend auf dem gewählten Outfit
func _process(_delta):
	for outfit in player_outfit:
		var animated_sprite = get_node("character_sprites/" + outfit)
		# Stelle sicher, dass wir einen String für die Animation haben
		var animation_value = str(player_outfit[outfit])
		animated_sprite.animation = animation_value
		animated_sprite.frame = 1

# Wird aufgerufen, wenn ein Item ausgewählt wird
func _on_item_button_pressed(item):
	var animated_sprite = get_node("character_sprites/" + selected_outfit_category)
	var old_value = player_outfit[selected_outfit_category]
	var new_value = str(item)
	
	if new_value == "none":
		animated_sprite.visible = false
	else:
		animated_sprite.visible = true
	
	# Setze has_unsaved_changes nur, wenn sich etwas geändert hat
	if old_value != new_value:
		player_outfit[selected_outfit_category] = new_value
		has_unsaved_changes = true
	else:
		player_outfit[selected_outfit_category] = new_value

# Wird aufgerufen, wenn eine Kategorie ausgewählt wird
func _on_category_button_pressed(category):
	if selected_outfit_category:
		get_node(selected_outfit_category).hide()
	get_node(category).show()
	selected_outfit_category = category
	
# Generiert ein zufälliges Outfit
func _random_button_pressed():
	var old_outfit = player_outfit.duplicate()
	var had_changes = false
	
	for category in player_outfit:
		if category == "bodies":
			# Körper sollte immer sichtbar sein
			var random_body = randi() % options_per_category[category] + 1
			if player_outfit[category] != str(random_body):
				player_outfit[category] = str(random_body)
				had_changes = true
		else:
			# Für andere Kategorien, entscheide zufällig, ob sie sichtbar sein sollen
			if randf() > 0.3: # 70% Chance, dass ein Item angezeigt wird
				var random_item = randi() % options_per_category[category] + 1
				if player_outfit[category] != str(random_item):
					player_outfit[category] = str(random_item)
					had_changes = true
				get_node("character_sprites/" + category).visible = true
			else:
				if player_outfit[category] != "none":
					player_outfit[category] = "none"
					had_changes = true
				get_node("character_sprites/" + category).visible = false
	
	if had_changes:
		has_unsaved_changes = true

# Speichert das aktuelle Outfit
func _save_button_pressed():
	var config = ConfigFile.new()
	
	# Versuche zuerst die vorhandene Konfigurationsdatei zu laden
	var err = config.load(config_path)
	
	# Speichere das Outfit, unabhängig davon, ob die Datei existiert
	config.set_value("settings", "outfit", player_outfit)
	
	err = config.save(config_path)
	if err != OK:
		emit_signal("debug_message", "Fehler beim Speichern der Einstellungen: " + str(err))
		show_message("Fehler beim Speichern!", Color(1, 0.3, 0.3, 1))
	else:
		has_unsaved_changes = false  # Änderungen wurden gespeichert
		show_message("Outfit erfolgreich gespeichert!", Color(0.3, 1, 0.3, 1))

# Setzt alle optionalen Teile des Outfits zurück
func _reset_button_pressed():
	var had_changes = false
	
	for category in player_outfit:
		if category != "bodies":
			var animated_sprite = get_node("character_sprites/" + category)
			animated_sprite.visible = false
			
			if player_outfit[category] != "none":
				player_outfit[category] = "none"
				had_changes = true
	
	if had_changes:
		has_unsaved_changes = true
	
	show_message("Outfit zurückgesetzt!", Color(0.3, 0.7, 1, 1))

# Hilfsfunktion zum Anzeigen von Nachrichten
func show_message(text, color = Color(1, 1, 1, 1)):
	if has_node("save_feedback"):
		var label = get_node("save_feedback")
		label.text = text
		label.modulate = color
		
		# Timer zum Ausblenden nach 2 Sekunden
		get_tree().create_timer(2.0).timeout.connect(func(): 
			if has_node("save_feedback"):
				get_node("save_feedback").text = ""
		)
		
# Lädt das gespeicherte Outfit, falls vorhanden
func load_saved_outfit():
	var config = ConfigFile.new()
	var err = config.load(config_path)
	
	if err == OK:
		var saved_outfit = config.get_value("settings", "outfit", null)
		if saved_outfit:
			# Aktualisiere das Outfit mit den gespeicherten Werten
			for category in saved_outfit:
				if player_outfit.has(category):
					# Konvertiere den Wert zu String
					var outfit_value = str(saved_outfit[category])
					player_outfit[category] = outfit_value
					
					# Aktualisiere die Sichtbarkeit
					var animated_sprite = get_node("character_sprites/" + category)
					if outfit_value == "none":
						animated_sprite.visible = false
					else:
						animated_sprite.visible = true

func _on_back_pressed():
	if has_unsaved_changes:
		PopupManager.confirm(
			"Nicht gespeicherte Änderungen",
			"Du hast nicht gespeicherte Änderungen. Möchtest du wirklich ohne Speichern zurückkehren?",
			"Abbrechen",
			"Zurück",
			"back_confirmation"
		)
	else:
		get_tree().change_scene_to_file("res://Start_Screen/start_screen.tscn")

func _on_dialog_confirmed(dialog_id):
	if dialog_id == "back_confirmation":
		get_tree().change_scene_to_file("res://Start_Screen/start_screen.tscn")
