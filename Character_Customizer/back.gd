extends Button

# Konstante für die Ziel-Szene
const TARGET_SCENE = "res://Start_Screen/start_screen.tscn"

# Signal für Button-Klick
signal back_button_pressed

# Wird aufgerufen, wenn der Node in den Szenenbaum eingefügt wird
func _ready():
	# Button mit Hover-Effekt verbessern
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exit)

# Hover-Effekt beim Betreten des Buttons
func _on_mouse_entered():
	modulate = Color(0.9, 0.9, 1.0, 1.0)  # Leicht heller

# Hover-Effekt beim Verlassen des Buttons
func _on_mouse_exit():
	modulate = Color(1.0, 1.0, 1.0, 1.0)  # Zurück zur normalen Farbe

# Diese Funktion könnte genutzt werden, falls eine Bestätigungsdialog
# vor dem Zurückkehren angezeigt werden soll
func confirm_back():
	# Hier könnte ein Bestätigungsdialog eingefügt werden
	# Für jetzt kehren wir direkt zurück
	get_tree().change_scene_to_file(TARGET_SCENE)
