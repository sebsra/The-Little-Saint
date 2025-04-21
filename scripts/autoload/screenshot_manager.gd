extends Node

# Dictionary für alle aufgenommenen Screenshots
var screenshots = {}

# Aktueller Screenshot-Index für auto-benennung
var current_screenshot_index: int = 0 

# Signal, das ausgelöst wird, wenn ein Screenshot gemacht wurde
signal screenshot_taken(screenshot_id, image)

# Optionale Pfade zum Speichern der Screenshots auf der Festplatte
var save_path: String = "user://screenshots/"

func _ready() -> void:
	# Stelle sicher, dass der Ordner existiert
	if not DirAccess.dir_exists_absolute(save_path):
		DirAccess.make_dir_recursive_absolute(save_path)
	
	# Lade alle zuvor gespeicherten Screenshots vom Speicher
	load_all_saved_screenshots()
	
	# NEUER DEBUG-CODE: Automatisches Hinzufügen von bestehenden Screenshots zu memorable_screenshots
	sync_screenshots_with_memorable()

# Synchronisiere ScreenshotManager mit Global.memorable_screenshots
func sync_screenshots_with_memorable() -> void:
	print("Screenshots synchronisieren...")
	
	# Stelle sicher, dass alle Kategorien existieren
	var categories = {
		"sack_drops": "sack_drop_",
		"sword_collections": "sword_collected_",
		"child_helped": "child_helped_"
	}
	
	# Kategorien in Global initialisieren, falls sie noch nicht existieren
	for category in categories.keys():
		if not category in Global.memorable_screenshots:
			Global.memorable_screenshots[category] = []
	
	# Durchsuche alle Screenshots und füge sie zur entsprechenden Kategorie hinzu
	var screenshot_ids = get_all_screenshot_ids()
	var added_count = {
		"sack_drops": 0,
		"sword_collections": 0,
		"child_helped": 0
	}
	
	# Jeden Screenshot prüfen und der richtigen Kategorie zuordnen
	for id in screenshot_ids:
		for category in categories.keys():
			var prefix = categories[category]
			if id.begins_with(prefix):
				if not id in Global.memorable_screenshots[category]:
					Global.memorable_screenshots[category].append(id)
					added_count[category] += 1
	
	# Debug-Ausgabe
	print("Global.memorable_screenshots nach Sync:", Global.memorable_screenshots)
	print("Hinzugefügte Screenshots:")
	for category in added_count.keys():
		print("- " + category + ": " + str(added_count[category]))

# Screenshot aufnehmen mit optionalem benutzerdefinierten Namen und optionaler Verzögerung
func take_screenshot(screenshot_id: String = "", delay: float = 0.0) -> String:
	# Wenn eine Verzögerung angefordert wird, warte entsprechend
	if delay > 0:
		print("Screenshot wird verzögert um", delay, "Sekunden...")
		await get_tree().create_timer(delay).timeout
		print("Verzögerung vorbei, erstelle Screenshot jetzt")
	
	# Wenn keine ID angegeben ist, generiere automatisch eine
	if screenshot_id.is_empty():
		screenshot_id = "screenshot_" + str(current_screenshot_index)
		current_screenshot_index += 1
	
	# Screenshot der aktuellen Viewport-Ansicht erstellen
	var image = get_viewport().get_texture().get_image()
	
	# Screenshot im Dictionary speichern
	screenshots[screenshot_id] = image
	
	# Speichere den Screenshot sofort auf der Festplatte für Persistenz
	save_screenshot_to_disk(screenshot_id)
	
	# Den Screenshot in die richtige Kategorie einfügen basierend auf ID-Präfix
	var categories = {
		"sack_drop_": "sack_drops",
		"sword_collected_": "sword_collections",
		"child_helped_": "child_helped"
	}
	
	# Prüfe für jede Kategorie, ob der Screenshot dazugehört
	for prefix in categories:
		if screenshot_id.begins_with(prefix):
			var category = categories[prefix]
			# Sicherstellen, dass die Kategorie existiert
			if not category in Global.memorable_screenshots:
				Global.memorable_screenshots[category] = []
			
			# Füge zur Liste der Kategorie hinzu, wenn nicht schon vorhanden
			if not screenshot_id in Global.memorable_screenshots[category]:
				Global.memorable_screenshots[category].append(screenshot_id)
				print("Screenshot zur Kategorie '" + category + "' hinzugefügt:", screenshot_id)
	
	# Debug-Ausgabe
	print("Global.memorable_screenshots:", Global.memorable_screenshots)
	
	# Signal auslösen
	screenshot_taken.emit(screenshot_id, image)
	
	return screenshot_id

