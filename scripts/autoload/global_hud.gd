extends Node

# Kernspielerstatistiken - DIE einzige Quelle der Wahrheit
var max_health: float = 3.0
var current_health: float = 3.0
var coins: int = 0
var heaven_coins: int = 0
var elixir_fill_level: float = 0.0

# Nachrichtensystem
var message_queue = []
var message_history = []
var max_message_history = 10

# Power-Up-Verfolgung
var active_power_ups: Array = []
var power_up_timers: Dictionary = {}

# Referenz zur tatsächlichen HUD-Szeneninstanz
var hud_instance = null

# Signale
signal health_changed(new_health, max_health) # Gesundheit geändert
signal coins_changed(new_amount) # Münzen geändert
signal heaven_coins_changed(new_amount) # Himmelsmünzen geändert
signal elixir_changed(new_level) # Elixier geändert
signal power_up_activated(power_up_name, duration) # Power-Up aktiviert
signal power_up_deactivated(power_up_name) # Power-Up deaktiviert
signal new_message(text, duration, color) # Neue Nachricht

#Visibility
var visible

func _ready():
	# Initialisierung mit Standardwerten
	reset_to_defaults()
	
	# Initially set the HUD to visible
	visible = true
	# Connect to the scene's pause signal to toggle visibility when game is paused/unpaused
	
	
	# Verbinde mit dem Spieler-Tod-Signal vom GameManager
	if get_node_or_null("/root/Global"):
		Global.player_died.connect(_on_player_died)

# Registriere die tatsächliche HUD-Szene
func register_hud(hud):
	hud_instance = hud
	notify_hud_of_all_values()

# Function to hide the HUD
func hide_hud():
	if hud_instance:
		hud_instance.visible = false
		print("HUD is now hidden.")

# Function to show the HUD
func show_hud():
	if hud_instance:
		hud_instance.visible = true
		print("HUD is now visible.")
	else:
		print("Error: HUD instance not found!")
# Benachrichtige das HUD über alle aktuellen Werte
func notify_hud_of_all_values():
	if not hud_instance:
		return
		
	# Sage dem HUD, dass es seine Visualisierungen mit unseren Werten aktualisieren soll
	hud_instance.update_health_display(current_health, max_health)
	hud_instance.update_coins_display(coins)
	
	# Aktualisiere die Münztyp-Anzeige, falls verfügbar
	if hud_instance.has_method("update_coin_type_display"):
		hud_instance.update_coin_type_display()
	
	# Verwende die vorherige Methode für Abwärtskompatibilität
	if hud_instance.has_method("update_heaven_coins_display"):
		hud_instance.update_heaven_coins_display(heaven_coins)
		
	hud_instance.update_elixir_display(elixir_fill_level)
	
	# Synchronisiere Power-Ups, falls erforderlich
	for power_up in active_power_ups:
		if power_up_timers.has(power_up):
			hud_instance.update_power_up_display(power_up, power_up_timers[power_up].duration)

# Setze das HUD auf Standardwerte zurück
func reset_to_defaults():
	current_health = max_health
	coins = 0
	heaven_coins = 0
	elixir_fill_level = 0.0
	active_power_ups.clear()
	power_up_timers.clear()
	message_queue.clear()
	message_history.clear()
	
	if hud_instance:
		notify_hud_of_all_values()

# --- Kernzustandsänderungsmethoden ---

# Gesundheit
func change_health(amount: float):
	var old_health = current_health
	current_health = clamp(current_health + amount, 0, max_health)
	
	if current_health != old_health:
		emit_signal("health_changed", current_health, max_health)
		
		if hud_instance:
			hud_instance.update_health_display(current_health, max_health)
			
			if amount < 0:
				hud_instance.play_damage_effect()
				
				# Zeige eine Schadensnachricht
				if amount <= -1.0:
					add_message("Kritischer Treffer! " + str(abs(amount)) + " Schaden erlitten!", 3.0, Color(1, 0, 0))
				else:
					add_message("Schaden erlitten: " + str(abs(amount)), 3.0, Color(1, 0.5, 0.5))
			elif amount > 0:
				hud_instance.play_healing_effect()
				
				# Zeige eine Heilungsnachricht
				add_message("Geheilt für " + str(amount), 3.0, Color(0, 1, 0.5))
		
		# Überprüfe auf Tod
		if current_health <= 0 and get_node_or_null("/root/Global"):
			add_message("Du bist gestorben!", 5.0, Color(1, 0, 0))
			Global.player_death()
			
		# Speichere den Zustand nach Gesundheitsänderungen
		save_state()

# Münzen
func add_coins(amount: int = 1):
	coins += amount
	
	if hud_instance:
		hud_instance.update_coins_display(coins)
		hud_instance.play_coin_effect()
		
		# Zeige Nachricht für mehrere Münzen
		if amount > 1:
			add_message("Gesammelt " + str(amount) + " Münzen!", 3.0, Color(1, 0.8, 0))
	
	emit_signal("coins_changed", coins)
	save_state()

