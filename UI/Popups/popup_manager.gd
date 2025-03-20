extends Node

# Signal, dass ein zuvor erstellter Dialog bestätigt wurde
signal dialog_confirmed(dialog_id: String)
# Signal, dass ein zuvor erstellter Dialog abgebrochen wurde
signal dialog_canceled(dialog_id: String)

# Speichert alle aktiven Popups
var _active_popups = {}

# Zeigt eine einfache Bestätigungsabfrage
func confirm(title: String, message: String, 
			 cancel_text: String = "Abbrechen", confirm_text: String = "Bestätigen",
			 dialog_id: String = "") -> String:
				
	# Generiere eine eindeutige ID, falls keine angegeben wurde
	var id = dialog_id if dialog_id else _generate_id()
	
	# Erstelle und zeige das Popup an
	var popup = _create_popup()
	popup.setup(title, message, cancel_text, confirm_text)
	
	# Verbinde Signale, um weiterzuleiten
	popup.confirmed.connect(func(): 
		emit_signal("dialog_confirmed", id)
		_active_popups.erase(id)
	)
	popup.canceled.connect(func(): 
		emit_signal("dialog_canceled", id)
		_active_popups.erase(id)
	)
	
	# Speichere das Popup für spätere Referenz
	_active_popups[id] = popup
	
	# Zeige das Popup an
	popup.popup()
	
	return id

# Zeigt einen Warnungs-Dialog
func warning(title: String, message: String, button_text: String = "OK") -> String:
	var id = _generate_id()
	var popup = _create_popup()
	
	# Stelle Warnungs-Dialog ein
	popup.setup(
		title, 
		message, 
		"", # Kein Abbrechen-Button
		button_text,
		Color(0.9, 0.6, 0.1, 1) # Orange für Warnungen
	)
	
	# Verbinde Signale
	popup.confirmed.connect(func():
		emit_signal("dialog_confirmed", id)
		_active_popups.erase(id)
	)
	
	# Verstecke den Abbrechen-Button
	popup.cancel_button.visible = false
	
	# Speichere und zeige an
	_active_popups[id] = popup
	popup.popup()
	
	return id

# Zeigt einen Fehler-Dialog
func error(title: String, message: String, button_text: String = "OK") -> String:
	var id = _generate_id()
	var popup = _create_popup()
	
	# Stelle Fehler-Dialog ein
	popup.setup(
		title, 
		message, 
		"", # Kein Abbrechen-Button
		button_text,
		Color(0.8, 0.1, 0.1, 1) # Rot für Fehler
	)
	
	# Verbinde Signale
	popup.confirmed.connect(func():
		emit_signal("dialog_confirmed", id)
		_active_popups.erase(id)
	)
	
	# Verstecke den Abbrechen-Button
	popup.cancel_button.visible = false
	
	# Speichere und zeige an
	_active_popups[id] = popup
	popup.popup()
	
	return id

# Zeigt eine Info-Nachricht
func info(title: String, message: String, button_text: String = "OK") -> String:
	var id = _generate_id()
	var popup = _create_popup()
	
	# Stelle Info-Dialog ein
	popup.setup(
		title, 
		message, 
		"", # Kein Abbrechen-Button
		button_text,
		Color(0.2, 0.6, 0.8, 1) # Blau für Info
	)
	
	# Verbinde Signale
	popup.confirmed.connect(func():
		emit_signal("dialog_confirmed", id)
		_active_popups.erase(id)
	)
	
	# Verstecke den Abbrechen-Button
	popup.cancel_button.visible = false
	
	# Speichere und zeige an
	_active_popups[id] = popup
	popup.popup()
	
	return id

# Schließt einen bestimmten Dialog
func close_dialog(dialog_id: String) -> bool:
	if _active_popups.has(dialog_id):
		_active_popups[dialog_id].close()
		_active_popups.erase(dialog_id)
		return true
	return false

# Schließt alle aktiven Dialoge
func close_all_dialogs():
	for id in _active_popups:
		_active_popups[id].close()
	_active_popups.clear()

# Erstellt eine neue Popup-Instanz
func _create_popup():
	var popup_script = load("res://UI/Popups/popup_dialog.gd")
	# Hier ist die Korrektur: Wir erstellen einen CanvasLayer statt eines Node
	var popup_instance = CanvasLayer.new()
	popup_instance.set_script(popup_script)
	add_child(popup_instance)
	return popup_instance

# Generiert eine eindeutige ID für Dialoge
func _generate_id() -> String:
	return "dialog_" + str(randi())
