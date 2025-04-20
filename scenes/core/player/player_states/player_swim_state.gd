class_name PlayerSwimState
extends PlayerState

# Variables for random water resistance
var base_resistance := 0.7  # Base resistance factor (30% speed reduction)
var resistance_variation := 0.2  # How much resistance can vary (±20%)
var current_resistance := base_resistance
var resistance_timer := 0.0
var resistance_change_interval := 0.5  # How often resistance changes (seconds)

# Splash effect variables
# Either create this scene or replace with your own water effect
# You can comment this line and use the fallback particle method below
var splash_scene = null
# var splash_scene = load("res://effects/WaterSplash.tscn")  # Use load instead of preload to avoid errors
var last_water_level := 0.0  # Track water level for splash effects

func enter():
	player.current_animation = "idle"
	
	# Spieler horizontal ausrichten
	player.get_node("character_sprites").rotation_degrees = 90
	
	# Get current velocity and reduce it (water entry slowdown)
	var entry_velocity = get_velocity()
	entry_velocity *= 0.5  # Reduce velocity by half when entering water
	set_velocity(entry_velocity)
	
	# Create splash effect when entering water
	create_splash_effect(true)  # true = entering water
	
	if player.debug_mode:
		print("Entered Swim State")

func physics_process(delta: float):
	# Update random resistance
	update_resistance(delta)
	
	# Reduzierte Schwerkraft (Auftrieb im Wasser)
	var velocity = get_velocity()
	velocity.y += (player.GRAVITY * 0.3) * delta
	
	# Eingaben lesen
	var x_input = Input.get_axis("left", "right")
	var y_input = Input.get_axis("down", "up")
	
	# Horizontale Bewegung mit zufälligem Widerstand
	if x_input != 0:
		velocity.x = x_input * (player.SPEED * current_resistance)
	else:
		velocity.x = move_toward(velocity.x, 0, 15 * current_resistance)
	
	# Vertikale Bewegung mit zufälligem Widerstand
	if y_input != 0:
		velocity.y = -y_input * (player.SPEED * current_resistance)
	else:
		velocity.y = move_toward(velocity.y, 0, 15 * current_resistance)
	
	# Check if player is near water surface to create ripples
	check_surface_effects(velocity)
		
	set_velocity(velocity)
	
	# Bewegung für character body verarbeiten
	player.move_and_slide()
	
	# Outfit aktualisieren
	update_outfit()

# Function to randomly vary water resistance
func update_resistance(delta: float):
	resistance_timer += delta
	if resistance_timer >= resistance_change_interval:
		resistance_timer = 0.0
		# Random value between -resistance_variation and +resistance_variation
		var variation = (randf() * 2.0 - 1.0) * resistance_variation
		current_resistance = base_resistance + variation
		# Ensure resistance stays within reasonable limits
		current_resistance = clamp(current_resistance, base_resistance - resistance_variation, 
								base_resistance + resistance_variation)

# Function to check if player is near water surface and create effects
func check_surface_effects(velocity: Vector2):
	# Approximate water surface position (adjust to match your game)
	var water_surface_y = player.global_position.y - 50  # Adjust this value
	
	# If player is moving up/down near the surface
	if abs(player.global_position.y - water_surface_y) < 10:
		# Create small ripples/bubbles based on movement speed
		if abs(velocity.y) > 50:
			# Create smaller splash or bubbles
			create_ripple_effect(velocity.y < 0)  # true if moving up (exiting)
	
	# Store water level for comparison next frame
	last_water_level = player.global_position.y

