extends Node2D

# Variable zum Verfolgen, ob der Spieler den Goldsack trägt
var player_has_sack: bool = false
# Variable zum Verfolgen, ob bereits ein Sack-Dialog aktiv ist
var is_sack_dialog_active: bool = false
# Variablen für die Dialogverwaltung
var _current_player_body: Node2D = null
var _current_dialog_id: String = ""
# Variablen für die Plattformbewegung
var platform_initial_position: Vector2
var platform_top_position: Vector2
var boss_music = load("res://assets/audio/music/Tracks/the-epic-2-by-rafael-krux(chosic.com).mp3")
func _ready() -> void:
	AudioManager.play_track(boss_music)
	# Verbinde mit dem player_died Signal aus dem Global Autoload in Godot 4.4 Syntax
	Global.player_died.connect(_on_player_died)
	$BeggarChild.has_been_helped = false
	if get_node_or_null("/root/Global"):
		Global.set_coin_type(Global.CoinType.NORMAL)
		await get_tree().create_timer(4.0).timeout
		GlobalHUD.set_coins(0)
	# Verbinde mit den Signalen des Goldsacks
	if has_node("sack_of_gold"):
		var sack = get_node("sack_of_gold")
		sack.sack_of_gold_collected.connect(_on_sack_of_gold_collected)
		sack.sack_of_gold_dropped.connect(_on_sack_of_gold_dropped)

	# Initialize blocker state
	update_blocker()
	
	# Plattformbewegung einrichten
	setup_platform_movement()

# Funktion, um die Plattformbewegung einzurichten
func setup_platform_movement() -> void:
	if has_node("platform"):
		var platform = get_node("platform")
		# Speichere die Anfangsposition der Plattform
		platform_initial_position = platform.position
		# Setze die obere Position (gleiche x-Koordinate, aber y = -950)
		platform_top_position = Vector2(platform.position.x, -950)
		
		# Starte die Bewegungssequenz für die Plattform
		var tween = create_tween().set_loops()  # Endlose Wiederholung
		
		# Bewegung nach oben
		tween.tween_property(platform, "position", platform_top_position, 2.0)
		# Pause oben
		tween.tween_interval(1.0)
		# Bewegung nach unten
		tween.tween_property(platform, "position", platform_initial_position, 2.0)
		# Pause unten
		tween.tween_interval(1.0)

# Function to update blocker's collision layer based on whether player has sack
func update_blocker():
	if has_node("blocker"):
		var blocker = get_node("blocker")
		if player_has_sack:
			# Set to active collision layer (1)
			blocker.collision_layer = 1
		else:
			# Set to inactive collision layer (5)
			blocker.collision_layer =16

# Diese Funktion wird aufgerufen, wenn die set_back_zone betreten wird
func _on_set_back_zone_body_entered(body: Node2D) -> void:
	$Player.position = Vector2(100, -100)  # Replace with your desired coordinates
	GlobalHUD.change_life(-1)
	
	# Falls der Spieler den Sack trägt, diesen fallen lassen
	if player_has_sack and $Player.has_node("sack_of_gold"):
		var sack = $Player.get_node("sack_of_gold")
		sack.drop_sack(Vector2(100, -50), self)  # Etwas über der Respawn-Position

# Diese Funktion wird aufgerufen, wenn das player_died Signal emittiert wird
func _on_player_died() -> void:
	if player_has_sack and $Player.has_node("sack_of_gold"):
		var sack = $Player.get_node("sack_of_gold")
		sack.drop_sack($Player.global_position + Vector2(0, -50), self)
	
	await get_tree().create_timer(3.0).timeout
	$Player.position = Vector2(-4611.0, -485.0)
	GlobalHUD.change_life(3.0)
	$Player.state_machine.change_state("PlayerIdleState")
	
func _on_water_body_entered(body):
	if body.name == "Player" or body.is_in_group("Player"):
		body.state_machine.change_state("PlayerSwimState")
		# Wir legen den Sack NICHT automatisch im Wasser ab
		# Der Sack soll nur durch den Dialog-Mechanismus abgelegt werden
	
	if body.is_in_group("enemy"):
		body.take_damage(1000.0)
		GlobalHUD.add_message("Ein Feind wurde im Wasser begraben")

func _on_water_body_exited(body):
	if body.name == "Player" or body.is_in_group("Player"):
		body.state_machine.change_state("PlayerIdleState")

