extends Node

# Core player stats - THE single source of truth
var max_health: float = 3.0
var current_health: float = 3.0
var coins: int = 0
var heaven_coins: int = 0
var elixir_fill_level: float = 0.0

# Message system
var message_queue = []
var message_history = []
var max_message_history = 10

# Power-up tracking
var active_power_ups: Array = []
var power_up_timers: Dictionary = {}

# Reference to the actual HUD scene instance
var hud_instance = null

# Signals
signal health_changed(new_health, max_health)
signal coins_changed(new_amount)
signal heaven_coins_changed(new_amount)
signal elixir_changed(new_level)
signal power_up_activated(power_up_name, duration)
signal power_up_deactivated(power_up_name)
signal new_message(text, duration, color)

func _ready():
	# Initialize with default values
	reset_to_defaults()
	
	# Connect to player death signal from GameManager
	if get_node_or_null("/root/Global"):
		Global.player_died.connect(_on_player_died)

# Register the actual HUD scene
func register_hud(hud):
	hud_instance = hud
	notify_hud_of_all_values()

# Notify HUD of all current values
func notify_hud_of_all_values():
	if not hud_instance:
		return
		
	# Tell the HUD to update its visuals with our values
	hud_instance.update_health_display(current_health, max_health)
	hud_instance.update_coins_display(coins)
	
	# Update the coin type display if available
	if hud_instance.has_method("update_coin_type_display"):
		hud_instance.update_coin_type_display()
	
	# Use the previous method for backward compatibility
	if hud_instance.has_method("update_heaven_coins_display"):
		hud_instance.update_heaven_coins_display(heaven_coins)
		
	hud_instance.update_elixir_display(elixir_fill_level)
	
	# Sync power-ups if needed
	for power_up in active_power_ups:
		if power_up_timers.has(power_up):
			hud_instance.update_power_up_display(power_up, power_up_timers[power_up].duration)

# Reset HUD to default values
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

# --- Core state modification methods ---

# Health
func change_health(amount: float):
	var old_health = current_health
	current_health = clamp(current_health + amount, 0, max_health)
	
	if current_health != old_health:
		emit_signal("health_changed", current_health, max_health)
		
		if hud_instance:
			hud_instance.update_health_display(current_health, max_health)
			
			if amount < 0:
				hud_instance.play_damage_effect()
				
				# Show a damage message
				if amount <= -1.0:
					add_message("Critical hit! " + str(abs(amount)) + " damage taken!", 3.0, Color(1, 0, 0))
				else:
					add_message("Damage taken: " + str(abs(amount)), 3.0, Color(1, 0.5, 0.5))
			elif amount > 0:
				hud_instance.play_healing_effect()
				
				# Show a healing message
				add_message("Healed for " + str(amount), 3.0, Color(0, 1, 0.5))
		
		# Check for death
		if current_health <= 0 and get_node_or_null("/root/Global"):
			add_message("You died!", 5.0, Color(1, 0, 0))
			Global.player_death()
			
		# Save state after health changes
		save_state()

# Coins
func add_coins(amount: int = 1):
	coins += amount
	
	if hud_instance:
		hud_instance.update_coins_display(coins)
		hud_instance.play_coin_effect()
		
		# Show message for multiple coins
		if amount > 1:
			add_message("Collected " + str(amount) + " coins!", 3.0, Color(1, 0.8, 0))
	
	emit_signal("coins_changed", coins)
	save_state()