# Optional: Screenshot auf die Festplatte speichern
func save_screenshot_to_disk(screenshot_id: String, file_format: String = "png") -> bool:
	if not screenshots.has(screenshot_id):
		push_error("Screenshot mit ID '%s' existiert nicht" % screenshot_id)
		return false
	
	var image = screenshots[screenshot_id]
	var file_path = save_path + screenshot_id + "." + file_format
	
	# Speichern des Bildes in der angegebenen Format
	var error = OK
	if file_format == "png":
		error = image.save_png(file_path)
	else:
		error = image.save_jpg(file_path)
	
	# Debug: Speicherpfad ausgeben
	print("Screenshot gespeichert unter:", file_path, "Ergebnis:", error)
	
	return error == OK

# Lade alle gespeicherten Screenshots vom Dateisystem
func load_all_saved_screenshots() -> void:
	# Überprüfe, ob der Ordner existiert
	var dir = DirAccess.open(save_path)
	if not dir:
		push_error("Konnte den Screenshot-Ordner nicht öffnen: %s" % save_path)
		return
	
	# Durchsuche den Ordner nach allen PNG-Dateien
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".png") or file_name.ends_with(".jpg")):
			var screenshot_id = file_name.get_basename()
			var file_path = save_path + file_name
			
			# In Godot 4.x benutzen wir FileAccess und Image.load_*_from_file
			var image = Image.new()
			var error = OK
			
			# Lade das Bild basierend auf dem Dateityp
			if file_name.ends_with(".png"):
				image = Image.load_from_file(file_path)
				error = image != null
			else:
				image = Image.load_from_file(file_path)
				error = image != null
			
			if error:
				# Füge es zum Dictionary hinzu
				screenshots[screenshot_id] = image
				print("Screenshot geladen: %s" % screenshot_id)
			else:
				push_error("Fehler beim Laden von Screenshot %s" % screenshot_id)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("Insgesamt %d Screenshots geladen" % screenshots.size())

# Screenshot als TextureRect-Node erstellen
func create_texture_rect_from_screenshot(screenshot_id: String) -> TextureRect:
	# Zuerst prüfen, ob der Screenshot im Speicher ist
	if not screenshots.has(screenshot_id):
		# Versuche, ihn von der Festplatte zu laden
		var file_path = save_path + screenshot_id + ".png"
		var alt_file_path = save_path + screenshot_id + ".jpg"
		
		var image = null
		
		if FileAccess.file_exists(file_path):
			image = Image.load_from_file(file_path)
		elif FileAccess.file_exists(alt_file_path):
			image = Image.load_from_file(alt_file_path)
		else:
			push_error("Screenshot mit ID '%s' existiert nicht auf der Festplatte" % screenshot_id)
			return null
		
		if image:
			screenshots[screenshot_id] = image
		else:
			push_error("Fehler beim Laden von Screenshot %s" % screenshot_id)
			return null
	
	var image = screenshots[screenshot_id]
	
	# Erstelle eine ImageTexture aus dem Bild
	var texture = ImageTexture.create_from_image(image)
	
	# Erstelle TextureRect und setze die Textur
	var texture_rect = TextureRect.new()
	texture_rect.texture = texture
	texture_rect.expand = true
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	return texture_rect

# Hole einen bestimmten Screenshot
func get_screenshot(screenshot_id: String) -> Image:
	if not screenshots.has(screenshot_id):
		# Versuche, ihn von der Festplatte zu laden
		var file_path = save_path + screenshot_id + ".png"
		var alt_file_path = save_path + screenshot_id + ".jpg"
		
		var image = null
		
		if FileAccess.file_exists(file_path):
			image = Image.load_from_file(file_path)
		elif FileAccess.file_exists(alt_file_path):
			image = Image.load_from_file(alt_file_path)
		else:
			push_error("Screenshot mit ID '%s' existiert nicht auf der Festplatte" % screenshot_id)
			return null
		
		if image:
			screenshots[screenshot_id] = image
			return image
		else:
			push_error("Fehler beim Laden von Screenshot %s" % screenshot_id)
			return null
	
	return screenshots[screenshot_id]