# Create splash effect when entering/exiting water
func create_splash_effect(is_entering: bool):
	if splash_scene:
		# If you have a splash scene, use it
		var splash = splash_scene.instantiate()
		player.get_parent().add_child(splash)
		splash.global_position = player.global_position
		
		# Configure splash based on entering or exiting
		if is_entering:
			splash.scale = Vector2(1.0, 1.0)
		else:
			splash.scale = Vector2(1.5, 1.5)  # Bigger splash when exiting
		
		# Start splash animation
		splash.play()
	else:
		# Fallback: Create CPUParticles2D for water splash
		var particles = CPUParticles2D.new()
		player.get_parent().add_child(particles)
		particles.global_position = player.global_position
		
		# Basic water-like particle settings
		particles.amount = 20 if is_entering else 30
		particles.lifetime = 0.7
		particles.explosiveness = 0.8
		particles.direction = Vector2(0, -1)  # Spray upward
		particles.spread = 60.0
		particles.gravity = Vector2(0, 980)
		particles.initial_velocity_min = 150.0
		particles.initial_velocity_max = 250.0
		particles.scale_amount_min = 3.0
		particles.scale_amount_max = 3.0
		particles.color = Color(0.7, 0.8, 1.0, 0.7)  # Light blue water color
		
		# Auto-remove particles after they finish
		particles.one_shot = true
		particles.emitting = true
		
		# Create a timer to free the particles after they're done
		var timer = Timer.new()
		particles.add_child(timer)
		timer.wait_time = particles.lifetime + 0.2
		timer.one_shot = true
		timer.timeout.connect(func(): particles.queue_free())
		timer.start()

# Create smaller ripple effects when moving near surface
func create_ripple_effect(is_exiting: bool):
	if splash_scene:
		# If you have a splash scene, use it with smaller scale
		var ripple = splash_scene.instantiate()
		player.get_parent().add_child(ripple)
		ripple.global_position = player.global_position
		
		# Smaller scale for ripples
		ripple.scale = Vector2(0.5, 0.5)
		
		# Configure based on direction
		if is_exiting:
			ripple.flip_v = true
		
		# Start ripple animation
		ripple.play()
	else:
		# Fallback: Create CPUParticles2D for ripple effect
		var particles = CPUParticles2D.new()
		player.get_parent().add_child(particles)
		particles.global_position = player.global_position
		
		# Basic ripple-like particle settings
		particles.amount = 10
		particles.lifetime = 0.5
		particles.explosiveness = 0.6
		particles.direction = Vector2(0, -1)
		particles.spread = 80.0
		particles.gravity = Vector2(0, 490)
		particles.initial_velocity_min = 80.0
		particles.initial_velocity_max = 120.0
		particles.scale_amount = 2.0
		particles.color = Color(0.8, 0.9, 1.0, 0.5)  # Very light blue water color
		
		# Auto-remove particles after they finish
		particles.one_shot = true
		particles.emitting = true
		
		# Create a timer to free the particles after they're done
		var timer = Timer.new()
		particles.add_child(timer)
		timer.wait_time = particles.lifetime + 0.2
		timer.one_shot = true
		timer.timeout.connect(func(): particles.queue_free())
		timer.start()
	
# Function to update the outfit based on the current state
func update_outfit():
	var player_outfit = player.player_outfit
	var player_animations = player.player_animations
	var current_animation = player.current_animation

	for outfit in player_outfit:
		var animated_sprite = player.get_node("character_sprites/" + outfit)
		var selected_outfit = player_outfit[outfit]

		if str(selected_outfit) == "none":
			animated_sprite.visible = false
		else:
			animated_sprite.visible = true
			animated_sprite.play(str(selected_outfit))
			animated_sprite.speed_scale = 2.0

			# Set direction based on movement
			var x_input = Input.get_axis("left", "right")
			if x_input != 0:
				animated_sprite.flip_v = x_input < 0
			
			# Frame management
			if current_animation in player_animations:
				if animated_sprite.frame < player_animations[current_animation][0] or animated_sprite.frame >= player_animations[current_animation][-1]:
					animated_sprite.frame = player_animations[current_animation][0]

func get_next_state() -> String:
	# Prüfe Lebensstatus
	var life_state = check_life()
	if life_state != "":
		return life_state
	
	# Im Schwimmzustand bleiben
	return ""
	
func handle_input(event: InputEvent):
	check_menu_input(event)

func exit():
	# Create splash effect when exiting water
	create_splash_effect(false)  # false = exiting water
	
	# Reduce exit velocity (water exit slowdown)
	var exit_velocity = get_velocity()
	exit_velocity *= 1.2
	set_velocity(exit_velocity)
	
	for outfit in player.player_outfit:
		var animated_sprite = player.get_node("character_sprites/" + outfit)
		animated_sprite.flip_v = false
			
	# Rotation zurücksetzen, wenn der Zustand verlassen wird
	player.get_node("character_sprites").rotation_degrees = 0