func add_heaven_coins(amount: int = 1):
	heaven_coins += amount
	
	if hud_instance:
		if hud_instance.has_method("update_heaven_coins_display"):
			hud_instance.update_heaven_coins_display(heaven_coins)
			
		# If we're in heavenly mode, update the main coin display
		if get_node_or_null("/root/Global") and Global.current_coin_type == Global.CoinType.HEAVENLY:
			hud_instance.update_coins_display(heaven_coins)
			
		if hud_instance.has_method("play_heaven_coin_effect"):
			hud_instance.play_heaven_coin_effect()
		else:
			hud_instance.play_coin_effect()
			
		# Show message for heavenly coins
		add_message("Heavenly coin collected!", 3.0, Color(0, 0.5, 1))
	
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
			
		# If we're in heavenly mode, update the main coin display
		if get_node_or_null("/root/Global") and Global.current_coin_type == Global.CoinType.HEAVENLY:
			hud_instance.update_coins_display(heaven_coins)
		
	emit_signal("heaven_coins_changed", heaven_coins)
	save_state()

# Elixir
func update_elixir_fill(amount: float):
	var old_level = elixir_fill_level
	elixir_fill_level = clamp(elixir_fill_level + amount, 0.0, 1.0)
	
	if hud_instance:
		hud_instance.update_elixir_display(elixir_fill_level)
		
	emit_signal("elixir_changed", elixir_fill_level)
	
	# Show message for significant elixir changes
	if amount >= 0.25:
		add_message("Elixir increased!", 2.0, Color(0.8, 0.2, 0.8))
	elif elixir_fill_level >= 1.0 and old_level < 1.0:
		add_message("Elixir fully charged!", 3.0, Color(1, 0.2, 1))
		
	save_state()

# Message System
func add_message(text: String, duration: float = 5.0, color: Color = Color.WHITE):
	# Create message data
	var message_data = {
		"text": text,
		"duration": duration,
		"color": color,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Add to history
	message_history.push_front(message_data)
	
	# Limit history size
	if message_history.size() > max_message_history:
		message_history.pop_back()
	
	# Emit signal for HUD to display
	emit_signal("new_message", text, duration, color)

func get_message_history():
	return message_history

# Power-ups
func activate_power_up(name: String, duration: float = 0.0):
	# Add to active power-ups
	if not active_power_ups.has(name):
		active_power_ups.append(name)
	
	# Set up timer if it has a duration
	if duration > 0:
		power_up_timers[name] = {
			"duration": duration,
			"time_remaining": duration
		}
	
	# Show message
	add_message(name + " activated!", 3.0, Color(1, 0.5, 0))
	emit_signal("power_up_activated", name, duration)
	
	# Notify HUD
	if hud_instance:
		hud_instance.update_power_up_display(name, duration)

# Handle player death
func _on_player_died():
	#reset_to_defaults()
	save_state()

# Save current HUD state to SaveManager
func save_state():
	if get_node_or_null("/root/SaveManager") and SaveManager.current_save_data:
		SaveManager.current_save_data.health = current_health
		SaveManager.current_save_data.coins = coins
		SaveManager.current_save_data.heaven_coins = heaven_coins
		# Any other HUD state to save

# Load state from SaveManager
func load_state():
	if get_node_or_null("/root/SaveManager") and SaveManager.current_save_data:
		current_health = SaveManager.current_save_data.health
		coins = SaveManager.current_save_data.coins
		heaven_coins = SaveManager.current_save_data.heaven_coins
		# Any other HUD state to load
		
		if hud_instance:
			notify_hud_of_all_values()

# --- Convenience methods ---

# Legacy API compatibility
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

# ProcessMode allows updating power-up timers
func _process(delta):
	# Update power-up timers
	for power_up_name in power_up_timers.keys():
		var timer_data = power_up_timers[power_up_name]
		timer_data.time_remaining -= delta
		
		# Check if power-up has expired
		if timer_data.time_remaining <= 0:
			power_up_timers.erase(power_up_name)
			active_power_ups.erase(power_up_name)
			
			# Show message
			add_message(power_up_name + " expired", 3.0, Color(0.7, 0.7, 0.7))
			emit_signal("power_up_deactivated", power_up_name)
			
			# Notify HUD
			if hud_instance:
				hud_instance.hide_power_up_display(power_up_name)
