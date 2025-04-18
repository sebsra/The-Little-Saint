extends Node

# Core player stats - THE single source of truth
var max_health: float = 3.0
var current_health: float = 3.0
var coins: int = 0
var heaven_coins: int = 0
var elixir_fill_level: float = 0.0

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
			elif amount > 0:
				hud_instance.play_healing_effect()
		
		# Check for death
		if current_health <= 0 and get_node_or_null("/root/Global"):
			
			Global.player_death()
			
		# Save state after health changes
		save_state()

# Coins
func add_coins(amount: int = 1):
	coins += amount
	
	if hud_instance:
		hud_instance.update_coins_display(coins)
		hud_instance.play_coin_effect()
		
	emit_signal("coins_changed", coins)
	save_state()

func add_heaven_coins(amount: int = 1):
	heaven_coins += amount
	
	if hud_instance:
		hud_instance.update_heaven_coins_display(heaven_coins)
		hud_instance.play_heaven_coin_effect()
		
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
		hud_instance.update_heaven_coins_display(heaven_coins)
		
	emit_signal("heaven_coins_changed", heaven_coins)
	save_state()

# Elixir
func update_elixir_fill(amount: float):
	elixir_fill_level = clamp(elixir_fill_level + amount, 0.0, 1.0)
	
	if hud_instance:
		hud_instance.update_elixir_display(elixir_fill_level)
		
	emit_signal("elixir_changed", elixir_fill_level)
	save_state()

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
		#SaveManager.current_save_data.heaven_coins = 1
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
			emit_signal("power_up_deactivated", power_up_name)
			
			# Notify HUD
			if hud_instance:
				hud_instance.hide_power_up_display(power_up_name)
