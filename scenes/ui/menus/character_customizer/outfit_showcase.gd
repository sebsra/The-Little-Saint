class_name OutfitShowcase
# outfit_showcase.gd
extends Control

var current_outfits = {}
var preview_container
var outfit_grid
var back_button
var outfit_name_field
var save_button
var delete_button
var preview_helper

func _ready():
	preview_helper = load("res://scripts/ui/character_customizer/preview_helper.gd").new()
	add_child(preview_helper)
	
	# UI erstellen
	setup_ui()
	
	# Gespeicherte Outfits laden
	load_saved_outfits()

func setup_ui():
	# Container für die Vorschau
	preview_container = ScrollContainer.new()
	preview_container.position = Vector2(50, 50)
	preview_container.size = Vector2(900, 400)
	add_child(preview_container)
	
	# Grid für Outfit-Vorschaubilder
	outfit_grid = GridContainer.new()
	outfit_grid.columns = 4
	preview_container.add_child(outfit_grid)
	
	# Textfeld für Outfit-Namen
	var name_label = Label.new()
	name_label.text = "Outfit-Name:"
	name_label.position = Vector2(50, 470)
	add_child(name_label)
	
	outfit_name_field = LineEdit.new()
	outfit_name_field.position = Vector2(150, 470)
	outfit_name_field.size = Vector2(300, 30)
	outfit_name_field.placeholder_text = "Mein cooles Outfit"
	add_child(outfit_name_field)
	
	# Save-Button
	save_button = Button.new()
	save_button.text = "Speichern"
	save_button.position = Vector2(470, 470)
	save_button.size = Vector2(120, 30)
	save_button.pressed.connect(_on_save_pressed)
	add_child(save_button)
	
	# Delete-Button
	delete_button = Button.new()
	delete_button.text = "Löschen"
	delete_button.position = Vector2(600, 470)
	delete_button.size = Vector2(120, 30)
	delete_button.pressed.connect(_on_delete_pressed)
	add_child(delete_button)
	
	# Back-Button
	back_button = Button.new()
	back_button.text = "Zurück"
	back_button.position = Vector2(400, 550)
	back_button.size = Vector2(200, 40)
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)

# Lädt alle gespeicherten Outfits und zeigt sie an
func load_saved_outfits():
	current_outfits = preview_helper.load_favorites()
	
	# UI aktualisieren
	update_showcase()

# Aktualisiert die Anzeige der Outfits
func update_showcase():
	# Alle vorherigen Kinder entfernen
	for child in outfit_grid.get_children():
		outfit_grid.remove_child(child)
		child.queue_free()
	
	# Aktuelle Outfit-Liste durchgehen
	for outfit_name in current_outfits:
		var outfit_config = current_outfits[outfit_name]
		
		# Container für jedes Outfit
		var outfit_container = VBoxContainer.new()
		outfit_grid.add_child(outfit_container)
		
		# Vorschaubild generieren
		var preview_image = await preview_helper.generate_outfit_preview(
			get_node("/root/Main/character_sprites"), 
			outfit_config
		)
		
		# TextureRect für das Vorschaubild
		var preview_rect = TextureRect.new()
		var image_texture = ImageTexture.create_from_image(preview_image)
		preview_rect.texture = image_texture
		preview_rect.custom_minimum_size = Vector2(200, 200)
		preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		outfit_container.add_child(preview_rect)
		
		# Label für den Namen
		var name_label = Label.new()
		name_label.text = outfit_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		outfit_container.add_child(name_label)
		
		# Button zum Laden dieses Outfits
		var load_button = Button.new()
		load_button.text = "Laden"
		load_button.pressed.connect(_on_load_outfit_pressed.bind(outfit_name))
		outfit_container.add_child(load_button)

# Event-Handler

func _on_save_pressed():
	var current_outfit = get_node("/root/Main").get_current_outfit()
	var name = outfit_name_field.text
	
	if name.empty():
		name = "Outfit " + str(current_outfits.size() + 1)
	
	# Outfit zu Favoriten hinzufügen
	preview_helper.save_to_favorites(current_outfit, name)
	
	# Liste aktualisieren
	load_saved_outfits()

func _on_delete_pressed():
	var name = outfit_name_field.text
	if current_outfits.has(name):
		current_outfits.erase(name)
		
		# Aktualisierte Liste speichern
		var config = ConfigFile.new()
		config.set_value("favorites", "outfits", current_outfits)
		config.save("user://favorites.cfg")
		
		# UI aktualisieren
		update_showcase()

func _on_load_outfit_pressed(outfit_name):
	var outfit_config = current_outfits[outfit_name]
	get_node("/root/Main").apply_outfit(outfit_config)
	
	# Eingabefeld aktualisieren
	outfit_name_field.text = outfit_name

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/menus/settings_menu.tscn")