# Signal-Handler für das Einsammeln des Goldsacks
func _on_sack_of_gold_collected(sack, player):
	player_has_sack = true
	GlobalHUD.add_message("+100 Goldmünzen! Du trägst jetzt den Goldsack")
	update_blocker()  # Update blocker collision layer
	
	# Hier kannst du weitere Aktionen ausführen, wenn der Spieler den Sack einsammelt
	# Zum Beispiel die Spielergeschwindigkeit verringern
	# player.movement_speed *= 0.8

# Signal-Handler für das Ablegen des Goldsacks
func _on_sack_of_gold_dropped(sack, position):
	player_has_sack = false
	GlobalHUD.set_coins(15)
	GlobalHUD.add_message("Du hast den Goldsack abgelegt")
	update_blocker()  # Update blocker collision layer
	
	# Hier kannst du weitere Aktionen ausführen, wenn der Spieler den Sack ablegt
	# Zum Beispiel die Spielergeschwindigkeit wiederherstellen
	# player.movement_speed /= 0.8

# Methode zum Ablegen des Sacks durch Spielereingabe
func drop_sack_if_player_has_it():
	if player_has_sack and $Player.has_node("sack_of_gold"):
		var sack = $Player.get_node("sack_of_gold")
		sack.drop_sack($Player.global_position + Vector2(0, 50), self)  # Level als Ziel-Parent

# Eingabeverarbeitung für das Ablegen des Sacks
func _input(event):
	# Beispiel mit der Taste "G" zum Ablegen des Sacks
	if event.is_action_pressed("drop_item") or (event is InputEventKey and event.pressed and event.keycode == KEY_G):
		drop_sack_if_player_has_it()

# Wird ausgelöst, wenn der Spieler den Sack-Detektor betritt
func _on_sack_detector_body_entered(body: Node2D) -> void:
	# Update blocker based on current sack status
	update_blocker()
	
	if (body.name == "Player" or body.is_in_group("Player")) and player_has_sack and not is_sack_dialog_active:
		# Dialog-Zustand setzen
		is_sack_dialog_active = true
		
		# Spieler-Körper speichern für spätere Verarbeitung
		_current_player_body = body
		
		# Dialog erstellen und anzeigen
		_current_dialog_id = PopupManager.confirm(
			"Ballast im Wasser entsorgen", 
			"Du trägst einen schwern Goldsack.... Mancher Ballast muss im Wasser begraben werden, leider kannst du nur 15 Münzen tragen.",
			"Abbrechen",
			"Okay, Sack ablegen"
		)
		
		# Verbinde die Dialog-Signale OHNE bind-Parameter
		PopupManager.dialog_confirmed.connect(_on_dialog_confirmed, CONNECT_ONE_SHOT)
		PopupManager.dialog_canceled.connect(_on_dialog_canceled, CONNECT_ONE_SHOT)

# Generischer Handler für Dialog-Bestätigung
func _on_dialog_confirmed(dialog_id: String):
	# Prüfen, ob es unser aktuelles Dialog ist
	if dialog_id == _current_dialog_id:
		# Dialog-Zustand zurücksetzen
		is_sack_dialog_active = false
		
		# Prüfen, ob der Spieler den Sack hat
		if player_has_sack and _current_player_body and _current_player_body.has_node("sack_of_gold"):
			# Sack ins Wasser ablegen
			var sack = _current_player_body.get_node("sack_of_gold")
			var drop_position = _current_player_body.global_position + Vector2(0, 50)
			sack.drop_sack(drop_position, self)
			
			# Nachricht anzeigen
			GlobalHUD.add_message("Der Goldsack wurde im Wasser versenkt")
			
			# Screenshot mit 0.5 Sekunden Verzögerung erstellen
			# Dies gibt Zeit für die visuelle Änderung nach dem Ablegen des Sacks
			var screenshot_id = "sack_drop_" + str(Time.get_unix_time_from_system())
			ScreenshotManager.take_screenshot(screenshot_id, 0.5)
			
# Generischer Handler für Dialog-Abbruch
func _on_dialog_canceled(dialog_id: String):
	# Prüfen, ob es unser aktuelles Dialog ist
	if dialog_id == _current_dialog_id:
		# Dialog-Zustand zurücksetzen
		is_sack_dialog_active = false