func add_heaven_coins(amount: int = 1):
	heaven_coins += amount
	
	if hud_instance:
		if hud_instance.has_method("update_heaven_coins_display"):
			hud_instance.update_heaven_coins_display(heaven_coins)
			
		# Wenn wir im Himmelsmodus sind, aktualisiere die Hauptmünzanzeige
		if get_node_or_null("/root/Global") and Global.current_coin_type == Global.CoinType.HEAVENLY:
			hud_instance.update_coins_display(heaven_coins)
			
		if hud_instance.has_method("play_heaven_coin_effect"):
			hud_instance.play_heaven_coin_effect()
		else:
			hud_instance.play_coin_effect()
			
		# Zeige Nachricht für Himmelsmünzen
		add_message("Himmelsmünze gesammelt!", 3.0, Color(0, 0.5, 1))
	
	emit_signal("heaven_coins_changed", heaven_coins)
	save_state()

func set_coins(amount: int):
	coins = max(0, amount)
	
	if hud_instance:
		hud_instance.update_coins_display(coins)
		
	emit_signal("coins_changed", coins)
	save_state()
	
func set_heaven_coins(amount: int):
	heaven_coins = max(0, amount)
	
	if hud_instance:
		if hud_instance.has_method("update_heaven_coins_display"):
			hud_instance.update_heaven_coins_display(heaven_coins)
			
		# Wenn wir im Himmelsmodus sind, aktualisiere die Hauptmünzanzeige
		if get_node_or_null("/root/Global") and Global.current_coin_type == Global.CoinType.HEAVENLY:
			hud_instance.update_coins_display(heaven_coins)
		
	emit_signal("heaven_coins_changed", heaven_coins)
	save_state()

# Elixier
func update_elixir_fill(amount: float):
	var old_level = elixir_fill_level
	elixir_fill_level = clamp(elixir_fill_level + amount, 0.0, 1.0)
	
	if hud_instance:
		hud_instance.update_elixir_display(elixir_fill_level)
		
	emit_signal("elixir_changed", elixir_fill_level)
	
	# Zeige Nachricht für signifikante Elixieränderungen
	if amount >= 0.25:
		add_message("Elixier erhöht!", 2.0, Color(0.8, 0.2, 0.8))
	elif elixir_fill_level >= 1.0 and old_level < 1.0:
		add_message("Elixier vollständig aufgeladen!", 3.0, Color(1, 0.2, 1))
		
	save_state()

# Nachrichtensystem
func add_message(text: String, duration: float = 5.0, color: Color = Color.WHITE):
	# Erstelle Nachrichtendaten
	var message_data = {
		"text": text,
		"duration": duration,
		"color": color,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Füge zur Historie hinzu
	message_history.push_front(message_data)
	
	# Begrenze die Größe der Historie
	if message_history.size() > max_message_history:
		message_history.pop_back()
	
	# Sende Signal für das HUD zur Anzeige
	emit_signal("new_message", text, duration, color)

func get_message_history():
	return message_history

# Power-Ups
func activate_power_up(name: String, duration: float = 0.0):
	# Füge zu aktiven Power-Ups hinzu
	if not active_power_ups.has(name):
		active_power_ups.append(name)
	
	# Richte Timer ein, falls er eine Dauer hat
	if duration > 0:
		power_up_timers[name] = {
			"duration": duration,
			"time_remaining": duration
		}
	
	# Zeige Nachricht
	add_message(name + " aktiviert!", 3.0, Color(1, 0.5, 0))
	emit_signal("power_up_activated", name, duration)
	
	# Benachrichtige das HUD
	if hud_instance:
		hud_instance.update_power_up_display(name, duration)

# Behandle Spielertod
func _on_player_died():
	#reset_to_defaults()
	save_state()

# Speichere den aktuellen HUD-Zustand im SaveManager
func save_state():
	if get_node_or_null("/root/SaveManager") and SaveManager.current_save_data:
		SaveManager.current_save_data.health = current_health
		SaveManager.current_save_data.coins = coins
		SaveManager.current_save_data.heaven_coins = heaven_coins
		# Alle anderen zu speichernden HUD-Zustände

# Lade den Zustand vom SaveManager
func load_state():
	if get_node_or_null("/root/SaveManager") and SaveManager.current_save_data:
		current_health = SaveManager.current_save_data.health
		coins = SaveManager.current_save_data.coins
		heaven_coins = SaveManager.current_save_data.heaven_coins
		# Alle anderen zu ladenden HUD-Zustände
		
		if hud_instance:
			notify_hud_of_all_values()

# --- Komfortmethoden ---

# Legacy-API-Kompatibilität
func change_life(amount: float):
	change_health(amount)

func coin_collected():
	add_coins(1)

func heaven_coin_collected():
	add_heaven_coins(1)

func collect_softpower(amount: float = 0.25):
	update_elixir_fill(amount)

func use_softpower(amount: float = 0.25) -> bool:
	if elixir_fill_level >= amount:
		update_elixir_fill(-amount)
		return true
	return false

# ProcessMode ermöglicht das Aktualisieren von Power-Up-Timern
func _process(delta):
	# Aktualisiere Power-Up-Timer
	for power_up_name in power_up_timers.keys():
		var timer_data = power_up_timers[power_up_name]
		timer_data.time_remaining -= delta
		
		# Überprüfe, ob das Power-Up abgelaufen ist
		if timer_data.time_remaining <= 0:
			power_up_timers.erase(power_up_name)
			active_power_ups.erase(power_up_name)
			
			# Zeige Nachricht
			add_message(power_up_name + " abgelaufen", 3.0, Color(0.7, 0.7, 0.7))
			emit_signal("power_up_deactivated", power_up_name)
			
			# Benachrichtige das HUD
			if hud_instance:
				hud_instance.hide_power_up_display(power_up_name)
