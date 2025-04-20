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
	
	# Vermeide Duplikate, falls Dialog bereits existiert
	if _active_popups.has(id):
		close_dialog(id)
	
	# Erstelle und zeige das Popup an
	var popup = _create_popup()
	popup.setup(title, message, cancel_text, confirm_text)
	
	# Verbinde Signale
	var confirmed_callable = Callable(self, "_on_popup_confirmed").bind(id)
	var canceled_callable = Callable(self, "_on_popup_canceled").bind(id)
	
	popup.confirmed.connect(confirmed_callable)
	popup.canceled.connect(canceled_callable)
	
	# Speichere das Popup und Callback-Referenzen für spätere Reinigung
	_active_popups[id] = {
		"popup": popup,
		"confirmed_callable": confirmed_callable,
		"canceled_callable": canceled_callable
	}
	
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
	var confirmed_callable = Callable(self, "_on_popup_confirmed").bind(id)
	popup.confirmed.connect(confirmed_callable)
	
	# Verstecke den Abbrechen-Button
	popup.cancel_button.visible = false
	
	# Speichere und zeige an
	_active_popups[id] = {
		"popup": popup,
		"confirmed_callable": confirmed_callable
	}
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
	var confirmed_callable = Callable(self, "_on_popup_confirmed").bind(id)
	popup.confirmed.connect(confirmed_callable)
	
	# Verstecke den Abbrechen-Button
	popup.cancel_button.visible = false
	
	# Speichere und zeige an
	_active_popups[id] = {
		"popup": popup,
		"confirmed_callable": confirmed_callable
	}
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
	var confirmed_callable = Callable(self, "_on_popup_confirmed").bind(id)
	popup.confirmed.connect(confirmed_callable)
	
	# Verstecke den Abbrechen-Button
	popup.cancel_button.visible = false
	
	# Speichere und zeige an
	_active_popups[id] = {
		"popup": popup,
		"confirmed_callable": confirmed_callable
	}
	popup.popup()
	
	return id

# Schließt einen bestimmten Dialog
func close_dialog(dialog_id: String) -> bool:
	if _active_popups.has(dialog_id):
		var dialog_data = _active_popups[dialog_id]
		var popup = dialog_data["popup"]
		
		# Trenne Signalverbindungen
		if dialog_data.has("confirmed_callable") and popup.confirmed.is_connected(dialog_data["confirmed_callable"]):
			popup.confirmed.disconnect(dialog_data["confirmed_callable"])
			
		if dialog_data.has("canceled_callable") and popup.canceled.is_connected(dialog_data["canceled_callable"]):
			popup.canceled.disconnect(dialog_data["canceled_callable"])
		
		# Schließe das Popup und entferne es
		popup.close()
		popup.queue_free()
		_active_popups.erase(dialog_id)
		return true
	return false

# Schließt alle aktiven Dialoge
func close_all_dialogs():
	var dialogs_to_close = _active_popups.keys().duplicate()
	for dialog_id in dialogs_to_close:
		close_dialog(dialog_id)

# Interne Methode: Handler für Dialog-Bestätigung
func _on_popup_confirmed(dialog_id: String):
	# Signal emittieren bevor Dialog geschlossen wird
	emit_signal("dialog_confirmed", dialog_id)
	# Dialog schließen und aufräumen
	close_dialog(dialog_id)

# Interne Methode: Handler für Dialog-Abbruch
func _on_popup_canceled(dialog_id: String):
	# Signal emittieren bevor Dialog geschlossen wird
	emit_signal("dialog_canceled", dialog_id)
	# Dialog schließen und aufräumen
	close_dialog(dialog_id)

# Erstellt eine neue Popup-Instanz
func _create_popup():
	var popup_script = load("res://scripts/ui/dialogs/popup_dialog.gd")
	# Wir erstellen einen CanvasLayer
	var popup_instance = CanvasLayer.new()
	popup_instance.set_script(popup_script)
	add_child(popup_instance)
	return popup_instance

# Generiert eine eindeutige ID für Dialoge
func _generate_id() -> String:
	return "dialog_" + str(randi())