# Hole die Textur eines Screenshots
func get_screenshot_texture(screenshot_id: String) -> ImageTexture:
	var image = get_screenshot(screenshot_id)
	if image:
		return ImageTexture.create_from_image(image)
	return null

# Lösche einen Screenshot aus dem Speicher und von der Festplatte
func delete_screenshot(screenshot_id: String) -> bool:
	if screenshots.has(screenshot_id):
		screenshots.erase(screenshot_id)
	
	# Prüfe, ob der Screenshot auf der Festplatte existiert
	var file_path = save_path + screenshot_id + ".png"
	var alt_file_path = save_path + screenshot_id + ".jpg"
	
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open(save_path.get_base_dir())
		if dir:
			return dir.remove(file_path) == OK
	
	if FileAccess.file_exists(alt_file_path):
		var dir = DirAccess.open(save_path.get_base_dir())
		if dir:
			return dir.remove(alt_file_path) == OK
	
	return false

# Alle Screenshots löschen
func clear_all_screenshots() -> void:
	screenshots.clear()
	
	# Lösche alle Screenshots von der Festplatte
	var dir = DirAccess.open(save_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".png") or file_name.ends_with(".jpg")):
				dir.remove(file_name)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	current_screenshot_index = 0

# Erhalte alle Screenshot-IDs
func get_all_screenshot_ids() -> Array:
	# Berücksichtige sowohl im Speicher als auch auf der Festplatte
	var ids = screenshots.keys()
	
	# Durchsuche den Ordner nach Screenshots, die noch nicht geladen wurden
	var dir = DirAccess.open(save_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".png") or file_name.ends_with(".jpg")):
				var screenshot_id = file_name.get_basename()
				if not screenshot_id in ids:
					ids.append(screenshot_id)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return ids

# Prüfen, ob ein Screenshot existiert
func has_screenshot(screenshot_id: String) -> bool:
	if screenshots.has(screenshot_id):
		return true
	
	# Prüfe auf der Festplatte
	var file_path = save_path + screenshot_id + ".png"
	var alt_file_path = save_path + screenshot_id + ".jpg"
	
	return FileAccess.file_exists(file_path) or FileAccess.file_exists(alt_file_path)

# Optionale Methode: Video-Aufnahme (eine Reihe von Screenshots in kurzer Zeit)
func record_video(duration: float, fps: int = 30, video_id: String = "video") -> void:
	var frames_to_capture = int(duration * fps)
	var time_between_frames = 1.0 / fps
	
	# Erstelle einen neuen Ordner für die Video-Frames
	var video_folder = video_id + "/"
	screenshots[video_folder] = []
	
	# Starte die Aufnahme
	_record_video_frame(video_folder, frames_to_capture, time_between_frames, 0)

# Hilfsmethode für die Video-Aufnahme (rekursiv)
func _record_video_frame(video_folder: String, total_frames: int, delay: float, current_frame: int) -> void:
	if current_frame >= total_frames:
		# Aufnahme beendet
		print("Video-Aufnahme abgeschlossen: ", video_folder)
		return
	
	# Screenshot machen
	var image = get_viewport().get_texture().get_image()
	screenshots[video_folder].append(image)
	
	# Warte bis zum nächsten Frame
	await get_tree().create_timer(delay).timeout
	
	# Nächsten Frame aufnehmen
	_record_video_frame(video_folder, total_frames, delay, current_frame + 1)

# Hole einen Video-Frame als TextureRect
func get_video_frame_texture_rect(video_id: String, frame_index: int) -> TextureRect:
	var video_folder = video_id + "/"
	
	if not screenshots.has(video_folder) or frame_index >= screenshots[video_folder].size():
		push_error("Video '%s' oder Frame %d existiert nicht" % [video_id, frame_index])
		return null
	
	var image = screenshots[video_folder][frame_index]
	var texture = ImageTexture.create_from_image(image)
	
	var texture_rect = TextureRect.new()
	texture_rect.texture = texture
	texture_rect.expand = true
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	return texture_rect
