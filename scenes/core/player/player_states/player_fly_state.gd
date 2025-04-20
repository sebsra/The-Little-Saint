class_name PlayerFlyState
extends PlayerState

# Drain 5% per second instead of at intervals
var drain_rate: float = 0.05  # 5% per second

func enter():
	player.current_animation = "idle"  # You may want a specific fly animation
	# Always set mode to fly when entering this state
	player.mode = "fly"

func physics_process(delta: float):
	# Apply gravity
	var velocity = get_velocity()
	velocity.y += player.GRAVITY * delta
	
	# Read inputs
	var x_input = Input.get_axis("left", "right")
	var y_input = Input.get_axis("down", "up")
	
	# Apply horizontal movement
	if x_input != 0:
		velocity.x = x_input * player.SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, 30)
		
	# Apply vertical flying movement if input received
	if y_input != 0:
		velocity.y = player.FLY_VELOCITY * y_input
	
	# Only drain elixir when in air (not on floor)
	if !player.is_on_floor():
		# Drain elixir continuously at 5% per second
		GlobalHUD.update_elixir_fill(-drain_rate * delta*y_input)
	
	# If elixir is depleted, switch to normal mode
	if GlobalHUD.elixir_fill_level <= 0:
		player.mode = "fall"
		
	set_velocity(velocity)
	
	# Handle movement for character body
	player.move_and_slide()
	
	# Update outfit
	update_outfit()

func get_next_state() -> String:
	# Check state transitions
	var life_state = check_life()
	if life_state:
		return life_state
		
	# Check for attack input
	if Input.is_action_just_pressed("attack"):
		return "PlayerAttackState"
	
	# Check elixir level - transition to fall if empty
	if GlobalHUD.elixir_fill_level <= 0:
		player.passed_fly_time = 0.0  # Reset fly time
		player.ready_for_jump = false
		return "PlayerFallState"
	
	# Landing transition
	if player.is_on_floor():
		player.jump_counter = 0
		player.ready_for_jump = true
		player.passed_fly_time = 0.0
		
		# Check movement direction after landing
		var x_input = Input.get_axis("left", "right")
		if x_input != 0:
			return "PlayerWalkState"
		else:
			return "PlayerIdleState"
	
	# Stay in fly state
	return ""
	
func handle_input(event: InputEvent):
	check_menu_input(event)
