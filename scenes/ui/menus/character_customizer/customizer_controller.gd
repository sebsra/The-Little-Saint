class_name CustomizerController
# UI.gd
extends Control

# Spieler-Outfit-Eigenschaften
var body
var player_outfit
var selected_outfit_category = ""
var player_animations
var options_per_category = {}
var has_unsaved_changes = false  # Neue Variable für ungespeicherte Änderungen

# Resource-basiertes Outfit System
var current_outfit_resource: PlayerOutfitResource = null

# Signal für Debugging
signal debug_message(message)

func _ready():
	randomize() # Initialisiere den Zufallsgenerator
	get_node("character_sprites/masks").visible = false
	player_outfit = get_node("character_sprites").default_outfit
	player_animations = get_node("character_sprites").animation_frames
	
	# Create outfit resource
	current_outfit_resource = PlayerOutfitResource.new()
	
	# Connect to PopupManager
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
		animated_sprite.animation = player_outfit[outfit]
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
		
		# Update outfit resource
		if selected_outfit_category == "bodies":
			current_outfit_resource.body = new_value
		elif selected_outfit_category == "hats":
			current_outfit_resource.hat = new_value
		elif current_outfit_resource.get(selected_outfit_category) != null:
			current_outfit_resource.set(selected_outfit_category, new_value)
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
	current_outfit_resource.randomize_outfit()
	var outfit_dict = current_outfit_resource.to_dictionary()
	var had_changes = false
	
	# Update the player_outfit from the resource
	for category in outfit_dict:
		if player_outfit.has(category):
			var new_value = outfit_dict[category]
			if player_outfit[category] != new_value:
				player_outfit[category] = new_value
				had_changes = true
			
			# Update sprite visibility
			var animated_sprite = get_node("character_sprites/" + category)
			if new_value == "none":
				animated_sprite.visible = false
			else:
				animated_sprite.visible = true

	if had_changes:
		has_unsaved_changes = true

# Speichert das aktuelle Outfit
func _save_button_pressed():
	# Update the outfit resource
	current_outfit_resource.from_dictionary(player_outfit)
	current_outfit_resource.outfit_name = "Last Saved Outfit"

	# Save to both the favorites and the player's current outfit
	SaveManager.save_outfit(player_outfit, "Last Saved Outfit")
	
	# Ensure the current save data has the outfit
	if SaveManager.current_save_data:
		SaveManager.current_save_data.player_outfit = player_outfit.duplicate(true)
	
	# Save both settings and game data
	SaveManager.save_settings()
	SaveManager.save_game()  # Add this line to ensure full game save
	
	has_unsaved_changes = false
	show_message("Outfit erfolgreich gespeichert!", Color(0.3, 1, 0.3, 1))

# Setzt alle optionalen Teile des Outfits zurück
func _reset_button_pressed():
	# Use the resource method to reset
	current_outfit_resource.reset()
	var outfit_dict = current_outfit_resource.to_dictionary()
	var had_changes = false
	
	# Apply the reset to player_outfit
	for category in outfit_dict:
		if player_outfit.has(category) and category != "bodies":
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
	# First try to load from current save data
	if SaveManager.current_save_data and SaveManager.current_save_data.player_outfit:
		var saved_outfit = SaveManager.current_save_data.player_outfit
		
		# Log for debugging
		print("Loading outfit from save data: ", saved_outfit)
		
		# Update the outfit resource
		current_outfit_resource.from_dictionary(saved_outfit)
		
		# Update the UI
		for category in saved_outfit:
			if player_outfit.has(category):
				var outfit_value = str(saved_outfit[category])
				player_outfit[category] = outfit_value
				
				# Update visibility
				var animated_sprite = get_node("character_sprites/" + category)
				if outfit_value == "none":
					animated_sprite.visible = false
				else:
					animated_sprite.visible = true
		
		print("Outfit loaded successfully")
	else:
		print("No saved outfit found in save data")


func _on_back_pressed() -> void:
	if has_unsaved_changes:
		PopupManager.confirm(
			"Nicht gespeicherte Änderungen",
			"Du hast nicht gespeicherte Änderungen. Möchtest du wirklich ohne Speichern zurückkehren?",
			"Abbrechen",
			"Zurück",
			"back_confirmation"
		)
	else:
		get_tree().change_scene_to_file("res://scenes/ui/settings/settings_menu.tscn")

func _on_dialog_confirmed(dialog_id):
	if dialog_id == "back_confirmation":
		get_tree().change_scene_to_file("res://scenes/ui/settings/settings_menu.tscn")
