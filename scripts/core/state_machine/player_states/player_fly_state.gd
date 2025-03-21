class_name PlayerFlyState
extends PlayerBaseState

var elixir_drain_timer: float = 0.0
var drain_interval: float = 3.0  # Drain every 5 seconds
var drain_amount: float = 0.25   # Drain 25% each time

func enter():
	player.current_animation = "idle"  # You may want a specific fly animation
	elixir_drain_timer = 0.0  # Reset timer on state entry

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
		
	# Update fly time counter
	if player.passed_fly_time < 4:
		player.passed_fly_time += delta
		if y_input != 0:
			velocity.y = player.FLY_VELOCITY * y_input
	
	# Handle elixir drain
	elixir_drain_timer += delta
	if elixir_drain_timer >= drain_interval:
		elixir_drain_timer = 0.0  # Reset timer
		player.hud.use_softpower()
	
	if player.hud.elixir_fill_level <= 0:
		player.mode = "normal"
		
	
	
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
	if player.hud.elixir_fill_level <= 0:
		player.passed_fly_time = 0.0  # Reset fly time
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
	
	# Time limit check
	if player.passed_fly_time >= 4:
		return "PlayerFallState"
	
	# Stay in fly state
	return ""
	
func handle_input(event: InputEvent):
	check_menu_input(event)
