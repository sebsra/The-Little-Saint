# preview_helper.gd
# Diese Datei enthält Hilfsfunktionen für die Vorschau im Character-Customizer

extends Node

# Cache für Outfit-Vorschaubilder
var preview_cache = {}

# Generiert ein Vorschaubild für ein komplettes Outfit
# Kann verwendet werden, um mehrere Outfits nebeneinander anzuzeigen
func generate_outfit_preview(character_sprites, outfit_config):
	var viewport = SubViewport.new()
	viewport.size = Vector2i(128, 128)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	var sprites_instance = character_sprites.duplicate()
	viewport.add_child(sprites_instance)
	
	# Positioniere die Sprites in der Mitte des Viewports
	sprites_instance.position = Vector2(64, 64)
	sprites_instance.scale = Vector2(4, 4)
	
	# Setze das Outfit gemäß der Konfiguration
	for category in outfit_config:
		if sprites_instance.has_node(category):
			var sprite = sprites_instance.get_node(category)
			if str(outfit_config[category]) == "none":
				sprite.visible = false
			else:
				sprite.visible = true
				sprite.animation = str(outfit_config[category])
				sprite.frame = 1
	
	# Rendern und Vorschaubild zurückgeben
	await get_tree().process_frame
	await get_tree().process_frame
	
	var texture = viewport.get_texture()
	var image = texture.get_image()
	
	# Viewport und Duplikat aufräumen
	viewport.remove_child(sprites_instance)
	sprites_instance.queue_free()
	viewport.queue_free()
	
	return image

# Speichert ein Outfit in einem gesonderten Bereich für Favoriten
func save_to_favorites(outfit_config, name = ""):
	var favorites = load_favorites()
	
	if name.empty():
		name = "Outfit " + str(favorites.size() + 1)
	
	favorites[name] = outfit_config
	
	var config = ConfigFile.new()
	config.set_value("favorites", "outfits", favorites)
	var err = config.save("user://favorites.cfg")
	
	return err == OK

# Lädt alle gespeicherten Favoriten
func load_favorites():
	var config = ConfigFile.new()
	var err = config.load("user://favorites.cfg")
	
	if err == OK:
		return config.get_value("favorites", "outfits", {})
	else:
		return {}

# Konvertiert ein Outfit in ein exportierbares Format (z.B. JSON)
func export_outfit_to_json(outfit_config):
	return JSON.stringify(outfit_config)

# Importiert ein Outfit aus einem exportierten Format
func import_outfit_from_json(json_string):
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		return json.get_data()
	else:
		return null
